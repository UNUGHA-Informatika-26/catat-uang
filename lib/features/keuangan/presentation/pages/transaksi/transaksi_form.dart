import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/format.dart';
import '../../../../../core/tema.dart';
import '../../../../../core/widgets.dart';
import '../../../data/app_data.dart';
import '../../../models/kategori.dart';
import '../../../models/transaksi.dart';

Future<void> bukaFormTransaksi(
  BuildContext context,
  AppData data, {
  Transaksi? awal,
}) async {
  final hasil = await Navigator.push<String>(
    context,
    MaterialPageRoute(
      builder: (_) => TransaksiFormScreen(data: data, awal: awal),
    ),
  );
  if (hasil != null && context.mounted) pesan(context, hasil);
}

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
    _nominal = TextEditingController(
      text: a == null ? '' : a.nominal.toString(),
    );
    _catatan = TextEditingController(text: a?.catatan ?? '');
  }

  @override
  void dispose() {
    _nominal.dispose();
    _catatan.dispose();
    super.dispose();
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
      late final bool tersinkron;
      if (_ubah) {
        tersinkron = await widget.data.ubahTransaksi(
          widget.awal!.id,
          nominal: nominal,
          kategori: _kategori,
          pemasukan: _pemasukan,
          tanggal: _tanggal,
          catatan: _catatan.text.trim(),
        );
      } else {
        tersinkron = await widget.data.tambahTransaksi(
          nominal: nominal,
          kategori: _kategori,
          pemasukan: _pemasukan,
          tanggal: _tanggal,
          catatan: _catatan.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(
        context,
        tersinkron
            ? (_ubah ? 'Transaksi diperbarui.' : 'Transaksi tersimpan.')
            : 'Tersimpan di perangkat; menunggu koneksi untuk sinkronisasi.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      pesan(context, 'Gagal menyimpan transaksi: $e');
    }
  }

  Future<void> _hapus() async {
    final ya = await konfirmasi(
      context,
      'Hapus transaksi?',
      'Transaksi ini akan dihapus permanen.',
    );
    if (!ya || !mounted) return;
    try {
      final tersinkron = await widget.data.hapusTransaksi(widget.awal!.id);
      if (mounted) {
        Navigator.pop(
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

  Widget _segmen(String teks, bool nilaiPemasukan) {
    final aktif = _pemasukan == nilaiPemasukan;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _pemasukan = nilaiPemasukan;
          _kategori =
              (_pemasukan ? kategoriPemasukan : kategoriPengeluaran).first.nama;
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
          border: Border.all(
            color: aktif ? hijauTua : garis,
            width: aktif ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: muda(k.warna),
              child: Icon(k.ikon, color: k.warna, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              k.nama,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
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
            kartu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NOMINAL TRANSAKSI',
                    style: TextStyle(
                      fontSize: 11,
                      color: teksAbu,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Rp',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _nominal,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
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
                    Text(
                      _errNominal!,
                      style: const TextStyle(color: merah, fontSize: 12),
                    )
                  else
                    Text(
                      nilai > 0 ? rp(nilai) : 'Masukkan jumlah uang',
                      style: const TextStyle(fontSize: 12, color: teksAbu),
                    ),
                ],
              ),
            ),
            judulBagian('Pilih Kategori'),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.92,
              children: [for (final k in daftar) _tile(k)],
            ),
            judulBagian('Tanggal Transaksi'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: hijauMuda,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: garis),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_outlined, color: hijauTua),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _ubah ? tgl(_tanggal) : 'Hari ini, ${tgl(_tanggal)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.lock_outline, color: teksAbu, size: 18),
                ],
              ),
            ),
            judulBagian('Catatan (opsional)'),
            TextField(
              controller: _catatan,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: dekor('Contoh: makan siang bersama teman'),
            ),
            const SizedBox(height: 24),
            tombolUtama(
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
