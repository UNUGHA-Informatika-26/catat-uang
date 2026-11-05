class Anggaran {
  const Anggaran({
    required this.id,
    required this.kategori,
    required this.batas,
  });
  final dynamic id;
  final String kategori;
  final int batas;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kategori': kategori,
    'batas': batas,
  };

  static Anggaran dariJson(Map<String, dynamic> j) => Anggaran(
    id: j['id'],
    kategori: (j['kategori'] as String?) ?? '',
    batas: ((j['batas'] as num?) ?? 0).toInt(),
  );
}

const kunciTotal = 'Total';
