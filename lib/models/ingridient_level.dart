class IngredientLevel {
  final String ingredientId;
  final String name;
  final int currentLevel;
  final int maxLevel;

  const IngredientLevel({
    required this.ingredientId,
    required this.name,
    required this.currentLevel,
    required this.maxLevel,
  });

  double get percentRemaining => currentLevel / maxLevel;
  
  bool get isLow => percentRemaining < 0.2;

  factory IngredientLevel.fromJson(Map<String, dynamic> json) {
    return IngredientLevel(
      ingredientId: json['ingredientId'] ?? '',
      name: json['name'] ?? '',
      currentLevel: json['currentLevel'] ?? 0,
      maxLevel: json['maxLevel'] ?? 1000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredientId': ingredientId,
      'name': name,
      'currentLevel': currentLevel,
      'maxLevel': maxLevel,
    };
  }
}