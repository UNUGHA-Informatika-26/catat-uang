import '../../../core/format.dart';

class Transaksi {
  const Transaksi({
    required this.id,
    required this.kategori,
    required this.catatan,
    required this.nominal,
    required this.pemasukan,
    required this.tanggal,
  });

  final String id;
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
    'tanggal': tanggalSql(tanggal),
  };

  static Transaksi dariJson(Map<String, dynamic> j) => Transaksi(
    id: '${j['sync_id'] ?? j['id']}',
    kategori: (j['kategori'] as String?) ?? 'Lainnya',
    catatan: (j['catatan'] as String?) ?? '',
    nominal: ((j['nominal'] as num?) ?? 0).toInt(),
    pemasukan: j['pemasukan'] == true,
    tanggal: DateTime.tryParse('${j['tanggal']}') ?? DateTime.now(),
  );
}

int totalTransaksi(Iterable<Transaksi> daftar, bool pemasukan) => daftar
    .where((t) => t.pemasukan == pemasukan)
    .fold<int>(0, (jumlah, t) => jumlah + t.nominal);
