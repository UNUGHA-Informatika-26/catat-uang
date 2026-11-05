import 'package:flutter/material.dart';

import '../../../../../core/format.dart';
import '../../../../../core/tema.dart';
import '../../../../../core/widgets.dart';
import '../../../../keuangan/data/app_data.dart';
import '../../../../keuangan/models/transaksi.dart';
import '../home_shell/home_shell.dart';
import '../../../../keuangan/presentation/pages/transaksi/transaksi_form.dart';

class BerandaTab extends StatefulWidget {
  const BerandaTab({super.key, required this.data, required this.onPindah});

  final AppData data;
  final ValueChanged<int> onPindah;

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  bool _sembunyi = false;

  AppData get data => widget.data;

  String _angka(int nilai) => _sembunyi ? 'Rp ••••••' : rp(nilai);

  Widget _lingkaran(double ukuran, int warna) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Color(warna)),
    );
  }

  Widget _kotakAlir(String label, int nilai, IconData ikon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x26FFFFFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x33FFFFFF),
              ),
              child: Icon(ikon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _angka(nilai),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
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

  Widget _menu(IconData ikon, String label, Color warna, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        highlightColor: const Color(0x120F766E),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              ikonKotak(ikon, warna, ukuran: 54),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
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
    final masuk = totalTransaksi(bln, true);
    final keluar = totalTransaksi(bln, false);
    final double rasio = masuk > 0
        ? (keluar / masuk).clamp(0.0, 1.0).toDouble()
        : (keluar > 0 ? 1.0 : 0.0);
    final namaTampil = data.nama;
    final inisial = namaTampil.isEmpty
        ? '?'
        : namaTampil.substring(0, 1).toUpperCase();

    return RefreshIndicator(
      onRefresh: data.muat,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
        children: [
          if (data.memuat) const LinearProgressIndicator(),
          Row(
            children: [
              InkWell(
                onTap: () => tampilProfil(context, data),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: gradienUtama,
                  ),
                  child: Text(
                    inisial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Halo,',
                      style: TextStyle(color: teksAbu, fontSize: 13),
                    ),
                    Text(
                      namaTampil,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: teksGelap,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: bayanganLembut,
                ),
                child: Text(
                  '${bulanPendek[sekarang.month - 1]} ${sekarang.year}',
                  style: const TextStyle(
                    color: hijauTua,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (data.error != null) ...[
            const SizedBox(height: 12),
            kartu(
              warna: merahMuda,
              child: Text(data.error!, style: const TextStyle(fontSize: 12)),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              gradient: gradienUtama,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x590F766E),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  Positioned(
                    right: -34,
                    top: -34,
                    child: _lingkaran(140, 0x14FFFFFF),
                  ),
                  Positioned(
                    left: -26,
                    bottom: -46,
                    child: _lingkaran(120, 0x0FFFFFFF),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Total Saldo',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () =>
                                  setState(() => _sembunyi = !_sembunyi),
                              child: Icon(
                                _sembunyi
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _angka(data.saldo),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _kotakAlir(
                              'Pemasukan',
                              masuk,
                              Icons.south_west_rounded,
                            ),
                            const SizedBox(width: 10),
                            _kotakAlir(
                              'Pengeluaran',
                              keluar,
                              Icons.north_east_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          kartu(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                _menu(
                  Icons.add_rounded,
                  'Catat',
                  hijauTua,
                  () => bukaFormTransaksi(context, data),
                ),
                _menu(
                  Icons.receipt_long_rounded,
                  'Transaksi',
                  const Color(0xFF3B82C4),
                  () => widget.onPindah(1),
                ),
                _menu(
                  Icons.bar_chart_rounded,
                  'Laporan',
                  const Color(0xFF8E5BC9),
                  () => widget.onPindah(2),
                ),
                _menu(
                  Icons.pie_chart_rounded,
                  'Anggaran',
                  const Color(0xFFE8833A),
                  () => widget.onPindah(3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ringkasan Bulan Ini',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: rasio >= 1 ? merahMuda : hijauMuda,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(rasio * 100).round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: rasio >= 1 ? merah : hijauTua,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                barProgres(rasio, rasio >= 1 ? merah : hijauTua),
                const SizedBox(height: 10),
                Text(
                  masuk - keluar >= 0
                      ? 'Sisa bulan ini ${_angka(masuk - keluar)}'
                      : 'Pengeluaran melebihi pemasukan ${_angka(keluar - masuk)}',
                  style: const TextStyle(fontSize: 12, color: teksAbu),
                ),
              ],
            ),
          ),
          judulBagian(
            'Transaksi Terbaru',
            aksi: TextButton(
              onPressed: () => widget.onPindah(1),
              child: const Text(
                'Lihat Semua',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (data.transaksi.isEmpty)
            kosong(
              Icons.receipt_long_rounded,
              'Belum ada transaksi',
              'Tekan tombol + untuk mencatat transaksi pertamamu.',
            )
          else
            ...data.transaksi
                .take(5)
                .map(
                  (t) => BarisTransaksi(
                    t: t,
                    onTap: () => bukaFormTransaksi(context, data, awal: t),
                  ),
                ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFD7F2EA), Color(0xFFEAF8F2)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ikonKotak(Icons.lightbulb_rounded, emas, ukuran: 44),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tips Hemat Hari Ini',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Catat pengeluaran kecil setiap hari. Biasanya dari situlah uang paling banyak bocor.',
                        style: TextStyle(
                          fontSize: 12,
                          color: teksAbu,
                          height: 1.4,
                        ),
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
