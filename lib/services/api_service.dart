import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ingridient_level.dart';
import '../models/review.dart';
import '../models/mocktail.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // IP-адрес Raspberry Pi
  static const String baseUrl = 'http://172.20.10.4:5001';
  
  // Health check для проверки доступности сервера
  static Future<bool> checkServerStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      // print('Server connection error: $e');
      return false;
    }
  }
  
  // Add this new method to get all mocktails with their ratings
  // In api_service.dart - update the getMocktails method
static Future<List<Mocktail>> getMocktails() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/mocktails'),
    ).timeout(const Duration(seconds: 5));
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      // print("API response: ${response.body}"); // Add this for debugging
      if (responseData.containsKey('mocktails') && responseData['mocktails'] is List) {
        final List<dynamic> data = responseData['mocktails'];
        return data.map((json) {
          // Make sure the JSON property names match what's coming from your API
          final mocktail = Mocktail.fromJson(json);
          // print("Loaded mocktail: ${mocktail.name}, rating: ${mocktail.rating}, reviewCount: ${mocktail.reviewCount}");
          return mocktail;
        }).toList();
      }
    }
    return [];
  } catch (e) {
    // print('Error fetching mocktails: $e');
    return [];
  }
}
  
  // Отправка запроса на приготовление коктейля
  static Future<Map<String, dynamic>> prepareMocktail({
    required String mocktailName,
    required Map<String, int> ingredients,
    required int totalVolume,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/prepare_mocktail'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mocktailName': mocktailName,
          'ingredients': ingredients,
          'totalVolume': totalVolume,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server returned status code ${response.statusCode}',
        };
      }
    } catch (e) {
      // print('Error sending mocktail preparation request: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
  
  // Проверка статуса заказа
  static Future<Map<String, dynamic>> checkOrderStatus(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order_status/$orderId'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server returned status code ${response.statusCode}',
        };
      }
    } catch (e) {
      // print('Error checking order status: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
  
  // --- МЕТОДЫ ДЛЯ РАБОТЫ С ОТЗЫВАМИ ---
  
  // Получение всех отзывов для конкретного коктейля
static Future<List<Review>> getMocktailReviews(String mocktailName) async {
  try {
    // print("===== REVIEW API DEBUG =====");
    // print("Getting reviews for mocktail: $mocktailName");
    
    // Try to use the mocktail name directly as the ID in the API call
    final response = await http.get(
      Uri.parse('$baseUrl/reviews/$mocktailName'),
    ).timeout(const Duration(seconds: 5));
    
    // print("API URL: $baseUrl/reviews/$mocktailName");
    // print("Response status code: ${response.statusCode}");
    // print("Response body: ${response.body}");
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      // print("Parsed response data: $responseData");
      
      if (responseData.containsKey('reviews') && responseData['reviews'] is List) {
        final List<dynamic> data = responseData['reviews'];
        // print("Found ${data.length} reviews in response");
        
        // // print each review for debugging
        for (var review in data) {
          // print("Review: $review");
        }
        
        return data.map((json) => Review.fromJson(json)).toList();
      } else {
        // print("Response does not contain 'reviews' list");
      }
    } else {
      // print("API returned error status code: ${response.statusCode}");
    }
    return [];
  } catch (e) {
    // print('Error fetching reviews: $e');
    return [];
  }
}

  // Добавление нового отзыва
static Future<bool> addMocktailReview({
  required String mocktailId,
  required String userName,
  required double rating,
  required String comment,
}) async {
  try {
    // print("===== ADD REVIEW DEBUG =====");
    // print("Adding review for mocktail: $mocktailId");
    
    // Try to find the actual mocktail_id if we're given a name
    final mocktails = await getMocktails();
    String actualMocktailId = mocktailId;
    
    // Look for a matching mocktail and use its ID
    for (var mocktail in mocktails) {
      if (mocktail.name == mocktailId) {
        actualMocktailId = mocktail.name.toLowerCase().replaceAll(' ', '_');
        // print("Found matching mocktail, using ID: $actualMocktailId");
        break;
      }
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/reviews'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mocktailId': actualMocktailId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': DateTime.now().toIso8601String(),
      }),
    ).timeout(const Duration(seconds: 10));
    
    // print("API response: ${response.statusCode} - ${response.body}");
    
    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    // print('Error adding review: $e');
    return false;
  }
}

  // --- МЕТОДЫ ДЛЯ РАБОТЫ С ИНГРЕДИЕНТАМИ ---

  // Получение уровня всех ингредиентов
  static Future<List<IngredientLevel>> getIngredientsLevels() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ingredients/levels'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('ingredients') && responseData['ingredients'] is List) {
          final List<dynamic> data = responseData['ingredients'];
          return data.map((json) => IngredientLevel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      // print('Error fetching ingredient levels: $e');
      return [];
    }
  }

  // Проверка наличия ингредиентов для коктейля
  static Future<Map<String, dynamic>> checkIngredientAvailability(
    Map<String, int> ingredients
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ingredients/check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ingredients': ingredients,
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        'available': false,
        'message': 'Erreur de connexion au serveur',
        'missingIngredients': [],
      };
    } catch (e) {
      // print('Error checking ingredients: $e');
      return {
        'available': false,
        'message': 'Erreur de connexion au serveur',
        'missingIngredients': [],
      };
    }
  }

  // Обновление уровня ингредиентов (для админ-панели)
  static Future<bool> updateIngredientLevels(Map<String, int> updatedLevels) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ingredients/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'updatedLevels': updatedLevels,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      // print('Error updating ingredient levels: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getOrders() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        'success': false,
        'message': 'Erreur ${response.statusCode}',
        'orders': [],
      };
    }
  } catch (e) {
    // print('Erreur lors de la récupération des commandes: $e');
    return {
      'success': false,
      'message': 'Erreur de connexion: $e',
      'orders': [],
    };
  }
}

static Future<bool> updateOrderStatus(String orderId, String newStatus) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/order_status/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'orderId': orderId,
        'status': newStatus,
      }),
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  } catch (e) {
    // // // print('Erreur lors de la mise à jour du statut: $e');
    return false;
  }
}

// Méthodes pour la gestion des avis
static Future<bool> deleteReview(String mocktailId, String reviewId) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/reviews/$reviewId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mocktailId': mocktailId,
      }),
    ).timeout(const Duration(seconds: 10));
    
    return response.statusCode == 200;
  } catch (e) {
    // print('Erreur lors de la suppression de l\'avis: $e');
    return false;
  }
}

static Future<bool> updateReview({
  required String mocktailId,
  required String reviewId,
  required double rating,
  required String comment,
}) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/reviews/$reviewId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mocktailId': mocktailId,
        'rating': rating,
        'comment': comment,
      }),
    ).timeout(const Duration(seconds: 10));
    
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}
}