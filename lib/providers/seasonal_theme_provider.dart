import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

// Провайдер для сезонной темы и эффектов
class SeasonalThemeProvider extends ChangeNotifier {
  // Текущий сезон
  final Season _currentSeason = Season.summer;
  
  // Режим праздника (для специальных событий)
  bool _holidayMode = false;
  
  // Случайный генератор для эффектов
  final math.Random _random = math.Random();
  
  // Геттеры
  Season get currentSeason => _currentSeason;
  bool get holidayMode => _holidayMode;
  
  // Градиент фона в зависимости от сезона
  List<Color> get seasonalGradient {
    switch (_currentSeason) {
      case Season.summer:
        return AppTheme.summerGradient;
      case Season.autumn:
        return const [Color(0xFFE65100), Color(0xFFBF360C)];
      case Season.winter:
        return const [Color(0xFF1A237E), Color(0xFF0D47A1)];
      case Season.spring:
        return const [Color(0xFF558B2F), Color(0xFF8BC34A)];
    }
  }
  
  // Цвет акцента в зависимости от сезона
  Color get seasonalAccentColor {
    switch (_currentSeason) {
      case Season.summer:
        return AppTheme.summerYellow;
      case Season.autumn:
        return const Color(0xFFFF9800);
      case Season.winter:
        return const Color(0xFF80DEEA);
      case Season.spring:
        return const Color(0xFFE91E63);
    }
  }
  
  // Иконка для рейтинга в зависимости от сезона
  IconData get seasonalRatingIcon {
    switch (_currentSeason) {
      case Season.summer:
        return Icons.beach_access;
      case Season.autumn:
        return Icons.eco;
      case Season.winter:
        return Icons.ac_unit;
      case Season.spring:
        return Icons.local_florist;
    }
  }
  
  // Название сезона
  String get seasonName {
    switch (_currentSeason) {
      case Season.summer:
        return "Été";
      case Season.autumn:
        return "Automne";
      case Season.winter:
        return "Hiver";
      case Season.spring:
        return "Printemps";
    }
  }
  
  // Приветственное сообщение в зависимости от сезона
  String get seasonalGreeting {
    switch (_currentSeason) {
      case Season.summer:
        return "Rafraîchissez-vous avec nos mocktails d'été!";
      case Season.autumn:
        return "Découvrez nos délicieuses saveurs d'automne!";
      case Season.winter:
        return "Réchauffez votre hiver avec nos mocktails!";
      case Season.spring:
        return "Célébrez le printemps avec des saveurs fraîches!";
    }
  }
  
  // Сезонное украшение для карточек коктейлей
  Widget buildSeasonalDecoration() {
    switch (_currentSeason) {
      case Season.summer:
        return _buildSummerDecoration();
      case Season.autumn:
        return _buildAutumnDecoration();
      case Season.winter:
        return _buildWinterDecoration();
      case Season.spring:
        return _buildSpringDecoration();
    }
  }
  
  // Летнее украшение (солнце и пальмы)
  Widget _buildSummerDecoration() {
    return Stack(
      children: [
        // Солнце в углу
        Positioned(
          top: -30,
          right: -30,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.summerYellow.withOpacity(0.7),
                  AppTheme.summerYellow.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        
        // Пальма (упрощенная)
        Positioned(
          bottom: 0,
          left: 10,
          child: SizedBox(
            width: 50,
            height: 80,
            child: CustomPaint(
              painter: PalmPainter(),
            ),
          ),
        ),
      ],
    );
  }
  
  // Осеннее украшение (опавшие листья)
  Widget _buildAutumnDecoration() {
    return Stack(
      children: List.generate(5, (index) {
        return Positioned(
          left: _random.nextDouble() * 300,
          top: _random.nextDouble() * 500,
          child: Transform.rotate(
            angle: _random.nextDouble() * math.pi,
            child: Icon(
              Icons.eco,
              color: Color(0xFFE65100).withOpacity(0.3),
              size: 20 + _random.nextDouble() * 20,
            ),
          ),
        );
      }),
    );
  }
  
  // Зимнее украшение (снежинки)
  Widget _buildWinterDecoration() {
    return Stack(
      children: List.generate(8, (index) {
        return Positioned(
          left: _random.nextDouble() * 300,
          top: _random.nextDouble() * 500,
          child: Icon(
            Icons.ac_unit,
            color: Colors.white.withOpacity(0.3),
            size: 15 + _random.nextDouble() * 15,
          ),
        );
      }),
    );
  }
  
  // Весеннее украшение (цветы)
  Widget _buildSpringDecoration() {
    return Stack(
      children: List.generate(6, (index) {
        return Positioned(
          left: _random.nextDouble() * 300,
          top: _random.nextDouble() * 500,
          child: Icon(
            Icons.local_florist,
            color: Color(0xFFE91E63).withOpacity(0.3),
            size: 15 + _random.nextDouble() * 15,
          ),
        );
      }),
    );
  }
  
  // Включить/выключить праздничный режим
  void toggleHolidayMode() {
    _holidayMode = !_holidayMode;
    notifyListeners();
  }
  
  // Сменить сезон
  void changeSeason(Season season) {
    // В реальном приложении здесь была бы логика смены сезона
    // Но для этого примера мы оставляем лето как фиксированный сезон
    notifyListeners();
  }
}

// Перечисление для сезонов
enum Season {
  summer,
  autumn,
  winter,
  spring,
}

// Пейнтер для отрисовки пальмы
class PalmPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Ствол пальмы
    final trunkPath = Path();
    trunkPath.moveTo(size.width * 0.4, size.height);
    trunkPath.quadraticBezierTo(
      size.width * 0.35, size.height * 0.7,
      size.width * 0.45, size.height * 0.4,
    );
    
    canvas.drawPath(trunkPath, paint);
    
    // Листья пальмы
    for (int i = 0; i < 5; i++) {
      final leafPath = Path();
      final startX = size.width * 0.45;
      final startY = size.height * 0.4;
      
      final angle = -math.pi / 6 + i * math.pi / 6;
      final endX = startX + size.width * 0.4 * math.cos(angle);
      final endY = startY + size.width * 0.4 * math.sin(angle);
      
      leafPath.moveTo(startX, startY);
      
      // Создаем изогнутый лист
      final cp1x = startX + (endX - startX) * 0.3;
      final cp1y = startY + (endY - startY) * 0.2 - 20;
      
      final cp2x = startX + (endX - startX) * 0.7;
      final cp2y = startY + (endY - startY) * 0.8 - 30;
      
      leafPath.cubicTo(cp1x, cp1y, cp2x, cp2y, endX, endY);
      
      canvas.drawPath(leafPath, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}