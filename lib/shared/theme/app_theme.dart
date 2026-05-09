import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Contrato que todos os temas devem implementar.
/// Para adicionar um novo tema, basta criar uma classe que retorne ThemeData.
abstract class ChessTheme {
  ThemeData get themeData;
  Color get lightSquare;
  Color get darkSquare;
  Color get highlightColor;
  Color get selectedColor;
  String get name;
}

/// Tema clássico madeira — padrão do aplicativo.
class WoodChessTheme implements ChessTheme {
  const WoodChessTheme();

  @override
  String get name => 'Madeira Clássica';

  @override
  Color get lightSquare => const Color(0xFFF0D9B5);

  @override
  Color get darkSquare => const Color(0xFFB58863);

  @override
  Color get highlightColor => const Color(0xAAF6F669);

  @override
  Color get selectedColor => const Color(0xCC7FC97F);

  @override
  ThemeData get themeData => AppTheme.woodTheme;
}

class AppTheme {
  static const ChessTheme defaultTheme = WoodChessTheme();

  static ThemeData get woodTheme {
    final merriweather = GoogleFonts.merriweatherTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      textTheme: merriweather,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7B4F2E),
        brightness: Brightness.dark,
        primary: const Color(0xFFB58863),
        secondary: const Color(0xFFF0D9B5),
        surface: const Color(0xFF2C1A0E),
        onSurface: const Color(0xFFF0D9B5),
      ),
      scaffoldBackgroundColor: const Color(0xFF2C1A0E),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1A0F07),
        foregroundColor: const Color(0xFFF0D9B5),
        elevation: 4,
        titleTextStyle: GoogleFonts.merriweather(
          color: const Color(0xFFF0D9B5),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB58863),
          foregroundColor: const Color(0xFF1A0F07),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.merriweather(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF3D2410),
        labelStyle: const TextStyle(color: Color(0xFFF0D9B5)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFB58863), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF0D9B5), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF3D2410),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
