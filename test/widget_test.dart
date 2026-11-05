import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catat_uang/features/auth/data/auth_repository.dart';
import 'package:catat_uang/features/auth/models/akun.dart';
import 'package:catat_uang/features/auth/presentation/pages/onboarding/onboarding_screen.dart';
import 'package:catat_uang/main.dart';

void main() {
  testWidgets('app starts on the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      CatatUangApp(authRepository: _FakeAuthRepository()),
    );

    expect(find.text('CatatUang'), findsOneWidget);
    expect(find.text('Catat keuangan, lebih terkendali'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('onboarding screen offers registration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(find.text('Mulai Sekarang'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<Akun> get signInEvents => const Stream<Akun>.empty();

  @override
  Stream<void> get passwordRecoveryEvents => const Stream<void>.empty();

  @override
  Future<Akun?> pulihkanSesi() async => null;

  @override
  Future<Akun> masuk({required String email, required String sandi}) {
    throw UnimplementedError();
  }

  @override
  Future<Akun?> daftar({
    required String nama,
    required String email,
    required String sandi,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> kirimEmailPemulihan(String email) {
    throw UnimplementedError();
  }

  @override
  Future<void> ubahSandi(String sandiBaru) {
    throw UnimplementedError();
  }

  @override
  Future<void> keluar() {
    throw UnimplementedError();
  }
}
