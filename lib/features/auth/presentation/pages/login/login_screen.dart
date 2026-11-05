import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/auth_bloc.dart';
import '../../../../../core/format.dart';
import '../../../../../core/tema.dart';
import '../../../../../core/widgets.dart';
import '../../widgets/auth_scaffold.dart';
import '../forgot_password/forgot_password_screen.dart';
import '../register/register_screen.dart';
import '../../../../home/presentation/pages/home_shell/home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  bool _sembunyi = true;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  void _logIn() {
    final email = _email.text.trim();
    if (email.isEmpty || _sandi.text.isEmpty) {
      pesan(context, 'Isi email dan password terlebih dahulu.');
      return;
    }
    context.read<AuthBloc>().add(
      LoginDiminta(email: email, sandi: _sandi.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      // Hanya layar yang sedang tampil yang merespons.
      listenWhen: (_, _) => ModalRoute.of(context)?.isCurrent ?? true,
      listener: (context, state) {
        if (state is AuthLogin) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeShell()),
            (_) => false,
          );
        } else if (state is AuthKonfirmasiEmail) {
          pesan(context, 'Periksa email ${state.email} untuk konfirmasi akun.');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        } else if (state is AuthGagal) {
          pesan(context, state.pesan);
        }
      },
      builder: (context, state) {
        final loading = state is AuthMemuat;
        return AuthScaffold(
          judul: 'Log In',
          subjudul:
              'Selamat datang kembali! Log In untuk mengelola keuanganmu.',
          children: [
            labelField('Email'),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: dekor(
                'Masukkan email kamu',
                ikon: Icons.mail_outline,
              ),
            ),
            const SizedBox(height: 18),
            labelField('Password'),
            TextField(
              controller: _sandi,
              obscureText: _sembunyi,
              decoration: dekor(
                'Masukkan password',
                ikon: Icons.lock_outline,
                suffix: ikonMata(
                  _sembunyi,
                  () => setState(() => _sembunyi = !_sembunyi),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                ),
                child: const Text('Lupa Kata Sandi?'),
              ),
            ),
            const SizedBox(height: 6),
            tombolUtama(
              'Log In ke CatatUang',
              _logIn,
              loading: loading,
              ikon: Icons.arrow_forward,
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ATAU',
                    style: TextStyle(fontSize: 11, color: teksAbu),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: teksGelap,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: garis),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () =>
                    pesan(context, 'Log In dengan Google belum tersedia.'),
                icon: const Text(
                  'G',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFFDB4437),
                  ),
                ),
                label: const Text('Lanjutkan dengan Google'),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Belum punya akun?',
                  style: TextStyle(color: teksAbu),
                ),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      color: hijauTua,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
