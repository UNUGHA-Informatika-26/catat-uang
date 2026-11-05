import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/auth_bloc.dart';
import '../../../../../core/format.dart';
import '../../../../../core/widgets.dart';
import '../../widgets/auth_scaffold.dart';
import '../login/login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _sandi = TextEditingController();
  final _konfirmasi = TextEditingController();
  bool _sembunyi = true;

  @override
  void dispose() {
    _sandi.dispose();
    _konfirmasi.dispose();
    super.dispose();
  }

  void _simpan() {
    if (_sandi.text.length < 8) {
      pesan(context, 'Password minimal 8 karakter.');
      return;
    }
    if (_sandi.text != _konfirmasi.text) {
      pesan(context, 'Konfirmasi password tidak sama.');
      return;
    }
    context.read<AuthBloc>().add(KataSandiBaruDiminta(sandiBaru: _sandi.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, state) =>
          state is KataSandiDiperbarui || state is AuthGagal,
      listener: (context, state) {
        if (state is KataSandiDiperbarui) {
          pesan(context, 'Kata sandi diperbarui. Silakan Log In kembali.');
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
        return AuthScaffold(
          judul: 'Buat Kata Sandi Baru',
          subjudul:
              'Tautan pemulihan berhasil dibuka. Masukkan kata sandi baru.',
          children: [
            labelField('Password Baru'),
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
              obscureText: _sembunyi,
              decoration: dekor(
                'Ulangi password baru',
                ikon: Icons.lock_outline,
              ),
            ),
            const SizedBox(height: 24),
            tombolUtama(
              'Simpan Password Baru',
              _simpan,
              loading: state is AuthMemuat,
            ),
          ],
        );
      },
    );
  }
}
