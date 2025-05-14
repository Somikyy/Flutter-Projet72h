import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class IngredientsMixer extends StatefulWidget {
  final Map<String, int> ingredients;
  final int totalVolume;
  final Function(Map<String, int>) onIngredientsChanged;

  const IngredientsMixer({
    Key? key,
    required this.ingredients,
    required this.totalVolume,
    required this.onIngredientsChanged,
  }) : super(key: key);

  @override
  State<IngredientsMixer> createState() => _IngredientsMixerState();
}

class _IngredientsMixerState extends State<IngredientsMixer>
    with TickerProviderStateMixin {
  // Карта для хранения локальных копий значений ингредиентов
  late Map<String, int> _adjustedIngredients;
  
  // Анимационные контроллеры
  late AnimationController _liquidController;
  late AnimationController _addIngredientController;
  
  // Контроллеры для анимации изменения каждого ингредиента
  Map<String, AnimationController> _ingredientControllers = {};
  
  // Для отображения анимации добавления ингредиента
  String? _lastChangedIngredient;
  bool _isAddingIngredient = false;
  
  // Цвета для ингредиентов
  final Map<String, Color> _ingredientColors = {
    'Jus de Cranberry': AppTheme.summerPink,
    'Sirop de Grenadine': Color(AppTheme.summerPink.value).withRed(220),
    'Jus de Citron': AppTheme.summerYellow,
    'Sprite': AppTheme.summerBlue.withOpacity(0.7),
  };
  
  // Иконки для ингредиентов
  final Map<String, IconData> _ingredientIcons = {
    'Jus de Cranberry': Icons.local_drink,
    'Sirop de Grenadine': Icons.local_bar,
    'Jus de Citron': Icons.opacity, // Заменено Icons.lemon на Icons.opacity
    'Sprite': Icons.bubble_chart,
  };
  
  // Геттеры для вычисления общего объема и оставшегося объема
  int get _totalCurrentVolume => _adjustedIngredients.values.fold(0, (sum, amount) => sum + amount);
  int get _remainingVolume => widget.totalVolume - _totalCurrentVolume;
  
  @override
  void initState() {
    super.initState();
    
    // Инициализируем локальную копию ингредиентов
    _adjustedIngredients = Map.from(widget.ingredients);
    
    // Создаем анимационные контроллеры
    _liquidController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    
    _addIngredientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Создаем контроллеры для каждого ингредиента
    for (final ingredient in _adjustedIngredients.keys) {
      _ingredientControllers[ingredient] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
    }
  }
  
  @override
  void didUpdateWidget(IngredientsMixer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Обновляем локальную копию при изменении входных данных
    if (oldWidget.ingredients != widget.ingredients) {
      setState(() {
        _adjustedIngredients = Map.from(widget.ingredients);
      });
      
      // Добавляем недостающие контроллеры
      for (final ingredient in _adjustedIngredients.keys) {
        if (!_ingredientControllers.containsKey(ingredient)) {
          _ingredientControllers[ingredient] = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 500),
          );
        }
      }
    }
  }
  
  @override
  void dispose() {
    _liquidController.dispose();
    _addIngredientController.dispose();
    
    // Освобождаем все контроллеры ингредиентов
    for (final controller in _ingredientControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  // Метод для изменения значения ингредиента
  void _updateIngredientValue(String ingredient, int newValue) {
    // Проверка, чтобы не превысить общий объем
    int currentTotal = _totalCurrentVolume;
    int oldValue = _adjustedIngredients[ingredient] ?? 0;
    int increase = newValue - oldValue;
    
    if (currentTotal + increase > widget.totalVolume) {
      // Если новое значение превышает общий объем,
      // ограничиваем его оставшимся объемом
      newValue = oldValue + _remainingVolume;
    }
    
    // Анимируем изменение
    setState(() {
      _lastChangedIngredient = ingredient;
      _isAddingIngredient = newValue > oldValue;
      _adjustedIngredients[ingredient] = newValue;
    });
    
    // Запускаем анимацию
    _addIngredientController.forward(from: 0.0);
    _ingredientControllers[ingredient]?.forward(from: 0.0);
    
    // Уведомляем родительский виджет об изменениях
    widget.onIngredientsChanged(_adjustedIngredients);
  }
  
  // Метод для равномерного распределения объема
  void _distributeEvenly() {
    if (_adjustedIngredients.isEmpty) return;
    
    final count = _adjustedIngredients.length;
    final perIngredient = widget.totalVolume ~/ count;
    
    final newValues = <String, int>{};
    var remaining = widget.totalVolume;
    
    // Распределяем объем равномерно
    for (final key in _adjustedIngredients.keys) {
      if (remaining >= perIngredient) {
        newValues[key] = perIngredient;
        remaining -= perIngredient;
      } else if (remaining > 0) {
        newValues[key] = remaining;
        remaining = 0;
      } else {
        newValues[key] = 0;
      }
    }
    
    // Если остался нераспределенный объем, добавляем к первому ингредиенту
    if (remaining > 0 && _adjustedIngredients.isNotEmpty) {
      final firstKey = _adjustedIngredients.keys.first;
      newValues[firstKey] = (newValues[firstKey] ?? 0) + remaining;
    }
    
    // Применяем изменения с анимацией
    setState(() {
      _adjustedIngredients = newValues;
    });
    
    // Запускаем анимацию для всех ингредиентов
    for (final controller in _ingredientControllers.values) {
      controller.forward(from: 0.0);
    }
    
    widget.onIngredientsChanged(_adjustedIngredients);
  }
  
  // Метод для сброса к оригинальным значениям
  void _resetToOriginal() {
    setState(() {
      _adjustedIngredients = Map.from(widget.ingredients);
    });
    
    // Запускаем анимацию для всех ингредиентов
    for (final controller in _ingredientControllers.values) {
      controller.forward(from: 0.0);
    }
    
    widget.onIngredientsChanged(_adjustedIngredients);
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Заголовок с информацией об объеме
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mise en place des ingrédients',
                  style: AppTheme.subtitleStyle,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _remainingVolume == 0 
                        ? AppTheme.summerGreen.withOpacity(0.3) 
                        : AppTheme.summerOrange.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _remainingVolume == 0 
                          ? AppTheme.summerGreen 
                          : AppTheme.summerOrange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$_totalCurrentVolume / ${widget.totalVolume} ml',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Кнопки управления
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildAnimatedButton(
                    onPressed: _distributeEvenly,
                    icon: Icons.balance,
                    label: 'Équilibrer',
                    backgroundColor: AppTheme.summerBlue.withOpacity(0.2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildAnimatedButton(
                    onPressed: _resetToOriginal,
                    icon: Icons.restart_alt,
                    label: 'Réinitialiser',
                    backgroundColor: AppTheme.summerOrange.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Визуализация смеси ингредиентов
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.black26,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: _buildLiquidStackLayers(),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Контроллеры ингредиентов
          ..._buildIngredientSliders(),
          
          // Дополнительное пространство внизу для прокрутки
          const SizedBox(height: 60),
        ],
      ),
    );
  }
  
  // Построение слоев жидкости для визуализации
  List<Widget> _buildLiquidStackLayers() {
    final result = <Widget>[];
    
    if (_adjustedIngredients.isEmpty || _totalCurrentVolume == 0) {
      // Если нет ингредиентов, показываем пустой контейнер
      return [
        Center(
          child: Text(
            'Добавьте ингредиенты',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ];
    }
    
    // Начальная позиция слева
    double currentPosition = 0;
    final totalWidth = MediaQuery.of(context).size.width - 32; // ширина с учетом отступов
    
    // Создаем слой для каждого ингредиента
    for (final entry in _adjustedIngredients.entries) {
      final ingredient = entry.key;
      final amount = entry.value;
      
      if (amount <= 0) continue;
      
      // Вычисляем ширину слоя на основе пропорции
      final ratio = amount / _totalCurrentVolume;
      final width = totalWidth * ratio;
      
      // Получаем цвет для ингредиента
      final color = _ingredientColors[ingredient] ?? AppTheme.summerPurple;
      
      // Анимируем изменение слоя
      final controller = _ingredientControllers[ingredient];
      
      // Добавляем слой жидкости
      result.add(
        Positioned(
          left: currentPosition,
          width: width,
          height: 60,
          child: AnimatedBuilder(
            animation: _liquidController,
            builder: (context, child) {
              return CustomPaint(
                painter: LiquidLayerPainter(
                  color: color,
                  waveOffset: _liquidController.value,
                ),
                child: Center(
                  child: Text(
                    '$amount ml',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      
      // Обновляем текущую позицию
      currentPosition += width;
    }
    
    return result;
  }
  
  // Построение слайдеров для каждого ингредиента
  List<Widget> _buildIngredientSliders() {
    final items = <Widget>[];
    
    for (final entry in _adjustedIngredients.entries.toList()) {
      final ingredient = entry.key;
      final amount = entry.value;
      final color = _ingredientColors[ingredient] ?? AppTheme.summerPurple;
      final icon = _ingredientIcons[ingredient] ?? Icons.water_drop;
      
      // Получаем контроллер анимации для этого ингредиента
      final controller = _ingredientControllers[ingredient];
      
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: AnimatedBuilder(
            animation: controller!,
            builder: (context, child) {
              // Вычисляем размер на основе анимации
              final scale = 1.0 + 0.1 * controller.value - 0.1 * math.pow(controller.value, 2);
              
              return Transform.scale(
                scale: scale,
                child: Card(
                  color: Colors.white.withOpacity(0.1),
                  elevation: 4 * controller.value,
                  shadowColor: color.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: color.withOpacity(0.3 + 0.7 * controller.value),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    icon,
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  ingredient,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$amount ml',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Кнопка уменьшения
                            _buildCircleButton(
                              icon: Icons.remove,
                              color: color,
                              onPressed: amount > 0
                                  ? () => _updateIngredientValue(ingredient, amount - 5)
                                  : null,
                            ),
                            
                            // Слайдер
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: color,
                                  inactiveTrackColor: color.withOpacity(0.3),
                                  thumbColor: Colors.white,
                                  overlayColor: color.withOpacity(0.2),
                                  valueIndicatorColor: color,
                                  valueIndicatorTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: Slider(
                                  value: amount.toDouble(),
                                  min: 0,
                                  max: widget.totalVolume.toDouble(),
                                  divisions: widget.totalVolume ~/ 5,
                                  label: '$amount ml',
                                  onChanged: (value) {
                                    _updateIngredientValue(ingredient, value.round());
                                  },
                                ),
                              ),
                            ),
                            
                            // Кнопка увеличения
                            _buildCircleButton(
                              icon: Icons.add,
                              color: color,
                              onPressed: _remainingVolume > 0
                                  ? () => _updateIngredientValue(ingredient, amount + 5)
                                  : null,
                            ),
                          ],
                        ),
                        
                        // Индикатор процента от общего объема
                        Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _totalCurrentVolume > 0
                                ? amount / _totalCurrentVolume
                                : 0,
                            child: Container(
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    return items;
  }
  
  // Кнопка с анимацией нажатия
  Widget _buildAnimatedButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
  
  // Круглая кнопка с иконкой
  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: onPressed != null
                ? color.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: onPressed != null
                ? Colors.white
                : Colors.white.withOpacity(0.3),
            size: 20,
          ),
        ),
      ),
    );
  }
}

// Пейнтер для отрисовки слоя жидкости с волнами
class LiquidLayerPainter extends CustomPainter {
  final Color color;
  final double waveOffset;
  
  LiquidLayerPainter({
    required this.color,
    required this.waveOffset,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    // Начальная точка
    path.moveTo(0, 0);
    
    // Волнистый верхний край
    final waveHeight = height * 0.1; // Высота волны
    final frequency = width / 20;     // Частота волн
    
    for (double x = 0; x <= width; x += 1) {
      final waveY = math.sin((x / frequency) + (waveOffset * 2 * math.pi)) * waveHeight;
      path.lineTo(x, waveY);
    }
    
    // Правый край
    path.lineTo(width, 0);
    path.lineTo(width, height);
    
    // Волнистый нижний край
    for (double x = width; x >= 0; x -= 1) {
      final waveY = height - math.sin((x / frequency) + (waveOffset * 2 * math.pi) + math.pi) * waveHeight;
      path.lineTo(x, waveY);
    }
    
    // Левый край и закрытие
    path.lineTo(0, height);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Добавляем блики для эффекта объема
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final highlightPath = Path();
    highlightPath.moveTo(width * 0.25, height * 0.3);
    highlightPath.arcTo(
      Rect.fromCenter(
        center: Offset(width * 0.25, height * 0.3),
        width: width * 0.15,
        height: height * 0.1,
      ),
      0,
      2 * math.pi,
      false,
    );
    
    canvas.drawPath(highlightPath, highlightPaint);
  }
  
  @override
  bool shouldRepaint(LiquidLayerPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.waveOffset != waveOffset;
}