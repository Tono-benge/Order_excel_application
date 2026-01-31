import 'dart:convert'; // Для jsonDecode
import 'package:alfred/alfred.dart'; // импорт либы сервера
import 'package:sqlite3/sqlite3.dart'; // для работы с БД sqlite
import 'dart:io';

void main() async {
  final app = Alfred();

  app.all('*', (req, res) async {
    // строки ниже для  фикса ошибки CORS
    res.headers.add('Access-Control-Allow-Origin', '*');
    res.headers
        .add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method == 'OPTIONS') {
      await res.close();
    }

    return null;
  });

  final dbPath =
      r'C:\D\Курамшин\Dart\Projects\V_2_Andrey_App\server\dart_server_application\Andrey_payments_database.db';
  final db = sqlite3.open(dbPath);

  print('✅ Подключено к БД: $dbPath');

  // 🔧 Отладочный эндпоинт (ИСПРАВЛЕННЫЙ)
  app.post('/api/debug', (req, res) async {
    print('🔧 DEBUG endpoint вызван');

    try {
      // Alfred УЖЕ распарсил JSON в Map!
      final body = await req.body as Map<String, dynamic>;
      print('✅ Получено как Map: $body');

      return {
        'status': 'success',
        'method': 'Map (Alfred auto-parsed)',
        'data': body
      };
    } catch (e) {
      print('❌ Ошибка: $e');
      return {'error': 'Ошибка: $e'};
    }
  });

  // 1. Маршрут для /appleserver
  app.get('/appleserver', (req, res) {
    print('✅ GET /appleserver');
    return 'hello world';
  });

  // 🎯 API ДЛЯ ПОЛЬЗОВАТЕЛЕЙ (Table1)

  // 2. Получить всех пользователей
  app.get('/api/users', (req, res) {
    print('✅ GET /api/users');
    final results = db.select('SELECT * FROM Table1 ORDER BY ID');
    return {'status': 'success', 'count': results.length, 'users': results};
  });

  // 3. Получить пользователя по ID
  app.get('/api/users/:id', (req, res) {
    final userId = int.tryParse(req.params['id'] ?? '');
    if (userId == null) return {'error': 'Неверный ID пользователя'};

    print('✅ GET /api/users/$userId');
    final results = db.select('SELECT * FROM Table1 WHERE ID = ?', [userId]);

    if (results.isEmpty) return {'error': 'Пользователь не найден'};
    return {'status': 'success', 'user': results.first};
  });

  // 4. Создать нового пользователя (ГИБРИДНЫЙ ВАРИАНТ)
  app.post('/api/users', (req, res) async {
    print('📨 POST /api/users вызван');

    Map<String, dynamic> body;
    String methodUsed = '';

    try {
      // Пробуем вариант 1: Как Map (если Alfred распарсил)
      try {
        body = await req.body as Map<String, dynamic>;
        methodUsed = 'Map (Alfred parsed)';
        print('✅ Данные получены как Map: $body');
      } catch (e) {
        print('⚠️ Вариант Map не сработал: $e');

        // Пробуем вариант 2: Как String и парсим вручную
        try {
          final rawBody = await req.body as String;
          print('📦 Сырые данные: "$rawBody"');
          methodUsed = 'String + manual parse';

          if (rawBody.isEmpty) {
            return {'error': 'Тело запроса пустое'};
          }

          body = jsonDecode(rawBody) as Map<String, dynamic>;
          print('✅ JSON распарсен вручную: $body');
        } catch (e2) {
          print('❌ Оба варианта не сработали: $e2');
          return {'error': 'Не могу прочитать JSON. Ошибки: 1) $e, 2) $e2'};
        }
      }

      // Теперь работаем с body
      final fullName = body['full_name']?.toString();

      if (fullName == null || fullName.isEmpty) {
        return {'error': 'Имя не может быть пустым'};
      }

      // Сохраняем в БД
      print('✅ Создаём пользователя: "$fullName" (метод: $methodUsed)');
      db.execute('INSERT INTO Table1 (full_name) VALUES (?)', [fullName]);
      final newId = db.lastInsertRowId;

      return {
        'status': 'success',
        'message': 'Пользователь создан',
        'id': newId,
        'method': methodUsed
      };
    } catch (e) {
      print('❌ Общая ошибка: $e');
      return {'error': 'Ошибка сервера: $e'};
    }
  });

  // ============================================================================
  // 4.1 PUT /api/users/:id - Обновить пользователя (ИСПРАВЛЕНО)
  // ============================================================================
  // URL: PUT http://localhost:8080/api/users/:id
  // Параметры URL: id - ID пользователя
  // Body (JSON): { "fullname": "Новое имя" }
  // Ответ: { "status": "success", "message": "Пользователь обновлён", "user": {...} }

  app.put('/api/users/:id', (req, res) async {
    print('📝 PUT /api/users/:id');
    
    try {
      // -------------------------------------------------------------------------
      // Шаг 1: Получаем ID пользователя из URL
      // -------------------------------------------------------------------------
      final userId = int.tryParse(req.params['id'] ?? '');
      
      if (userId == null) {
        return {'error': 'Некорректный ID пользователя'};
      }
      
      print('📝 ID пользователя: $userId');
      
      // -------------------------------------------------------------------------
      // Шаг 2: Парсим JSON из body запроса
      // -------------------------------------------------------------------------
      Map<String, dynamic> body;
      try {
        body = await req.body as Map<String, dynamic>;
      } catch (e) {
        final rawBody = await req.body as String;
        body = jsonDecode(rawBody) as Map<String, dynamic>;
      }
      
      print('📝 Body: $body');
      
      // -------------------------------------------------------------------------
      // Шаг 3: Извлекаем и валидируем новое имя
      // -------------------------------------------------------------------------
      final fullName = body['fullname']?.toString();
      
      if (fullName == null || fullName.trim().isEmpty) {
        return {'error': 'Поле fullname обязательно'};
      }
      
      if (fullName.trim().length < 3) {
        return {'error': 'Имя должно содержать минимум 3 символа'};
      }
      
      print('📝 Новое имя: $fullName');
      
      // -------------------------------------------------------------------------
      // Шаг 4: Проверяем существование пользователя
      // -------------------------------------------------------------------------
      final existingUser = db.select(
        'SELECT ID FROM Table1 WHERE ID = ?',
        [userId],
      );
      
      if (existingUser.isEmpty) {
        return {'error': 'Пользователь с ID $userId не найден'};
      }
      
      // -------------------------------------------------------------------------
      // Шаг 5: Обновляем пользователя в БД
      // -------------------------------------------------------------------------
      db.execute(
        'UPDATE Table1 SET full_name = ? WHERE ID = ?',
        [fullName, userId],
      );
      
      print('✅ Пользователь обновлён: $fullName');
      
      // -------------------------------------------------------------------------
      // Шаг 6: Возвращаем обновлённого пользователя
      // -------------------------------------------------------------------------
      final updatedUser = db.select(
        'SELECT * FROM Table1 WHERE ID = ?',
        [userId],
      );
      
      return {
        'status': 'success',
        'message': 'Пользователь обновлён',
        'user': updatedUser.first,
      };
      
    } catch (e, stackTrace) {
      print('❌ ERROR: $e');
      print('❌ StackTrace: $stackTrace');
      return {'error': e.toString()};
    }
  });

  // ============================================================================
  // 4.2 DELETE /api/users/:id - Удалить пользователя
  // ============================================================================
  // URL: DELETE http://localhost:8080/api/users/:id
  // Параметры URL: id - ID пользователя для удаления
  // ⚠️ ВАЖНО: Заказы пользователя НЕ удаляются, UserID_Foreign_Key становится NULL
  // Ответ: { "status": "success", "message": "Пользователь удалён" }
  
  app.delete('/api/users/:id', (req, res) async {
    print('🗑️ DELETE /api/users/:id');
    
    try {
      // -------------------------------------------------------------------------
      // Шаг 1: Получаем ID пользователя из URL
      // -------------------------------------------------------------------------
      final userId = int.tryParse(req.params['id'] ?? '');
      
      if (userId == null) {
        return {'error': 'Некорректный ID пользователя'};
      }
      
      print('🗑️ ID пользователя для удаления: $userId');
      
      // -------------------------------------------------------------------------
      // Шаг 2: Проверяем существование пользователя
      // -------------------------------------------------------------------------
      final existingUser = db.select(
        'SELECT ID FROM Table1 WHERE ID = ?',
        [userId],
      );
      
      if (existingUser.isEmpty) {
        return {'error': 'Пользователь с ID $userId не найден'};
      }
      
      // -------------------------------------------------------------------------
      // Шаг 3: Устанавливаем NULL в заказах этого пользователя
      // -------------------------------------------------------------------------
      // Это сохраняет заказы, но "отвязывает" их от удалённого пользователя
      db.execute(
        'UPDATE Table2 SET UserID_Foreign_Key = NULL WHERE UserID_Foreign_Key = ?',
        [userId],
      );
      
      print('✅ Заказы пользователя отвязаны (UserID_Foreign_Key = NULL)');
      
      // -------------------------------------------------------------------------
      // Шаг 4: Удаляем пользователя из базы данных
      // -------------------------------------------------------------------------
      db.execute('DELETE FROM Table1 WHERE ID = ?', [userId]);
      
      print('✅ Пользователь удалён: ID $userId');
      
      // -------------------------------------------------------------------------
      // Шаг 5: Возвращаем успешный ответ
      // -------------------------------------------------------------------------
      return {
        'status': 'success',
        'message': 'Пользователь удалён',
      };
      
    } catch (e, stackTrace) {
      print('❌ ERROR: $e');
      print('❌ StackTrace: $stackTrace');
      return {'error': e.toString()};
    }
  });

  // 🎯 API ДЛЯ ЗАКАЗОВ (Table2)

  // 5. Получить все заказы
  app.get('/api/orders', (req, res) {
    print('✅ GET /api/orders');

    try {
      final results = db.select('''
        SELECT o.*, u.full_name 
        FROM Table2 o 
        LEFT JOIN Table1 u ON o.UserID_Foreign_Key = u.ID 
        ORDER BY o.order_ID
      ''');

      print('📊 Найдено заказов: ${results.length}');
      return {'status': 'success', 'count': results.length, 'orders': results};
    } catch (e) {
      print('❌ Ошибка при запросе заказов: $e');
      return {'error': 'Ошибка БД: $e'};
    }
  });

  // 6. Получить заказы конкретного пользователя
  app.get('/api/users/:id/orders', (req, res) {
    final userId = int.tryParse(req.params['id'] ?? '');
    if (userId == null) return {'error': 'Неверный ID пользователя'};

    print('✅ GET /api/users/$userId/orders');

    final results = db.select('''
      SELECT * FROM Table2 
      WHERE UserID_Foreign_Key = ? 
      ORDER BY order_ID
    ''', [userId]);

    return {
      'status': 'success',
      'user_id': userId,
      'count': results.length,
      'orders': results
    };
  });

  // 7. Создать новый заказ (ИСПРАВЛЕННЫЙ)
  // ============================================================================
  // API ENDPOINT: Создать новый заказ (POST /api/orders)
  // ============================================================================
  // Принимает: { "orderamount": 2500.0, "userforeignkey": 1 }
  // Возвращает: полный объект заказа с userName через JOIN

  app.post('/api/orders', (req, res) async {
    print('📥 POST /api/orders'); // Логирование для отладки
    
    try {
      // Шаг 1: Парсим тело запроса (JSON)
      Map<String, dynamic> body;
      
      try {
        // Пытаемся распарсить как Map (Alfred auto-parse)
        body = await req.body as Map<String, dynamic>;
        print('✅ Map-парсинг успешен: $body');
      } catch (e) {
        // Если не получилось - парсим как String
        print('⚠️  Map-парсинг не сработал, пробуем String');
        final rawBody = await req.body as String;
        body = jsonDecode(rawBody) as Map<String, dynamic>;
        print('✅ String-парсинг успешен: $body');
      }
      
      // Шаг 2: Извлекаем данные из body
      final orderAmount = body['orderamount'];
      final userForeignKey = body['userforeignkey'];
      
      // Валидация: проверяем что данные пришли
      if (orderAmount == null || userForeignKey == null) {
        return {
          'error': 'Отсутствуют обязательные поля: orderamount, userforeignkey'
        };
      }
      
      print('💾 Вставка в БД: amount=$orderAmount, userId=$userForeignKey');
      
      // Шаг 3: Вставляем заказ в Table2
      db.execute(
        'INSERT INTO Table2 (order_amount, UserID_Foreign_Key) VALUES (?, ?)',
        [orderAmount, userForeignKey],
      );
      
      // Шаг 4: Получаем ID созданного заказа
      final newOrderId = db.lastInsertRowId;
      print('✅ Заказ создан с ID: $newOrderId');
      
      // Шаг 5: Получаем полные данные заказа через JOIN с Table1
      final newOrderResult = db.select('''
        SELECT 
          o.order_ID as orderID,
          o.order_amount as orderamount,
          o.UserID_Foreign_Key as UserIDForeignKey,
          u.full_name as fullname
        FROM Table2 o
        LEFT JOIN Table1 u ON o.UserID_Foreign_Key = u.ID
        WHERE o.order_ID = ?
      ''', [newOrderId]);
      
      // Проверяем что заказ найден
      if (newOrderResult.isEmpty) {
        return {
          'error': 'Заказ создан, но не найден в БД (ID: $newOrderId)'
        };
      }
      
      // Шаг 6: Возвращаем успешный ответ с полным объектом заказа
      final orderData = newOrderResult.first;
      print('📤 Возвращаем заказ: $orderData');
      
      return {
        'status': 'success',
        'message': 'Заказ создан',
        'order': orderData, // ✅ ПОЛНЫЙ объект с userName
      };
      
    } catch (e, stackTrace) {
      // Ловим любые ошибки и логируем
      print('❌ ОШИБКА создания заказа: $e');
      print('❌ StackTrace: $stackTrace');
      
      return {
        'error': 'Ошибка создания заказа: $e'
      };
    }
  });

  // ============================================================================
  // ✅ ОБНОВЛЁННЫЙ ЭНДПОИНТ: Массовый импорт заказов из Excel
  // ============================================================================
  // POST /api/orders/import
  // Ожидает JSON:
  // {
  //   "orders": [
  //     { "fullName": "ФИО", "orderAmount": 123.45, "rowNumber": 8 },
  //     ...
  //   ]
  // }
  // НОВАЯ ЛОГИКА:
  //  - Для каждого заказа ищет пользователя по ФИО в Table1
  //  - Если пользователя нет → создаёт его
  //  - Вставляет заказ в Table2 с реальным UserID_Foreign_Key
  //  - Транзакция: если ошибка — откатывает всё
  // Возвращает: { status, inserted, usersCreated, failed, errors: [...] }

  app.post('/api/orders/import', (req, res) async {
    print('📥 POST /api/orders/import (массовый импорт из Excel)');

    try {
      Map<String, dynamic> body;

      // 1. Парсим тело запроса
      try {
        body = await req.body as Map<String, dynamic>;
        print('✅ Map-парсинг успешен: $body');
      } catch (e) {
        print('⚠️ Map-парсинг не сработал, пробуем String');
        final rawBody = await req.body as String;
        body = jsonDecode(rawBody) as Map<String, dynamic>;
        print('✅ String-парсинг успешен: $body');
      }

      // 2. Достаём массив orders
      final orders = body['orders'];
      if (orders == null || orders is! List) {
        return {
          'error': 'Поле "orders" обязательно и должно быть массивом',
        };
      }

      if (orders.isEmpty) {
        return {
          'error': 'Массив "orders" пуст. Нет данных для импорта.',
        };
      }

      print('📊 Получено заказов для импорта: ${orders.length}');

      int insertedCount = 0;
      int usersCreatedCount = 0;
      final List<Map<String, dynamic>> errors = [];

      // 3. Транзакция SQLite: все или ничего
      db.execute('BEGIN TRANSACTION');
      
      try {
        for (final rawOrder in orders) {
          if (rawOrder is! Map) {
            errors.add({
              'order': rawOrder,
              'error': 'Элемент не является объектом JSON',
            });
            continue;
          }

          final fullName = rawOrder['fullName']?.toString().trim();
          final orderAmount = rawOrder['orderAmount'];
          final rowNumber = rawOrder['rowNumber'];

          // ===================================================================
          // Валидация ФИО
          // ===================================================================
          if (fullName == null || fullName.isEmpty) {
            errors.add({
              'rowNumber': rowNumber,
              'error': 'fullName отсутствует или пустое',
            });
            continue;
          }

          // ===================================================================
          // Валидация суммы заказа
          // ===================================================================
          if (orderAmount == null) {
            errors.add({
              'rowNumber': rowNumber,
              'fullName': fullName,
              'error': 'orderAmount отсутствует',
            });
            continue;
          }

          double? amount;
          try {
            if (orderAmount is num) {
              amount = orderAmount.toDouble();
            } else {
              amount = double.tryParse(orderAmount.toString());
            }
          } catch (_) {
            amount = null;
          }

          if (amount == null || amount <= 0) {
            errors.add({
              'rowNumber': rowNumber,
              'fullName': fullName,
              'error': 'orderAmount некорректен или <= 0',
            });
            continue;
          }

          // ===================================================================
          // ✅ НОВАЯ ЛОГИКА: Найти или создать пользователя в Table1
          // ===================================================================
          int userId;

          // Ищем пользователя по ФИО (без учёта регистра для надёжности)
          final existingUsers = db.select(
            'SELECT ID FROM Table1 WHERE LOWER(full_name) = LOWER(?)',
            [fullName],
          );

          if (existingUsers.isEmpty) {
            // Пользователя нет → создаём нового в Table1
            db.execute(
              'INSERT INTO Table1 (full_name) VALUES (?)',
              [fullName],
            );
            userId = db.lastInsertRowId;
            usersCreatedCount++;
            print('✅ Создан пользователь: "$fullName" (ID: $userId)');
          } else {
            // Пользователь уже существует → берём его ID
            userId = existingUsers.first['ID'] as int;
            print('📌 Найден существующий пользователь: "$fullName" (ID: $userId)');
          }

          // ===================================================================
          // ✅ Вставляем заказ в Table2 с реальным UserID_Foreign_Key
          // ===================================================================
          db.execute(
            'INSERT INTO Table2 (order_amount, UserID_Foreign_Key) VALUES (?, ?)',
            [amount, userId],
          );
          insertedCount++;
          print('✅ Заказ добавлен: amount=$amount, userId=$userId');
        }

        // Если все ок — фиксируем транзакцию
        db.execute('COMMIT');
        
      } catch (e, stackTrace) {
        // При любой ошибке откатываем все вставки
        print('❌ Ошибка в транзакции импорта: $e');
        print('❌ StackTrace: $stackTrace');
        db.execute('ROLLBACK');
        
        return {
          'error': 'Ошибка при массовом импорте: $e',
        };
      }

      print('✅ Массовый импорт завершён');
      print('   Заказов создано: $insertedCount');
      print('   Пользователей создано: $usersCreatedCount');
      print('   Ошибок: ${errors.length}');

      return {
        'status': 'success',
        'message': 'Массовый импорт завершён',
        'inserted': insertedCount,
        'usersCreated': usersCreatedCount,
        'failed': errors.length,
        'errors': errors,
      };
      
    } catch (e, stackTrace) {
      print('❌ Общая ошибка /api/orders/import: $e');
      print('❌ StackTrace: $stackTrace');
      
      return {
        'error': 'Ошибка сервера при импорте: $e',
      };
    }
  });

  // 8. Удалить заказ
  app.delete('/api/orders/:id', (req, res) {
    final orderId = int.tryParse(req.params['id'] ?? '');
    if (orderId == null) return {'error': 'Неверный ID заказа'};

    print('✅ DELETE /api/orders/$orderId');

    try {
      db.execute('DELETE FROM Table2 WHERE order_ID = ?', [orderId]);
      return {'status': 'success', 'message': 'Заказ удалён'};
    } catch (e) {
      return {'error': 'Ошибка удаления: $e'};
    }
  });

  // 8.1 Редактура заказов
  // ============================================================================
  // API ENDPOINT: Обновить заказ (PUT /api/orders/:id)
  // ============================================================================
  // Принимает: { "orderamount": 3000.0, "userforeignkey": 2 }
  // Обновляет заказ с указанным ID

  app.put('/api/orders/:id', (req, res) async {
    print('📝 PUT /api/orders/:id'); // Логирование
    
    try {
      // Шаг 1: Получаем ID заказа из URL параметра
      final orderId = int.tryParse(req.params['id'] ?? '');
      
      if (orderId == null) {
        return {'error': 'Неверный ID заказа'};
      }
      
      print('📝 Обновление заказа ID: $orderId');
      
      // Шаг 2: Парсим тело запроса
      Map<String, dynamic> body;
      
      try {
        body = await req.body as Map<String, dynamic>;
      } catch (e) {
        final rawBody = await req.body as String;
        body = jsonDecode(rawBody) as Map<String, dynamic>;
      }
      
      // Шаг 3: Извлекаем новые данные
      final orderAmount = body['orderamount'];
      final userForeignKey = body['userforeignkey'];
      
      if (orderAmount == null || userForeignKey == null) {
        return {'error': 'Отсутствуют обязательные поля'};
      }
      
      print('💾 Новые данные: amount=$orderAmount, userId=$userForeignKey');
      
      // Шаг 4: Проверяем что заказ существует
      final existingOrder = db.select(
        'SELECT order_ID FROM Table2 WHERE order_ID = ?',
        [orderId],
      );
      
      if (existingOrder.isEmpty) {
        return {'error': 'Заказ с ID $orderId не найден'};
      }
      
      // Шаг 5: Обновляем заказ в БД
      db.execute(
        'UPDATE Table2 SET order_amount = ?, UserID_Foreign_Key = ? WHERE order_ID = ?',
        [orderAmount, userForeignKey, orderId],
      );
      
      print('✅ Заказ обновлён');
      
      // Шаг 6: Возвращаем обновлённый заказ с userName через JOIN
      final updatedOrderResult = db.select('''
        SELECT 
          o.order_ID as orderID,
          o.order_amount as orderamount,
          o.UserID_Foreign_Key as UserIDForeignKey,
          u.full_name as fullname
        FROM Table2 o
        LEFT JOIN Table1 u ON o.UserID_Foreign_Key = u.ID
        WHERE o.order_ID = ?
      ''', [orderId]);
      
      if (updatedOrderResult.isEmpty) {
        return {'error': 'Заказ обновлён, но не найден'};
      }
      
      final orderData = updatedOrderResult.first;
      print('📤 Возвращаем обновлённый заказ: $orderData');
      
      return {
        'status': 'success',
        'message': 'Заказ обновлён',
        'order': orderData,
      };
      
    } catch (e, stackTrace) {
      print('❌ ОШИБКА обновления заказа: $e');
      print('❌ StackTrace: $stackTrace');
      
      return {'error': 'Ошибка обновления заказа: $e'};
    }
  });

  // 9. JSON тестовый маршрут
  app.get('/appleserver/json', (req, res) {
    print('✅ GET /appleserver/json');
    return {
      'message': 'hello world',
      'status': 'success',
      'timestamp': DateTime.now().toIso8601String(),
      'server': 'Apple Server'
    };
  });

  
  
  
