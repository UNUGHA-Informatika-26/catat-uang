import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/akun.dart';

abstract interface class AuthRepository {
  Stream<Akun> get signInEvents;
  Stream<void> get passwordRecoveryEvents;

  Future<Akun?> pulihkanSesi();
  Future<Akun> masuk({required String email, required String sandi});
  Future<Akun?> daftar({
    required String nama,
    required String email,
    required String sandi,
  });
  Future<void> kirimEmailPemulihan(String email);
  Future<void> ubahSandi(String sandiBaru);
  Future<void> keluar();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<Akun> get signInEvents => _client.auth.onAuthStateChange
      .where((state) => state.event == AuthChangeEvent.signedIn)
      .map((state) {
        final user = state.session?.user;
        if (user == null) {
          throw const AuthException('Sesi login tidak memiliki data pengguna.');
        }
        return _akun(user);
      });

  @override
  Stream<void> get passwordRecoveryEvents => _client.auth.onAuthStateChange
      .where((state) => state.event == AuthChangeEvent.passwordRecovery)
      .map((_) {});

  @override
  Future<Akun?> pulihkanSesi() async {
    final user = _client.auth.currentUser;
    return user == null ? null : _akun(user);
  }

  @override
  Future<Akun> masuk({required String email, required String sandi}) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: sandi,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Supabase tidak mengembalikan data pengguna.');
    }
    return _akun(user);
  }

  @override
  Future<Akun?> daftar({
    required String nama,
    required String email,
    required String sandi,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: sandi,
      data: {'nama': nama.trim()},
      emailRedirectTo: 'catatuang://login-callback',
    );
    final user = response.user;
    if (user == null || response.session == null) return null;
    return _akun(user);
  }

  @override
  Future<void> kirimEmailPemulihan(String email) =>
      _client.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
        redirectTo: 'catatuang://reset-password',
      );

  @override
  Future<void> ubahSandi(String sandiBaru) async {
    await _client.auth.updateUser(UserAttributes(password: sandiBaru));
    await keluar();
  }

  @override
  Future<void> keluar() => _client.auth.signOut(scope: SignOutScope.local);

  Akun _akun(User user) {
    final nama = user.userMetadata?['nama'];
    return Akun(
      id: user.id,
      nama: nama is String && nama.trim().isNotEmpty
          ? nama.trim()
          : user.email?.split('@').first ?? 'Pengguna',
      email: user.email ?? '',
    );
  }
}
