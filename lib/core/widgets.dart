import 'package:flutter/material.dart';

import 'format.dart';
import 'tema.dart';
import '../features/keuangan/models/kategori.dart';
import '../features/keuangan/models/transaksi.dart';

Widget kartu({
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  Color warna = Colors.white,
}) {
  return Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: warna,
      borderRadius: BorderRadius.circular(22),
      boxShadow: bayanganLembut,
    ),
    child: child,
  );
}

/// Ikon dalam kotak membulat berwarna (gaya e-wallet / iOS).
Widget ikonKotak(IconData ikon, Color warna, {double ukuran = 44}) {
  return Container(
    width: ukuran,
    height: ukuran,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          muda(warna),
          Color.alphaBlend(warna.withAlpha(64), Colors.white),
        ],
      ),
      borderRadius: BorderRadius.circular(ukuran * 0.32),
    ),
    child: Icon(ikon, color: warna, size: ukuran * 0.5),
  );
}

Widget kosong(IconData ikon, String judul, String isi) {
  return kartu(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
    child: Column(
      children: [
        ikonKotak(ikon, hijauTua, ukuran: 56),
        const SizedBox(height: 12),
        Text(judul, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          isi,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: teksAbu, height: 1.4),
        ),
      ],
    ),
  );
}

Widget judulBagian(String teks, {Widget? aksi}) {
  return Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          teks,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: teksGelap,
          ),
        ),
        ?aksi,
      ],
    ),
  );
}

InputDecoration dekor(String hint, {Widget? suffix, IconData? ikon}) {
  final batas = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: garis),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9AA8AD)),
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

Widget tombolUtama(
  String teks,
  VoidCallback? onTap, {
  bool loading = false,
  IconData? ikon,
}) {
  final aktif = !loading && onTap != null;
  return Container(
    width: double.infinity,
    height: 54,
    decoration: BoxDecoration(
      gradient: aktif ? gradienUtama : null,
      color: aktif ? null : const Color(0xFF7FB8B2),
      borderRadius: BorderRadius.circular(16),
      boxShadow: aktif
          ? const [
              BoxShadow(
                color: Color(0x4D0F766E),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ]
          : null,
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.transparent,
        disabledForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
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

Widget barProgres(double nilai, Color warna, {double tinggi = 9}) {
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

Widget labelField(String teks) {
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

Widget ikonMata(bool tersembunyi, VoidCallback onTap) {
  return IconButton(
    onPressed: onTap,
    icon: Icon(
      tersembunyi ? Icons.visibility_off_rounded : Icons.visibility_rounded,
      color: teksAbu,
      size: 20,
    ),
  );
}

class BarisTransaksi extends StatelessWidget {
  const BarisTransaksi({
    super.key,
    required this.t,
    this.onTap,
    this.onLongPress,
  });

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
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          highlightColor: const Color(0x120F766E),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ikonKotak(info.ikon, info.warna, ukuran: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.judul,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${t.kategori} · ${tgl(t.tanggal)}',
                        style: const TextStyle(fontSize: 11.5, color: teksAbu),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${t.pemasukan ? '+' : '-'}${rp(t.nominal)}',
                  style: TextStyle(
                    color: warna,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
