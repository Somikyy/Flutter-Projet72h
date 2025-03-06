import 'package:flutter/material.dart';
import '../models/ingridient_level.dart';
import '../services/api_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<IngredientLevel> _ingredients = [];
  Map<String, int> _updatedLevels = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }
  
  Future<void> _loadIngredients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _updatedLevels = {};
    });
    
    try {
      final ingredients = await ApiService.getIngredientsLevels();
      setState(() {
        _ingredients = ingredients;
        _isLoading = false;
        
        // Инициализируем map с текущими значениями
        for (var ingredient in ingredients) {
          _updatedLevels[ingredient.ingredientId] = ingredient.currentLevel;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveIngredientLevels() async {
    if (_updatedLevels.isEmpty) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final success = await ApiService.updateIngredientLevels(_updatedLevels);
      
      setState(() {
        _isSaving = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Niveaux d\'ingrédients mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Перезагружаем для отображения обновленных данных
        _loadIngredients();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour des niveaux'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _updateIngredientLevel(String ingredientId, int newLevel) {
    setState(() {
      _updatedLevels[ingredientId] = newLevel;
    });
  }
  
  void _resetToMaxLevel(String ingredientId, int maxLevel) {
    setState(() {
      _updatedLevels[ingredientId] = maxLevel;
    });
  }
  
  void _incrementLevel(String ingredientId, int maxLevel) {
    final currentLevel = _updatedLevels[ingredientId] ?? 0;
    final newLevel = currentLevel + 50 > maxLevel ? maxLevel : currentLevel + 50;
    setState(() {
      _updatedLevels[ingredientId] = newLevel;
    });
  }
  
  void _decrementLevel(String ingredientId) {
    final currentLevel = _updatedLevels[ingredientId] ?? 0;
    final newLevel = currentLevel - 50 < 0 ? 0 : currentLevel - 50;
    setState(() {
      _updatedLevels[ingredientId] = newLevel;
    });
  }
  
  bool get _hasChanges {
    for (var ingredient in _ingredients) {
      final updatedLevel = _updatedLevels[ingredient.ingredientId];
      if (updatedLevel != null && updatedLevel != ingredient.currentLevel) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panneau d\'administration'),
        automaticallyImplyLeading: false,
        actions: [
          // Кнопка сохранения изменений
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveIngredientLevels,
              tooltip: 'Enregistrer les modifications',
            ),
          
          // Кнопка выхода из админ-панели
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // Показываем диалог подтверждения, если есть несохраненные изменения
              if (_hasChanges) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Modifications non enregistrées'),
                    content: const Text(
                      'Vous avez des modifications non enregistrées. Êtes-vous sûr de vouloir quitter?'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Закрываем диалог
                          Navigator.pop(context); // Возвращаемся на предыдущий экран
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Quitter sans enregistrer'),
                      ),
                    ],
                  ),
                );
              } else {
                // Просто выходим без диалога, если нет изменений
                Navigator.pop(context);
              }
            },
            tooltip: 'Quitter le mode administrateur',
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadIngredients,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : _buildIngredientsList(),
      ),
    );
  }
  
  Widget _buildIngredientsList() {
    return Column(
      children: [
        // Заголовок секции
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Niveaux des ingrédients',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Кнопка обновления данных
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadIngredients,
                tooltip: 'Actualiser',
              ),
            ],
          ),
        ),
        
        // Список ингредиентов
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _ingredients.length,
            itemBuilder: (context, index) {
              final ingredient = _ingredients[index];
              final currentLevel = _updatedLevels[ingredient.ingredientId] ?? ingredient.currentLevel;
              final percentFilled = currentLevel / ingredient.maxLevel;
              final Color levelColor = _getLevelColor(percentFilled);
              
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
                      // Название ингредиента и кнопки быстрых действий
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ingredient.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Кнопка заполнения до максимума
                          IconButton(
                            icon: const Icon(Icons.vertical_align_top, color: Colors.white),
                            onPressed: () => _resetToMaxLevel(
                              ingredient.ingredientId, 
                              ingredient.maxLevel
                            ),
                            tooltip: 'Remplir au maximum',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Информация о текущем уровне и максимуме
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Niveau actuel: $currentLevel ml',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Max: ${ingredient.maxLevel} ml',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Слайдер и кнопки изменения уровня
                      Row(
                        children: [
                          // Кнопка уменьшения
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.white),
                            onPressed: currentLevel > 0
                                ? () => _decrementLevel(ingredient.ingredientId)
                                : null,
                            style: IconButton.styleFrom(
                              disabledForegroundColor: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          
                          // Слайдер
                          Expanded(
                            child: Slider(
                              value: currentLevel.toDouble(),
                              min: 0,
                              max: ingredient.maxLevel.toDouble(),
                              divisions: ingredient.maxLevel ~/ 10, // Шаг 10 мл
                              activeColor: levelColor,
                              inactiveColor: levelColor.withOpacity(0.3),
                              label: '$currentLevel ml',
                              onChanged: (newValue) {
                                _updateIngredientLevel(
                                  ingredient.ingredientId,
                                  newValue.round(),
                                );
                              },
                            ),
                          ),
                          
                          // Кнопка увеличения
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.white),
                            onPressed: currentLevel < ingredient.maxLevel
                                ? () => _incrementLevel(
                                    ingredient.ingredientId, 
                                    ingredient.maxLevel
                                  )
                                : null,
                            style: IconButton.styleFrom(
                              disabledForegroundColor: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                      
                      // Визуальный индикатор уровня
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentFilled,
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Процент заполнения
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(percentFilled * 100).toInt()}%',
                              style: TextStyle(
                                color: levelColor,
                                fontWeight: FontWeight.bold,
                              ),
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
        
        // Кнопка сохранения внизу экрана
        if (_hasChanges)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveIngredientLevels,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Enregistrer les modifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
  
  Color _getLevelColor(double percent) {
    if (percent <= 0.2) return Colors.red;
    if (percent <= 0.4) return Colors.orange;
    if (percent <= 0.6) return Colors.yellow;
    return Colors.green;
  }
}