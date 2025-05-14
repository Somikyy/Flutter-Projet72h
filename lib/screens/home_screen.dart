import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'cocktail_selection_screen.dart';
import 'cocktail_preview.dart';
import '../providers/seasonal_theme_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _bubblesController;
  final List<Bubble> _bubbles = [];
  final int _numberOfBubbles = 20;

  @override
  void initState() {
    super.initState();
    
    // Создаем контроллер анимации только для пузырьков
    _bubblesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..repeat();
    
    // Генерируем начальные пузырьки
    final random = math.Random();
    for (int i = 0; i < _numberOfBubbles; i++) {
      _bubbles.add(
        Bubble(
          x: random.nextDouble() * 400,
          y: random.nextDouble() * 800,
          size: 10 + random.nextDouble() * 40,
          speed: 0.5 + random.nextDouble() * 1.5,
        ),
      );
    }
  }

  @override
  void dispose() {
    _bubblesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    // Получаем провайдер темы
    final themeProvider = Provider.of<SeasonalThemeProvider>(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Фон с градиентом
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeProvider.seasonalGradient,
              ),
            ),
          ),
          
          // Сезонные украшения
          themeProvider.buildSeasonalDecoration(),
          
          // Анимированные пузырьки в отдельном виджете
          AnimatedBubbles(
            bubbles: _bubbles,
            controller: _bubblesController,
            screenSize: screenSize,
          ),
          
          // Статичный контент главного экрана
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Лого или Заголовок
                  FadeInDown(
                    duration: const Duration(milliseconds: 800),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.seasonalAccentColor.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_bar,
                            size: 60,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Mocktail\nMachine',
                            textAlign: TextAlign.center,
                            style: AppTheme.titleStyle,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            themeProvider.seasonalGreeting,
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Основная кнопка
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.seasonalAccentColor.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CocktailSelectionScreen(),
                            ),
                          );
                        },
                        style: AppTheme.primaryButtonStyle,
                        child: const Text(
                          'Choisir un Mocktail',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Добавляем демо-кнопку
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.seasonalAccentColor.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CocktailPreviewScreen(
                                cocktailName: "Sunrise Rouge",
                                cocktailDescription: "Un mocktail rafraîchissant aux fruits rouges avec des bulles",
                                initialIngredients: {
                                  'Jus de Cranberry': 70, 
                                  'Sirop de Grenadine': 20, 
                                  'Sprite': 60,
                                  'Jus de Citron': 30,
                                },
                                tags: ['Fruité', 'Pétillant', 'Rouge'],
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.withOpacity(0.2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Voir Démo 3D',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Отдельный StatefulWidget для анимации пузырьков
class AnimatedBubbles extends StatefulWidget {
  final List<Bubble> bubbles;
  final AnimationController controller;
  final Size screenSize;
  
  const AnimatedBubbles({
    Key? key,
    required this.bubbles,
    required this.controller,
    required this.screenSize,
  }) : super(key: key);
  
  @override
  State<AnimatedBubbles> createState() => _AnimatedBubblesState();
}

class _AnimatedBubblesState extends State<AnimatedBubbles> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateBubbles);
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_updateBubbles);
    super.dispose();
  }
  
  void _updateBubbles() {
    if (mounted) {
      setState(() {
        for (final bubble in widget.bubbles) {
          bubble.update();
          
          // Если пузырек вышел за верхнюю границу, перемещаем его вниз
          if (bubble.y < -bubble.size) {
            bubble.y = widget.screenSize.height + bubble.size;
            bubble.x = math.Random().nextDouble() * widget.screenSize.width;
          }
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BubblesPainter(bubbles: widget.bubbles),
      size: Size.infinite,
    );
  }
}

// Класс для хранения данных о пузырьке
class Bubble {
  double x;
  double y;
  final double size;
  final double speed;
  
  Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
  
  // Метод для обновления позиции пузырька (движение вверх)
  void update() {
    // Двигаем пузырек вверх на основе его скорости
    y -= speed;
  }
}

// Painter для рисования пузырьков
class BubblesPainter extends CustomPainter {
  final List<Bubble> bubbles;
  
  BubblesPainter({required this.bubbles});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    // Рисуем каждый пузырек
    for (final bubble in bubbles) {
      canvas.drawCircle(
        Offset(bubble.x, bubble.y),
        bubble.size,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}