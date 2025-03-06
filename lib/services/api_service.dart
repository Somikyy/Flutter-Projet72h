import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ingridient_level.dart';
import '../models/review.dart';

class ApiService {
  // Замените на IP-адрес вашего Raspberry Pi или сервера
  static const String baseUrl = 'http://192.168.1.27:5000';
  
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
      print('Server connection error: $e');
      return false;
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
      print('Error sending mocktail preparation request: $e');
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
      print('Error checking order status: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
  
  // --- МЕТОДЫ ДЛЯ РАБОТЫ С ОТЗЫВАМИ ---
  
  // Получение всех отзывов для конкретного коктейля
  static Future<List<Review>> getMocktailReviews(String mocktailId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/$mocktailId'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['reviews'];
        return data.map((json) => Review.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching reviews: $e');
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
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mocktailId': mocktailId,
          'userName': userName,
          'rating': rating,
          'comment': comment,
          'createdAt': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error adding review: $e');
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
        final List<dynamic> data = jsonDecode(response.body)['ingredients'];
        return data.map((json) => IngredientLevel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching ingredient levels: $e');
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
      print('Error checking ingredients: $e');
      return {
        'available': false,
        'message': 'Erreur de connexion au serveur',
        'missingIngredients': [],
      };
    }
  }

  // Добавьте этот метод в класс ApiService

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
    print('Error updating ingredient levels: $e');
    return false;
  }
}
}