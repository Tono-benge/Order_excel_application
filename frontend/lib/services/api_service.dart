// API клиент - Frontend)
// Назначение: Взаимодействие с сервером. Все HTTP запросы к вашему Alfred серверу проходят через этот класс.
import 'dart:convert'; // Для работы с JSON (jsonEncode, jsonDecode)
import 'package:http/http.dart' as http;  // HTTP клиент для запросов
import 'package:flutter/foundation.dart';        // ✅ ДОБАВЛЕНО: для debugPrint
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../models/import_row_model.dart';        // ✅ ДОБАВЛЕНО: для ImportRow
import 'error_handler.dart';


// Сервис для работы с API (взаимодействие с сервером)
class ApiService {
  // Базовый URL вашего сервера (Alfred на порту 8080)
  static const String baseUrl = 'http://localhost:8080';
  
  // Таймаут для всех запросов (30 секунд)
  static const Duration timeout = Duration(seconds: 30);


  // ========== МЕТОДЫ ДЛЯ РАБОТЫ С ПОЛЬЗОВАТЕЛЯМИ ==========


  // Получить список всех пользователей (GET /api/users)
  Future<List<UserModel>> getUsers() async {
    try {
      // Выполняем GET запрос с таймаутом
      final response = await http
          .get(Uri.parse('$baseUrl/api/users'))
          .timeout(timeout);


      // Проверяем статус-код ответа
      final error = ErrorHandler.handleHttpResponse(response);
      if (error != null) throw Exception(error);


      // Парсим JSON ответ
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final List<dynamic> usersJson = jsonData['users'];


      // Преобразуем каждый элемент JSON в модель UserModel
      return usersJson.map((json) => UserModel.fromJson(json)).toList();
      
    } catch (e) {
      // Обрабатываем ошибку и пробрасываем с понятным сообщением
      throw Exception(ErrorHandler.handleHttpError(e));
    }
  }


  // Получить одного пользователя по ID (GET /api/users/:id)
  Future<UserModel> getUserById(int id) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/users/$id'))
          .timeout(timeout);


      final error = ErrorHandler.handleHttpResponse(response);
      if (error != null) throw Exception(error);


