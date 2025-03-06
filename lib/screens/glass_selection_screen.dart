import 'package:flutter/material.dart';
import '../models/mocktail.dart';
import 'adjustment_screen.dart';

class GlassSelectionScreen extends StatelessWidget {
  final Mocktail mocktail;
  final List<int> glassVolumes = const [150, 250, 350];

  const GlassSelectionScreen({
    super.key,
    required this.mocktail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choisir le volume pour ${mocktail.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E1437), Color(0xFF1A1A1A)],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: glassVolumes.length,
          itemBuilder: (context, index) {
            final volume = glassVolumes[index];
            Map<String, int> scaledIngredients = {};
            mocktail.ingredients.forEach((ingredient, baseAmount) {
              scaledIngredients[ingredient] = 
                (baseAmount * volume / 150).round();
            });
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: Colors.white.withOpacity(0.1),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdjustmentScreen(
                        mocktail: mocktail,
                        selectedVolume: volume,
                        scaledIngredients: scaledIngredients,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verre de $volume ml',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...scaledIngredients.entries.map((e) =>
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Text(
                            '${e.key}: ${e.value}ml',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
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
}