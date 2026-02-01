import 'dart:convert'; // Для jsonDecode
import 'package:alfred/alfred.dart'; // импорт либы сервера
import 'package:sqlite3/sqlite3.dart'; // ДЛЯ РАБОТЫ С SQLite
import 'dart:io';

void main() async {
  final app = Alfred();

  app.all('*', (req, res) async {
    // строки ниже для фикса ошибки CORS
    res.headers.add('Access-Control-Allow-Origin', '*');
    res.headers
        .add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method == 'OPTIONS') {
      await res.close();
    }

    return null;
  });

  // 🔧 АВТОМАТИЧЕСКИЙ ВЫБОР ПУТИ К БАЗЕ ДАННЫХ
  // Для сервера: /var/www/myapp/database/andrey_payments.db
  // Для разработки: локальный путь
  final String dbPath;
  
  if (Platform.isLinux && Directory('/var/www/myapp').existsSync()) {
    // Режим сервера (Ubuntu)
    dbPath = '/var/www/myapp/database/andrey_payments.db';
    print('🌐 Режим: СЕРВЕР (Linux)');
  } else if (Platform.isWindows) {
    // Режим разработки (Windows)
    dbPath = r'C:\D\Курамшин\Dart\Projects\V_2_Andrey_App\server\dart_server_application\Andrey_payments_database.db';
    print('💻 Режим: РАЗРАБОТКА (Windows)');
  } else {
    // Запасной путь
    dbPath = 'andrey_payments.db';
    print('⚠️  Режим: ПО УМОЛЧАНИЮ');
  }

  print('📁 Путь к базе данных: $dbPath');
  
  try {
    final db = sqlite3.open(dbPath);
    print('✅ Подключено к SQLite БД');
    
    // Проверяем таблицы
    try {
      final usersCount = db.select('SELECT COUNT(*) FROM Table1').first.values.first;
      final ordersCount = db.select('SELECT COUNT(*) FROM Table2').first.values.first;
      print('📊 Пользователей в Table1: $usersCount');
      print('📊 Заказов в Table2: $ordersCount');
    } catch (e) {
      print('⚠️  Ошибка при проверке таблиц: $e');
      print('⚠️  Проверьте структуру БД или создайте таблицы');
      
      // Создаем таблицы если их нет
      try {
        db.execute('''
          CREATE TABLE IF NOT EXISTS Table1 (
            ID INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL
          )
        ''');
        
        db.execute('''
          CREATE TABLE IF NOT EXISTS Table2 (
            order_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            order_amount REAL NOT NULL,
            UserID_Foreign_Key INTEGER
          )
        ''');
        
        print('✅ Таблицы созданы (если не существовали)');
      } catch (createError) {
        print('❌ Ошибка создания таблиц: $createError');
      }
    }

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
      return '✅ Сервер работает! База: ${dbPath.split('/').last}';
    });

    // 🎯 API ДЛЯ ПОЛЬЗОВАТЕЛЕЙ (Table1)

    // 2. Получить всех пользователей
    app.get('/api/users', (req, res) {
      print('✅ GET /api/users');
      try {
        final results = db.select('SELECT * FROM Table1 ORDER BY ID');
        return {'status': 'success', 'count': results.length, 'users': results};
      } catch (e) {
        return {'status': 'error', 'message': 'Ошибка БД: $e', 'users': []};
      }
    });

    // 3. Получить пользователя по ID
    app.get('/api/users/:id', (req, res) {
      final userId = int.tryParse(req.params['id'] ?? '');
      if (userId == null) return {'error': 'Неверный ID пользователя'};

      print('✅ GET /api/users/$userId');
      try {
        final results = db.select('SELECT * FROM Table1 WHERE ID = ?', [userId]);

        if (results.isEmpty) return {'error': 'Пользователь не найден'};
        return {'status': 'success', 'user': results.first};
      } catch (e) {
        return {'error': 'Ошибка БД: $e'};
      }
    });

    // 4. Создать нового пользователя
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

        // Сохраняем в БД (SQLite)
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

    // 4.1 PUT /api/users/:id - Обновить пользователя
    app.put('/api/users/:id', (req, res) async {
      print('📝 PUT /api/users/:id');
      
      try {
        final userId = int.tryParse(req.params['id'] ?? '');
        
        if (userId == null) {
          return {'error': 'Некорректный ID пользователя'};
        }
        
        print('📝 ID пользователя: $userId');
        
        Map<String, dynamic> body;
        try {
          body = await req.body as Map<String, dynamic>;
        } catch (e) {
          final rawBody = await req.body as String;
          body = jsonDecode(rawBody) as Map<String, dynamic>;
        }
        
        print('📝 Body: $body');
        
        final fullName = body['fullname']?.toString();
        
        if (fullName == null || fullName.trim().isEmpty) {
          return {'error': 'Поле fullname обязательно'};
        }
        
        if (fullName.trim().length < 3) {
          return {'error': 'Имя должно содержать минимум 3 символа'};
        }
        
        print('📝 Новое имя: $fullName');
        
        // Проверяем существование пользователя
        final existingUser = db.select(
          'SELECT ID FROM Table1 WHERE ID = ?',
          [userId],
        );
        
        if (existingUser.isEmpty) {
          return {'error': 'Пользователь с ID $userId не найден'};
        }
        
        // Обновляем пользователя в БД
        db.execute(
          'UPDATE Table1 SET full_name = ? WHERE ID = ?',
          [fullName, userId],
        );
        
        print('✅ Пользователь обновлён: $fullName');
        
        // Возвращаем обновлённого пользователя
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

    // 4.2 DELETE /api/users/:id - Удалить пользователя
    app.delete('/api/users/:id', (req, res) async {
      print('🗑️ DELETE /api/users/:id');
      
      try {
        final userId = int.tryParse(req.params['id'] ?? '');
        
        if (userId == null) {
          return {'error': 'Некорректный ID пользователя'};
        }
        
        print('🗑️ ID пользователя для удаления: $userId');
        
        // Проверяем существование пользователя
        final existingUser = db.select(
          'SELECT ID FROM Table1 WHERE ID = ?',
          [userId],
        );
        
        if (existingUser.isEmpty) {
          return {'error': 'Пользователь с ID $userId не найден'};
        }
        
        // Устанавливаем NULL в заказах этого пользователя
        db.execute(
          'UPDATE Table2 SET UserID_Foreign_Key = NULL WHERE UserID_Foreign_Key = ?',
          [userId],
        );
        
        print('✅ Заказы пользователя отвязаны (UserID_Foreign_Key = NULL)');
        
        // Удаляем пользователя из базы данных
        db.execute('DELETE FROM Table1 WHERE ID = ?', [userId]);
        
        print('✅ Пользователь удалён: ID $userId');
        
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

    // 7. Создать новый заказ
    app.post('/api/orders', (req, res) async {
      print('📥 POST /api/orders');
      
      try {
        Map<String, dynamic> body;
        
        try {
          body = await req.body as Map<String, dynamic>;
          print('✅ Map-парсинг успешен: $body');
        } catch (e) {
          print('⚠️  Map-парсинг не сработал, пробуем String');
          final rawBody = await req.body as String;
          body = jsonDecode(rawBody) as Map<String, dynamic>;
          print('✅ String-парсинг успешен: $body');
        }
        
        final orderAmount = body['orderamount'];
        final userForeignKey = body['userforeignkey'];
        
        if (orderAmount == null || userForeignKey == null) {
          return {
            'error': 'Отсутствуют обязательные поля: orderamount, userforeignkey'
          };
        }
        
        print('💾 Вставка в БД: amount=$orderAmount, userId=$userForeignKey');
        
        // Вставляем заказ
        db.execute(
          'INSERT INTO Table2 (order_amount, UserID_Foreign_Key) VALUES (?, ?)',
          [orderAmount, userForeignKey],
        );
        
        final newOrderId = db.lastInsertRowId;
        print('✅ Заказ создан с ID: $newOrderId');
        
        // Получаем полные данные заказа
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
        
        if (newOrderResult.isEmpty) {
          return {
            'error': 'Заказ создан, но не найден в БД (ID: $newOrderId)'
          };
        }
        
        final orderData = newOrderResult.first;
        print('📤 Возвращаем заказ: $orderData');
        
        return {
          'status': 'success',
          'message': 'Заказ создан',
          'order': orderData,
        };
        
      } catch (e, stackTrace) {
        print('❌ ОШИБКА создания заказа: $e');
        print('❌ StackTrace: $stackTrace');
        
        return {
          'error': 'Ошибка создания заказа: $e'
        };
      }
    });

    // Импорт заказов из Excel
    app.post('/api/orders/import', (req, res) async {
      print('📥 POST /api/orders/import (массовый импорт из Excel)');

      try {
        Map<String, dynamic> body;

        try {
          body = await req.body as Map<String, dynamic>;
          print('✅ Map-парсинг успешен');
        } catch (e) {
          print('⚠️ Map-парсинг не сработал, пробуем String');
          final rawBody = await req.body as String;
          body = jsonDecode(rawBody) as Map<String, dynamic>;
          print('✅ String-парсинг успешен');
        }

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

        // Начинаем транзакцию SQLite
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

            if (fullName == null || fullName.isEmpty) {
              errors.add({
                'rowNumber': rowNumber,
                'error': 'fullName отсутствует или пустое',
              });
              continue;
            }

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

            // Найти или создать пользователя
            int userId;

            final existingUsers = db.select(
              'SELECT ID FROM Table1 WHERE LOWER(full_name) = LOWER(?)',
              [fullName],
            );

            if (existingUsers.isEmpty) {
              db.execute(
                'INSERT INTO Table1 (full_name) VALUES (?)',
                [fullName],
              );
              userId = db.lastInsertRowId;
              usersCreatedCount++;
              print('✅ Создан пользователь: "$fullName" (ID: $userId)');
            } else {
              userId = existingUsers.first['ID'] as int;
              print('📌 Найден существующий пользователь: "$fullName" (ID: $userId)');
            }

            // Вставляем заказ
            db.execute(
              'INSERT INTO Table2 (order_amount, UserID_Foreign_Key) VALUES (?, ?)',
              [amount, userId],
            );
            insertedCount++;
            print('✅ Заказ добавлен: amount=$amount, userId=$userId');
          }

          // Фиксируем транзакцию
          db.execute('COMMIT');
          
        } catch (e, stackTrace) {
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

    // 8.1 Обновить заказ
    app.put('/api/orders/:id', (req, res) async {
      print('📝 PUT /api/orders/:id');
      
      try {
        final orderId = int.tryParse(req.params['id'] ?? '');
        
        if (orderId == null) {
          return {'error': 'Неверный ID заказа'};
        }
        
        print('📝 Обновление заказа ID: $orderId');
        
        Map<String, dynamic> body;
        
        try {
          body = await req.body as Map<String, dynamic>;
        } catch (e) {
          final rawBody = await req.body as String;
          body = jsonDecode(rawBody) as Map<String, dynamic>;
        }
        
        final orderAmount = body['orderamount'];
        final userForeignKey = body['userforeignkey'];
        
        if (orderAmount == null || userForeignKey == null) {
          return {'error': 'Отсутствуют обязательные поля'};
        }
        
        print('💾 Новые данные: amount=$orderAmount, userId=$userForeignKey');
        
        // Проверяем что заказ существует
        final existingOrder = db.select(
          'SELECT order_ID FROM Table2 WHERE order_ID = ?',
          [orderId],
        );
        
        if (existingOrder.isEmpty) {
          return {'error': 'Заказ с ID $orderId не найден'};
        }
        
        // Обновляем заказ в БД
        db.execute(
          'UPDATE Table2 SET order_amount = ?, UserID_Foreign_Key = ? WHERE order_ID = ?',
          [orderAmount, userForeignKey, orderId],
        );
        
        print('✅ Заказ обновлён');
        
        // Возвращаем обновлённый заказ
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
        
        return {
          'error': 'Ошибка обновления заказа: $e'
        };
      }
    });

    // 9. JSON тестовый маршрут
    app.get('/appleserver/json', (req, res) {
      print('✅ GET /appleserver/json');
      return {
        'message': 'hello world',
        'status': 'success',
        'timestamp': DateTime.now().toIso8601String(),
        'server': 'Apple Server',
        'database': dbPath.split('/').last,
        'platform': Platform.operatingSystem,
      };
    });

    // Импорт агрегированных данных
    app.post('/api/orders/import-aggregated', (req, res) async {
      print('POST /api/orders/import-aggregated - Импорт агрегированных данных');
      
      try {
        Map<String, dynamic> body;
        try {
          body = await req.body as Map<String, dynamic>;
        } catch (e) {
          final rawBody = await req.body as String;
          body = jsonDecode(rawBody) as Map<String, dynamic>;
        }

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

        int usersCreatedCount = 0;
        int ordersCreatedCount = 0;
        final List<Map<String, dynamic>> errors = [];

        // Начинаем транзакцию
        db.execute('BEGIN TRANSACTION');

        try {
          for (final rawInstaller in installers) {
            if (rawInstaller is! Map) {
              errors.add({
                'installer': rawInstaller,
                'error': 'Неверный формат данных',
              });
              continue;
            }

            final fullName = rawInstaller['fullName']?.toString().trim();
            final orderAmount = rawInstaller['orderAmount'];
            final rowCount = rawInstaller['rowCount'];

            if (fullName == null || fullName.isEmpty) {
              errors.add({
                'installer': rawInstaller,
                'error': 'Пустое поле fullName',
              });
              continue;
            }

            if (orderAmount == null) {
              errors.add({
                'fullName': fullName,
                'error': 'Отсутствует поле orderAmount',
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
            } catch (e) {
              amount = null;
            }

            if (amount == null || amount <= 0) {
              errors.add({
                'fullName': fullName,
                'error': 'Сумма orderAmount должна быть больше 0',
              });
              continue;
            }

            print('→ Обработка: $fullName, сумма: $amount ₽, заказов: $rowCount');

            // Поиск или создание пользователя
            int userId;
            
            final existingUsers = db.select(
              'SELECT ID FROM Table1 WHERE LOWER(full_name) = LOWER(?)',
              [fullName],
            );

            if (existingUsers.isEmpty) {
              db.execute(
                'INSERT INTO Table1 (full_name) VALUES (?)',
                [fullName],
              );
              userId = db.lastInsertRowId;
              usersCreatedCount++;
              print('  ✓ Создан новый пользователь ID: $userId');
            } else {
              userId = existingUsers.first['ID'] as int;
              print('  ✓ Найден существующий пользователь ID: $userId');
            }

            // Создаём заказ
            db.execute(
              'INSERT INTO Table2 (order_amount, UserID_Foreign_Key) VALUES (?, ?)',
              [amount, userId],
            );
            ordersCreatedCount++;
            print('  ✓ Создан заказ на сумму: $amount ₽');
          }

          db.execute('COMMIT');
          print('✓ Транзакция завершена успешно');

        } catch (e, stackTrace) {
          print('✗ Ошибка в транзакции: $e');
          print('StackTrace: $stackTrace');
          db.execute('ROLLBACK');
          
          return {
            'status': 'error',
            'message': 'Ошибка при импорте данных',
            'error': e.toString(),
          };
        }

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
    final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
    final server = await app.listen(port, '0.0.0.0');

    print('\n' + '='*50);
    print('🎉 СЕРВЕР ЗАПУЩЕН!');
    print('='*50);
    print('📍 Локальный адрес: http://localhost:$port');
    print('📍 Внешний адрес:   http://212.193.63.116:$port');
    print('📁 База данных:     $dbPath');
    print('💻 Платформа:       ${Platform.operatingSystem}');
    print('📡 API endpoints:');
    print('   - GET  /appleserver               - тест сервера');
    print('   - GET  /api/users                 - все пользователи');
    print('   - GET  /api/users/:id             - пользователь по ID');
    print('   - POST /api/users                 - создать пользователя');
    print('   - PUT  /api/users/:id             - обновить пользователя');
    print('   - DELETE /api/users/:id           - удалить пользователя');  
    print('   - GET  /api/orders                - все заказы');
    print('   - GET  /api/users/:id/orders      - заказы пользователя');
    print('   - POST /api/orders                - создать заказ');
    print('   - PUT  /api/orders/:id            - обновить заказ');
    print('   - DELETE /api/orders/:id          - удалить заказ');
    print('   - POST /api/orders/import         - массовый импорт');
    print('   - POST /api/orders/import-aggregated - агрегированный импорт');
    print('='*50);
    print('⏹️  Для остановки: Ctrl+C');
    print('='*50);

    await server;
    
  } catch (e, stackTrace) {
    print('\n❌❌❌ КРИТИЧЕСКАЯ ОШИБКА ❌❌❌');
    print('Ошибка: $e');
    print('StackTrace: $stackTrace');
    print('Проверьте:');
    print('1. Существует ли файл базы: $dbPath');
    print('2. Правильные ли права доступа к файлу');
    print('3. Установлены ли зависимости: dart pub get');
    exit(1);
  }
}
