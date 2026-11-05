import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'core/tema.dart';
import 'core/supabase_config.dart';
import 'features/auth/presentation/pages/reset_password/reset_password_screen.dart';
import 'features/auth/presentation/pages/splash/splash_screen.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>('data');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    runApp(
      const CatatUangApp(
        configurationError:
            'Konfigurasi Supabase belum diisi. Jalankan aplikasi dengan '
            '--dart-define=SUPABASE_URL=... dan '
            '--dart-define=SUPABASE_ANON_KEY=....',
      ),
    );
    return;
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  } catch (e) {
    runApp(
      CatatUangApp(configurationError: 'Gagal menginisialisasi Supabase: $e'),
    );
    return;
  }
  runApp(const CatatUangApp());
}

class CatatUangApp extends StatelessWidget {
  const CatatUangApp({super.key, this.configurationError, this.authRepository});

  final String? configurationError;
  final AuthRepository? authRepository;

  @override
  Widget build(BuildContext context) {
    if (configurationError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(configurationError!, textAlign: TextAlign.center),
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => AuthBloc(
        repository:
            authRepository ?? SupabaseAuthRepository(Supabase.instance.client),
      ),
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (_, state) => state is AuthResetSesi,
        listener: (context, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
              (_) => false,
            );
          });
        },
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Catat Uang',
          theme: buatTema(),
          scrollBehavior: const PerilakuScroll(),
          // Di layar lebar (Chrome) tampilan dibatasi selebar HP.
          builder: (context, child) => ColoredBox(
            color: const Color(0xFFDCE9E6),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: child,
              ),
            ),
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
