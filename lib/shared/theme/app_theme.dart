import 'package:flutter/material.dart';

// Helpers de fonte local — sem dependência de rede
class _F {
  _F._();
  static TextStyle cinzel({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) =>
      TextStyle(
        fontFamily: 'Cinzel',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        shadows: shadows,
      );

  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
}

// ─── Paleta "Onyx & Gold" ────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Fundos
  static const bg0 = Color(0xFF0A0A0F);
  static const bg1 = Color(0xFF12121C);
  static const bg2 = Color(0xFF1A1A2E);
  static const bg3 = Color(0xFF22223A);

  // Superfícies / cards
  static const surface1 = Color(0xFF1E1E30);
  static const surface2 = Color(0xFF252540);
  static const surface3 = Color(0xFF2E2E50);

  // Primário — Ouro
  static const gold0 = Color(0xFFFFF3CC);
  static const gold1 = Color(0xFFF5D06E);
  static const gold2 = Color(0xFFE8B84B);   // ← primário principal
  static const gold3 = Color(0xFFCC9A2A);
  static const gold4 = Color(0xFF9B7219);

  // Accent — Roxo suave
  static const purple1 = Color(0xFFC084FC);
  static const purple2 = Color(0xFF9B6DE0);

  // Semânticas
  static const success = Color(0xFF22C55E);
  static const danger  = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info    = Color(0xFF60A5FA);

  // Texto
  static const textPrimary   = Color(0xFFF8F8F8);
  static const textSecondary = Color(0xFFB0B0CC);
  static const textMuted     = Color(0xFF6B6B8A);

  // Tabuleiro (mantém visual clássico)
  static const boardLight     = Color(0xFFF0D9B5);
  static const boardDark      = Color(0xFFB58863);
  static const boardHighlight = Color(0xAAF6F669);
  static const boardSelected  = Color(0xCC6FCF6F);

  // Glassmorphism
  static const glassWhite  = Color(0x14FFFFFF);
  static const glassBorder = Color(0x22FFFFFF);
  static const glassGold   = Color(0x1AE8B84B);
}

// ─── Gradientes reutilizáveis ─────────────────────────────────────────────────
class AppGradients {
  AppGradients._();

  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.bg0, AppColors.bg2],
  );

  static const gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gold1, AppColors.gold2, AppColors.gold3],
  );

  static const goldShimmer = LinearGradient(
    begin: Alignment(-1, -0.5),
    end: Alignment(1, 0.5),
    colors: [AppColors.gold3, AppColors.gold1, AppColors.gold0, AppColors.gold1, AppColors.gold3],
    stops: [0.0, 0.3, 0.5, 0.7, 1.0],
  );

  static const surface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surface1, AppColors.surface2],
  );

  static const cardGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A2010), Color(0xFF1E1A0C)],
  );
}

// ─── Contrato de tema de tabuleiro ───────────────────────────────────────────
abstract class ChessTheme {
  ThemeData get themeData;
  Color get lightSquare;
  Color get darkSquare;
  Color get highlightColor;
  Color get selectedColor;
  String get name;
}

class WoodChessTheme implements ChessTheme {
  const WoodChessTheme();

  @override String get name => 'Madeira Clássica';
  @override Color get lightSquare    => AppColors.boardLight;
  @override Color get darkSquare     => AppColors.boardDark;
  @override Color get highlightColor => AppColors.boardHighlight;
  @override Color get selectedColor  => AppColors.boardSelected;
  @override ThemeData get themeData  => AppTheme.darkTheme;
}

class GlassChessTheme implements ChessTheme {
  const GlassChessTheme();

  @override String get name => 'Vidro';
  @override Color get lightSquare    => const Color(0xFFD6EAF8);
  @override Color get darkSquare     => const Color(0xFF5DADE2);
  @override Color get highlightColor => const Color(0xAAFFD700);
  @override Color get selectedColor  => const Color(0xCC82E0AA);
  @override ThemeData get themeData  => AppTheme.darkTheme;
}

class NeonChessTheme implements ChessTheme {
  const NeonChessTheme();

