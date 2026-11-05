part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthDipulihkan extends AuthEvent {
  const AuthDipulihkan();
}

class LoginDiminta extends AuthEvent {
  const LoginDiminta({required this.email, required this.sandi});
  final String email;
  final String sandi;

  @override
  List<Object?> get props => [email, sandi];
}

class RegisterDiminta extends AuthEvent {
  const RegisterDiminta({
    required this.nama,
    required this.email,
    required this.sandi,
  });
  final String nama;
  final String email;
  final String sandi;

  @override
  List<Object?> get props => [nama, email, sandi];
}

class LupaSandiDiminta extends AuthEvent {
  const LupaSandiDiminta({required this.email});
  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthResetLinkDiterima extends AuthEvent {
  const AuthResetLinkDiterima();
}

class AuthSesiDiterima extends AuthEvent {
  const AuthSesiDiterima(this.akun);
  final Akun akun;

  @override
  List<Object?> get props => [akun.id];
}

class KataSandiBaruDiminta extends AuthEvent {
  const KataSandiBaruDiminta({required this.sandiBaru});
  final String sandiBaru;

  @override
  List<Object?> get props => [sandiBaru];
}

class AuthGalatDiterima extends AuthEvent {
  const AuthGalatDiterima(this.pesan);
  final String pesan;

  @override
  List<Object?> get props => [pesan];
}

class LogoutDiminta extends AuthEvent {
  const LogoutDiminta();
}
