import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/auth_bloc.dart';
import '../../../../../core/format.dart';
import '../../../../../core/widgets.dart';
import '../../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _kirim() {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      pesan(context, 'Masukkan email yang valid.');
      return;
    }
    context.read<AuthBloc>().add(LupaSandiDiminta(email: email));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, _) => ModalRoute.of(context)?.isCurrent ?? true,
      listener: (context, state) {
        if (state is LupaSandiBerhasil) {
          pesan(
            context,
            'Tautan untuk mengatur ulang kata sandi telah dikirim.',
          );
          Navigator.pop(context);
        } else if (state is AuthGagal) {
          pesan(context, state.pesan);
        }
      },
      builder: (context, state) {
        return AuthScaffold(
          bisaKembali: true,
          judul: 'Lupa Kata Sandi?',
          subjudul: 'Kami akan mengirim tautan pemulihan ke email Anda.',
          children: [
            labelField('Email'),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: dekor(
                'Masukkan email terdaftar',
                ikon: Icons.mail_outline,
              ),
            ),
            const SizedBox(height: 24),
            tombolUtama(
              'Kirim Tautan Pemulihan',
              _kirim,
              loading: state is AuthMemuat,
            ),
          ],
        );
      },
    );
  }
}