      final jsonData = json.decode(response.body);
      return UserModel.fromJson(jsonData['user']);
      
    } catch (e) {
      throw Exception(ErrorHandler.handleHttpError(e));
    }
  }


  // Создать нового пользователя (POST /api/users)
  Future<UserModel> createUser(String fullName) async {
    try {
      // Валидация перед отправкой
      final validationError = ErrorHandler.validateUserName(fullName);
      if (validationError != null) throw Exception(validationError);


      // Подготавливаем тело запроса (JSON)
      final body = json.encode({'full_name': fullName});


      // Отправляем POST запрос с заголовком Content-Type
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/users'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeout);


      final error = ErrorHandler.handleHttpResponse(response);
      if (error != null) throw Exception(error);


      final jsonData = json.decode(response.body);
      
      // Возвращаем созданного пользователя с новым ID
      return UserModel(
        id: jsonData['id'],
        fullName: fullName,
      );
      
    } catch (e) {
      throw Exception(ErrorHandler.handleHttpError(e));
    }
  }


  // ============================================================================
  // PUT /api/users/:id - Обновить пользователя
  // ============================================================================
  // userId - ID пользователя для обновления
  // fullName - новое имя пользователя
  // Возвращает: обновлённый UserModel


  Future<UserModel> updateUser(int userId, String fullName) async {
    print('🔵 ApiService: PUT /api/users/$userId');
    print('📤 Новое имя: $fullName');
    
    try {
      // Валидация на клиенте
      final validationError = ErrorHandler.validateUserName(fullName);
      if (validationError != null) {
        throw Exception(validationError);
      }
      
      // Формируем JSON body
      final body = json.encode({
        'fullname': fullName.trim(),
      });
      
      // Отправляем PUT запрос
      final response = await http
          .put(
            Uri.parse('$baseUrl/api/users/$userId'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeout);
      
      print('📥 Статус: ${response.statusCode}');
      print('📥 Ответ: ${response.body}');
      
      // Проверяем статус ответа
      final error = ErrorHandler.handleHttpResponse(response);
      if (error != null) {
        throw Exception(error);
      }
      
      // Парсим JSON ответ
      final jsonData = json.decode(response.body);
      
      // Извлекаем данные пользователя из ответа
      if (jsonData['user'] != null) {
        print('✅ ApiService: Пользователь обновлён');
        return UserModel.fromJson(jsonData['user']);
      } else {
        // Если сервер вернул данные в другом формате
        return UserModel(
          id: userId,
          fullName: fullName.trim(),
        );
      }
      
    } catch (e) {
      print('❌ ApiService updateUser - Ошибка: $e');
      throw Exception(ErrorHandler.handleHttpError(e));
    }
  }


  // ============================================================================
  // DELETE /api/users/:id - Удалить пользователя
  // ============================================================================
  // userId - ID пользователя для удаления
  // Возвращает: Future<void> (ничего не возвращает при успехе)


  Future<void> deleteUser(int userId) async {
    print('🗑️ ApiService: Отправка DELETE /api/users/$userId');
    
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/api/users/$userId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);
      
      print('📥 ApiService: Статус DELETE: ${response.statusCode}');
      
      // Проверяем статус ответа (200 или 204 = успех)
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ ApiService: Пользователь удалён');
        return; // Успешно удалён
      }
      
      // Если статус не успешный - проверяем ошибку
      final error = ErrorHandler.handleHttpResponse(response);
      if (error != null) {
        throw Exception(error);
      }
      
    } catch (e) {
      print('❌ ApiService deleteUser - Ошибка: $e');
      throw Exception(ErrorHandler.handleHttpError(e));
    }
  }


  // ========== МЕТОДЫ ДЛЯ РАБОТЫ С ЗАКАЗАМИ ==========


  // Получить все заказы (GET /api/orders)
  Future<List<OrderModel>> getOrders() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/orders'))
          .timeout(timeout);


      final error = ErrorHandler.handleHttpResponse(response);
      if (error != null) throw Exception(error);


      final jsonData = json.decode(response.body);
      final List<dynamic> ordersJson = jsonData['orders'];


      return ordersJson.map((json) => OrderModel.fromJson(json)).toList();
      
    } catch (e) {
      throw Exception(ErrorHandler.handleHttpError(e));
    }
  }


  // Получить заказы конкретного пользователя (GET /api/users/:id/orders)
  Future<List<OrderModel>> getUserOrders(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/users/$userId/orders'))
          .timeout(timeout);


      final error = ErrorHandler.handleHttpResponse(response);
      if (error != null) throw Exception(error);


      final jsonData = json.decode(response.body);
      final List<dynamic> ordersJson = jsonData['orders'];


      return ordersJson.map((json) => OrderModel.fromJson(json)).toList();
      
    } catch (e) {
      throw Exception(ErrorHandler.handleHttpError(e));
    }
  }


  // Создать новый заказ (POST /api/orders)
  Future<OrderModel> createOrder(double amount, int userId) async {
    print('📤 ApiService: Отправка POST /api/orders');
    print('📤 amount: $amount, userId: $userId');


    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/orders'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'orderamount': amount,
          'userforeignkey': userId,
        }),
      ).timeout(timeout);


      print('✅ ApiService: Ответ получен, statusCode: ${response.statusCode}');
      print('✅ ApiService: Body: ${response.body}');


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['order'] != null) {
          print('✅ ApiService: Создан OrderModel из data["order"]');
          return OrderModel.fromJson(data['order']);
        } else if (data['orderid'] != null) {
          print('✅ ApiService: Создан OrderModel вручную с orderid');
          final orderId = data['orderid'];
          return OrderModel.fromJson({
            'orderID': orderId,
            'orderamount': amount,
            'UserIDForeignKey': userId,
          });
        } else {
          throw Exception('Сервер не вернул данные заказа');
        }
      } else {
        throw Exception('Ошибка HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ ApiService: Ошибка - $e');
      throw Exception(ErrorHandler.handleHttpError(e));
    }
  }


  // ============================================================================
  // МЕТОД: Обновить заказ (PUT /api/orders/:id)
  // ============================================================================
  // orderId - ID заказа который нужно обновить
  // amount - новая сумма заказа
  // userId - новый ID пользователя


  Future<OrderModel> updateOrder(int orderId, double amount, int userId) async {
    print('📝 ApiService: Отправка PUT /api/orders/$orderId');
    print('📝 amount: $amount, userId: $userId');
    
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/orders/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderamount': amount,
          'userforeignkey': userId,
        }),
      ).timeout(timeout);
      
      print('✅ ApiService: Ответ получен, statusCode: ${response.statusCode}');
      print('✅ ApiService: Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['order'] != null) {
          print('✅ ApiService: Заказ обновлён');
          return OrderModel.fromJson(data['order']);
        } else {
          throw Exception('Сервер не вернул обновлённый заказ');
        }
      } else {
        throw Exception('Ошибка HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ ApiService: Ошибка - $e');
      throw Exception(ErrorHandler.handleHttpError(e));
    }
  }


  // Удалить заказ (DELETE /api/orders/:id)
  Future<void> deleteOrder(int orderId) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/api/orders/$orderId'))
          .timeout(timeout);


      final error = ErrorHandler.handleHttpResponse(response);
      if (error != null) throw Exception(error);
      
    } catch (e) {
      throw Exception(ErrorHandler.handleHttpError(e));
    }
  }


  // ========== ПОИСК ==========


  // Поиск пользователей по имени (локальная фильтрация)
  Future<List<UserModel>> searchUsers(String query) async {
    final allUsers = await getUsers();
    
    if (query.trim().isEmpty) return allUsers;
    
    // Фильтруем пользователей по имени (без учета регистра)
    return allUsers
        .where((user) =>
            user.fullName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }


  // Поиск заказов по номеру (локальная фильтрация)
  Future<List<OrderModel>> searchOrders(String query) async {
    final allOrders = await getOrders();
    
    if (query.trim().isEmpty) return allOrders;
    
    // Фильтруем заказы по номеру
    return allOrders
        .where((order) => order.orderId.toString().contains(query))
        .toList();
  }


  // ============================================================================
  // ✅ УНИВЕРСАЛЬНЫЙ МЕТОД: POST запрос (для любых endpoints)
  // ============================================================================
  // Назначение: Универсальный метод для отправки POST запросов
  // Используется в import_excel_screen.dart для загрузки агрегированных данных из Excel
  // endpoint - путь эндпоинта (например: '/api/orders/import-aggregated')
  // data - Map с данными для отправки (будет преобразован в JSON)
  // Возвращает: Map<String, dynamic> с распарсенным JSON ответом сервера
  // 
  // Пример использования:
  // final response = await apiService.post('/api/orders/import-aggregated', {
  //   'installers': [{'fullName': 'Иванов', 'orderAmount': 1000.0}]
  // });


  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    debugPrint('📤 ApiService: POST $endpoint');
    debugPrint('   Данные: $data');
    
    try {
      // Формируем полный URL (baseUrl + endpoint)
      final url = Uri.parse('$baseUrl$endpoint');
      
      // Отправляем POST запрос с JSON телом
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json', // Указываем, что отправляем JSON
            },
            body: jsonEncode(data), // Преобразуем Map в JSON строку
          )
          .timeout(timeout); // Применяем таймаут 30 секунд
      
      debugPrint('📥 ApiService: Статус ответа: ${response.statusCode}');
      debugPrint('📥 ApiService: Тело ответа: ${response.body}');
      
      // Проверяем статус-код ответа (200 = успех, 201 = создано)
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Парсим JSON ответ и возвращаем Map
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ ApiService: POST успешен');
        return jsonData;
      } else {
        // HTTP ошибка (4xx, 5xx)
        final error = ErrorHandler.handleHttpResponse(response);
        throw Exception(error ?? 'Ошибка HTTP ${response.statusCode}');
      }
      
    } catch (e) {
      // Обработка ошибок сети, таймаутов, парсинга JSON
      debugPrint('❌ ApiService post - Ошибка: $e');
      throw Exception(ErrorHandler.handleHttpError(e));
    }
  }
}
