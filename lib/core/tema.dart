import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';

// ==========================================
// PALET WARNA APLIKASI
// ==========================================

const Color hijauTua = Color(0xFF0F766E);
const Color hijau = Color(0xFF10B981);
const Color latar = Color(0xFFF2F6F6);
const Color hijauMuda = Color(0xFFD7F2EA);

const Color merah = Color(0xFFEF4444);
const Color merahMuda = Color(0xFFFEE2E2);

const Color teksGelap = Color(0xFF0F1F1C);
const Color teksAbu = Color(0xFF6B7A80);
const Color garis = Color(0xFFE5EAEC);

const Color emas = Color(0xFFF5A623);

// ==========================================
// GRADIEN UTAMA
// ==========================================

const LinearGradient gradienUtama = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0B5F59), Color(0xFF14B8A6)],
);

// ==========================================
// BAYANGAN KARTU
// ==========================================

const List<BoxShadow> bayanganLembut = [
  BoxShadow(color: Color(0x0F0F766E), blurRadius: 20, offset: Offset(0, 6)),
];

// ==========================================
// TEMA APLIKASI
// ==========================================

ThemeData buatTema() {
  return ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: latar,

    colorScheme: ColorScheme.fromSeed(
      seedColor: hijauTua,
      brightness: Brightness.light,
    ),

    // Menghilangkan efek riak pada tombol
    splashFactory: NoSplash.splashFactory,

    // Transisi halaman seperti iPhone
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),

        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),

        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),

        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),

        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    ),

    // Tampilan Snackbar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,

      backgroundColor: const Color(0xFF1C2B29),

      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

// ==========================================
// PERILAKU SCROLL SEPERTI IPHONE
// ==========================================

class PerilakuScroll extends MaterialScrollBehavior {
  const PerilakuScroll();

  // Mendukung berbagai perangkat input
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  // Efek scroll memantul
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  // Menghilangkan indikator overscroll
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
