import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:flutter/material.dart';

import '../../../../../core/format.dart';
import '../../../../../core/tema.dart';
import '../../../../../core/widgets.dart';
import '../../../data/app_data.dart';
import '../../../models/transaksi.dart';
import 'transaksi_form.dart';

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
    final ya = await konfirmasi(
      context,
      'Hapus transaksi?',
      '${t.judul} (${rp(t.nominal)}) akan dihapus.',
    );
    if (!ya || !mounted) return;
    try {
      final tersinkron = await widget.data.hapusTransaksi(t.id);
      if (mounted) {
        pesan(
          context,
          tersinkron
              ? 'Transaksi dihapus.'
              : 'Penghapusan tersimpan dan menunggu sinkronisasi.',
        );
      }
    } catch (e) {
      if (mounted) pesan(context, 'Gagal menghapus: $e');
    }
  }

  Widget _segmen(String teks) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      child: Text(
        teks,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _pil(String label, int nilai, Color warna, IconData ikon) {
    return Expanded(
      child: kartu(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ikonKotak(ikon, warna, ukuran: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: teksAbu),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      rp(nilai),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: warna,
                      ),
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
      if (terakhir == null || !sama(terakhir, t.tanggal)) {
        isi.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
            child: Text(
              labelHari(t.tanggal),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: teksAbu,
                fontSize: 13,
              ),
            ),
          ),
        );
        terakhir = t.tanggal;
      }
      isi.add(
        BarisTransaksi(
          t: t,
          onTap: () => bukaFormTransaksi(context, data, awal: t),
          onLongPress: () => _hapus(t),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: data.muat,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          const Text(
            'Transaksi',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ketuk untuk mengubah, tekan lama untuk menghapus.',
            style: TextStyle(color: teksAbu, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _pil(
                'Pemasukan',
                totalTransaksi(bln, true),
                hijauTua,
                Icons.south_west_rounded,
              ),
              const SizedBox(width: 10),
              _pil(
                'Pengeluaran',
                totalTransaksi(bln, false),
                merah,
                Icons.north_east_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _cari = v),
            decoration: dekor(
              'Cari transaksi atau kategori',
              ikon: Icons.search_rounded,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _filter,
              backgroundColor: const Color(0xFFE3EBEA),
              thumbColor: Colors.white,
              children: {
                0: _segmen('Semua'),
                1: _segmen('Pemasukan'),
                2: _segmen('Pengeluaran'),
              },
              onValueChanged: (v) {
                if (v != null) setState(() => _filter = v);
              },
            ),
          ),
          if (data.memuat) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (data.error != null) ...[
            const SizedBox(height: 12),
            kartu(
              warna: merahMuda,
              child: Text(data.error!, style: const TextStyle(fontSize: 12)),
            ),
          ],
          if (daftar.isEmpty) ...[
            const SizedBox(height: 16),
            kosong(
              Icons.receipt_long_rounded,
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
