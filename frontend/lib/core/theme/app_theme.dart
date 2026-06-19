import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Échelle d'espacement (multiples de 4) — cohérence des marges/paddings.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Échelle de rayons d'arrondi.
class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

/// Durées d'animation standard.
class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 550);
}

class AppTheme {
  // ── Identité ────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0F3D2E);
  static const Color primaryLight = Color(0xFF1A5C44);
  static const Color gold = Color(0xFFC8A24A);
  static const Color goldLight = Color(0xFFD9B968);

  // ── Clair ───────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFAFAF8); // blanc cassé chaud
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF2F3F0);
  static const Color outline = Color(0xFFE6E8E3);
  static const Color textPrimary = Color(0xFF14181D);
  static const Color textSecondary = Color(0xFF6B7280);

  // ── Sombre ──────────────────────────────────────────────────────────────
  static const Color dark = Color(0xFF12161B);
  static const Color surfaceDark = Color(0xFF1A1F26);
  static const Color surfaceVariantDark = Color(0xFF222831);
  static const Color outlineDark = Color(0xFF2A313A);
  static const Color textPrimaryDark = Color(0xFFECEEF0);
  static const Color textSecondaryDark = Color(0xFF9AA3AD);

  static const Color errorColor = Color(0xFFC0392B);

  /// Style serif élégant (citations, grands titres éditoriaux).
  static TextStyle serif({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.lora(
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
        height: height,
      );

  /// Ombre douce pour les cartes/élévations (thème clair).
  static List<BoxShadow> softShadow([double opacity = 0.06]) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: opacity),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static const SystemUiOverlayStyle _overlayLight = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  static const SystemUiOverlayStyle _overlayDark = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  static const PageTransitionsTheme _transitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
    },
  );

  // ── THÈME CLAIR ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final scheme = const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: gold,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceVariant,
      outline: outline,
      error: errorColor,
    );
    return _base(
      scheme: scheme,
      brightness: Brightness.light,
      scaffold: background,
      onSurfaceVariant: textSecondary,
      navUnselected: textSecondary,
      overlay: _overlayLight,
      fieldFill: surface,
      fieldBorder: outline,
    );
  }

  // ── THÈME SOMBRE ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final scheme = const ColorScheme.dark(
      primary: gold, // l'or porte mieux le contraste sur fond sombre
      onPrimary: Color(0xFF1A1206),
      secondary: goldLight,
      onSecondary: Color(0xFF1A1206),
      surface: surfaceDark,
      onSurface: textPrimaryDark,
      surfaceContainerHighest: surfaceVariantDark,
      outline: outlineDark,
      error: Color(0xFFE57373),
    );
    return _base(
      scheme: scheme,
      brightness: Brightness.dark,
      scaffold: dark,
      onSurfaceVariant: textSecondaryDark,
      navUnselected: textSecondaryDark,
      overlay: _overlayDark,
      fieldFill: surfaceDark,
      fieldBorder: outlineDark,
    );
  }

  static ThemeData _base({
    required ColorScheme scheme,
    required Brightness brightness,
    required Color scaffold,
    required Color onSurfaceVariant,
    required Color navUnselected,
    required SystemUiOverlayStyle overlay,
    required Color fieldFill,
    required Color fieldBorder,
  }) {
    final isDark = brightness == Brightness.dark;
    final baseText = GoogleFonts.poppinsTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: baseText,
      pageTransitionsTheme: _transitions,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlay,
        titleTextStyle: GoogleFonts.poppins(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? surfaceDark : surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: (isDark ? gold : primary).withValues(alpha: 0.14),
        elevation: 0,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? (isDark ? gold : primary) : navUnselected,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? (isDark ? gold : primary) : navUnselected,
          );
        }),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(double.infinity, 54),
          side: BorderSide(color: fieldBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? gold : primary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceVariantDark : surfaceVariant,
        prefixIconColor: onSurfaceVariant,
        hintStyle: TextStyle(color: onSurfaceVariant),
        labelStyle: TextStyle(color: onSurfaceVariant),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: isDark ? gold : primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: errorColor, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? surfaceVariantDark : surfaceVariant,
        selectedColor: (isDark ? gold : primary).withValues(alpha: 0.16),
        side: BorderSide.none,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: DividerThemeData(
        color: fieldBorder,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? surfaceVariantDark : textPrimary,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? gold : primary,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }
}
