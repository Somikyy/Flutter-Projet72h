// ignore_for_file: prefer_const_constructors

import 'base_ingredients.dart';
import 'mocktail.dart';

class CocktailManager {
  static final List<Mocktail> mocktails = [
    // Оригинальные коктейли
    Mocktail(
      name: 'Sunrise Rouge',
      description: 'Un mocktail rafraîchissant aux fruits rouges avec des bulles',
      imageUrl: 'assets/images/sunrise.png',
      ingredients: {
        BaseIngredients.CRANBERRY: 70,
        BaseIngredients.GRENADINE: 20,
        BaseIngredients.SPRITE: 60,
      },
      tags: ['Fruité', 'Pétillant', 'Rouge'],
    ),
    
    Mocktail(
      name: 'Citrus Fizz',
      description: 'Une boisson pétillante et acidulée',
      imageUrl: 'assets/images/citrus.png',
      ingredients: {
        BaseIngredients.CITRON: 30,
        BaseIngredients.SPRITE: 100,
        BaseIngredients.GRENADINE: 20,
      },
      tags: ['Agrumes', 'Pétillant', 'Rafraîchissant'],
    ),
    
    Mocktail(
      name: 'Berry Splash',
      description: 'Un mélange parfait de fruits rouges et d\'agrumes',
      imageUrl: 'assets/images/berry.png',
      ingredients: {
        BaseIngredients.CRANBERRY: 90,
        BaseIngredients.CITRON: 30,
        BaseIngredients.SPRITE: 30,
      },
      tags: ['Fruité', 'Rafraîchissant', 'Rouge'],
    ),
    
    // Новые коктейли
    Mocktail(
      name: 'Bleu Lagoon',
      description: 'Un mocktail rafraîchissant avec une belle couleur bleutée',
      imageUrl: 'assets/images/blue.png',
      ingredients: {
        BaseIngredients.SPRITE: 100,
        BaseIngredients.CITRON: 40,
        BaseIngredients.GRENADINE: 10,
      },
      tags: ['Doux', 'Pétillant', 'Rafraîchissant'],
    ),
    
    Mocktail(
      name: 'Sunset Dream',
      description: 'Un mocktail élégant avec des saveurs douces de fruits rouges',
      imageUrl: 'assets/images/sunset.png',
      ingredients: {
        BaseIngredients.CRANBERRY: 60,
        BaseIngredients.SPRITE: 70,
        BaseIngredients.GRENADINE: 20,
      },
      tags: ['Doux', 'Élégant', 'Fruité'],
    ),
    
    Mocktail(
      name: 'Zesty Lemon',
      description: 'Une explosion d\'agrumes pour un rafraîchissement maximal',
      imageUrl: 'assets/images/lemon.png',
      ingredients: {
        BaseIngredients.CITRON: 50,
        BaseIngredients.SPRITE: 90,
        BaseIngredients.GRENADINE: 10,
      },
      tags: ['Agrumes', 'Acidulé', 'Rafraîchissant'],
    ),
    
    Mocktail(
      name: 'Ruby Sparkle',
      description: 'Un mocktail festif avec une belle couleur rubis profonde',
      imageUrl: 'assets/images/ruby.png',
      ingredients: {
        BaseIngredients.CRANBERRY: 80,
        BaseIngredients.GRENADINE: 30,
        BaseIngredients.SPRITE: 40,
      },
      tags: ['Fruité', 'Festif', 'Rouge'],
    ),
    
    Mocktail(
      name: 'Fresh Breeze',
      description: 'Un mélange léger et aérien qui évoque la fraîcheur d\'une brise d\'été',
      imageUrl: 'assets/images/breeze.png',
      ingredients: {
        BaseIngredients.CITRON: 35,
        BaseIngredients.SPRITE: 95,
        BaseIngredients.CRANBERRY: 20,
      },
      tags: ['Léger', 'Rafraîchissant', 'Estival'],
    ),
  ];
}