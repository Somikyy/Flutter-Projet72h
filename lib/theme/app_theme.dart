import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Основная летняя тема
  static ThemeData get theme => ThemeData(
    primarySwatch: Colors.blue,
    textTheme: GoogleFonts.poppinsTextTheme(),
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
  
  // Новые летние цвета
  static const Color summerBlue = Color(0xFF0FB4D3);      // Яркий голубой (океан)
  static const Color summerYellow = Color(0xFFFFDD00);    // Солнечный жёлтый
  static const Color summerOrange = Color(0xFFFF8A00);    // Апельсиновый
  static const Color summerPink = Color(0xFFFF5E7A);      // Арбузный розовый
  static const Color summerGreen = Color(0xFF4CD964);     // Лаймовый зелёный
  static const Color summerPurple = Color(0xFF9B59F8);    // Ягодный фиолетовый
  
  // Летний градиент для фона
  static const List<Color> summerGradient = [
    Color(0xFF0064B7), // Глубокий синий (море)
    Color(0xFF0EADC9), // Бирюзовый (мелководье)
  ];
  
  // Фоновый градиент для карточек
  static const List<Color> summerCardGradient = [
    Color(0xFF336699),
    Color(0xFF3399CC),
  ];
  
  // Стили текста
  static TextStyle get titleStyle => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold, 
    color: Colors.white,
    shadows: [
      Shadow(
        color: summerBlue.withOpacity(0.6),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static TextStyle get subtitleStyle => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.white.withOpacity(0.9),
  );
  
  static TextStyle get bodyStyle => GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.white.withOpacity(0.8),
  );
  
  // Стили кнопок
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: summerBlue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    elevation: 4,
    shadowColor: summerBlue.withOpacity(0.5),
  );
  
  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Colors.white.withOpacity(0.15),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  );
  
  // Декорация для карточек
  static BoxDecoration get cardDecoration => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF3366CC), // Более тёмный оттенок синего
        Color(0xFF33CCFF), // Яркий голубой
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: summerBlue.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Декорация для контейнеров
  static BoxDecoration get containerDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withOpacity(0.1),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Летние иконки для рейтингов вместо звёзд
  static IconData get ratingIcon => Icons.beach_access;
}