import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:flutter/material.dart';

import '../../../../../core/format.dart';
import '../../../../../core/tema.dart';
import '../../../../../core/widgets.dart';
import '../../../data/app_data.dart';
import '../../../models/kategori.dart';
import '../../../models/transaksi.dart';

class LaporanTab extends StatefulWidget {
  const LaporanTab({super.key, required this.data});
  final AppData data;

  @override
  State<LaporanTab> createState() => _LaporanTabState();
}

class _LaporanTabState extends State<LaporanTab> {
  int _periode = 1; // 0 minggu, 1 bulan
  int _geser = 0; // 0 = sekarang, -1 = periode sebelumnya, dst.

  Widget _segmen(String teks) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      child: Text(
        teks,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
      child: kartu(
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
                rp(nilai),
                style: TextStyle(fontWeight: FontWeight.w800, color: warna),
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
      mulai = DateTime(
        hariIni.year,
        hariIni.month,
        hariIni.day - 6 + _geser * 7,
      );
      akhir = DateTime(mulai.year, mulai.month, mulai.day + 7);
      judulPeriode = _geser == 0
          ? '7 hari terakhir'
          : '${tgl(mulai)} - ${tgl(DateTime(akhir.year, akhir.month, akhir.day - 1))}';
    } else {
      final b = DateTime(now.year, now.month + _geser, 1);
      mulai = b;
      akhir = DateTime(b.year, b.month + 1, 1);
      judulPeriode = '${bulanPanjang[b.month - 1]} ${b.year}';
    }

    // Panah kiri aktif hanya kalau masih ada transaksi yang lebih lama.
    final bisaMundur = data.transaksi.any((t) => t.tanggal.isBefore(mulai));
    final bisaMaju = _geser < 0;

    final dalam = data.transaksi
        .where((t) => !t.tanggal.isBefore(mulai) && t.tanggal.isBefore(akhir))
        .toList();
    final masuk = totalTransaksi(dalam, true);
    final keluar = totalTransaksi(dalam, false);

    final int n;
    final List<String> label;
    if (_periode == 0) {
      n = 7;
      label = [
        for (var i = 0; i < 7; i++)
          hariPendek[DateTime(mulai.year, mulai.month, mulai.day + i).weekday -
              1],
      ];
    } else {
      n = DateTime(mulai.year, mulai.month + 1, 0).day;
      label = [
        for (var i = 0; i < n; i++)
          (i == 0 || (i + 1) % 5 == 0) ? '${i + 1}' : '',
      ];
    }

    int indeks(DateTime d) {
      if (_periode == 0) {
        final selisih = DateTime(
          d.year,
          d.month,
          d.day,
        ).difference(mulai).inDays;
        return selisih.clamp(0, n - 1).toInt();
      }
      return (d.day - 1).clamp(0, n - 1).toInt();
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          const Text(
            'Laporan',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _periode,
              backgroundColor: const Color(0xFFE3EBEA),
              thumbColor: Colors.white,
              children: {0: _segmen('Minggu'), 1: _segmen('Bulan')},
              onValueChanged: (v) {
                if (v != null) {
                  setState(() {
                    _periode = v;
                    _geser = 0;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: 'Sebelumnya',
                onPressed: bisaMundur ? () => setState(() => _geser--) : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      judulPeriode,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (_geser != 0)
                      GestureDetector(
                        onTap: () => setState(() => _geser = 0),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            'Kembali ke sekarang',
                            style: TextStyle(
                              fontSize: 11,
                              color: hijauTua,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Berikutnya',
                onPressed: bisaMaju ? () => setState(() => _geser++) : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _ringkas('Pemasukan', masuk, hijauTua),
              const SizedBox(width: 8),
              _ringkas('Pengeluaran', keluar, merah),
              const SizedBox(width: 8),
              _ringkas(
                'Selisih',
                masuk - keluar,
                masuk - keluar >= 0 ? hijauTua : merah,
              ),
            ],
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
                      'Pemasukan vs Pengeluaran',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
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
                  SizedBox(
                    width: double.infinity,
                    height: 190,
                    child: CustomPaint(
                      painter: GrafikGarisPainter(
                        masuk: masukB,
                        keluar: keluarB,
                        label: label,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pengeluaran Berdasarkan Kategori',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
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
                            painter: DonutPainter(
                              urut.map((e) => e.value.toDouble()).toList(),
                              urut
                                  .map((e) => infoKategori(e.key, false).warna)
                                  .toList(),
                            ),
                          ),
                          SizedBox(
                            width: 92,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: teksAbu,
                                  ),
                                ),
                                FittedBox(
                                  child: Text(
                                    rp(keluar),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${keluar == 0 ? 0 : (e.value / keluar * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: teksAbu,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            rp(e.value),
                            style: const TextStyle(fontWeight: FontWeight.w800),
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

// ---------------------------------------------------------------------------
// Grafik garis: pemasukan (hijau) dan pengeluaran (merah) per hari.
// ---------------------------------------------------------------------------
class GrafikGarisPainter extends CustomPainter {
  GrafikGarisPainter({
    required this.masuk,
    required this.keluar,
    required this.label,
  });

  final List<int> masuk;
  final List<int> keluar;
  final List<String> label;

  static const double _kiri = 44;
  static const double _kanan = 10;
  static const double _atas = 10;
  static const double _bawah = 24;

  static int _bulatkan(int v) {
    if (v <= 0) return 1000;
    final p = math.pow(10, v.toString().length - 1).toInt();
    for (final k in const [1, 2, 3, 4, 5, 6, 8, 10]) {
      if (v <= k * p) return k * p;
    }
    return 10 * p;
  }

  static String _ringkas(num v) {
    if (v >= 1000000) {
      final j = v / 1000000;
      final teks = j == j.roundToDouble()
          ? '${j.round()}'
          : j.toStringAsFixed(1).replaceAll('.', ',');
      return '${teks}jt';
    }
    if (v >= 1000) return '${(v / 1000).round()}rb';
    return '${v.round()}';
  }

  void _tulis(
    Canvas canvas,
    String s,
    double x,
    double y, {
    bool rataKanan = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: const TextStyle(fontSize: 9.5, color: teksAbu),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = rataKanan ? x - tp.width : x - tp.width / 2;
    final dy = rataKanan ? y - tp.height / 2 : y;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = masuk.length;
    if (n == 0) return;

    final lebar = size.width - _kiri - _kanan;
    final tinggi = size.height - _atas - _bawah;
    final dasarY = _atas + tinggi;
    final maksData = [...masuk, ...keluar].fold<int>(0, math.max);
    final maks = _bulatkan(maksData);

    double px(int i) => _kiri + (n == 1 ? lebar / 2 : lebar * i / (n - 1));
    double py(int v) => dasarY - tinggi * (v / maks);

    final garisBantu = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = garis;
    for (var i = 0; i <= 4; i++) {
      final y = dasarY - tinggi * i / 4;
      canvas.drawLine(
        Offset(_kiri, y),
        Offset(size.width - _kanan, y),
        garisBantu,
      );
      _tulis(canvas, _ringkas(maks * i / 4), _kiri - 6, y, rataKanan: true);
    }

    void gambarSeri(List<int> nilai, Color warna) {
      final jalur = Path();
      for (var i = 0; i < n; i++) {
        final x = px(i);
        final y = py(nilai[i]);
        if (i == 0) {
          jalur.moveTo(x, y);
        } else {
          jalur.lineTo(x, y);
        }
      }
      final area = Path.from(jalur)
        ..lineTo(px(n - 1), dasarY)
        ..lineTo(px(0), dasarY)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..style = PaintingStyle.fill
          ..color = warna.withAlpha(28),
      );
      canvas.drawPath(
        jalur,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = warna,
      );
      if (n <= 8) {
        for (var i = 0; i < n; i++) {
          canvas.drawCircle(
            Offset(px(i), py(nilai[i])),
            3.5,
            Paint()..color = Colors.white,
          );
          canvas.drawCircle(
            Offset(px(i), py(nilai[i])),
            3.5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = warna,
          );
        }
      }
    }

    gambarSeri(keluar, merah);
    gambarSeri(masuk, hijau);

    for (var i = 0; i < n; i++) {
      if (label[i].isEmpty) continue;
      _tulis(canvas, label[i], px(i), dasarY + 6);
    }
  }

  @override
  bool shouldRepaint(covariant GrafikGarisPainter old) => true;
}

class DonutPainter extends CustomPainter {
  DonutPainter(this.nilai, this.warna);

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
      ..color = const Color(0xFFE3EEEB);
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
  bool shouldRepaint(covariant DonutPainter old) => true;
}
