import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:projet72h/screens/ingridients_level_widget.dart';
import '../models/cocktail_manager.dart';
import '../models/ingridient_level.dart';
import '../models/mocktail.dart';
import '../services/api_service.dart';
import 'glass_selection_screen.dart';
import 'reviews_screen.dart';
import 'admin_login_screen.dart'; // Новый импорт

class CocktailSelectionScreen extends StatefulWidget {
  const CocktailSelectionScreen({super.key});

  @override
  State<CocktailSelectionScreen> createState() => _CocktailSelectionScreenState();
}

class _CocktailSelectionScreenState extends State<CocktailSelectionScreen> {
  bool _isCheckingIngredients = false;
  List<IngredientLevel> _lowIngredients = [];
  
  @override
  void initState() {
    super.initState();
    _checkLowIngredients();
  }
  
  Future<void> _checkLowIngredients() async {
    try {
      final levels = await ApiService.getIngredientsLevels();
      
      setState(() {
        _lowIngredients = levels.where((ing) => ing.isLow).toList();
      });
    } catch (e) {
      print('Erreur lors de la vérification des ingrédients: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Nos Mocktails',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Кнопка доступа к админ-панели
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminLoginScreen(),
                ),
              );
            },
            tooltip: 'Panneau d\'administration',
          ),
          
          // Кнопка просмотра уровня ингредиентов
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.inventory_2_outlined, color: Colors.white),
                if (_lowIngredients.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${_lowIngredients.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IngredientsLevelScreen(),
                ),
              ).then((_) => _checkLowIngredients());
            },
            tooltip: 'Niveaux des Ingrédients',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E1437), Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: CocktailManager.mocktails.length,
            itemBuilder: (context, index) {
              final mocktail = CocktailManager.mocktails[index];
              return Animate(
                effects: [
                  FadeEffect(delay: Duration(milliseconds: 100 * index)),
                  SlideEffect(
                    begin: const Offset(0.2, 0),
                    end: Offset.zero,
                    delay: Duration(milliseconds: 100 * index),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.white.withOpacity(0.15),
                    child: Column(
                      children: [
                        // Основная информация о коктейле
                        InkWell(
                          onTap: () => _selectMocktail(mocktail),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                          child: Container(
                            height: 160,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      mocktail.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    
                                    // Рейтинг коктейля
                                    Row(
                                      children: [
                                        ...List.generate(5, (starIndex) {
                                          return Icon(
                                            Icons.star,
                                            color: starIndex < mocktail.rating 
                                                ? Colors.amber 
                                                : Colors.white.withOpacity(0.2),
                                            size: 16,
                                          );
                                        }),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${mocktail.reviewCount})',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Text(
                                    mocktail.description,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                                // Теги коктейля
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 40),
                                  child: Wrap(
                                    spacing: 8,
                                    children: mocktail.tags.map((tag) => Chip(
                                      label: Text(
                                        tag,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.blue.withOpacity(0.3),
                                    )).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Разделитель
                        Divider(
                          color: Colors.white.withOpacity(0.1),
                          height: 1,
                        ),
                        
                        // Кнопки действий
                        Row(
                          children: [
                            // Кнопка просмотра отзывов
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReviewsScreen(mocktail: mocktail),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.rate_review,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Avis',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            // Вертикальный разделитель
                            Container(
                              height: 24,
                              width: 1,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            
                            // Кнопка выбора коктейля
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectMocktail(mocktail),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.local_bar,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Préparer',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Future<void> _selectMocktail(Mocktail mocktail) async {
    setState(() {
      _isCheckingIngredients = true;
    });
    
    try {
      // Проверяем наличие ингредиентов перед переходом к выбору стакана
      final result = await ApiService.checkIngredientAvailability(mocktail.ingredients);
      
      setState(() {
        _isCheckingIngredients = false;
      });
      
      if (result['available'] == true) {
        // Переходим к выбору стакана
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GlassSelectionScreen(mocktail: mocktail),
          ),
        );
      } else {
        // Показываем диалог с предупреждением о недостатке ингредиентов
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ingrédients insuffisants'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Certains ingrédients sont en quantité insuffisante:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...List<String>.from(result['missingIngredients'] ?? []).map(
                  (ingredient) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Text(ingredient),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Voulez-vous quand même continuer?',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GlassSelectionScreen(mocktail: mocktail),
                    ),
                  );
                },
                child: const Text('Continuer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCheckingIngredients = false;
      });
      
      // Просто переходим к выбору стакана, если не удалось проверить ингредиенты
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GlassSelectionScreen(mocktail: mocktail),
        ),
      );
    }
  }
}