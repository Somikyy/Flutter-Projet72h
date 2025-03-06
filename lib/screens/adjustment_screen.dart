import 'package:flutter/material.dart';
import '../models/mocktail.dart';
import '../services/api_service.dart';

class AdjustmentScreen extends StatefulWidget {
  final Mocktail mocktail;
  final int selectedVolume;
  final Map<String, int> scaledIngredients;

  const AdjustmentScreen({
    Key? key,
    required this.mocktail,
    required this.selectedVolume,
    required this.scaledIngredients,
  }) : super(key: key);

  @override
  State<AdjustmentScreen> createState() => _AdjustmentScreenState();
}

class _AdjustmentScreenState extends State<AdjustmentScreen> {
  late Map<String, int> adjustedIngredients;
  bool isShowingSnackBar = false;
  bool isLoading = false;
  bool isServerConnected = false;
  
  // Для отображения ингредиентов в визуализации
  final List<Color> _ingredientColors = [
    Colors.red.shade300,
    Colors.blue.shade300,
    Colors.green.shade300,
    Colors.purple.shade300,
  ];
  
  @override
  void initState() {
    super.initState();
    // Создаем копию, гарантируя отсутствие нулевых значений
    adjustedIngredients = {};
    for (var entry in widget.scaledIngredients.entries) {
      adjustedIngredients[entry.key] = entry.value > 0 ? entry.value : 0;
    }
    _checkServerConnection();
  }

