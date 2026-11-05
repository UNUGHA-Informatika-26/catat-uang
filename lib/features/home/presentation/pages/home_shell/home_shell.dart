import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../auth/bloc/auth_bloc.dart';
import '../../../../auth/presentation/pages/login/login_screen.dart';
import '../../../../keuangan/data/app_data.dart';
import '../../../../keuangan/presentation/pages/anggaran/anggaran_tab.dart';
import '../../../../keuangan/presentation/pages/laporan/laporan_tab.dart';
import '../../../../keuangan/presentation/pages/transaksi/transaksi_form.dart';
import '../../../../keuangan/presentation/pages/transaksi/transaksi_tab.dart';
import '../../../../../core/tema.dart';
import '../beranda/beranda_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final AppData data = AppData();
  int tab = 0;

  @override
  void initState() {
    super.initState();
    data.muat();
  }

  @override
  void dispose() {
    data.dispose();
    super.dispose();
  }

  void _pindah(int i) => setState(() => tab = i);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      // Setelah Log Out, kembali ke layar Log In.
      listenWhen: (_, s) => s is AuthTidakLogin,
      listener: (context, _) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: AnimatedBuilder(
            animation: data,
            builder: (context, _) => IndexedStack(
              index: tab,
              children: [
                BerandaTab(data: data, onPindah: _pindah),
                TransaksiTab(data: data),
                LaporanTab(data: data),
                AnggaranTab(data: data),
              ],
            ),
          ),
        ),
        floatingActionButton: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradienUtama,
            boxShadow: [
              BoxShadow(
                color: Color(0x660F766E),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => bukaFormTransaksi(context, data),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 12,
          shadowColor: const Color(0x330F766E),
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          height: 64,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, 'Beranda'),
                _navItem(1, Icons.receipt_long_rounded, 'Transaksi'),
                const SizedBox(width: 48),
                _navItem(2, Icons.bar_chart_rounded, 'Laporan'),
                _navItem(3, Icons.pie_chart_rounded, 'Anggaran'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData ikon, String label) {
    final aktif = tab == index;
    final warna = aktif ? hijauTua : const Color(0xFF9AA8AD);
    return InkWell(
      onTap: () => _pindah(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, color: warna, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: aktif ? FontWeight.w800 : FontWeight.w500,
                color: warna,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void tampilProfil(BuildContext context, AppData data) {
  final state = context.read<AuthBloc>().state;
  final akun = state is AuthLogin ? state.akun : null;
  final nama = data.nama.isEmpty ? 'Pengguna' : data.nama;
  final email = akun?.email ?? '-';
  final inisial = nama.isEmpty ? '?' : nama.substring(0, 1).toUpperCase();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: latar,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradienUtama,
            ),
            child: Text(
              inisial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            nama,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(color: teksAbu)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: merah,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.pop(sheet);
                context.read<AuthBloc>().add(const LogoutDiminta());
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
