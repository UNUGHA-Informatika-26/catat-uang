import 'package:flutter/material.dart';

import '../../../../../core/format.dart';
import '../../../../../core/tema.dart';
import '../../../../../core/widgets.dart';
import '../../../data/app_data.dart';
import '../../../models/anggaran.dart';
import '../../../models/kategori.dart';
import '../../../models/transaksi.dart';
import '../../widgets/dialogs.dart';

class AnggaranTab extends StatelessWidget {
  const AnggaranTab({super.key, required this.data});
  final AppData data;

  void _gagal(BuildContext context, String awalan, Object e) {
    if (context.mounted) pesan(context, '$awalan: $e');
  }

  Future<void> _aturTotal(BuildContext context) async {
    final hasil = await showDialog<int>(
      context: context,
      builder: (_) => NominalDialog(
        judul: 'Batas Pengeluaran Bulanan',
        label: 'Batas per bulan (Rp)',
        tombol: 'Simpan',
        awal: data.batasBulanan?.batas,
      ),
    );
    if (hasil == null) return;
    try {
      final tersinkron = await data.simpanAnggaran(kunciTotal, hasil);
      if (!tersinkron && context.mounted) {
        pesan(
          context,
          'Anggaran tersimpan di perangkat; menunggu sinkronisasi.',
        );
      }
    } catch (e) {
      if (context.mounted) _gagal(context, 'Gagal menyimpan anggaran', e);
    }
  }

  Future<void> _aturKategori(BuildContext context, {Anggaran? awal}) async {
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AnggaranDialog(awal: awal),
    );
    if (hasil == null) return;
    try {
      final tersinkron = await data.simpanAnggaran(
        hasil['kategori'] as String,
        hasil['batas'] as int,
      );
      if (!tersinkron && context.mounted) {
        pesan(
          context,
          'Anggaran tersimpan di perangkat; menunggu sinkronisasi.',
        );
      }
    } catch (e) {
      if (context.mounted) _gagal(context, 'Gagal menyimpan anggaran', e);
    }
  }

  Future<void> _hapusAnggaran(BuildContext context, Anggaran a) async {
    final ya = await konfirmasi(
      context,
      'Hapus anggaran?',
      'Anggaran ${a.kategori} akan dihapus.',
    );
    if (!ya) return;
    try {
      final tersinkron = await data.hapusAnggaran(a.id);
      if (!tersinkron && context.mounted) {
        pesan(context, 'Penghapusan tersimpan dan menunggu sinkronisasi.');
      }
    } catch (e) {
      if (context.mounted) _gagal(context, 'Gagal menghapus anggaran', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bln = data.bulan(DateTime.now());
    final keluarBulan = totalTransaksi(bln, false);
    final batas = data.batasBulanan;
    final kategoriAnggaran = data.anggaran
        .where((a) => a.kategori != kunciTotal)
        .toList();

    return RefreshIndicator(
      onRefresh: data.muat,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const Text(
            'Anggaran',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Atur batas pengeluaran bulanan dan per kategori.',
            style: TextStyle(color: teksAbu, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (data.memuat) const LinearProgressIndicator(),
          if (data.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: kartu(
                warna: merahMuda,
                child: Text(data.error!, style: const TextStyle(fontSize: 12)),
              ),
            ),

          // ----- Batas pengeluaran bulanan -----
          kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Batas Pengeluaran Bulanan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                        'Pengeluaran bulan ini ${rp(keluarBulan)}',
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
                    rp(batas.batas),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  barProgres(
                    batas.batas <= 0
                        ? 0.0
                        : (keluarBulan / batas.batas)
                              .clamp(0.0, 1.0)
                              .toDouble(),
                    keluarBulan >= batas.batas ? merah : hijauTua,
                    tinggi: 10,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    keluarBulan > batas.batas
                        ? 'Terpakai ${rp(keluarBulan)}. Melebihi batas ${rp(keluarBulan - batas.batas)}'
                        : 'Terpakai ${rp(keluarBulan)}. Sisa ${rp(batas.batas - keluarBulan)}',
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
          judulBagian(
            'Anggaran per Kategori',
            aksi: TextButton.icon(
              onPressed: () => _aturKategori(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
            ),
          ),
          if (kategoriAnggaran.isEmpty)
            kosong(
              Icons.pie_chart_outline,
              'Belum ada anggaran kategori',
              'Tekan Tambah untuk membatasi pengeluaran per kategori.',
            )
          else
            for (final a in kategoriAnggaran)
              Builder(
                builder: (context) {
                  final info = infoKategori(a.kategori, false);
                  final terpakai = bln
                      .where((t) => !t.pemasukan && t.kategori == a.kategori)
                      .fold<int>(0, (s, t) => s + t.nominal);
                  final lebih = terpakai > a.batas;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: kartu(
                      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 19,
                            backgroundColor: muda(info.warna),
                            child: Icon(info.ikon, color: info.warna, size: 19),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.kategori,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                barProgres(
                                  a.batas <= 0
                                      ? 0.0
                                      : (terpakai / a.batas)
                                            .clamp(0.0, 1.0)
                                            .toDouble(),
                                  lebih ? merah : info.warna,
                                  tinggi: 7,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${rp(terpakai)} dari ${rp(a.batas)}',
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
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: teksAbu,
                            ),
                            onPressed: () => _aturKategori(context, awal: a),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Hapus',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: merah,
                            ),
                            onPressed: () => _hapusAnggaran(context, a),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}
