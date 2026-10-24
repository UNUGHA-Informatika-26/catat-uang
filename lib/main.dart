import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// MODE OFFLINE: semua data disimpan di perangkat (shared_preferences).
// Akun (Register / Log In / Log Out) juga disimpan lokal. Tanpa internet.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CatatUangApp());
}

// ============================================================
// WARNA, FORMAT, DAN WIDGET BANTU
// ============================================================

const Color hijauTua = Color(0xFF075C3B);
const Color hijau = Color(0xFF0B7A4B);
const Color latar = Color(0xFFF4F8F3);
const Color hijauMuda = Color(0xFFE4F3E9);
const Color merah = Color(0xFFD64545);
const Color merahMuda = Color(0xFFFFE9E7);
const Color teksGelap = Color(0xFF17251D);
const Color teksAbu = Color(0xFF6B7770);
const Color garis = Color(0xFFDDE5DD);

const _bulanPendek = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];
const _bulanPanjang = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const _hariPendek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

String _tanggalSql(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String _tgl(DateTime d) => '${d.day} ${_bulanPendek[d.month - 1]} ${d.year}';

bool _sama(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _labelHari(DateTime d) {
  final sekarang = DateTime.now();
  if (_sama(d, sekarang)) return 'Hari ini';
  if (_sama(d, DateTime(sekarang.year, sekarang.month, sekarang.day - 1))) {
    return 'Kemarin';
  }
  return _tgl(d);
}

String _rp(int angka) {
  final teks = angka.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < teks.length; i++) {
    buffer.write(teks[i]);
    final sisa = teks.length - i - 1;
    if (sisa > 0 && sisa % 3 == 0) buffer.write('.');
  }
  return '${angka < 0 ? '-' : ''}Rp$buffer';
}

Color _muda(Color c) => Color.alphaBlend(c.withAlpha(36), Colors.white);

void _pesan(BuildContext context, String teks) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(teks)));
}

Future<bool> _konfirmasi(BuildContext context, String judul, String isi) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(judul),
      content: Text(isi),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Hapus', style: TextStyle(color: merah)),
        ),
      ],
    ),
  );
  return hasil == true;
}

Widget _kartu({
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  Color warna = Colors.white,
}) {
  return Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: warna,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 3)),
      ],
    ),
    child: child,
  );
}

Widget _kosong(IconData ikon, String judul, String isi) {
  return _kartu(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
    child: Column(
      children: [
        Icon(ikon, size: 38, color: Colors.black38),
        const SizedBox(height: 10),
        Text(judul, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          isi,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: teksAbu),
        ),
      ],
    ),
  );
}

Widget _judulBagian(String teks, {Widget? aksi}) {
  return Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          teks,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: teksGelap,
          ),
        ),
        if (aksi != null) aksi,
      ],
    ),
  );
}

InputDecoration _dekor(String hint, {Widget? suffix, IconData? ikon}) {
  final batas = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: garis),
  );
  return InputDecoration(
    hintText: hint,
    prefixIcon: ikon == null ? null : Icon(ikon, color: teksAbu, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: batas,
    enabledBorder: batas,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: hijauTua, width: 1.5),
    ),
  );
}

Widget _tombolUtama(
  String teks,
  VoidCallback? onTap, {
  bool loading = false,
  IconData? ikon,
}) {
  return SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: hijauTua,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF5E9983),
        disabledForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: loading ? null : onTap,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  teks,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (ikon != null) ...[
                  const SizedBox(width: 8),
                  Icon(ikon, size: 18),
                ],
              ],
            ),
    ),
  );
}

Widget _bar(double nilai, Color warna, {double tinggi = 9}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: LinearProgressIndicator(
      value: nilai,
      minHeight: tinggi,
      backgroundColor: hijauMuda,
      color: warna,
    ),
  );
}

// ============================================================
// KATEGORI
// ============================================================

class KategoriInfo {
  const KategoriInfo(this.nama, this.ikon, this.warna);
  final String nama;
  final IconData ikon;
  final Color warna;
}

const kategoriPengeluaran = [
  KategoriInfo('Makanan', Icons.restaurant, Color(0xFFE8833A)),
  KategoriInfo('Transportasi', Icons.directions_bus, Color(0xFF3B82C4)),
  KategoriInfo('Belanja', Icons.shopping_bag, Color(0xFF8E5BC9)),
  KategoriInfo('Tagihan', Icons.receipt_long, Color(0xFFD9534F)),
  KategoriInfo('Hiburan', Icons.movie, Color(0xFFE05A9C)),
  KategoriInfo('Kesehatan', Icons.favorite, Color(0xFF2FA89A)),
  KategoriInfo('Pendidikan', Icons.school, Color(0xFF4F6FD8)),
  KategoriInfo('Lainnya', Icons.more_horiz, Color(0xFF7A8580)),
];

const kategoriPemasukan = [
  KategoriInfo('Gaji', Icons.payments, Color(0xFF0B7A4B)),
  KategoriInfo('Bonus', Icons.card_giftcard, Color(0xFF3B82C4)),
  KategoriInfo('Usaha', Icons.storefront, Color(0xFFE8833A)),
  KategoriInfo('Hadiah', Icons.redeem, Color(0xFFE05A9C)),
  KategoriInfo('Lainnya', Icons.more_horiz, Color(0xFF7A8580)),
];

KategoriInfo infoKategori(String nama, bool pemasukan) {
  final daftar = pemasukan ? kategoriPemasukan : kategoriPengeluaran;
  for (final k in daftar) {
    if (k.nama == nama) return k;
  }
  return KategoriInfo(nama, Icons.category, const Color(0xFF7A8580));
}

// ============================================================
// MODEL DATA (DISIMPAN LOKAL SEBAGAI JSON)
// ============================================================

class Transaksi {
  const Transaksi({
    required this.id,
    required this.kategori,
    required this.catatan,
    required this.nominal,
    required this.pemasukan,
    required this.tanggal,
  });

  final dynamic id;
  final String kategori;
  final String catatan;
  final int nominal;
  final bool pemasukan;
  final DateTime tanggal;

  String get judul => catatan.isEmpty ? kategori : catatan;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kategori': kategori,
        'catatan': catatan,
        'nominal': nominal,
        'pemasukan': pemasukan,
        'tanggal': _tanggalSql(tanggal),
      };

  static Transaksi dariJson(Map<String, dynamic> j) => Transaksi(
        id: j['id'],
        kategori: (j['kategori'] as String?) ?? 'Lainnya',
        catatan: (j['catatan'] as String?) ?? '',
        nominal: ((j['nominal'] as num?) ?? 0).toInt(),
        pemasukan: j['pemasukan'] == true,
        tanggal: DateTime.tryParse('${j['tanggal']}') ?? DateTime.now(),
      );
}

class Setoran {
  const Setoran({
    required this.id,
    required this.targetId,
    required this.nominal,
    required this.tanggal,
  });

  final dynamic id;
  final dynamic targetId;
  final int nominal;
  final DateTime tanggal;

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetId': targetId,
        'nominal': nominal,
        'tanggal': _tanggalSql(tanggal),
      };

  static Setoran dariJson(Map<String, dynamic> j) => Setoran(
        id: j['id'],
        targetId: j['targetId'],
        nominal: ((j['nominal'] as num?) ?? 0).toInt(),
        tanggal: DateTime.tryParse('${j['tanggal']}') ?? DateTime.now(),
      );
}

class TargetTabungan {
  const TargetTabungan({
    required this.id,
    required this.nama,
    required this.target,
    required this.awal,
    required this.tanggal,
    this.riwayat = const [],
  });

  final dynamic id;
  final String nama;
  final int target;
  final int awal; // setoran awal
  final DateTime? tanggal; // tenggat target
  final List<Setoran> riwayat; // setoran berikutnya, masing-masing ada tanggal

  int get terkumpul => awal + riwayat.fold<int>(0, (s, r) => s + r.nominal);

  double get rasio =>
      target <= 0 ? 0.0 : (terkumpul / target).clamp(0.0, 1.0).toDouble();

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'target': target,
        'awal': awal,
        'tanggal': tanggal == null ? null : _tanggalSql(tanggal!),
      };

  static TargetTabungan dariJson(Map<String, dynamic> j) => TargetTabungan(
        id: j['id'],
        nama: (j['nama'] as String?) ?? '',
        target: ((j['target'] as num?) ?? 0).toInt(),
        awal: ((j['awal'] as num?) ?? 0).toInt(),
        tanggal: DateTime.tryParse('${j['tanggal']}'),
      );
}

class Anggaran {
  const Anggaran({required this.id, required this.kategori, required this.batas});
  final dynamic id;
  final String kategori;
  final int batas;