  // Проверка соединения с сервером
  Future<void> _checkServerConnection() async {
    try {
      final isConnected = await ApiService.checkServerStatus();
      if (mounted) {
        setState(() {
          isServerConnected = isConnected;
        });
        
        if (!isConnected) {
          _showConnectionError();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isServerConnected = false;
        });
        _showConnectionError();
      }
    }
  }
  
  void _showConnectionError() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          'Impossible de se connecter au serveur. Mode hors ligne.',
          style: TextStyle(color: Colors.white),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  int get totalVolume => adjustedIngredients.values.fold(0, (sum, amount) => sum + amount);
  int get remainingVolume => widget.selectedVolume - totalVolume;

  // Подготовка заказа коктейля
  Future<void> _prepareMocktail() async {
    if (!isServerConnected) {
      _showConnectionError();
      return;
    }
    
    setState(() {
      isLoading = true;
    });
    
    // Подготовка данных запроса
    final response = await ApiService.prepareMocktail(
      mocktailName: widget.mocktail.name,
      ingredients: adjustedIngredients,
      totalVolume: totalVolume,
    );
    
    setState(() {
      isLoading = false;
    });
    
    if (response['success'] == true) {
      // Show success dialog
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.9),
          title: const Text(
            'Succès!',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Votre commande de mocktail a été envoyée avec succès!',
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 10),
              Text(
                'ID de commande: ${response['orderId']}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Le mocktail est en cours de préparation...',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil(
                  (route) => route.isFirst,
                );
              },
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      );
    } else {
      // Show error dialog
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.9),
          title: const Text(
            'Erreur',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            response['message'] ?? 'Une erreur est survenue lors de la commande.',
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // Равномерно распределить объем
  void _distributeEvenly() {
    if (adjustedIngredients.isEmpty) return;
    
    final int ingredientsCount = adjustedIngredients.length;
    final int volumePerIngredient = widget.selectedVolume ~/ ingredientsCount;
    
    final Map<String, int> newValues = {};
    int runningTotal = 0;
    
    // Распределяем равномерно основной объем
    adjustedIngredients.forEach((ingredient, _) {
      if (runningTotal + volumePerIngredient <= widget.selectedVolume) {
        newValues[ingredient] = volumePerIngredient;
        runningTotal += volumePerIngredient;
      }
    });
    
    // Распределяем оставшийся объем
    if (runningTotal < widget.selectedVolume) {
      final int remaining = widget.selectedVolume - runningTotal;
      final String firstKey = adjustedIngredients.keys.first;
      newValues[firstKey] = (newValues[firstKey] ?? 0) + remaining;
    }
    
    setState(() {
      adjustedIngredients = newValues;
    });
  }

  // Сбросить до оригинальных пропорций
  void _resetToOriginal() {
    setState(() {
      adjustedIngredients = {};
      for (var entry in widget.scaledIngredients.entries) {
        adjustedIngredients[entry.key] = entry.value > 0 ? entry.value : 0;
      }
    });
  }
  
  // Увеличить значение ингредиента на 5 мл
  void _incrementValue(String ingredient) {
    if (totalVolume < widget.selectedVolume) {
      setState(() {
        adjustedIngredients[ingredient] = (adjustedIngredients[ingredient] ?? 0) + 5;
        if (totalVolume > widget.selectedVolume) {
          adjustedIngredients[ingredient] = (adjustedIngredients[ingredient] ?? 0) - (totalVolume - widget.selectedVolume);
        }
      });
    }
  }
  
  // Уменьшить значение ингредиента на 5 мл
  void _decrementValue(String ingredient) {
    setState(() {
      adjustedIngredients[ingredient] = (adjustedIngredients[ingredient] ?? 0) - 5;
      if (adjustedIngredients[ingredient]! < 0) {
        adjustedIngredients[ingredient] = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ajuster ${widget.mocktail.name}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Индикатор подключения к серверу
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              isServerConnected ? Icons.cloud_done : Icons.cloud_off,
              color: isServerConnected ? Colors.green : Colors.red,
            ),
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
        child: Column(
          children: [
            // Визуальный индикатор объема с горизонтальными полосами
            Container(
              height: 120,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок секции
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Composition du mocktail',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$totalVolume/${widget.selectedVolume} ml',
                          style: TextStyle(
                            color: totalVolume == widget.selectedVolume 
                                ? Colors.green 
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Горизонтальные полосы для каждого ингредиента
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView.builder(
                        itemCount: adjustedIngredients.length,
                        itemBuilder: (context, index) {
                          String ingredient = adjustedIngredients.keys.elementAt(index);
                          int amount = adjustedIngredients[ingredient]!;
                          Color color = _ingredientColors[index % _ingredientColors.length];
                          
                          // Вычисляем процент от полного объема
                          double percent = widget.selectedVolume > 0 
                              ? amount / widget.selectedVolume
                              : 0.0;
                              
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                // Индикатор цвета
                                Container(
                                  width: 12,
                                  height: 12,
                                  color: color,
                                ),
                                const SizedBox(width: 8),
                                
                                // Название и количество
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    ingredient,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                
                                // Полоса объема
                                Expanded(
                                  flex: 4,
                                  child: Stack(
                                    children: [
                                      // Фон
                                      Container(
                                        height: 15,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                      // Заполнение
                                      Container(
                                        height: 15,
                                        width: percent * MediaQuery.of(context).size.width * 0.4,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 8),
                                
                                // Количество
                                Text(
                                  '$amount ml',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Кнопки быстрых действий
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.balance, size: 18),
                      label: const Text('Équilibrer'),
                      onPressed: _distributeEvenly,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.restart_alt, size: 18),
                      label: const Text('Réinitialiser'),
                      onPressed: _resetToOriginal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Слайдеры для каждого ингредиента
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: adjustedIngredients.length,
                itemBuilder: (context, index) {
                  String ingredient = adjustedIngredients.keys.elementAt(index);
                  int amount = adjustedIngredients[ingredient]!;
                  Color ingredientColor = _ingredientColors[index % _ingredientColors.length];
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Название ингредиента и текущее значение
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: ingredientColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    ingredient,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  '$amount ml',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Слайдер и кнопки
                          Row(
                            children: [
                              // Кнопка уменьшения
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.white),
                                onPressed: amount > 0 ? () => _decrementValue(ingredient) : null,
                                style: IconButton.styleFrom(
                                  disabledForegroundColor: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              
                              // Слайдер
                              Expanded(
                                child: Slider(
                                  value: amount.toDouble(),
                                  min: 0,
                                  max: widget.selectedVolume.toDouble(),
                                  divisions: widget.selectedVolume,
                                  activeColor: ingredientColor,
                                  inactiveColor: ingredientColor.withOpacity(0.3),
                                  label: '$amount ml',
                                  onChanged: (newValue) {
                                    int newAmount = newValue.round();
                                    
                                    setState(() {
                                      if (totalVolume - amount + newAmount <= widget.selectedVolume) {
                                        adjustedIngredients[ingredient] = newAmount;
                                      } else if (!isShowingSnackBar) {
                                        isShowingSnackBar = true;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                backgroundColor: Colors.red,
                                                content: Text(
                                                  'Volume maximum atteint!',
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                                duration: Duration(milliseconds: 500),
                                              ),
                                            )
                                            .closed
                                            .then((_) {
                                          isShowingSnackBar = false;
                                        });
                                      }
                                    });
                                  },
                                ),
                              ),
                              
                              // Кнопка увеличения
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.white),
                                onPressed: totalVolume < widget.selectedVolume 
                                    ? () => _incrementValue(ingredient) 
                                    : null,
                                style: IconButton.styleFrom(
                                  disabledForegroundColor: Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Нижняя панель с кнопкой отправки
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Volume total:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Restant: $remainingVolume ml',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$totalVolume / ${widget.selectedVolume} ml',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: totalVolume == widget.selectedVolume 
                              ? Colors.green 
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: totalVolume == widget.selectedVolume && !isLoading
                        ? _prepareMocktail
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          )
                        : const Text(
                            'Préparer le mocktail',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}