// НОВЫЙ ENDPOINT: POST /api/orders/import-aggregated
// Принимает агрегированные данные по монтажникам из Excel
// Формат: { "installers": [ {"fullName": "...", "orderAmount": 123.45, "rowCount": 5}, ... ] }

app.post('/api/orders/import-aggregated', (req, res) async {
  print('POST /api/orders/import-aggregated - Импорт агрегированных данных из Excel');
  
  try {
    //-------------------------------------------------------------------------
    // 1. Получаем JSON из тела запроса
    //-------------------------------------------------------------------------
    Map<String, dynamic> body;
    try {
      // Пытаемся распарсить как Map
      body = await req.body as Map<String, dynamic>;
      print('✓ Map-парсинг body');
    } catch (e) {
      // Если не получилось - парсим как String
      print('✗ Map-парсинг не удался, пробуем String');
      final rawBody = await req.body as String;
      body = jsonDecode(rawBody) as Map<String, dynamic>;
      print('✓ String-парсинг body');
    }

    //-------------------------------------------------------------------------
    // 2. Валидация: проверяем наличие массива installers
    //-------------------------------------------------------------------------
    final installers = body['installers'];
    
    if (installers == null || installers is! List) {
      return {
        'status': 'error',
        'message': 'Отсутствует поле "installers" или оно не является массивом',
      };
    }

    if (installers.isEmpty) {
      return {
        'status': 'error',
        'message': 'Массив "installers" пуст. Нет данных для импорта.',
      };
    }

    print('✓ Получено монтажников: ${installers.length}');

    //-------------------------------------------------------------------------
    // 3. Переменные для подсчета результатов
    //-------------------------------------------------------------------------
    int usersCreatedCount = 0; // Количество созданных пользователей
    int ordersCreatedCount = 0; // Количество созданных заказов
    final List<Map<String, dynamic>> errors = []; // Список ошибок

    //-------------------------------------------------------------------------
    // 4. Начинаем транзакцию SQLite
    //-------------------------------------------------------------------------
    db.execute('BEGIN TRANSACTION');

    try {
      // Проходим по каждому монтажнику
      for (final rawInstaller in installers) {
        // Проверка: элемент должен быть Map
        if (rawInstaller is! Map) {
          errors.add({
            'installer': rawInstaller,
            'error': 'Неверный формат данных (ожидается JSON объект)',
          });
          continue;
        }

        // Извлекаем данные
        final fullName = rawInstaller['fullName']?.toString().trim();
        final orderAmount = rawInstaller['orderAmount'];
        final rowCount = rawInstaller['rowCount'];

        //---------------------------------------------------------------------
        // 5. Валидация данных монтажника
        //---------------------------------------------------------------------
        
        // Проверка: ФИО не должно быть пустым
        if (fullName == null || fullName.isEmpty) {
          errors.add({
            'installer': rawInstaller,
            'error': 'Пустое поле fullName',
          });
          continue;
        }

        // Проверка: сумма должна быть числом
        if (orderAmount == null) {
          errors.add({
            'fullName': fullName,
            'error': 'Отсутствует поле orderAmount',
          });
          continue;
        }

        // Парсинг суммы
        double? amount;
        try {
          if (orderAmount is num) {
            amount = orderAmount.toDouble();
          } else {
            amount = double.tryParse(orderAmount.toString());
          }
        } catch (e) {
          amount = null;
        }

        // Проверка: сумма должна быть больше 0
        if (amount == null || amount <= 0) {
          errors.add({
            'fullName': fullName,
            'error': 'Сумма orderAmount должна быть больше 0 (получено: $orderAmount)',
          });
          continue;
        }

        print('→ Обработка: $fullName, сумма: $amount ₽, заказов: $rowCount');

        //---------------------------------------------------------------------
        // 6. Поиск или создание пользователя в Table1
        //---------------------------------------------------------------------
        int userId;
        
        // Ищем пользователя по ФИО (регистронезависимый поиск)
        final existingUsers = db.select(
          'SELECT ID FROM Table1 WHERE LOWER(full_name) = LOWER(?)',
          [fullName],
        );

        if (existingUsers.isEmpty) {
          // Пользователь не найден → создаем нового
          db.execute(
            'INSERT INTO Table1 (full_name) VALUES (?)',
            [fullName],
          );
          userId = db.lastInsertRowId;
          usersCreatedCount++;
          print('  ✓ Создан новый пользователь ID: $userId');
        } else {
          // Пользователь найден → берем его ID
          userId = existingUsers.first['ID'] as int;
          print('  ✓ Найден существующий пользователь ID: $userId');
        }

        //---------------------------------------------------------------------
        // 7. Создаем запись в Table2 (заказ)
        //---------------------------------------------------------------------
        db.execute(
          'INSERT INTO Table2 (order_amount, UserID_Foreign_Key) VALUES (?, ?)',
          [amount, userId],
        );
        ordersCreatedCount++;
        print('  ✓ Создан заказ на сумму: $amount ₽');
      }

      //-----------------------------------------------------------------------
      // 8. Фиксируем транзакцию
      //-----------------------------------------------------------------------
      db.execute('COMMIT');
      print('✓ Транзакция завершена успешно');

    } catch (e, stackTrace) {
      //-----------------------------------------------------------------------
      // 9. Откатываем транзакцию при ошибке
      //-----------------------------------------------------------------------
      print('✗ Ошибка в транзакции: $e');
      print('StackTrace: $stackTrace');
      db.execute('ROLLBACK');
      
      return {
        'status': 'error',
        'message': 'Ошибка при импорте данных',
        'error': e.toString(),
      };
    }

    //-------------------------------------------------------------------------
    // 10. Возвращаем результат
    //-------------------------------------------------------------------------
    print('');
    print('=== ИТОГИ ИМПОРТА ===');
    print('Пользователей создано: $usersCreatedCount');
    print('Заказов создано: $ordersCreatedCount');
    print('Ошибок: ${errors.length}');
    print('=====================');

    return {
      'status': 'success',
      'message': 'Импорт завершен',
      'usersCreated': usersCreatedCount,
      'ordersCreated': ordersCreatedCount,
      'failed': errors.length,
      'errors': errors,
    };

  } catch (e, stackTrace) {
    print('✗ Критическая ошибка /api/orders/import-aggregated: $e');
    print('StackTrace: $stackTrace');
    
    return {
      'status': 'error',
      'message': 'Критическая ошибка сервера',
      'error': e.toString(),
    };
  }
});

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  // 🚀 Запускаем сервер
  final server = await app.listen(8080);

  print('\n🎉 Сервер запущен!');
  print('📍 Адрес: http://localhost:8080');
  print('📡 API endpoints:');
  print('   - POST /api/debug                      - отладка');
  print('   - GET  /appleserver                    - тест сервера');
  print('   - GET  /api/users                      - все пользователи');
  print('   - GET  /api/users/:id                  - пользователь по ID');
  print('   - POST /api/users                      - создать пользователя');
  print('   - PUT  /api/users/:id                  - обновить пользователя ✅');
  print('   - DELETE /api/users/:id                - удалить пользователя ✅');  
  print('   - GET  /api/orders                     - все заказы');
  print('   - GET  /api/users/:id/orders           - заказы пользователя');
  print('   - POST /api/orders                     - создать заказ');
  print('   - PUT  /api/orders/:id                 - обновить заказ');
  print('   - DELETE /api/orders/:id               - удалить заказ');
  print('   - POST /api/orders/import              - массовый импорт заказов ✅ (с автосозданием пользователей)');
  print('   - GET  /appleserver/json               - тестовый JSON');
  print('');
  print('⏹️  Для остановки: Ctrl+C');

  await server;
}
