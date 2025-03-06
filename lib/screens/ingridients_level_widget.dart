import 'package:flutter/material.dart';
import '../models/ingridient_level.dart';
import '../services/api_service.dart';

class IngredientsLevelScreen extends StatefulWidget {
  const IngredientsLevelScreen({Key? key}) : super(key: key);

  @override
  State<IngredientsLevelScreen> createState() => _IngredientsLevelScreenState();
}

class _IngredientsLevelScreenState extends State<IngredientsLevelScreen> {
  List<IngredientLevel> _ingredientLevels = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadIngredientLevels();
  }

  Future<void> _loadIngredientLevels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final levels = await ApiService.getIngredientsLevels();
      setState(() {
        _ingredientLevels = levels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger les niveaux des ingrédients: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Niveaux des Ingrédients'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIngredientLevels,
            tooltip: 'Rafraîchir',
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
                          onPressed: _loadIngredientLevels,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : _ingredientLevels.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun ingrédient disponible',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : _buildIngredientsList(),
      ),
    );
  }

  Widget _buildIngredientsList() {
    // First, sort ingredients - low levels first
    final sortedIngredients = List<IngredientLevel>.from(_ingredientLevels)
      ..sort((a, b) => a.percentRemaining.compareTo(b.percentRemaining));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedIngredients.length,
      itemBuilder: (context, index) {
        final ingredient = sortedIngredients[index];
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bubble_chart,
                          color: _getColorForIngredient(ingredient.name),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          ingredient.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (ingredient.isLow)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Niveau bas',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: ingredient.percentRemaining,
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getLevelColor(ingredient.percentRemaining),
                          ),
                          minHeight: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(ingredient.percentRemaining * 100).toInt()}%',
                        style: TextStyle(
                          color: _getLevelColor(ingredient.percentRemaining),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${ingredient.currentLevel} ml / ${ingredient.maxLevel} ml',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getLevelColor(double percent) {
    if (percent <= 0.2) return Colors.red;
    if (percent <= 0.4) return Colors.orange;
    if (percent <= 0.6) return Colors.yellow;
    return Colors.green;
  }

  Color _getColorForIngredient(String name) {
    // Determine color based on ingredient name
    if (name.contains('Cranberry')) return Colors.red.shade400;
    if (name.contains('Grenadine')) return Colors.red.shade300;
    if (name.contains('Citron')) return Colors.yellow.shade400;
    if (name.contains('Sprite')) return Colors.blue.shade300;
    return Colors.purple.shade300; // Default
  }
}