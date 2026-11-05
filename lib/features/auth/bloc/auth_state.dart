part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthAwal extends AuthState {
  const AuthAwal();
}

class AuthMemuat extends AuthState {
  const AuthMemuat();
}

class AuthLogin extends AuthState {
  const AuthLogin(this.akun);
  final Akun akun;

  @override
  List<Object?> get props => [akun.id, akun.nama, akun.email];
}

class AuthTidakLogin extends AuthState {
  const AuthTidakLogin();
}

class AuthGagal extends AuthState {
  const AuthGagal(this.pesan);
  final String pesan;

  @override
  List<Object?> get props => [pesan];
}

class LupaSandiBerhasil extends AuthState {
  const LupaSandiBerhasil();
}

class AuthKonfirmasiEmail extends AuthState {
  const AuthKonfirmasiEmail(this.email);
  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthResetSesi extends AuthState {
  const AuthResetSesi();
}

class KataSandiDiperbarui extends AuthState {
  const KataSandiDiperbarui();
}
