import 'package:flutter/material.dart';

import '../../../../../core/tema.dart';
import '../../../../../core/widgets.dart';
import '../login/login_screen.dart';
import '../register/register_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Widget _fitur(IconData ikon, String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: kartu(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: hijauMuda,
              child: Icon(ikon, size: 18, color: hijauTua),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                teks,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kotak(String label, String nilai, IconData ikon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0x26FFFFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ikon, size: 14, color: Colors.white70),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              nilai,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'CatatUang',
                        style: TextStyle(
                          color: hijauTua,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: gradienUtama,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x590F766E),
                            blurRadius: 22,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Saldo',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Rp14.850.000',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _kotak(
                                'Pemasukan',
                                'Rp8.000.000',
                                Icons.south_west,
                              ),
                              const SizedBox(width: 10),
                              _kotak(
                                'Pengeluaran',
                                'Rp2.150.000',
                                Icons.north_east,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Kelola Uang Harian Jadi Lebih Mudah & Teratur',
                      style: TextStyle(
                        fontSize: 24,
                        height: 1.25,
                        fontWeight: FontWeight.bold,
                        color: teksGelap,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Catat pemasukan dan pengeluaran, pantau laporan, dan atur anggaranmu dalam satu aplikasi.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: teksAbu,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _fitur(Icons.edit_note, 'Catat transaksi dengan cepat'),
                    _fitur(
                      Icons.bar_chart,
                      'Lihat grafik keuangan dengan jelas',
                    ),
                    _fitur(
                      Icons.account_balance_wallet_outlined,
                      'Atur anggaran bulananmu',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              tombolUtama(
                'Mulai Sekarang',
                () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                ikon: Icons.arrow_forward,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sudah punya akun?',
                    style: TextStyle(color: teksAbu, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: hijauTua,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
