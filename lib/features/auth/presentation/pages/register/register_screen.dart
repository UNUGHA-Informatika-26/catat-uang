import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/auth_bloc.dart';
import '../../../../../core/format.dart';
import '../../../../../core/tema.dart';
import '../../../../../core/widgets.dart';
import '../../widgets/auth_scaffold.dart';
import '../login/login_screen.dart';
import '../../../../home/presentation/pages/home_shell/home_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  final _konfirmasi = TextEditingController();
  bool _sembunyi = true;
  bool _sembunyiKonfirmasi = true;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _sandi.dispose();
    _konfirmasi.dispose();
    super.dispose();
  }

  void _register() {
    final nama = _nama.text.trim();
    final email = _email.text.trim();
    if (nama.isEmpty) {
      pesan(context, 'Nama lengkap harus diisi.');
      return;
    }
    if (!email.contains('@')) {
      pesan(context, 'Masukkan email yang valid.');
      return;
    }
    if (_sandi.text.length < 8) {
      pesan(context, 'Password minimal 8 karakter.');
      return;
    }
    if (_sandi.text != _konfirmasi.text) {
      pesan(context, 'Konfirmasi password tidak sama.');
      return;
    }
    context.read<AuthBloc>().add(
      RegisterDiminta(nama: nama, email: email, sandi: _sandi.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, _) => ModalRoute.of(context)?.isCurrent ?? true,
      listener: (context, state) {
        if (state is AuthLogin) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeShell()),
            (_) => false,
          );
        } else if (state is AuthKonfirmasiEmail) {
          pesan(
            context,
            'Akun dibuat. Periksa email ${state.email} untuk konfirmasi.',
          );
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
          judul: 'Register',
          subjudul: 'Buat akun baru untuk mulai mencatat keuanganmu.',
          children: [
            labelField('Nama Lengkap'),
            TextField(
              controller: _nama,
              textCapitalization: TextCapitalization.words,
              decoration: dekor('Nama kamu', ikon: Icons.person_outline),
            ),
            const SizedBox(height: 16),
            labelField('Email'),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: dekor('Email aktif', ikon: Icons.mail_outline),
            ),
            const SizedBox(height: 16),
            labelField('Password'),
            TextField(
              controller: _sandi,
              obscureText: _sembunyi,
              decoration: dekor(
                'Minimal 8 karakter',
                ikon: Icons.lock_outline,
                suffix: ikonMata(
                  _sembunyi,
                  () => setState(() => _sembunyi = !_sembunyi),
                ),
              ),
            ),
            const SizedBox(height: 16),
            labelField('Konfirmasi Password'),
            TextField(
              controller: _konfirmasi,
              obscureText: _sembunyiKonfirmasi,
              decoration: dekor(
                'Ulangi password',
                ikon: Icons.lock_outline,
                suffix: ikonMata(
                  _sembunyiKonfirmasi,
                  () => setState(
                    () => _sembunyiKonfirmasi = !_sembunyiKonfirmasi,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            tombolUtama('Register', _register, loading: loading),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Sudah punya akun?',
                  style: TextStyle(color: teksAbu),
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
        );
      },
    );
  }
}