  Map<String, dynamic> toJson() =>
      {'id': id, 'kategori': kategori, 'batas': batas};

  static Anggaran dariJson(Map<String, dynamic> j) => Anggaran(
        id: j['id'],
        kategori: (j['kategori'] as String?) ?? '',
        batas: ((j['batas'] as num?) ?? 0).toInt(),
      );
}

const kunciTotal = 'Total';

int _total(Iterable<Transaksi> daftar, bool pemasukan) => daftar
    .where((t) => t.pemasukan == pemasukan)
    .fold<int>(0, (jumlah, t) => jumlah + t.nominal);

// ============================================================
// PENYIMPANAN LOKAL (CRUD TANPA INTERNET)
// ============================================================

class AppData extends ChangeNotifier {
  List<Transaksi> transaksi = [];
  List<TargetTabungan> _targetDasar = [];
  List<Setoran> _setoran = [];
  List<Anggaran> anggaran = [];
  String nama = 'Pengguna';
  bool memuat = false;
  String? error;
  int _nextId = 1;
  bool _selesai = false;

  // Data dipisah per akun.
  String get _p => 'u${AuthLokal.aktif?.id ?? 0}_';

  @override
  void dispose() {
    _selesai = true;
    super.dispose();
  }

  void _kabari() {
    if (!_selesai) notifyListeners();
  }

  int get saldo => _total(transaksi, true) - _total(transaksi, false);

  /// Target beserta riwayat setorannya.
  List<TargetTabungan> get target => _targetDasar
      .map((t) => TargetTabungan(
            id: t.id,
            nama: t.nama,
            target: t.target,
            awal: t.awal,
            tanggal: t.tanggal,
            riwayat: _setoran.where((s) => s.targetId == t.id).toList(),
          ))
      .toList();

  List<Transaksi> bulan(DateTime d) => transaksi
      .where((t) => t.tanggal.year == d.year && t.tanggal.month == d.month)
      .toList();

  Anggaran? get batasBulanan {
    for (final a in anggaran) {
      if (a.kategori == kunciTotal) return a;
    }
    return null;
  }

