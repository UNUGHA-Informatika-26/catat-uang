import 'package:flutter/material.dart';

class KategoriInfo {
  const KategoriInfo(this.nama, this.ikon, this.warna);
  final String nama;
  final IconData ikon;
  final Color warna;
}

const kategoriPengeluaran = [
  KategoriInfo('Makanan', Icons.restaurant_rounded, Color(0xFFE8833A)),
  KategoriInfo('Transportasi', Icons.directions_bus_rounded, Color(0xFF3B82C4)),
  KategoriInfo('Belanja', Icons.shopping_bag_rounded, Color(0xFF8E5BC9)),
  KategoriInfo('Tagihan', Icons.receipt_long_rounded, Color(0xFFD9534F)),
  KategoriInfo('Hiburan', Icons.movie_rounded, Color(0xFFE05A9C)),
  KategoriInfo('Kesehatan', Icons.favorite_rounded, Color(0xFF2FA89A)),
  KategoriInfo('Pendidikan', Icons.school_rounded, Color(0xFF4F6FD8)),
  KategoriInfo('Lainnya', Icons.more_horiz_rounded, Color(0xFF7A8580)),
];

const kategoriPemasukan = [
  KategoriInfo('Gaji', Icons.payments_rounded, Color(0xFF0B7A4B)),
  KategoriInfo('Bonus', Icons.card_giftcard_rounded, Color(0xFF3B82C4)),
  KategoriInfo('Usaha', Icons.storefront_rounded, Color(0xFFE8833A)),
  KategoriInfo('Hadiah', Icons.redeem_rounded, Color(0xFFE05A9C)),
  KategoriInfo('Lainnya', Icons.more_horiz_rounded, Color(0xFF7A8580)),
];

KategoriInfo infoKategori(String nama, bool pemasukan) {
  final daftar = pemasukan ? kategoriPemasukan : kategoriPengeluaran;
  for (final k in daftar) {
    if (k.nama == nama) return k;
  }
  return KategoriInfo(nama, Icons.category_rounded, const Color(0xFF7A8580));
}
