import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import '../models/akun.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required this.repository}) : super(const AuthAwal()) {
    on<AuthDipulihkan>(_dipulihkan);
    on<LoginDiminta>(_login);
    on<RegisterDiminta>(_register);
    on<LupaSandiDiminta>(_lupaSandi);
    on<AuthResetLinkDiterima>((event, emit) => emit(const AuthResetSesi()));
    on<KataSandiBaruDiminta>(_kataSandiBaru);
    on<AuthSesiDiterima>((event, emit) {
      if (state is! AuthLogin ||
          (state as AuthLogin).akun.id != event.akun.id) {
        emit(AuthLogin(event.akun));
      }
    });
    on<LogoutDiminta>(_logout);
    _signInSubscription = repository.signInEvents.listen(
      (akun) => add(AuthSesiDiterima(akun)),
      onError: (Object error) => add(AuthGalatDiterima('$error')),
    );
    _recoverySubscription = repository.passwordRecoveryEvents.listen(
      (_) => add(const AuthResetLinkDiterima()),
      onError: (Object error) => add(AuthGalatDiterima('$error')),
    );
    on<AuthGalatDiterima>((event, emit) => emit(AuthGagal(event.pesan)));
  }

  final AuthRepository repository;
  late final StreamSubscription<Akun> _signInSubscription;
  late final StreamSubscription<void> _recoverySubscription;

  Future<void> _dipulihkan(
    AuthDipulihkan event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthMemuat());
    try {
      final akun = await repository.pulihkanSesi();
      emit(akun == null ? const AuthTidakLogin() : AuthLogin(akun));
    } catch (e) {
      emit(AuthGagal('Gagal memulihkan sesi Supabase: $e'));
    }
  }

  Future<void> _login(LoginDiminta event, Emitter<AuthState> emit) async {
    emit(const AuthMemuat());
    try {
      final akun = await repository.masuk(
        email: event.email,
        sandi: event.sandi,
      );
      emit(AuthLogin(akun));
    } catch (e) {
      emit(AuthGagal('Gagal Log In: $e'));
    }
  }

  Future<void> _register(RegisterDiminta event, Emitter<AuthState> emit) async {
    emit(const AuthMemuat());
    try {
      final akun = await repository.daftar(
        nama: event.nama,
        email: event.email,
        sandi: event.sandi,
      );
      emit(akun == null ? AuthKonfirmasiEmail(event.email) : AuthLogin(akun));
    } catch (e) {
      emit(AuthGagal('Gagal Register: $e'));
    }
  }

  Future<void> _lupaSandi(
    LupaSandiDiminta event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthMemuat());
    try {
      await repository.kirimEmailPemulihan(event.email);
      emit(const LupaSandiBerhasil());
    } catch (e) {
      emit(AuthGagal('Gagal mengirim email pemulihan: $e'));
    }
  }

  Future<void> _kataSandiBaru(
    KataSandiBaruDiminta event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthMemuat());
    try {
      await repository.ubahSandi(event.sandiBaru);
      emit(const KataSandiDiperbarui());
    } catch (e) {
      emit(AuthGagal('Gagal memperbarui kata sandi: $e'));
    }
  }

  Future<void> _logout(LogoutDiminta event, Emitter<AuthState> emit) async {
    try {
      await repository.keluar();
      emit(const AuthTidakLogin());
    } catch (e) {
      emit(AuthGagal('Gagal Log Out: $e'));
    }
  }

  @override
  Future<void> close() async {
    await _signInSubscription.cancel();
    await _recoverySubscription.cancel();
    await super.close();
  }
}
