import 'package:flutter/material.dart';

/// All app colours in one place so the look stays consistent.
/// Arena uses a bold "debate" palette — a fiery red for heat/energy and a
/// deep navy for the opposing side, so a room always feels like a face-off.
class AppColors {
  static const primary = Color(0xFFE63946); // arena red
  static const primaryLight = Color(0xFFFF6B6B); // light red
  static const secondary = Color(0xFF1D3557); // deep navy (the "other side")
  static const accent = Color(0xFFF4A261); // warm orange highlight
  static const background = Color(0xFFFFF5F3); // warm off-white
  static const card = Colors.white;
  static const textDark = Color(0xFF1F2933);
  static const textGrey = Color(0xFF8A9099);
  static const border = Color(0xFFECE3E1);

  // Debate stances.
  static const forSide = Color(0xFF2A9D8F); // teal-green = "For"
  static const againstSide = Color(0xFFE63946); // red = "Against"
}

/// Builds the app-wide Material theme from [AppColors].
ThemeData buildArenaTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.card,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
  );
}

/// The debate topic categories the user can tag a room with. Used for the
/// coloured chips and (later) for filtering and the daily random topic.
const List<String> kCategories = [
  'Science',
  'Religion',
  'Movies',
  'Politics',
  'Sports',
  'Technology',
  'History',
  'Other',
];

/// A small emoji per category for the room cards.
String categoryEmoji(String category) {
  switch (category) {
    case 'Science':
      return '🔬';
    case 'Religion':
      return '🕊️';
    case 'Movies':
      return '🎬';
    case 'Politics':
      return '🏛️';
    case 'Sports':
      return '⚽';
    case 'Technology':
      return '💻';
    case 'History':
      return '📜';
    default:
      return '💬';
  }
}