  // ---------- BACA ----------
  Future<void> muat() async {
    memuat = true;
    error = null;
    _kabari();
    try {
      final p = await SharedPreferences.getInstance();
      List<T> baca<T>(String kunci, T Function(Map<String, dynamic>) dari) {
        final s = p.getString(kunci);
        if (s == null || s.isEmpty) return <T>[];
        return (jsonDecode(s) as List)
            .map<T>((e) => dari(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      transaksi = baca('${_p}transaksi', Transaksi.dariJson);
      _targetDasar = baca('${_p}target', TargetTabungan.dariJson);
      _setoran = baca('${_p}setoran', Setoran.dariJson);
      anggaran = baca('${_p}anggaran', Anggaran.dariJson);
      nama = p.getString('${_p}nama') ?? 'Pengguna';
      _nextId = p.getInt('${_p}next_id') ?? 1;
      _urutkan();
    } catch (e) {
      error = 'Gagal membaca data: $e';
    }
    memuat = false;
    _kabari();
  }

  // ---------- SIMPAN ----------
  void _urutkan() {
    int banding(DateTime a, dynamic ida, DateTime b, dynamic idb) {
      final c = b.compareTo(a);
      return c != 0 ? c : (idb as int).compareTo(ida as int);
    }

    transaksi.sort((a, b) => banding(a.tanggal, a.id, b.tanggal, b.id));
    _setoran.sort((a, b) => banding(a.tanggal, a.id, b.tanggal, b.id));
    _targetDasar.sort((a, b) {
      if (a.tanggal == null && b.tanggal == null) return 0;
      if (a.tanggal == null) return 1;
      if (b.tanggal == null) return -1;
      return a.tanggal!.compareTo(b.tanggal!);
    });
  }

  Future<void> _commit() async {
    _urutkan();
    final p = await SharedPreferences.getInstance();
    await p.setString(
        '${_p}transaksi', jsonEncode(transaksi.map((e) => e.toJson()).toList()));
    await p.setString(
        '${_p}target', jsonEncode(_targetDasar.map((e) => e.toJson()).toList()));
    await p.setString(
        '${_p}setoran', jsonEncode(_setoran.map((e) => e.toJson()).toList()));
    await p.setString(
        '${_p}anggaran', jsonEncode(anggaran.map((e) => e.toJson()).toList()));
    await p.setString('${_p}nama', nama);
    await p.setInt('${_p}next_id', _nextId);
    _kabari();
  }

  Future<void> ubahNama(String baru) async {
    nama = baru.trim().isEmpty ? 'Pengguna' : baru.trim();
    await _commit();
  }

  // ---------- TRANSAKSI ----------
  Future<void> tambahTransaksi({
    required int nominal,
    required String kategori,
    required bool pemasukan,
    required DateTime tanggal,
    required String catatan,
  }) async {
    transaksi.add(Transaksi(
      id: _nextId++,
      kategori: kategori,
      catatan: catatan,
      nominal: nominal,
      pemasukan: pemasukan,
      tanggal: tanggal,
    ));
    await _commit();
  }

  Future<void> ubahTransaksi(
    dynamic id, {
    required int nominal,
    required String kategori,
    required bool pemasukan,
    required DateTime tanggal,
    required String catatan,
  }) async {
    final i = transaksi.indexWhere((t) => t.id == id);
    if (i < 0) return;
    transaksi[i] = Transaksi(
      id: id,
      kategori: kategori,
      catatan: catatan,
      nominal: nominal,
      pemasukan: pemasukan,
      tanggal: tanggal,
    );
    await _commit();
  }

  Future<void> hapusTransaksi(dynamic id) async {
    transaksi.removeWhere((t) => t.id == id);
    await _commit();
  }

  // ---------- TARGET TABUNGAN ----------
  Future<void> tambahTarget({
    required String nama,
    required int target,
    required int terkumpul,
    required DateTime tanggal,
  }) async {
    _targetDasar.add(TargetTabungan(
      id: _nextId++,
      nama: nama,
      target: target,
      awal: terkumpul,
      tanggal: tanggal,
    ));
    await _commit();
  }

  Future<void> ubahTarget(
    dynamic id, {
    required String nama,
    required int target,
    required int terkumpul,
    required DateTime tanggal,
  }) async {
    final i = _targetDasar.indexWhere((t) => t.id == id);
    if (i < 0) return;
    _targetDasar[i] = TargetTabungan(
      id: id,
      nama: nama,
      target: target,
      awal: terkumpul,
      tanggal: tanggal,
    );
    await _commit();
  }

  Future<void> hapusTarget(dynamic id) async {
    _targetDasar.removeWhere((t) => t.id == id);
    _setoran.removeWhere((s) => s.targetId == id);
    await _commit();
  }

  // ---------- SETORAN (RIWAYAT PER TARGET) ----------
  Future<void> setorTarget(
    TargetTabungan t, {
    required int nominal,
    required DateTime tanggal,
  }) async {
    _setoran.add(Setoran(
      id: _nextId++,
      targetId: t.id,
      nominal: nominal,
      tanggal: tanggal,
    ));
    await _commit();
  }

  Future<void> ubahSetoran(
    dynamic id, {
    required int nominal,
    required DateTime tanggal,
  }) async {
    final i = _setoran.indexWhere((s) => s.id == id);
    if (i < 0) return;
    _setoran[i] = Setoran(
      id: id,
      targetId: _setoran[i].targetId,
      nominal: nominal,
      tanggal: tanggal,
    );
    await _commit();
  }

  Future<void> hapusSetoran(dynamic id) async {
    _setoran.removeWhere((s) => s.id == id);
    await _commit();
  }

  // ---------- ANGGARAN ----------
  Future<void> simpanAnggaran(String kategori, int batas) async {
    final i = anggaran.indexWhere((a) => a.kategori == kategori);
    if (i >= 0) {
      anggaran[i] = Anggaran(id: anggaran[i].id, kategori: kategori, batas: batas);
    } else {
      anggaran.add(Anggaran(id: _nextId++, kategori: kategori, batas: batas));
    }
    await _commit();
  }

  Future<void> hapusAnggaran(dynamic id) async {
    anggaran.removeWhere((a) => a.id == id);
    await _commit();
  }
}

// ============================================================
// APLIKASI, SPLASH, ONBOARDING
// ============================================================

class CatatUangApp extends StatelessWidget {
  const CatatUangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Catat Uang',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: latar,
        colorScheme: ColorScheme.fromSeed(seedColor: hijauTua),
      ),
      // Di layar lebar (Chrome) tampilan dibatasi selebar HP.
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFE6ECE5),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      await AuthLokal.pulihkan();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AuthLokal.aktif != null
              ? const HomeShell()
              : const OnboardingScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hijauTua,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 38,
                color: hijauTua,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'CatatUang',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Catat keuangan, lebih terkendali',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Widget _fitur(IconData ikon, String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _kartu(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: hijauMuda,
              child: Icon(ikon, size: 18, color: hijauTua),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                teks,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kotak(String label, String nilai, IconData ikon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0x26FFFFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ikon, size: 14, color: Colors.white70),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              nilai,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'CatatUang',
                        style: TextStyle(
                          color: hijauTua,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: hijauTua,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Saldo',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Rp14.850.000',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _kotak('Pemasukan', 'Rp8.000.000', Icons.south_west),
                              const SizedBox(width: 10),
                              _kotak('Pengeluaran', 'Rp2.150.000', Icons.north_east),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Kelola Uang Harian Jadi Lebih Mudah & Teratur',
                      style: TextStyle(
                        fontSize: 24,
                        height: 1.25,
                        fontWeight: FontWeight.bold,
                        color: teksGelap,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Catat pemasukan dan pengeluaran, pantau laporan, dan capai target tabunganmu dalam satu aplikasi.',
                      style: TextStyle(fontSize: 14, height: 1.5, color: teksAbu),
                    ),
                    const SizedBox(height: 20),
                    _fitur(Icons.edit_note, 'Catat transaksi dengan cepat'),
                    _fitur(Icons.bar_chart, 'Lihat grafik keuangan dengan jelas'),
                    _fitur(Icons.savings_outlined, 'Capai target tabunganmu'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _tombolUtama(
                'Mulai Sekarang',
                () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                ikon: Icons.arrow_forward,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sudah punya akun?',
                    style: TextStyle(color: teksAbu, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: hijauTua,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// AKUN LOKAL (OFFLINE): REGISTER, LOG IN, LOG OUT
// Akun disimpan di perangkat, tanpa internet dan tanpa server.
// ============================================================

class Akun {
  const Akun({
    required this.id,
    required this.nama,
    required this.email,
    required this.sandi,
  });

  final String id;
  final String nama;
  final String email;
  final String sandi; // sudah di-hash, bukan teks asli

  Map<String, dynamic> toJson() =>
      {'id': id, 'nama': nama, 'email': email, 'sandi': sandi};

  static Akun dariJson(Map<String, dynamic> j) => Akun(
        id: '${j['id']}',
        nama: (j['nama'] as String?) ?? 'Pengguna',
        email: (j['email'] as String?) ?? '',
        sandi: (j['sandi'] as String?) ?? '',
      );
}

class AuthGalat implements Exception {
  const AuthGalat(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthLokal {
  static Akun? aktif;

  // Pengamanan sederhana (cukup untuk aplikasi offline di perangkat sendiri).
  static String _hash(String sandi) {
    var a = 5381;
    var b = 52711;
    for (final c in 'catatuang|$sandi'.codeUnits) {
      a = ((a * 33) ^ c) & 0x7FFFFFFF;
      b = ((b * 131) + c) & 0x7FFFFFFF;
    }
    return '${a.toRadixString(16)}-${b.toRadixString(16)}';
  }

  static List<Akun> _daftar(SharedPreferences p) {
    final s = p.getString('akun_daftar');
    if (s == null || s.isEmpty) return [];
    return (jsonDecode(s) as List)
        .map<Akun>((e) => Akun.dariJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> _simpan(SharedPreferences p, List<Akun> d) async {
    await p.setString('akun_daftar', jsonEncode(d.map((e) => e.toJson()).toList()));
  }

  /// Dipanggil saat aplikasi dibuka: masuk otomatis kalau belum Log Out.
  static Future<void> pulihkan() async {
    try {
      final p = await SharedPreferences.getInstance();
      final id = p.getString('akun_aktif');
      if (id == null) return;
      for (final a in _daftar(p)) {
        if (a.id == id) {
          aktif = a;
          return;
        }
      }
    } catch (_) {}
  }

  static Future<Akun> daftar({
    required String nama,
    required String email,
    required String sandi,
  }) async {
    final p = await SharedPreferences.getInstance();
    final d = _daftar(p);
    final em = email.trim().toLowerCase();
    if (d.any((a) => a.email == em)) {
      throw const AuthGalat('Email sudah terdaftar. Silakan Log In.');
    }
    final no = p.getInt('akun_next') ?? 1;
    await p.setInt('akun_next', no + 1);
    final akun = Akun(id: '$no', nama: nama.trim(), email: em, sandi: _hash(sandi));
    d.add(akun);
    await _simpan(p, d);
    await p.setString('akun_aktif', akun.id);
    aktif = akun;
    return akun;
  }

  static Future<Akun> masuk({required String email, required String sandi}) async {
    final p = await SharedPreferences.getInstance();
    final em = email.trim().toLowerCase();
    for (final a in _daftar(p)) {
      if (a.email == em && a.sandi == _hash(sandi)) {
        await p.setString('akun_aktif', a.id);
        aktif = a;
        return a;
      }
    }
    throw const AuthGalat('Email atau password salah.');
  }

  static Future<void> keluar() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('akun_aktif');
    aktif = null;
  }

  static Future<void> aturUlangSandi({
    required String email,
    required String sandiBaru,
  }) async {
    final p = await SharedPreferences.getInstance();
    final d = _daftar(p);
    final em = email.trim().toLowerCase();
    final i = d.indexWhere((a) => a.email == em);
    if (i < 0) throw const AuthGalat('Email belum terdaftar.');
    d[i] = Akun(id: d[i].id, nama: d[i].nama, email: d[i].email, sandi: _hash(sandiBaru));
    await _simpan(p, d);
  }
}

Widget _label(String teks) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      teks,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: teksGelap,
      ),
    ),
  );
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.judul,
    required this.subjudul,
    required this.children,
    this.bisaKembali = false,
  });

  final String judul;
  final String subjudul;
  final List<Widget> children;
  final bool bisaKembali;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bisaKembali)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                )
              else
                const SizedBox(height: 28),
              const SizedBox(height: 8),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: hijauTua,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                judul,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: teksGelap,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subjudul,
                style: const TextStyle(fontSize: 14, color: teksAbu, height: 1.4),
              ),
              const SizedBox(height: 28),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

Widget _ikonMata(bool tersembunyi, VoidCallback onTap) {
  return IconButton(
    onPressed: onTap,
    icon: Icon(
      tersembunyi ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      color: teksAbu,
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  bool _loading = false;
  bool _sembunyi = true;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    final email = _email.text.trim();
    if (email.isEmpty || _sandi.text.isEmpty) {
      _pesan(context, 'Isi email dan password terlebih dahulu.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthLokal.masuk(email: email, sandi: _sandi.text);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (_) => false,
      );
    } on AuthGalat catch (e) {
      if (mounted) _pesan(context, e.message);
    } catch (e) {
      if (mounted) _pesan(context, 'Gagal Log In: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      judul: 'Log In',
      subjudul: 'Selamat datang kembali! Log In untuk mengelola keuanganmu.',
      children: [
        _label('Email'),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: _dekor('Masukkan email kamu', ikon: Icons.mail_outline),
        ),
        const SizedBox(height: 18),
        _label('Password'),
        TextField(
          controller: _sandi,
          obscureText: _sembunyi,
          decoration: _dekor(
            'Masukkan password',
            ikon: Icons.lock_outline,
            suffix: _ikonMata(_sembunyi, () => setState(() => _sembunyi = !_sembunyi)),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
            ),
            child: const Text('Lupa Kata Sandi?'),
          ),
        ),
        const SizedBox(height: 6),
        _tombolUtama('Log In ke CatatUang', _logIn,
            loading: _loading, ikon: Icons.arrow_forward),
        const SizedBox(height: 18),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('ATAU', style: TextStyle(fontSize: 11, color: teksAbu)),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: teksGelap,
              backgroundColor: Colors.white,
              side: const BorderSide(color: garis),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _pesan(context, 'Log In dengan Google belum tersedia.'),
            icon: const Text(
              'G',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFFDB4437),
              ),
            ),
            label: const Text('Lanjutkan dengan Google'),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Belum punya akun?', style: TextStyle(color: teksAbu)),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text(
                'Register',
                style: TextStyle(color: hijauTua, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  final _konfirmasi = TextEditingController();
  bool _loading = false;
  bool _sembunyi = true;
  bool _sembunyiKonfirmasi = true;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _sandi.dispose();
    _konfirmasi.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final nama = _nama.text.trim();
    final email = _email.text.trim();
    if (nama.isEmpty) {
      _pesan(context, 'Nama lengkap harus diisi.');
      return;
    }
    if (!email.contains('@')) {
      _pesan(context, 'Masukkan email yang valid.');
      return;
    }
    if (_sandi.text.length < 8) {
      _pesan(context, 'Password minimal 8 karakter.');
      return;
    }
    if (_sandi.text != _konfirmasi.text) {
      _pesan(context, 'Konfirmasi password tidak sama.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthLokal.daftar(nama: nama, email: email, sandi: _sandi.text);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (_) => false,
      );
    } on AuthGalat catch (e) {
      if (mounted) _pesan(context, e.message);
    } catch (e) {
      if (mounted) _pesan(context, 'Gagal Register: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      judul: 'Register',
      subjudul: 'Buat akun baru untuk mulai mencatat keuanganmu.',
      children: [
        _label('Nama Lengkap'),
        TextField(
          controller: _nama,
          textCapitalization: TextCapitalization.words,
          decoration: _dekor('Nama kamu', ikon: Icons.person_outline),
        ),
        const SizedBox(height: 16),
        _label('Email'),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: _dekor('Email aktif', ikon: Icons.mail_outline),
        ),
        const SizedBox(height: 16),
        _label('Password'),
        TextField(
          controller: _sandi,
          obscureText: _sembunyi,
          decoration: _dekor(
            'Minimal 8 karakter',
            ikon: Icons.lock_outline,
            suffix: _ikonMata(_sembunyi, () => setState(() => _sembunyi = !_sembunyi)),
          ),
        ),
        const SizedBox(height: 16),
        _label('Konfirmasi Password'),
        TextField(
          controller: _konfirmasi,
          obscureText: _sembunyiKonfirmasi,
          decoration: _dekor(
            'Ulangi password',
            ikon: Icons.lock_outline,
            suffix: _ikonMata(
              _sembunyiKonfirmasi,
              () => setState(() => _sembunyiKonfirmasi = !_sembunyiKonfirmasi),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _tombolUtama('Register', _register, loading: _loading),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Sudah punya akun?', style: TextStyle(color: teksAbu)),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text(
                'Log In',
                style: TextStyle(color: hijauTua, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  bool _loading = false;
  bool _sembunyi = true;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _atur() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      _pesan(context, 'Masukkan email terdaftar.');
      return;
    }
    if (_sandi.text.length < 8) {
      _pesan(context, 'Password baru minimal 8 karakter.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthLokal.aturUlangSandi(email: email, sandiBaru: _sandi.text);
      if (!mounted) return;
      _pesan(context, 'Kata sandi diperbarui. Silakan Log In.');
      Navigator.pop(context);
    } on AuthGalat catch (e) {
      if (mounted) _pesan(context, e.message);
    } catch (e) {
      if (mounted) _pesan(context, 'Gagal mengatur ulang kata sandi: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      bisaKembali: true,
      judul: 'Lupa Kata Sandi?',
      subjudul: 'Masukkan email terdaftar dan kata sandi baru.',
      children: [
        _label('Email'),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: _dekor('Masukkan email terdaftar', ikon: Icons.mail_outline),
        ),
        const SizedBox(height: 16),
        _label('Password Baru'),
        TextField(
          controller: _sandi,
          obscureText: _sembunyi,
          decoration: _dekor(
            'Minimal 8 karakter',
            ikon: Icons.lock_outline,
            suffix: _ikonMata(_sembunyi, () => setState(() => _sembunyi = !_sembunyi)),
          ),
        ),
        const SizedBox(height: 24),
        _tombolUtama('Atur Ulang Kata Sandi', _atur, loading: _loading),
      ],
    );
  }
}

Future<void> _logOut(BuildContext context) async {
  final nav = Navigator.of(context);
  try {
    await AuthLokal.keluar();
  } catch (e) {
    if (context.mounted) _pesan(context, 'Gagal Log Out: $e');
    return;
  }
  nav.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}

void _tampilProfil(BuildContext context, AppData data) {
  final akun = AuthLokal.aktif;
  final nama = akun?.nama ?? 'Pengguna';
  final email = akun?.email ?? '-';
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: hijauMuda,
            child: Icon(Icons.person_outline, size: 36, color: hijauTua),
          ),
          const SizedBox(height: 12),
          Text(nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(color: teksAbu)),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: merah,
                side: const BorderSide(color: merah),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(sheet);
                _logOut(context);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
            ),
          ),
        ],
      ),
    ),
  );
}

// ============================================================
// HALAMAN UTAMA (BOTTOM NAVIGATION)
// ============================================================

Future<void> _bukaFormTransaksi(
  BuildContext context,
  AppData data, {
  Transaksi? awal,
}) async {
  final hasil = await Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => TransaksiFormScreen(data: data, awal: awal)),
  );
  if (hasil != null && context.mounted) _pesan(context, hasil);
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final AppData data = AppData();
  int tab = 0;

  @override
  void initState() {
    super.initState();
    data.muat();
  }

  @override
  void dispose() {
    data.dispose();
    super.dispose();
  }

  void _pindah(int i) => setState(() => tab = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: data,
          builder: (context, _) => IndexedStack(
            index: tab,
            children: [
              BerandaTab(data: data, onPindah: _pindah),
              TransaksiTab(data: data),
              LaporanTab(data: data),
              TabunganTab(data: data),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: hijauTua,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => _bukaFormTransaksi(context, data),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_outlined, 'Beranda'),
              _navItem(1, Icons.receipt_long_outlined, 'Transaksi'),
              const SizedBox(width: 40),
              _navItem(2, Icons.bar_chart_outlined, 'Laporan'),
              _navItem(3, Icons.savings_outlined, 'Tabungan'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData ikon, String label) {
    final aktif = tab == index;
    return InkWell(
      onTap: () => _pindah(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, color: aktif ? hijauTua : Colors.grey),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
                color: aktif ? hijauTua : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarisTransaksi extends StatelessWidget {
  const _BarisTransaksi({required this.t, this.onTap, this.onLongPress});

  final Transaksi t;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final info = infoKategori(t.kategori, t.pemasukan);
    final warna = t.pemasukan ? hijauTua : merah;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _muda(info.warna),
                  child: Icon(info.ikon, color: info.warna, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.judul,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${t.kategori} · ${_tgl(t.tanggal)}',
                        style: const TextStyle(fontSize: 11, color: teksAbu),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${t.pemasukan ? '+' : '-'}${_rp(t.nominal)}',
                  style: TextStyle(color: warna, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TAB BERANDA
// ============================================================

class BerandaTab extends StatelessWidget {
  const BerandaTab({super.key, required this.data, required this.onPindah});

  final AppData data;
  final ValueChanged<int> onPindah;

  Widget _kotakAlir(String label, int nilai, IconData ikon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x26FFFFFF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ikon, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _rp(nilai),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aksi(IconData ikon, String label, Color warna, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _muda(warna),
                child: Icon(ikon, color: warna, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sekarang = DateTime.now();
    final bln = data.bulan(sekarang);
    final masuk = _total(bln, true);
    final keluar = _total(bln, false);
    final double rasio = masuk > 0
        ? (keluar / masuk).clamp(0.0, 1.0).toDouble()
        : (keluar > 0 ? 1.0 : 0.0);

    return RefreshIndicator(
      onRefresh: data.muat,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          if (data.memuat) const LinearProgressIndicator(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Halo,',
                        style: TextStyle(color: teksAbu, fontSize: 14)),
                    Text(
                      AuthLokal.aktif?.nama ?? data.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: teksGelap,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: hijauMuda,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_bulanPanjang[sekarang.month - 1]} ${sekarang.year}',
                  style: const TextStyle(
                    color: hijauTua,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _tampilProfil(context, data),
                borderRadius: BorderRadius.circular(30),
                child: const CircleAvatar(
                  backgroundColor: hijauMuda,
                  child: Icon(Icons.person_outline, color: hijauTua),
                ),
              ),
            ],
          ),
          if (data.error != null) ...[
            const SizedBox(height: 12),
            _kartu(
              warna: merahMuda,
              child: Text(data.error!, style: const TextStyle(fontSize: 12)),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: hijauTua,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Saldo',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Text(
                  _rp(data.saldo),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _kotakAlir('Pemasukan', masuk, Icons.south_west),
                    const SizedBox(width: 10),
                    _kotakAlir('Pengeluaran', keluar, Icons.north_east),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ringkasan Bulan Ini',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${(rasio * 100).round()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rasio >= 1 ? merah : hijauTua,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _bar(rasio, rasio >= 1 ? merah : hijauTua),
                const SizedBox(height: 8),
                Text(
                  masuk - keluar >= 0
                      ? 'Sisa bulan ini ${_rp(masuk - keluar)}'
                      : 'Pengeluaran melebihi pemasukan ${_rp(keluar - masuk)}',
                  style: const TextStyle(fontSize: 12, color: teksAbu),
                ),
              ],
            ),
          ),
          _judulBagian('Akses Cepat'),
          Row(
            children: [
              _aksi(Icons.add, 'Tambah Transaksi', hijauTua,
                  () => _bukaFormTransaksi(context, data)),
              const SizedBox(width: 10),
              _aksi(Icons.savings_outlined, 'Target Tabungan',
                  const Color(0xFFE8833A), () => onPindah(3)),
              const SizedBox(width: 10),
              _aksi(Icons.bar_chart, 'Lihat Laporan', const Color(0xFF3B82C4),
                  () => onPindah(2)),
            ],
          ),
          _judulBagian(
            'Transaksi Terbaru',
            aksi: TextButton(
              onPressed: () => onPindah(1),
              child: const Text('Lihat Semua'),
            ),
          ),
          if (data.transaksi.isEmpty)
            _kosong(
              Icons.receipt_long_outlined,
              'Belum ada transaksi',
              'Tekan tombol + untuk mencatat transaksi pertamamu.',
            )
          else
            ...data.transaksi.take(5).map(
                  (t) => _BarisTransaksi(
                    t: t,
                    onTap: () => _bukaFormTransaksi(context, data, awal: t),
                  ),
                ),
          const SizedBox(height: 6),
          _kartu(
            warna: hijauMuda,
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: hijauTua),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tips Hemat Hari Ini',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(
                        'Catat pengeluaran kecil setiap hari. Biasanya dari situlah uang paling banyak bocor.',
                        style: TextStyle(fontSize: 12, color: teksAbu, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB TRANSAKSI
// ============================================================

class TransaksiTab extends StatefulWidget {
  const TransaksiTab({super.key, required this.data});
  final AppData data;

  @override
  State<TransaksiTab> createState() => _TransaksiTabState();
}

class _TransaksiTabState extends State<TransaksiTab> {
  String _cari = '';
  int _filter = 0; // 0 semua, 1 pemasukan, 2 pengeluaran

  Future<void> _hapus(Transaksi t) async {
    final ya = await _konfirmasi(
      context,
      'Hapus transaksi?',
      '${t.judul} (${_rp(t.nominal)}) akan dihapus.',
    );
    if (!ya || !mounted) return;
    try {
      await widget.data.hapusTransaksi(t.id);
      if (mounted) _pesan(context, 'Transaksi dihapus.');
    } catch (e) {
      if (mounted) _pesan(context, 'Gagal menghapus: $e');
    }
  }

  Widget _chip(String label, int nilai) {
    final aktif = _filter == nilai;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: aktif,
        showCheckmark: false,
        selectedColor: hijauTua,
        backgroundColor: Colors.white,
        side: const BorderSide(color: garis),
        labelStyle: TextStyle(
          color: aktif ? Colors.white : teksGelap,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => setState(() => _filter = nilai),
      ),
    );
  }

  Widget _pil(String label, int nilai, Color warna, IconData ikon) {
    return Expanded(
      child: _kartu(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: _muda(warna),
              child: Icon(ikon, size: 16, color: warna),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: teksAbu)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _rp(nilai),
                      style: TextStyle(fontWeight: FontWeight.bold, color: warna),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final kata = _cari.trim().toLowerCase();
    final daftar = data.transaksi.where((t) {
      if (_filter == 1 && !t.pemasukan) return false;
      if (_filter == 2 && t.pemasukan) return false;
      if (kata.isEmpty) return true;
      return t.judul.toLowerCase().contains(kata) ||
          t.kategori.toLowerCase().contains(kata);
    }).toList();
    final bln = data.bulan(DateTime.now());

    final isi = <Widget>[];
    DateTime? terakhir;
    for (final t in daftar) {
      if (terakhir == null || !_sama(terakhir, t.tanggal)) {
        isi.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Text(
            _labelHari(t.tanggal),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: teksAbu,
              fontSize: 13,
            ),
          ),
        ));
        terakhir = t.tanggal;
      }
      isi.add(_BarisTransaksi(
        t: t,
        onTap: () => _bukaFormTransaksi(context, data, awal: t),
        onLongPress: () => _hapus(t),
      ));
    }

    return RefreshIndicator(
      onRefresh: data.muat,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const Text(
            'Transaksi',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ketuk untuk mengubah, tekan lama untuk menghapus.',
            style: TextStyle(color: teksAbu, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _pil('Pemasukan', _total(bln, true), hijauTua, Icons.south_west),
              const SizedBox(width: 10),
              _pil('Pengeluaran', _total(bln, false), merah, Icons.north_east),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _cari = v),
            decoration: _dekor('Cari transaksi atau kategori', ikon: Icons.search),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _chip('Semua', 0),
              _chip('Pemasukan', 1),
              _chip('Pengeluaran', 2),
            ],
          ),
          if (data.memuat) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (data.error != null) ...[
            const SizedBox(height: 12),
            _kartu(
              warna: merahMuda,
              child: Text(data.error!, style: const TextStyle(fontSize: 12)),
            ),
          ],
          if (daftar.isEmpty) ...[
            const SizedBox(height: 16),
            _kosong(
              Icons.receipt_long_outlined,
              data.transaksi.isEmpty
                  ? 'Belum ada transaksi'
                  : 'Tidak ada transaksi yang cocok',
              data.transaksi.isEmpty
                  ? 'Tekan tombol + untuk mencatat transaksi pertamamu.'
                  : 'Coba ubah kata pencarian atau filter.',
            ),
          ] else
            ...isi,
        ],
      ),
    );
  }
}

// ============================================================
// FORM TRANSAKSI (TAMBAH / UBAH / HAPUS)
// ============================================================

class TransaksiFormScreen extends StatefulWidget {
  const TransaksiFormScreen({super.key, required this.data, this.awal});

  final AppData data;
  final Transaksi? awal; // null = tambah baru, terisi = ubah

  @override
  State<TransaksiFormScreen> createState() => _TransaksiFormScreenState();
}

class _TransaksiFormScreenState extends State<TransaksiFormScreen> {
  late bool _pemasukan;
  late String _kategori;
  late DateTime _tanggal;
  late final TextEditingController _nominal;
  late final TextEditingController _catatan;
  String? _errNominal;
  bool _menyimpan = false;

  bool get _ubah => widget.awal != null;

  @override
  void initState() {
    super.initState();
    final a = widget.awal;
    _pemasukan = a?.pemasukan ?? false;
    _kategori = a?.kategori ?? 'Makanan';
    _tanggal = a?.tanggal ?? DateTime.now();
    _nominal = TextEditingController(text: a == null ? '' : a.nominal.toString());
    _catatan = TextEditingController(text: a?.catatan ?? '');
  }

  @override
  void dispose() {
    _nominal.dispose();
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (dipilih != null) setState(() => _tanggal = dipilih);
  }

  Future<void> _simpan() async {
    final nominal = int.tryParse(_nominal.text.trim()) ?? 0;
    if (nominal <= 0) {
      setState(() => _errNominal = 'Masukkan nominal yang valid');
      return;
    }
    setState(() {
      _errNominal = null;
      _menyimpan = true;
    });
    try {
      if (_ubah) {
        await widget.data.ubahTransaksi(
          widget.awal!.id,
          nominal: nominal,
          kategori: _kategori,
          pemasukan: _pemasukan,
          tanggal: _tanggal,
          catatan: _catatan.text.trim(),
        );
      } else {
        await widget.data.tambahTransaksi(
          nominal: nominal,
          kategori: _kategori,
          pemasukan: _pemasukan,
          tanggal: _tanggal,
          catatan: _catatan.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, _ubah ? 'Transaksi diperbarui.' : 'Transaksi tersimpan.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      _pesan(context, 'Gagal menyimpan transaksi: $e');
    }
  }

  Future<void> _hapus() async {
    final ya = await _konfirmasi(
      context,
      'Hapus transaksi?',
      'Transaksi ini akan dihapus permanen.',
    );
    if (!ya || !mounted) return;
    try {
      await widget.data.hapusTransaksi(widget.awal!.id);
      if (mounted) Navigator.pop(context, 'Transaksi dihapus.');
    } catch (e) {
      if (mounted) _pesan(context, 'Gagal menghapus: $e');
    }
  }

  Widget _segmen(String teks, bool nilaiPemasukan) {
    final aktif = _pemasukan == nilaiPemasukan;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _pemasukan = nilaiPemasukan;
          _kategori = (_pemasukan ? kategoriPemasukan : kategoriPengeluaran).first.nama;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: aktif ? hijauTua : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            teks,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: aktif ? Colors.white : teksAbu,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(KategoriInfo k) {
    final aktif = _kategori == k.nama;
    return InkWell(
      onTap: () => setState(() => _kategori = k.nama),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: aktif ? hijauMuda : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: aktif ? hijauTua : garis, width: aktif ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: _muda(k.warna),
              child: Icon(k.ikon, color: k.warna, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              k.nama,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daftar = _pemasukan ? kategoriPemasukan : kategoriPengeluaran;
    final nilai = int.tryParse(_nominal.text.trim()) ?? 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: latar,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _ubah ? 'Ubah Transaksi' : 'Tambah Transaksi',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_ubah)
            IconButton(
              tooltip: 'Hapus',
              onPressed: _hapus,
              icon: const Icon(Icons.delete_outline, color: merah),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: garis),
              ),
              child: Row(
                children: [
                  _segmen('Pengeluaran', false),
                  _segmen('Pemasukan', true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _kartu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NOMINAL TRANSAKSI',
                    style: TextStyle(fontSize: 11, color: teksAbu, letterSpacing: 0.6),
                  ),
                  Row(
                    children: [
                      const Text('Rp',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _nominal,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (_) => setState(() => _errNominal = null),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_errNominal != null)
                    Text(_errNominal!,
                        style: const TextStyle(color: merah, fontSize: 12))
                  else
                    Text(
                      nilai > 0 ? _rp(nilai) : 'Masukkan jumlah uang',
                      style: const TextStyle(fontSize: 12, color: teksAbu),
                    ),
                ],
              ),
            ),
            _judulBagian('Pilih Kategori'),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.92,
              children: [for (final k in daftar) _tile(k)],
            ),
            _judulBagian('Tanggal Transaksi'),
            InkWell(
              onTap: _pilihTanggal,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: garis),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined, color: hijauTua),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _tgl(_tanggal),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: teksAbu),
                  ],
                ),
              ),
            ),
            _judulBagian('Catatan (opsional)'),
            TextField(
              controller: _catatan,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: _dekor('Contoh: makan siang bersama teman'),
            ),
            const SizedBox(height: 24),
            _tombolUtama(
              _ubah ? 'Simpan Perubahan' : 'Simpan Transaksi',
              _simpan,
              loading: _menyimpan,
              ikon: Icons.check,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TAB LAPORAN
// ============================================================

class LaporanTab extends StatefulWidget {
  const LaporanTab({super.key, required this.data});
  final AppData data;

  @override
  State<LaporanTab> createState() => _LaporanTabState();
}

class _LaporanTabState extends State<LaporanTab> {
  int _periode = 1; // 0 minggu, 1 bulan, 2 tahun

  Widget _batang(int nilai, int maks, Color warna) {
    final tinggi = maks == 0 ? 0.0 : (nilai / maks) * 120.0;
    return Container(
      width: 8,
      height: nilai > 0 ? (tinggi < 3 ? 3.0 : tinggi) : 0,
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _grafikBatang(List<String> label, List<int> masuk, List<int> keluar) {
    final maks = [...masuk, ...keluar].fold<int>(0, math.max);
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < label.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _batang(masuk[i], maks, hijau),
                      const SizedBox(width: 3),
                      _batang(keluar[i], maks, merah),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label[i],
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(fontSize: 9.5, color: teksAbu),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _legenda(Color warna, String teks) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(teks, style: const TextStyle(fontSize: 11, color: teksAbu)),
      ],
    );
  }

  Widget _ringkas(String label, int nilai, Color warna) {
    return Expanded(
      child: _kartu(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: teksAbu)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _rp(nilai),
                style: TextStyle(fontWeight: FontWeight.bold, color: warna),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final now = DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);

    final DateTime mulai;
    final DateTime akhir;
    final String judulPeriode;
    if (_periode == 0) {
      mulai = DateTime(hariIni.year, hariIni.month, hariIni.day - 6);
      akhir = DateTime(hariIni.year, hariIni.month, hariIni.day + 1);
      judulPeriode = '7 hari terakhir';
    } else if (_periode == 1) {
      mulai = DateTime(now.year, now.month, 1);
      akhir = DateTime(now.year, now.month + 1, 1);
      judulPeriode = '${_bulanPanjang[now.month - 1]} ${now.year}';
    } else {
      mulai = DateTime(now.year, 1, 1);
      akhir = DateTime(now.year + 1, 1, 1);
      judulPeriode = 'Tahun ${now.year}';
    }

    final dalam = data.transaksi
        .where((t) => !t.tanggal.isBefore(mulai) && t.tanggal.isBefore(akhir))
        .toList();
    final masuk = _total(dalam, true);
    final keluar = _total(dalam, false);

    final int n;
    final List<String> label;
    if (_periode == 0) {
      n = 7;
      label = [
        for (var i = 0; i < 7; i++)
          _hariPendek[DateTime(mulai.year, mulai.month, mulai.day + i).weekday - 1],
      ];
    } else if (_periode == 1) {
      final hari = DateTime(now.year, now.month + 1, 0).day;
      n = ((hari - 1) ~/ 7) + 1;
      label = [for (var i = 0; i < n; i++) 'M${i + 1}'];
    } else {
      n = 12;
      label = List<String>.from(_bulanPendek);
    }

    int indeks(DateTime d) {
      if (_periode == 0) {
        final selisih =
            DateTime(d.year, d.month, d.day).difference(mulai).inDays;
        return selisih.clamp(0, n - 1).toInt();
      }
      if (_periode == 1) return ((d.day - 1) ~/ 7).clamp(0, n - 1).toInt();
      return d.month - 1;
    }

    final masukB = List<int>.filled(n, 0);
    final keluarB = List<int>.filled(n, 0);
    for (final t in dalam) {
      final i = indeks(t.tanggal);
      if (t.pemasukan) {
        masukB[i] += t.nominal;
      } else {
        keluarB[i] += t.nominal;
      }
    }

    final perKategori = <String, int>{};
    for (final t in dalam) {
      if (!t.pemasukan) {
        perKategori[t.kategori] = (perKategori[t.kategori] ?? 0) + t.nominal;
      }
    }
    final urut = perKategori.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return RefreshIndicator(
      onRefresh: data.muat,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const Text(
            'Laporan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(judulPeriode, style: const TextStyle(color: teksAbu, fontSize: 12)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: hijauTua,
                selectedForegroundColor: Colors.white,
              ),
              segments: const [
                ButtonSegment(value: 0, label: Text('Minggu')),
                ButtonSegment(value: 1, label: Text('Bulan')),
                ButtonSegment(value: 2, label: Text('Tahun')),
              ],
              selected: {_periode},
              onSelectionChanged: (s) => setState(() => _periode = s.first),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ringkas('Pemasukan', masuk, hijauTua),
              const SizedBox(width: 8),
              _ringkas('Pengeluaran', keluar, merah),
              const SizedBox(width: 8),
              _ringkas('Selisih', masuk - keluar, masuk - keluar >= 0 ? hijauTua : merah),
            ],
          ),
          const SizedBox(height: 14),
          _kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pemasukan vs Pengeluaran',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        _legenda(hijau, 'Masuk'),
                        const SizedBox(width: 10),
                        _legenda(merah, 'Keluar'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (masuk == 0 && keluar == 0)
                  const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        'Belum ada data pada periode ini',
                        style: TextStyle(color: teksAbu, fontSize: 12),
                      ),
                    ),
                  )
                else
                  _grafikBatang(label, masukB, keluarB),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pengeluaran Berdasarkan Kategori',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (urut.isEmpty)
                  const SizedBox(
                    height: 80,
                    child: Center(
                      child: Text(
                        'Belum ada pengeluaran pada periode ini',
                        style: TextStyle(color: teksAbu, fontSize: 12),
                      ),
                    ),
                  )
                else ...[
                  Center(
                    child: SizedBox(
                      width: 176,
                      height: 176,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(176, 176),
                            painter: _DonutPainter(
                              urut.map((e) => e.value.toDouble()).toList(),
                              urut.map((e) => infoKategori(e.key, false).warna).toList(),
                            ),
                          ),
                          SizedBox(
                            width: 92,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Total',
                                    style: TextStyle(fontSize: 11, color: teksAbu)),
                                FittedBox(
                                  child: Text(
                                    _rp(keluar),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final e in urut)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: infoKategori(e.key, false).warna,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.key,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${keluar == 0 ? 0 : (e.value / keluar * 100).round()}%',
                            style: const TextStyle(fontSize: 12, color: teksAbu),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _rp(e.value),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.nilai, this.warna);

  final List<double> nilai;
  final List<Color> warna;

  @override
  void paint(Canvas canvas, Size size) {
    const tebal = 24.0;
    final rect = Rect.fromLTWH(
      tebal / 2,
      tebal / 2,
      size.width - tebal,
      size.height - tebal,
    );
    final dasar = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tebal
      ..color = const Color(0xFFE9EFE8);
    canvas.drawArc(rect, 0, 2 * math.pi, false, dasar);

    final total = nilai.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    var awal = -math.pi / 2;
    for (var i = 0; i < nilai.length; i++) {
      final sapuan = nilai[i] / total * 2 * math.pi;
      final kuas = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tebal
        ..strokeCap = StrokeCap.butt
        ..color = warna[i];
      canvas.drawArc(rect, awal, sapuan, false, kuas);
      awal += sapuan;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}

// ============================================================
// TAB TABUNGAN: TARGET TABUNGAN + ANGGARAN
// ============================================================

class TabunganTab extends StatelessWidget {
  const TabunganTab({super.key, required this.data});
  final AppData data;

  void _gagal(BuildContext context, String awalan, Object e) {
    if (context.mounted) _pesan(context, '$awalan: $e');
  }

  // ----- Anggaran -----
  Future<void> _aturTotal(BuildContext context) async {
    final hasil = await showDialog<int>(
      context: context,
      builder: (_) => _NominalDialog(
        judul: 'Batas Pengeluaran Bulanan',
        label: 'Batas per bulan (Rp)',
        tombol: 'Simpan',
        awal: data.batasBulanan?.batas,
      ),
    );
    if (hasil == null) return;
    try {
      await data.simpanAnggaran(kunciTotal, hasil);
    } catch (e) {
      if (context.mounted) _gagal(context, 'Gagal menyimpan anggaran', e);
    }
  }

  Future<void> _aturKategori(BuildContext context, {Anggaran? awal}) async {
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AnggaranDialog(awal: awal),
    );
    if (hasil == null) return;
    try {
      await data.simpanAnggaran(hasil['kategori'] as String, hasil['batas'] as int);
    } catch (e) {
      if (context.mounted) _gagal(context, 'Gagal menyimpan anggaran', e);
    }
  }

  Future<void> _hapusAnggaran(BuildContext context, Anggaran a) async {
    final ya = await _konfirmasi(
      context,
      'Hapus anggaran?',
      'Anggaran ${a.kategori} akan dihapus.',
    );
    if (!ya) return;
    try {
      await data.hapusAnggaran(a.id);
    } catch (e) {
      if (context.mounted) _gagal(context, 'Gagal menghapus anggaran', e);
    }
  }

  // ----- Target tabungan -----
  Future<void> _tambahTarget(BuildContext context) async {
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _TargetDialog(),
    );
    if (hasil == null) return;
    try {
      await data.tambahTarget(
        nama: hasil['nama'] as String,
        target: hasil['target'] as int,
        terkumpul: hasil['terkumpul'] as int,
        tanggal: hasil['tanggal'] as DateTime,
      );
      if (context.mounted) _pesan(context, 'Target tersimpan.');
    } catch (e) {
      if (context.mounted) _gagal(context, 'Gagal menyimpan target', e);
    }
  }

  Future<void> _ubahTarget(BuildContext context, TargetTabungan t) async {
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _TargetDialog(awal: t),
    );
    if (hasil == null) return;
    try {
      await data.ubahTarget(
        t.id,
        nama: hasil['nama'] as String,
        target: hasil['target'] as int,
        terkumpul: hasil['terkumpul'] as int,
        tanggal: hasil['tanggal'] as DateTime,
      );
      if (context.mounted) _pesan(context, 'Target diperbarui.');
    } catch (e) {
      if (context.mounted) _gagal(context, 'Gagal mengubah target', e);
    }
  }

  Future<void> _setor(BuildContext context, TargetTabungan t) async {
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _SetorDialog(judul: 'Setor ke ${t.nama}'),
    );
    if (hasil == null) return;
    try {
      await data.setorTarget(
        t,
        nominal: hasil['nominal'] as int,
        tanggal: hasil['tanggal'] as DateTime,
      );
      if (context.mounted) {
        _pesan(context, 'Setoran ${_rp(hasil['nominal'] as int)} tersimpan.');
      }
    } catch (e) {
      if (context.mounted) _gagal(context, 'Gagal menyetor', e);
    }
  }

  Future<void> _ubahSetoran(BuildContext context, Setoran s) async {
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _SetorDialog(judul: 'Ubah Setoran', awal: s),
    );
    if (hasil == null) return;
    try {
      await data.ubahSetoran(
        s.id,
        nominal: hasil['nominal'] as int,
        tanggal: hasil['tanggal'] as DateTime,
      );
      if (context.mounted) _pesan(context, 'Setoran diperbarui.');
    } catch (e) {
      if (context.mounted) _gagal(context, 'Gagal mengubah setoran', e);
    }
  }

  Future<void> _hapusSetoran(BuildContext context, Setoran s) async {
    final ya = await _konfirmasi(
      context,
      'Hapus setoran?',
      'Setoran ${_rp(s.nominal)} (${_tgl(s.tanggal)}) akan dihapus.',
    );
    if (!ya) return;
    try {
      await data.hapusSetoran(s.id);
      if (context.mounted) _pesan(context, 'Setoran dihapus.');
    } catch (e) {
      if (context.mounted) _gagal(context, 'Gagal menghapus setoran', e);
    }
  }

  Future<void> _hapusTarget(BuildContext context, TargetTabungan t) async {
    final ya = await _konfirmasi(
      context,
      'Hapus target?',
      'Target "${t.nama}" akan dihapus.',
    );
    if (!ya) return;
    try {
      await data.hapusTarget(t.id);
      if (context.mounted) _pesan(context, 'Target dihapus.');
    } catch (e) {
      if (context.mounted) _gagal(context, 'Gagal menghapus target', e);
    }
  }

  Widget _kartuTarget(BuildContext context, TargetTabungan t) {
    final tercapai = t.target > 0 && t.terkumpul >= t.target;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _kartu(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.nama,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Ubah',
                  icon: const Icon(Icons.edit_outlined, color: teksAbu),
                  onPressed: () => _ubahTarget(context, t),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.delete_outline, color: merah),
                  onPressed: () => _hapusTarget(context, t),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _bar(t.rasio, tercapai ? hijau : hijauTua, tinggi: 10),
            const SizedBox(height: 8),
            Text(
              '${_rp(t.terkumpul)} dari ${_rp(t.target)} (${(t.rasio * 100).round()}%)',
              style: const TextStyle(fontSize: 12, color: teksAbu),
            ),
            if (t.tanggal != null) ...[
              const SizedBox(height: 3),
              Text(
                'Tenggat: ${_tgl(t.tanggal!)}',
                style: const TextStyle(fontSize: 12, color: teksAbu),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: hijauTua,
                    side: const BorderSide(color: hijauTua),
                  ),
                  onPressed: () => _setor(context, t),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Setor'),
                ),
                if (tercapai) ...[
                  const SizedBox(width: 10),
                  const Chip(
                    label: Text('Target tercapai'),
                    avatar: Icon(Icons.check_circle, color: hijau, size: 18),
                    backgroundColor: hijauMuda,
                    side: BorderSide.none,
                  ),
                ],
              ],
            ),
            if (t.awal > 0 || t.riwayat.isNotEmpty)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text(
                    'Riwayat Setoran (${t.riwayat.length + (t.awal > 0 ? 1 : 0)})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  children: [
                    for (final s in t.riwayat)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          radius: 16,
                          backgroundColor: hijauMuda,
                          child: Icon(Icons.south_west, size: 15, color: hijauTua),
                        ),
                        title: Text(
                          '+${_rp(s.nominal)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: hijauTua,
                          ),
                        ),
                        subtitle: Text(_tgl(s.tanggal)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Ubah',
                              icon: const Icon(Icons.edit_outlined, size: 20, color: teksAbu),
                              onPressed: () => _ubahSetoran(context, s),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Hapus',
                              icon: const Icon(Icons.delete_outline, size: 20, color: merah),
                              onPressed: () => _hapusSetoran(context, s),
                            ),
                          ],
                        ),
                      ),
                    if (t.awal > 0)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          radius: 16,
                          backgroundColor: hijauMuda,
                          child: Icon(Icons.flag_outlined, size: 15, color: hijauTua),
                        ),
                        title: Text(
                          _rp(t.awal),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Setoran awal (diatur lewat tombol ubah target)'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bln = data.bulan(DateTime.now());
    final keluarBulan = _total(bln, false);
    final batas = data.batasBulanan;
    final kategoriAnggaran =
        data.anggaran.where((a) => a.kategori != kunciTotal).toList();
    final daftarTarget = data.target;

    return RefreshIndicator(
      onRefresh: data.muat,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const Text(
            'Target & Anggaran',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Atur batas pengeluaran dan wujudkan target tabunganmu.',
            style: TextStyle(color: teksAbu, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (data.memuat) const LinearProgressIndicator(),
          if (data.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _kartu(
                warna: merahMuda,
                child: Text(data.error!, style: const TextStyle(fontSize: 12)),
              ),
            ),

          // ----- Batas pengeluaran bulanan -----
          _kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Batas Pengeluaran Bulanan',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: batas == null ? 'Atur batas' : 'Ubah batas',
                      icon: const Icon(Icons.edit_outlined, color: teksAbu),
                      onPressed: () => _aturTotal(context),
                    ),
                  ],
                ),
                if (batas == null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengeluaran bulan ini ${_rp(keluarBulan)}',
                        style: const TextStyle(fontSize: 12, color: teksAbu),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _aturTotal(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Atur Batas'),
                      ),
                    ],
                  )
                else ...[
                  Text(
                    _rp(batas.batas),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _bar(
                    batas.batas <= 0
                        ? 0.0
                        : (keluarBulan / batas.batas).clamp(0.0, 1.0).toDouble(),
                    keluarBulan >= batas.batas ? merah : hijauTua,
                    tinggi: 10,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    keluarBulan > batas.batas
                        ? 'Terpakai ${_rp(keluarBulan)}. Melebihi batas ${_rp(keluarBulan - batas.batas)}'
                        : 'Terpakai ${_rp(keluarBulan)}. Sisa ${_rp(batas.batas - keluarBulan)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: keluarBulan > batas.batas ? merah : teksAbu,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ----- Anggaran per kategori -----
          _judulBagian(
            'Anggaran per Kategori',
            aksi: TextButton.icon(
              onPressed: () => _aturKategori(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
            ),
          ),
          if (kategoriAnggaran.isEmpty)
            _kosong(
              Icons.pie_chart_outline,
              'Belum ada anggaran kategori',
              'Tekan Tambah untuk membatasi pengeluaran per kategori.',
            )
          else
            for (final a in kategoriAnggaran)
              Builder(builder: (context) {
                final info = infoKategori(a.kategori, false);
                final terpakai = bln
                    .where((t) => !t.pemasukan && t.kategori == a.kategori)
                    .fold<int>(0, (s, t) => s + t.nominal);
                final lebih = terpakai > a.batas;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _kartu(
                    padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: _muda(info.warna),
                          child: Icon(info.ikon, color: info.warna, size: 19),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.kategori,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              _bar(
                                a.batas <= 0
                                    ? 0.0
                                    : (terpakai / a.batas).clamp(0.0, 1.0).toDouble(),
                                lebih ? merah : info.warna,
                                tinggi: 7,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${_rp(terpakai)} dari ${_rp(a.batas)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: lebih ? merah : teksAbu,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Ubah',
                          icon: const Icon(Icons.edit_outlined, color: teksAbu),
                          onPressed: () => _aturKategori(context, awal: a),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Hapus',
                          icon: const Icon(Icons.delete_outline, color: merah),
                          onPressed: () => _hapusAnggaran(context, a),
                        ),
                      ],
                    ),
                  ),
                );
              }),

          // ----- Target tabungan -----
          _judulBagian(
            'Target Tabungan',
            aksi: TextButton.icon(
              onPressed: () => _tambahTarget(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Target Baru'),
            ),
          ),
          if (daftarTarget.isEmpty)
            _kosong(
              Icons.savings_outlined,
              'Belum ada target tabungan',
              'Tekan Target Baru untuk membuat target pertamamu.',
            )
          else
            for (final t in daftarTarget) _kartuTarget(context, t),
        ],
      ),
    );
  }
}

