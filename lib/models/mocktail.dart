class Mocktail {
  final String name;
  final String description;
  final String imageUrl;
  final Map<String, int> ingredients;
  final List<String> tags;
  final double rating; // Средний рейтинг
  final int reviewCount; // Количество отзывов

  const Mocktail({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.ingredients,
    required this.tags,
    this.rating = 0.0,
    this.reviewCount = 0,
  });
  
  // Создание копии объекта с обновлёнными данными
  Mocktail copyWith({
    String? name,
    String? description,
    String? imageUrl,
    Map<String, int>? ingredients,
    List<String>? tags,
    double? rating,
    int? reviewCount,
  }) {
    return Mocktail(
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
  
  // Преобразование из JSON
  factory Mocktail.fromJson(Map<String, dynamic> json) {
    return Mocktail(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      ingredients: Map<String, int>.from(json['ingredients'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
    );
  }
  
  // Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'tags': tags,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }
}