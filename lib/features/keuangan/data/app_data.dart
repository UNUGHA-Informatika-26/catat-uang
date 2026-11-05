import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anggaran.dart';
import '../models/transaksi.dart';

class AppData extends ChangeNotifier with WidgetsBindingObserver {
  AppData({SupabaseClient? client, Connectivity? connectivity})
    : _client = client ?? Supabase.instance.client,
      _connectivity = connectivity ?? Connectivity() {
    WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _koneksiBerubah,
      onError: (Object e) {
        error = 'Gagal memantau koneksi: $e';
        _kabari();
      },
    );
  }

  final SupabaseClient _client;
  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>>
  _connectivitySubscription;
  final List<Map<String, dynamic>> _outbox = [];
  Future<void> _syncQueue = Future<void>.value();
  Future<void> _persistQueue = Future<void>.value();
  bool _siap = false;
  bool _selesai = false;

  List<Transaksi> transaksi = [];
  List<Anggaran> anggaran = [];
  String nama = 'Pengguna';
  bool memuat = false;
  String? error;

  Box<String> get _box => Hive.box<String>('data');
  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Sesi Supabase tidak ditemukan. Silakan Log In.');
    }
    return id;
  }

  String get _prefix => 'u${_userId}_';

  @override
  void dispose() {
    _selesai = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_connectivitySubscription.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _siap) {
      unawaited(_jadwalkanSinkronisasi(ambilServer: true));
    }
  }

  void _koneksiBerubah(List<ConnectivityResult> hasil) {
    if (_siap && hasil.any((koneksi) => koneksi != ConnectivityResult.none)) {
      unawaited(_jadwalkanSinkronisasi(ambilServer: true));
    }
  }

  void _kabari() {
    if (!_selesai) notifyListeners();
  }

  int get saldo =>
      totalTransaksi(transaksi, true) - totalTransaksi(transaksi, false);

  List<Transaksi> bulan(DateTime d) => transaksi
      .where((t) => t.tanggal.year == d.year && t.tanggal.month == d.month)
      .toList();

  Anggaran? get batasBulanan {
    for (final a in anggaran) {
      if (a.kategori == kunciTotal) return a;
    }
    return null;
  }

  Future<void> muat() async {
    memuat = true;
    error = null;
    _kabari();
    try {
      final prefix = _prefix;
      transaksi = _baca('${prefix}transaksi', Transaksi.dariJson);
      anggaran = _baca('${prefix}anggaran', Anggaran.dariJson);
      _outbox
        ..clear()
        ..addAll(_bacaOutbox('${prefix}outbox'));
      nama = _box.get('${prefix}nama') ?? _namaDariSesi ?? 'Pengguna';
      _urutkan();
      _siap = true;
      _kabari();
      await _jadwalkanSinkronisasi(ambilServer: true);
    } catch (e) {
      error = 'Gagal memuat data lokal: $e';
    } finally {
      memuat = false;
      _kabari();
    }
  }

  String? get _namaDariSesi {
    final nilai = _client.auth.currentUser?.userMetadata?['nama'];
    return nilai is String && nilai.trim().isNotEmpty ? nilai.trim() : null;
  }

  List<T> _baca<T>(String key, T Function(Map<String, dynamic>) decode) {
    final json = _box.get(key);
    if (json == null || json.isEmpty) return <T>[];
    return (jsonDecode(json) as List)
        .map<T>((item) => decode(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  List<Map<String, dynamic>> _bacaOutbox(String key) {
    final json = _box.get(key);
    if (json == null || json.isEmpty) return [];
    return (jsonDecode(json) as List)
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  Future<void> _simpanLokal() {
    final prefix = _prefix;
    final snapshot = {
      '${prefix}transaksi': jsonEncode(
        transaksi.map((item) => item.toJson()).toList(),
      ),
      '${prefix}anggaran': jsonEncode(
        anggaran.map((item) => item.toJson()).toList(),
      ),
      '${prefix}nama': nama,
      '${prefix}outbox': jsonEncode(_outbox),
    };
    final write = _persistQueue.then((_) async {
      for (final entry in snapshot.entries) {
        await _box.put(entry.key, entry.value);
      }
      _kabari();
    });
    _persistQueue = write.catchError((Object _) {});
    return write;
  }

  Future<bool> _simpanDanSinkronkan(Map<String, dynamic> operasi) async {
    _outbox.add(operasi);
    await _simpanLokal();
    return _jadwalkanSinkronisasi();
  }

  Future<bool> _jadwalkanSinkronisasi({bool ambilServer = false}) {
    final pekerjaan = _syncQueue.then(
      (_) => _sinkronkan(ambilServer: ambilServer),
    );
    _syncQueue = pekerjaan.then<void>((_) {});
    return pekerjaan;
  }

  Future<bool> _sinkronkan({required bool ambilServer}) async {
    try {
      await _kirimOutbox();
      if (ambilServer) {
        final rowsTransaksi = await _client
            .from('transaksi')
            .select()
            .order('tanggal', ascending: false)
            .order('id', ascending: false);
        final rowsAnggaran = await _client
            .from('anggaran')
            .select()
            .order('kategori');
        transaksi = rowsTransaksi
            .map((row) => Transaksi.dariJson(row))
            .toList();
        anggaran = rowsAnggaran.map((row) => Anggaran.dariJson(row)).toList();
        _terapkanOutboxLokal();
        _urutkan();
        await _simpanLokal();
      }
      error = null;
      _kabari();
      return true;
    } catch (e) {
      error =
          'Data tetap tersimpan di perangkat. Sinkronisasi akan dicoba lagi saat koneksi tersedia. Detail: $e';
      _kabari();
      return false;
    }
  }

  Future<void> _kirimOutbox() async {
    while (_outbox.isNotEmpty) {
      final operasi = _outbox.first;
      final tipe = operasi['tipe'];
      final aksi = operasi['aksi'];

      if (tipe == 'transaksi' && aksi == 'simpan') {
        final data = Map<String, dynamic>.from(operasi['data'] as Map);
        final row = <String, dynamic>{
          'sync_id': data.remove('id'),
          ...data,
          'user_id': _userId,
        };
        await _client.from('transaksi').upsert(row, onConflict: 'sync_id');
      } else if (tipe == 'transaksi' && aksi == 'hapus') {
        await _client
            .from('transaksi')
            .delete()
            .eq('sync_id', operasi['id'])
            .eq('user_id', _userId);
      } else if (tipe == 'anggaran' && aksi == 'simpan') {
        final row = await _client
            .from('anggaran')
            .upsert({
              'user_id': _userId,
              'kategori': operasi['kategori'],
              'batas': operasi['batas'],
            }, onConflict: 'user_id,kategori')
            .select()
            .single();
        final index = anggaran.indexWhere(
          (item) => item.kategori == operasi['kategori'],
        );
        if (index >= 0) {
          anggaran[index] = Anggaran(
            id: row['id'],
            kategori: row['kategori'] as String,
            batas: (row['batas'] as num).toInt(),
          );
        }
      } else if (tipe == 'anggaran' && aksi == 'hapus') {
        await _client
            .from('anggaran')
            .delete()
            .eq('kategori', operasi['kategori'])
            .eq('user_id', _userId);
      } else {
        throw StateError('Operasi sinkronisasi tidak dikenal: $operasi');
      }

      _outbox.removeAt(0);
      await _simpanLokal();
    }
  }

  void _terapkanOutboxLokal() {
    for (final operasi in _outbox) {
      final tipe = operasi['tipe'];
      final aksi = operasi['aksi'];
      if (tipe == 'transaksi' && aksi == 'simpan') {
        final trans = Transaksi.dariJson(
          Map<String, dynamic>.from(operasi['data'] as Map),
        );
        final index = transaksi.indexWhere((item) => item.id == trans.id);
        if (index < 0) {
          transaksi.add(trans);
        } else {
          transaksi[index] = trans;
        }
      } else if (tipe == 'transaksi' && aksi == 'hapus') {
        transaksi.removeWhere((item) => item.id == operasi['id']);
      } else if (tipe == 'anggaran' && aksi == 'simpan') {
        final index = anggaran.indexWhere(
          (item) => item.kategori == operasi['kategori'],
        );
        final item = Anggaran(
          id: index < 0 ? _uuidV7() : anggaran[index].id,
          kategori: operasi['kategori'] as String,
          batas: (operasi['batas'] as num).toInt(),
        );
        if (index < 0) {
          anggaran.add(item);
        } else {
          anggaran[index] = item;
        }
      } else if (tipe == 'anggaran' && aksi == 'hapus') {
        anggaran.removeWhere((item) => item.kategori == operasi['kategori']);
      }
    }
  }

  void _urutkan() {
    transaksi.sort((a, b) {
      final tanggal = b.tanggal.compareTo(a.tanggal);
      return tanggal != 0 ? tanggal : b.id.compareTo(a.id);
    });
  }

  Future<void> ubahNama(String baru) async {
    final namaBaru = baru.trim().isEmpty ? 'Pengguna' : baru.trim();
    await _client.auth.updateUser(UserAttributes(data: {'nama': namaBaru}));
    await _client.from('profiles').update({'nama': namaBaru}).eq('id', _userId);
    nama = namaBaru;
    await _simpanLokal();
  }

  Future<bool> tambahTransaksi({
    required int nominal,
    required String kategori,
    required bool pemasukan,
    required DateTime tanggal,
    required String catatan,
  }) async {
    final trans = Transaksi(
      id: _uuidV7(),
      kategori: kategori,
      catatan: catatan,
      nominal: nominal,
      pemasukan: pemasukan,
      tanggal: tanggal,
    );
    transaksi.add(trans);
    _urutkan();
    return _simpanDanSinkronkan({
      'tipe': 'transaksi',
      'aksi': 'simpan',
      'data': trans.toJson(),
    });
  }

  Future<bool> ubahTransaksi(
    String id, {
    required int nominal,
    required String kategori,
    required bool pemasukan,
    required DateTime tanggal,
    required String catatan,
  }) async {
    final index = transaksi.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Transaksi tidak ditemukan.');
    final trans = Transaksi(
      id: id,
      kategori: kategori,
      catatan: catatan,
      nominal: nominal,
      pemasukan: pemasukan,
      tanggal: tanggal,
    );
    transaksi[index] = trans;
    _urutkan();
    return _simpanDanSinkronkan({
      'tipe': 'transaksi',
      'aksi': 'simpan',
      'data': trans.toJson(),
    });
  }

  Future<bool> hapusTransaksi(String id) async {
    final index = transaksi.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Transaksi tidak ditemukan.');
    transaksi.removeAt(index);
    return _simpanDanSinkronkan({
      'tipe': 'transaksi',
      'aksi': 'hapus',
      'id': id,
    });
  }

  Future<bool> simpanAnggaran(String kategori, int batas) async {
    final kategoriBersih = kategori.trim();
    if (kategoriBersih.isEmpty || batas <= 0) {
      throw ArgumentError('Kategori dan batas anggaran harus valid.');
    }
    final index = anggaran.indexWhere(
      (item) => item.kategori == kategoriBersih,
    );
    final anggaranBaru = Anggaran(
      id: index >= 0 ? anggaran[index].id : _uuidV7(),
      kategori: kategoriBersih,
      batas: batas,
    );
    if (index >= 0) {
      anggaran[index] = anggaranBaru;
    } else {
      anggaran.add(anggaranBaru);
    }
    return _simpanDanSinkronkan({
      'tipe': 'anggaran',
      'aksi': 'simpan',
      'kategori': kategoriBersih,
      'batas': batas,
    });
  }

  Future<bool> hapusAnggaran(dynamic id) async {
    final index = anggaran.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Anggaran tidak ditemukan.');
    final kategori = anggaran.removeAt(index).kategori;
    return _simpanDanSinkronkan({
      'tipe': 'anggaran',
      'aksi': 'hapus',
      'kategori': kategori,
    });
  }

  String _uuidV7() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    for (var index = 0; index < 6; index++) {
      bytes[index] = (timestamp >> ((5 - index) * 8)) & 0xff;
    }
    bytes[6] = 0x70 | (bytes[6] & 0x0f);
    bytes[8] = 0x80 | (bytes[8] & 0x3f);
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}