// ============================================================
// DIALOG
// ============================================================

class _NominalDialog extends StatefulWidget {
  const _NominalDialog({
    required this.judul,
    required this.label,
    required this.tombol,
    this.awal,
  });

  final String judul;
  final String label;
  final String tombol;
  final int? awal;

  @override
  State<_NominalDialog> createState() => _NominalDialogState();
}

class _NominalDialogState extends State<_NominalDialog> {
  late final TextEditingController _c =
      TextEditingController(text: widget.awal?.toString() ?? '');
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.judul),
      content: TextField(
        controller: _c,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: widget.label,
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final n = int.tryParse(_c.text.trim());
            if (n == null || n <= 0) {
              setState(() => _error = 'Masukkan nominal yang valid');
              return;
            }
            Navigator.pop(context, n);
          },
          child: Text(widget.tombol),
        ),
      ],
    );
  }
}

class _SetorDialog extends StatefulWidget {
  const _SetorDialog({required this.judul, this.awal});

  final String judul;
  final Setoran? awal; // terisi = ubah setoran

  @override
  State<_SetorDialog> createState() => _SetorDialogState();
}

class _SetorDialogState extends State<_SetorDialog> {
  late final TextEditingController _c = TextEditingController(
      text: widget.awal == null ? '' : widget.awal!.nominal.toString());
  late DateTime _tanggal = widget.awal?.tanggal ?? DateTime.now();
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (dipilih != null) setState(() => _tanggal = dipilih);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.judul),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _c,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Jumlah setoran (Rp)',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pilihTanggal,
              icon: const Icon(Icons.event_outlined),
              label: Text('Tanggal: ${_tgl(_tanggal)}'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final n = int.tryParse(_c.text.trim());
            if (n == null || n <= 0) {
              setState(() => _error = 'Masukkan nominal yang valid');
              return;
            }
            Navigator.pop(context, <String, dynamic>{'nominal': n, 'tanggal': _tanggal});
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _AnggaranDialog extends StatefulWidget {
  const _AnggaranDialog({this.awal});
  final Anggaran? awal;

  @override
  State<_AnggaranDialog> createState() => _AnggaranDialogState();
}

class _AnggaranDialogState extends State<_AnggaranDialog> {
  late String _kategori = widget.awal?.kategori ?? kategoriPengeluaran.first.nama;
  late final TextEditingController _c =
      TextEditingController(text: widget.awal?.batas.toString() ?? '');
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mengubah = widget.awal != null;
    return AlertDialog(
      title: Text(mengubah ? 'Ubah Anggaran' : 'Tambah Anggaran'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mengubah) ...[
              const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final k in kategoriPengeluaran)
                    ChoiceChip(
                      label: Text(k.nama),
                      selected: _kategori == k.nama,
                      showCheckmark: false,
                      selectedColor: hijauMuda,
                      onSelected: (_) => setState(() => _kategori = k.nama),
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ] else ...[
              Text(_kategori, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _c,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Batas per bulan (Rp)',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final n = int.tryParse(_c.text.trim());
            if (n == null || n <= 0) {
              setState(() => _error = 'Masukkan nominal yang valid');
              return;
            }
            Navigator.pop(context, <String, dynamic>{'kategori': _kategori, 'batas': n});
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _TargetDialog extends StatefulWidget {
  const _TargetDialog({this.awal});
  final TargetTabungan? awal;

  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama =
      TextEditingController(text: widget.awal?.nama ?? '');
  late final TextEditingController _target = TextEditingController(
      text: widget.awal == null ? '' : widget.awal!.target.toString());
  late final TextEditingController _terkumpul = TextEditingController(
      text: widget.awal == null ? '' : widget.awal!.awal.toString());
  late DateTime? _tanggal = widget.awal?.tanggal;
  bool _tanggalKosong = false;

  @override
  void dispose() {
    _nama.dispose();
    _target.dispose();
    _terkumpul.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final sekarang = DateTime.now();
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggal ?? sekarang.add(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime(sekarang.year + 20),
    );
    if (dipilih != null) {
      setState(() {
        _tanggal = dipilih;
        _tanggalKosong = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.awal == null ? 'Target Baru' : 'Ubah Target'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nama,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nama target',
                  hintText: 'Contoh: Beli laptop',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Nama target harus diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _target,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Target nominal (Rp)',
                  hintText: 'Contoh: 5000000',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  return (n == null || n <= 0) ? 'Masukkan nominal yang valid' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _terkumpul,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Setoran awal (Rp)',
                  hintText: 'Kosongkan jika belum ada',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pilihTanggal,
                icon: const Icon(Icons.event_outlined),
                label: Text(_tanggal == null ? 'Pilih tanggal target' : _tgl(_tanggal!)),
              ),
              if (_tanggalKosong)
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'Tanggal target harus dipilih',
                    style: TextStyle(color: merah, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final valid = _formKey.currentState!.validate();
            if (_tanggal == null) {
              setState(() => _tanggalKosong = true);
              return;
            }
            if (!valid) return;
            Navigator.pop(context, <String, dynamic>{
              'nama': _nama.text.trim(),
              'target': int.parse(_target.text.trim()),
              'terkumpul': int.tryParse(_terkumpul.text.trim()) ?? 0,
              'tanggal': _tanggal,
            });
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}