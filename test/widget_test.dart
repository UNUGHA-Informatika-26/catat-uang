import 'package:flutter_test/flutter_test.dart';

import 'package:catat_uang/main.dart';

void main() {
  testWidgets('requires Supabase configuration before authenticating', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CatatUangApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai Sekarang'));
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang Kembali!'), findsOneWidget);
    await tester.tap(find.text('Masuk Sekarang'));
    await tester.pumpAndSettle();

    expect(find.text('Supabase belum dikonfigurasi. Jalankan aplikasi dengan '
        'SUPABASE_URL dan SUPABASE_ANON_KEY.'), findsOneWidget);
    expect(find.text('Ringkasan Keuangan'), findsNothing);
  });
}
