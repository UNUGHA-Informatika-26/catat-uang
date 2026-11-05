import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/auth_bloc.dart';
import '../../../../../core/tema.dart';
import '../onboarding/onboarding_screen.dart';
import '../../../../home/presentation/pages/home_shell/home_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthDipulihkan());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLogin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeShell()),
          );
        } else if (state is AuthTidakLogin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthGagal) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.pesan, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<AuthBloc>().add(const AuthDipulihkan()),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(gradient: gradienUtama),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 132,
                    height: 132,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x59000000),
                          blurRadius: 26,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo/logo_bulat.png',
                      width: 132,
                      height: 132,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 60,
                          color: hijauTua,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'CatatUang',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Catat keuangan, lebih terkendali',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
