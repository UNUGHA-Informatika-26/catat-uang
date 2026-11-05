import 'package:flutter/material.dart';

import '../../../../core/tema.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.judul,
    required this.subjudul,
    required this.children,
    this.bisaKembali = false,
  });

  final String judul;
  final String subjudul;
  final List<Widget> children;
  final bool bisaKembali;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bisaKembali)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                )
              else
                const SizedBox(height: 28),
              const SizedBox(height: 8),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x4D0F766E),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/logo/logo_bulat.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: gradienUtama,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                judul,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: teksGelap,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subjudul,
                style: const TextStyle(
                  fontSize: 14,
                  color: teksAbu,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
