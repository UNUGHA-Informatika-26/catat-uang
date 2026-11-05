import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/tema.dart';
import '../../models/anggaran.dart';
import '../../models/kategori.dart';

class NominalDialog extends StatefulWidget {
  const NominalDialog({
    super.key,
    required this.judul,
    required this.label,
    required this.tombol,
    this.awal,
  });

  final String judul;
  final String label;
  final String tombol;
  final int? awal;

  @override
  State<NominalDialog> createState() => _NominalDialogState();
}

class _NominalDialogState extends State<NominalDialog> {
  late final TextEditingController _c = TextEditingController(
    text: widget.awal?.toString() ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.judul),
      content: TextField(
        controller: _c,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: widget.label,
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final n = int.tryParse(_c.text.trim());
            if (n == null || n <= 0) {
              setState(() => _error = 'Masukkan nominal yang valid');
              return;
            }
            Navigator.pop(context, n);
          },
          child: Text(widget.tombol),
        ),
      ],
    );
  }
}

class AnggaranDialog extends StatefulWidget {
  const AnggaranDialog({super.key, this.awal});
  final Anggaran? awal;

  @override
  State<AnggaranDialog> createState() => _AnggaranDialogState();
}

class _AnggaranDialogState extends State<AnggaranDialog> {
  late String _kategori =
      widget.awal?.kategori ?? kategoriPengeluaran.first.nama;
  late final TextEditingController _c = TextEditingController(
    text: widget.awal?.batas.toString() ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mengubah = widget.awal != null;
    return AlertDialog(
      title: Text(mengubah ? 'Ubah Anggaran' : 'Tambah Anggaran'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mengubah) ...[
              const Text(
                'Kategori',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final k in kategoriPengeluaran)
                    ChoiceChip(
                      label: Text(k.nama),
                      selected: _kategori == k.nama,
                      showCheckmark: false,
                      selectedColor: hijauMuda,
                      onSelected: (_) => setState(() => _kategori = k.nama),
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ] else ...[
              Text(
                _kategori,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _c,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Batas per bulan (Rp)',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final n = int.tryParse(_c.text.trim());
            if (n == null || n <= 0) {
              setState(() => _error = 'Masukkan nominal yang valid');
              return;
            }
            Navigator.pop(context, <String, dynamic>{
              'kategori': _kategori,
              'batas': n,
            });
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
