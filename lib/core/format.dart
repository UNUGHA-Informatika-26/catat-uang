import 'package:flutter/cupertino.dart'
    show CupertinoAlertDialog, CupertinoDialogAction, showCupertinoDialog;
import 'package:flutter/material.dart';

const bulanPendek = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];
const bulanPanjang = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];
const hariPendek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

String tanggalSql(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String tgl(DateTime d) => '${d.day} ${bulanPendek[d.month - 1]} ${d.year}';

bool sama(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String labelHari(DateTime d) {
  final sekarang = DateTime.now();
  if (sama(d, sekarang)) return 'Hari ini';
  if (sama(d, DateTime(sekarang.year, sekarang.month, sekarang.day - 1))) {
    return 'Kemarin';
  }
  return tgl(d);
}

String rp(int angka) {
  final teks = angka.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < teks.length; i++) {
    buffer.write(teks[i]);
    final sisa = teks.length - i - 1;
    if (sisa > 0 && sisa % 3 == 0) buffer.write('.');
  }
  return '${angka < 0 ? '-' : ''}Rp$buffer';
}

Color muda(Color c) => Color.alphaBlend(c.withAlpha(36), Colors.white);

void pesan(BuildContext context, String teks) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(teks)));
}

/// Dialog konfirmasi bergaya iPhone.
Future<bool> konfirmasi(BuildContext context, String judul, String isi) async {
  final hasil = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(judul),
      content: Text(isi),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return hasil == true;
}
