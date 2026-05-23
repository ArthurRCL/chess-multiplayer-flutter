import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'board_theme_preset.dart';

// ─── Estado ───────────────────────────────────────────────────────────────────

class ThemePreferences {
  final BoardTheme boardTheme;
  final PieceStyle pieceStyle;

  const ThemePreferences({
    this.boardTheme = BoardTheme.madeira,
    this.pieceStyle = PieceStyle.tradicional,
  });

  ThemePreferences copyWith({BoardTheme? boardTheme, PieceStyle? pieceStyle}) {
    return ThemePreferences(
      boardTheme: boardTheme ?? this.boardTheme,
      pieceStyle: pieceStyle ?? this.pieceStyle,
    );
  }
}

// ─── Keys de persistência ─────────────────────────────────────────────────────

const _kBoardTheme = 'chess_board_theme';
const _kPieceStyle = 'chess_piece_style';

// ─── Notifier ────────────────────────────────────────────────────────────────

class ThemePreferenceNotifier extends StateNotifier<ThemePreferences> {
  ThemePreferenceNotifier() : super(const ThemePreferences()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final boardKey = prefs.getString(_kBoardTheme);
    final pieceKey = prefs.getString(_kPieceStyle);

    final board = BoardTheme.values.firstWhere(
      (t) => t.storageKey == boardKey,
      orElse: () => BoardTheme.madeira,
    );
    final piece = PieceStyle.values.firstWhere(
      (s) => s.storageKey == pieceKey,
      orElse: () => PieceStyle.tradicional,
    );

    state = ThemePreferences(boardTheme: board, pieceStyle: piece);
  }

  Future<void> setBoardTheme(BoardTheme theme) async {
    state = state.copyWith(boardTheme: theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBoardTheme, theme.storageKey);
  }

  Future<void> setPieceStyle(PieceStyle style) async {
    state = state.copyWith(pieceStyle: style);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPieceStyle, style.storageKey);
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final themePreferenceProvider =
    StateNotifierProvider<ThemePreferenceNotifier, ThemePreferences>(
  (_) => ThemePreferenceNotifier(),
);
