class Review {
  final String id;
  final String mocktailId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.mocktailId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

// In review.dart - check that fromJson correctly handles the API response
factory Review.fromJson(Map<String, dynamic> json) {
  // print("Парсинг JSON отзыва: $json");
  
  // Обработка поля created_at, которое может быть double (timestamp) или строкой
  DateTime createdAt;
  if (json['created_at'] != null) {
    if (json['created_at'] is double || json['created_at'] is int) {
      // Конвертация Unix timestamp в DateTime
      createdAt = DateTime.fromMillisecondsSinceEpoch(
        (json['created_at'] * 1000).toInt());
    } else if (json['created_at'] is String) {
      try {
        createdAt = DateTime.parse(json['created_at']);
      } catch (e) {
        // print("Ошибка парсинга даты: $e");
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }
  } else if (json['createdAt'] != null) {
    // Такая же логика для поля 'createdAt', если нужно
    if (json['createdAt'] is double || json['createdAt'] is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] * 1000).toInt());
    } else if (json['createdAt'] is String) {
      try {
        createdAt = DateTime.parse(json['createdAt']);
      } catch (e) {
        // print("Ошибка парсинга даты: $e");
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }
  } else {
    createdAt = DateTime.now();
  }
  
  return Review(
    id: json['review_id'] ?? json['id'] ?? '',
    mocktailId: json['mocktail_id'] ?? json['mocktailId'] ?? '',
    userName: json['user_name'] ?? json['userName'] ?? '',
    rating: (json['rating'] ?? 0.0).toDouble(),
    comment: json['comment'] ?? '',
    createdAt: createdAt,
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mocktailId': mocktailId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}