  @override String get name => 'Neon';
  @override Color get lightSquare    => const Color(0xFF1A2A3A);
  @override Color get darkSquare     => const Color(0xFF002B3A);
  @override Color get highlightColor => const Color(0xAA00D4FF);
  @override Color get selectedColor  => const Color(0xCC00FF88);
  @override ThemeData get themeData  => AppTheme.darkTheme;
}

class ClassicGreenChessTheme implements ChessTheme {
  const ClassicGreenChessTheme();

  @override String get name => 'Clássico Verde';
  @override Color get lightSquare    => const Color(0xFFEEEED2);
  @override Color get darkSquare     => const Color(0xFF769656);
  @override Color get highlightColor => const Color(0xAAF6F669);
  @override Color get selectedColor  => const Color(0xCC6FCF6F);
  @override ThemeData get themeData  => AppTheme.darkTheme;
}

// ─── AppTheme principal ───────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static const ChessTheme defaultTheme = WoodChessTheme();

  // Mantém alias para não quebrar referências antigas
  static ThemeData get woodTheme => darkTheme;

  static ThemeData get darkTheme {
    // Mistura: Inter para body, Cinzel para display — fontes empacotadas localmente
    final mergedText = ThemeData.dark().textTheme.copyWith(
      displayLarge:  const TextStyle(fontFamily: 'Cinzel', color: AppColors.textPrimary),
      displayMedium: const TextStyle(fontFamily: 'Cinzel', color: AppColors.textPrimary),
      displaySmall:  const TextStyle(fontFamily: 'Cinzel', color: AppColors.textPrimary),
      headlineLarge: const TextStyle(fontFamily: 'Cinzel', color: AppColors.textPrimary),
      headlineMedium:const TextStyle(fontFamily: 'Cinzel', color: AppColors.textPrimary),
      headlineSmall: const TextStyle(fontFamily: 'Cinzel', color: AppColors.textPrimary, letterSpacing: 0.5),
      titleLarge:    const TextStyle(fontFamily: 'Inter',  color: AppColors.textPrimary,   fontWeight: FontWeight.w600),
      titleMedium:   const TextStyle(fontFamily: 'Inter',  color: AppColors.textPrimary,   fontWeight: FontWeight.w600),
      titleSmall:    const TextStyle(fontFamily: 'Inter',  color: AppColors.textSecondary),
      bodyLarge:     const TextStyle(fontFamily: 'Inter',  color: AppColors.textPrimary),
      bodyMedium:    const TextStyle(fontFamily: 'Inter',  color: AppColors.textSecondary),
      bodySmall:     const TextStyle(fontFamily: 'Inter',  color: AppColors.textMuted),
      labelLarge:    const TextStyle(fontFamily: 'Inter',  color: AppColors.textPrimary, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: mergedText,

      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary:          AppColors.gold2,
        onPrimary:        AppColors.bg0,
        primaryContainer: AppColors.gold4,
        secondary:        AppColors.gold1,
        onSecondary:      AppColors.bg0,
        tertiary:         AppColors.purple1,
        onTertiary:       AppColors.bg0,
        surface:          AppColors.surface1,
        onSurface:        AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surface2,
        error:            AppColors.danger,
        onError:          AppColors.textPrimary,
      ),

      scaffoldBackgroundColor: AppColors.bg0,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg1,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: _F.cinzel(
          color: AppColors.gold2,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.gold2),
      ),

      // ── ElevatedButton ──────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold2,
          foregroundColor: AppColors.bg0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: _F.inter(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ── OutlinedButton ──────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold2,
          side: const BorderSide(color: AppColors.gold2, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: _F.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // ── TextButton ──────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold2,
          textStyle: _F.inter(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),

      // ── Input fields ────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: _F.inter(color: AppColors.textMuted, fontSize: 14),
        hintStyle: _F.inter(color: AppColors.textMuted, fontSize: 14),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold2, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),

      // ── Card ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── BottomSheet ─────────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 0,
      ),

      // ── Dialog ──────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: _F.cinzel(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ── SnackBar ────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface3,
        contentTextStyle: _F.inter(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── ListTile ────────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.gold2,
        textColor: AppColors.textPrimary,
      ),

      // ── ProgressIndicator ───────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold2,
      ),

      // ── Divider ─────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 1,
        space: 0,
      ),
    );
  }
}
