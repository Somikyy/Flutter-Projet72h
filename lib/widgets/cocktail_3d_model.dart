import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Cocktail3DModel extends StatefulWidget {
  final Map<String, int> ingredients;
  final String cocktailName;
  final Function(Map<String, int>) onIngredientsChanged;

  const Cocktail3DModel({
    Key? key,
    required this.ingredients,
    required this.cocktailName,
    required this.onIngredientsChanged,
  }) : super(key: key);

  @override
  State<Cocktail3DModel> createState() => _Cocktail3DModelState();
}

class _Cocktail3DModelState extends State<Cocktail3DModel>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _wavesController;
  late Animation<double> _rotationAnimation;
  
  // Карта цветов для ингредиентов
  final Map<String, Color> _ingredientColors = {
    'Jus de Cranberry': AppTheme.summerPink,
    'Sirop de Grenadine': Color(AppTheme.summerPink.value).withRed(220),
    'Jus de Citron': AppTheme.summerYellow,
    'Sprite': AppTheme.summerBlue.withOpacity(0.7),
  };
  
  int get _totalVolume =>
      widget.ingredients.values.fold(0, (sum, amount) => sum + amount);

  @override
  void initState() {
    super.initState();
    
    // Контроллер для вращения
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _rotationAnimation = CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    );
    
    // Контроллер для анимации волн
    _wavesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _wavesController.dispose();
    super.dispose();
  }

  // Получаем цвет для коктейля на основе ингредиентов
  Color _getCocktailColor() {
    if (widget.ingredients.isEmpty) {
      return Colors.transparent;
    }
    
    // Создаем смешанный цвет на основе пропорций ингредиентов
    Color resultColor = Colors.transparent;
    int totalAmount = _totalVolume;
    
    if (totalAmount == 0) return Colors.transparent;
    
    for (var entry in widget.ingredients.entries) {
      final ingredientName = entry.key;
      final amount = entry.value;
      
      final color = _ingredientColors[ingredientName] ?? 
                    Colors.purple; // Дефолтный цвет, если не найден
      
      // Смешиваем цвета на основе пропорций
      final ratio = amount / totalAmount;
      
      if (resultColor == Colors.transparent) {
        resultColor = color;
      } else {
        final r = (resultColor.red + (color.red - resultColor.red) * ratio).round();
        final g = (resultColor.green + (color.green - resultColor.green) * ratio).round();
        final b = (resultColor.blue + (color.blue - resultColor.blue) * ratio).round();
        final a = (resultColor.alpha + (color.alpha - resultColor.alpha) * ratio).round();
        
        resultColor = Color.fromARGB(a, r, g, b);
      }
    }
    
    return resultColor;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Text(
            widget.cocktailName,
            style: AppTheme.titleStyle.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // 3D модель коктейля
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Фон для 3D эффекта
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.summerBlue.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      radius: 0.7,
                    ),
                  ),
                ),
                
                // Вращающийся стакан с коктейлем
                RotationTransition(
                  turns: _rotationAnimation,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      // Ручное вращение при перетаскивании
                      _rotationController.value += details.delta.dx / 500;
                    },
                    child: Container(
                      width: 160,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Стакан (контур)
                          Container(
                            width: 140,
                            height: 220,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.7), width: 3),
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                            ),
                          ),
                          
                          // Жидкость в стакане с волнами
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 134,
                              height: 214,
                              child: AnimatedBuilder(
                                animation: _wavesController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: CocktailPainter(
                                      fillRatio: _totalVolume / 350, // Предполагаем макс объем 350мл
                                      color: _getCocktailColor(),
                                      waveOffset: _wavesController.value,
                                    ),
                                    size: Size(134, 214),
                                  );
                                },
                              ),
                            ),
                          ),
                          
                          // Соломинка
                          Positioned(
                            top: 10,
                            right: 50,
                            child: Container(
                              width: 8,
                              height: 200,
                              color: AppTheme.summerYellow,
                            ),
                          ),
                          
                          // Украшения (лед, фрукты)
                          _buildIceCubes(),
                          
                          // Блик на стакане
                          Positioned(
                            top: 20,
                            left: 20,
                            child: Container(
                              width: 15,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.7),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Пузырьки
                ..._buildBubbles(),
                
                // Подсказка
                Positioned(
                  bottom: 10,
                  child: Text(
                    'Faites glisser pour faire pivoter',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Ингредиенты с цветными маркерами (горизонтальный скроллинг)
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: widget.ingredients.entries.map((ingredient) {
                final color = _ingredientColors[ingredient.key] ?? AppTheme.summerPurple;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    backgroundColor: color.withOpacity(0.2),
                    side: BorderSide(color: color.withOpacity(0.5)),
                    avatar: CircleAvatar(
                      backgroundColor: color,
                      radius: 10,
                    ),
                    label: Text(
                      '${ingredient.key}: ${ingredient.value} ml',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  // Создание кубиков льда для украшения
  Widget _buildIceCubes() {
    final random = math.Random(42); // Фиксированный сид для одинаковых результатов
    
    return Stack(
      children: List.generate(5, (index) {
        return Positioned(
          top: 30 + random.nextDouble() * 100,
          left: 20 + random.nextDouble() * 100,
          child: Opacity(
            opacity: 0.7,
            child: Transform.rotate(
              angle: random.nextDouble() * math.pi,
              child: Container(
                width: 15 + random.nextDouble() * 15,
                height: 15 + random.nextDouble() * 15,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
  
  // Создание анимированных пузырьков
  List<Widget> _buildBubbles() {
    final random = math.Random();
    
    return List.generate(15, (index) {
      final size = 5.0 + random.nextDouble() * 8;
      final speedFactor = 1 + random.nextDouble() * 3;
      
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 0.0),
        duration: Duration(seconds: (3 * speedFactor).round()),
        onEnd: () => setState(() {}), // Перестраиваем виджет для новой анимации
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Positioned(
            bottom: 300 * (1 - value), // Двигаем снизу вверх
            left: 100 + math.sin(value * 10) * 50 * random.nextDouble(),
            child: Opacity(
              opacity: 0.7 * (1 - value), // Исчезают при подъеме
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

// Кастомный пейнтер для отрисовки жидкости с волнами
class CocktailPainter extends CustomPainter {
  final double fillRatio;
  final Color color;
  final double waveOffset;
  
  CocktailPainter({
    required this.fillRatio,
    required this.color,
    required this.waveOffset,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;
    final fillHeight = height * fillRatio;
    
    if (fillHeight <= 0) return;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    // Начальная точка в левом нижнем углу
    path.moveTo(0, height);
    
    // Нижний правый угол
    path.lineTo(width, height);
    
    // Правая сторона до уровня жидкости
    path.lineTo(width, height - fillHeight);
    
    // Верхняя граница с волнами
    final waveHeight = 6.0; // Высота волны
    final waveLength = 30.0; // Длина волны
    
    for (double x = width; x >= 0; x -= 1) {
      final waveY = math.sin((x / waveLength) + waveOffset * 2 * math.pi) * waveHeight;
      path.lineTo(x, height - fillHeight + waveY);
    }
    
    // Замыкаем путь
    path.close();
    
    // Рисуем основную жидкость
    canvas.drawPath(path, paint);
    
    // Добавляем блики для реалистичности
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final highlightPath = Path();
    highlightPath.moveTo(width * 0.6, height - fillHeight * 0.3);
    highlightPath.arcTo(
      Rect.fromCenter(
        center: Offset(width * 0.6, height - fillHeight * 0.3), 
        width: 40, 
        height: 20
      ),
      0,
      2 * math.pi,
      false,
    );
    
    canvas.drawPath(highlightPath, highlightPaint);
  }
  
  @override
  bool shouldRepaint(CocktailPainter oldDelegate) =>
      oldDelegate.fillRatio != fillRatio ||
      oldDelegate.color != color ||
      oldDelegate.waveOffset != waveOffset;
}