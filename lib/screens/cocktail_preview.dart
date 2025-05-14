import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/cocktail_3d_model.dart';
import '../widgets/ingredients_mixer.dart';

/// Демонстрационный экран для 3D просмотра коктейля с возможностью редактирования ингредиентов
class CocktailPreviewScreen extends StatefulWidget {
  final String cocktailName;
  final String cocktailDescription;
  final Map<String, int> initialIngredients;
  final List<String> tags;

  const CocktailPreviewScreen({
    Key? key,
    required this.cocktailName,
    required this.cocktailDescription,
    required this.initialIngredients,
    required this.tags,
  }) : super(key: key);

  @override
  State<CocktailPreviewScreen> createState() => _CocktailPreviewScreenState();
}

class _CocktailPreviewScreenState extends State<CocktailPreviewScreen>
    with SingleTickerProviderStateMixin {
  late Map<String, int> _currentIngredients;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  bool _showIngredientMixer = false;
  
  // Для демонстрации возможности заказа
  bool _isOrderingInProgress = false;
  
  @override
  void initState() {
    super.initState();
    _currentIngredients = Map.from(widget.initialIngredients);
    
    // Настраиваем анимацию для плавных переходов
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutBack,
    );
    
    // Запускаем начальную анимацию
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Переключение между режимами просмотра и редактирования
  void _toggleIngredientMixer() {
    setState(() {
      _showIngredientMixer = !_showIngredientMixer;
    });
    
    if (_showIngredientMixer) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }
  
  // Имитация процесса заказа
  void _simulateOrdering() {
    setState(() {
      _isOrderingInProgress = true;
    });
    
    // Через 2 секунды показываем успешное сообщение
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isOrderingInProgress = false;
        });
        
        _showSuccessDialog();
      }
    });
  }
  
  // Диалог успешного заказа
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppTheme.summerGreen,
            ),
            const SizedBox(width: 8),
            const Text(
              'Succès!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Votre commande de mocktail a été envoyée avec succès!',
            ),
            const SizedBox(height: 10),
            Text(
              'ID de commande: MCK-${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 10)}',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Le mocktail est en cours de préparation...',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Рассчитываем общий объем прямо здесь для уверенного доступа во всех виджетах
    final totalVolume = _currentIngredients.values.fold(0, (sum, amount) => sum + amount);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.summerGradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Фоновые элементы летней темы
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 120,
                  height: 120,
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
              
              // Основной контент
              Column(
                children: [
                  // Верхняя панель
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Кнопка назад
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Заголовок
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.cocktailName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.cocktailDescription,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Кнопка переключения режима
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _showIngredientMixer ? Icons.visibility : Icons.edit,
                              color: Colors.white,
                            ),
                            onPressed: _toggleIngredientMixer,
                            tooltip: _showIngredientMixer
                                ? 'Voir en 3D'
                                : 'Modifier les ingrédients',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Теги коктейля
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.tags.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.summerBlue.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.tags[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Основное содержимое с анимацией переключения
                  Expanded(
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 500),
                      firstChild: _build3DView(totalVolume),
                      secondChild: _buildIngredientMixerView(),
                      crossFadeState: _showIngredientMixer
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                    ),
                  ),
                  
                  // Нижняя панель с кнопкой заказа
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Информация о объеме
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Volume total:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '$totalVolume ml',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Кнопка заказа
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isOrderingInProgress ? null : _simulateOrdering,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.summerBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 4,
                              shadowColor: AppTheme.summerBlue.withOpacity(0.5),
                            ),
                            child: _isOrderingInProgress
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Commander ce mocktail',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Вид с 3D моделью коктейля (передаем totalVolume как параметр)
  Widget _build3DView(int totalVolume) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Cocktail3DModel(
            ingredients: _currentIngredients,
            cocktailName: widget.cocktailName,
            onIngredientsChanged: (ingredients) {
              setState(() {
                _currentIngredients = ingredients;
              });
            },
          ),
          
          // Информация об ингредиентах в виде карточек
          Container(
            height: 100,
            margin: const EdgeInsets.all(16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _currentIngredients.length,
              itemBuilder: (context, index) {
                final ingredient = _currentIngredients.entries.elementAt(index);
                final colors = [
                  AppTheme.summerBlue,
                  AppTheme.summerPink,
                  AppTheme.summerYellow,
                  AppTheme.summerGreen,
                  AppTheme.summerPurple,
                ];
                final color = colors[index % colors.length];
                
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.7),
                        color.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Иконка и название
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIngredientIcon(ingredient.key),
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getShortIngredientName(ingredient.key),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Количество
                      Text(
                        '${ingredient.value} ml',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // Процент от общего объема (используем переданный параметр totalVolume)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: totalVolume > 0 ? (ingredient.value / totalVolume).toDouble() : 0.0,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          color: Colors.white,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // Вид с настройкой ингредиентов
  Widget _buildIngredientMixerView() {
    return IngredientsMixer(
      ingredients: _currentIngredients,
      totalVolume: 350, // Максимальный объем для настройки
      onIngredientsChanged: (ingredients) {
        setState(() {
          _currentIngredients = ingredients;
        });
      },
    );
  }
  
  // Получение иконки для ингредиента
  IconData _getIngredientIcon(String ingredient) {
    if (ingredient.contains('Cranberry')) return Icons.local_drink;
    if (ingredient.contains('Grenadine')) return Icons.local_bar;
    if (ingredient.contains('Citron')) return Icons.opacity; // Заменено Icons.lemon на Icons.opacity
    if (ingredient.contains('Sprite')) return Icons.bubble_chart;
    return Icons.water_drop;
  }
  
  // Получение короткого имени ингредиента
  String _getShortIngredientName(String ingredient) {
    if (ingredient.contains('Cranberry')) return 'Cranberry';
    if (ingredient.contains('Grenadine')) return 'Grenadine';
    if (ingredient.contains('Citron')) return 'Citron';
    if (ingredient.contains('Sprite')) return 'Sprite';
    return ingredient;
  }
}