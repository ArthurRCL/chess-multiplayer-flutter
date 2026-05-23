import 'package:flutter/material.dart';
import 'app_theme.dart';

// ─── Tema de Tabuleiro ────────────────────────────────────────────────────────

enum BoardTheme {
  madeira,
  vidro,
  neon,
  classicoVerde;

  String get label {
    switch (this) {
      case BoardTheme.madeira:       return 'Madeira';
      case BoardTheme.vidro:         return 'Vidro';
      case BoardTheme.neon:          return 'Neon';
      case BoardTheme.classicoVerde: return 'Clássico';
    }
  }

  String get description {
    switch (this) {
      case BoardTheme.madeira:       return 'Estilo clássico de madeira';
      case BoardTheme.vidro:         return 'Azul translúcido moderno';
      case BoardTheme.neon:          return 'Brilhante e futurista';
      case BoardTheme.classicoVerde: return 'Verde tradicional Lichess';
    }
  }

  IconData get icon {
    switch (this) {
      case BoardTheme.madeira:       return Icons.texture;
      case BoardTheme.vidro:         return Icons.water;
      case BoardTheme.neon:          return Icons.bolt;
      case BoardTheme.classicoVerde: return Icons.grass;
    }
  }

  /// Cor clara de preview
  Color get previewLight {
    switch (this) {
      case BoardTheme.madeira:       return const Color(0xFFF0D9B5);
      case BoardTheme.vidro:         return const Color(0xFFD6EAF8);
      case BoardTheme.neon:          return const Color(0xFF1A2A3A);
      case BoardTheme.classicoVerde: return const Color(0xFFEEEED2);
    }
  }

  /// Cor escura de preview
  Color get previewDark {
    switch (this) {
      case BoardTheme.madeira:       return const Color(0xFFB58863);
      case BoardTheme.vidro:         return const Color(0xFF5DADE2);
      case BoardTheme.neon:          return const Color(0xFF00D4FF);
      case BoardTheme.classicoVerde: return const Color(0xFF769656);
    }
  }

  ChessTheme toChessTheme() {
    switch (this) {
      case BoardTheme.madeira:       return const WoodChessTheme();
      case BoardTheme.vidro:         return const GlassChessTheme();
      case BoardTheme.neon:          return const NeonChessTheme();
      case BoardTheme.classicoVerde: return const ClassicGreenChessTheme();
    }
  }

  String get storageKey => name;
}

// ─── Estilo de Peças ──────────────────────────────────────────────────────────

enum PieceStyle {
  tradicional,
  minimalista,
  tridimensional;

  String get label {
    switch (this) {
      case PieceStyle.tradicional:    return 'Tradicional';
      case PieceStyle.minimalista:    return 'Minimalista';
      case PieceStyle.tridimensional: return '3D';
    }
  }

  String get description {
    switch (this) {
      case PieceStyle.tradicional:    return 'Peças Cburnett clássicas';
      case PieceStyle.minimalista:    return 'Design limpo e moderno';
      case PieceStyle.tridimensional: return 'Com profundidade e sombra';
    }
  }

  /// Pasta base dos assets SVG
  String get assetFolder {
    switch (this) {
      case PieceStyle.tradicional:    return 'assets/pieces';
      case PieceStyle.minimalista:    return 'assets/pieces_min';
      case PieceStyle.tridimensional: return 'assets/pieces_3d';
    }
  }

  /// Todos os estilos estão disponíveis
  bool get disponivel => true;

  String get storageKey => name;
}
