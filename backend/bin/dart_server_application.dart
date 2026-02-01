import 'dart:convert';
import 'package:alfred/alfred.dart';
import 'package:sqlite3/sqlite3.dart';
import 'dart:io';

void main() async {
  final app = Alfred();

  app.all('*', (req, res) async {
    res.headers.add('Access-Control-Allow-Origin', '*');
    res.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.headers.add('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method == 'OPTIONS') await res.close();
    return null;
  });

  // 🔧 АВТОМАТИЧЕСКИЙ ВЫБОР ПУТИ К БАЗЕ ДАННЫХ
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
    final tables = db.select("SELECT name FROM sqlite_master WHERE type='table'");
    print('📊 Найдены таблицы:');
    for (final table in tables) {
      print('   - ${table['name']}');
    }
    
    // Проверяем данные
    try {
      final usersCount = db.select('SELECT COUNT(*) as count FROM Table1').first['count'];
      final ordersCount = db.select('SELECT COUNT(*) as count FROM Table2').first['count'];
      print('📊 Данные: $usersCount пользователей, $ordersCount заказов');
    } catch (e) {
      print('⚠️  Ошибка при проверке данных: $e');
    }

    // 1. Тестовый эндпоинт
    app.get('/appleserver', (req, res) {
      print('✅ GET /appleserver');
      return '✅ Сервер работает с SQLite! Путь к БД: $dbPath';
    });

    // 2. Все пользователи
    app.get('/api/users', (req, res) {
      print('✅ GET /api/users');
      try {
        final results = db.select('SELECT * FROM Table1 ORDER BY ID');
        return {'status': 'success', 'count': results.length, 'users': results};
      } catch (e) {
        return {'status': 'error', 'message': 'Ошибка БД: $e', 'users': []};
      }
    });

    // 3. Пользователь по ID
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

    // 4. Все заказы
    app.get('/api/orders', (req, res) {
      print('✅ GET /api/orders');
      try {
        final results = db.select('''
          SELECT o.*, u.full_name 
          FROM Table2 o 
          LEFT JOIN Table1 u ON o.UserID_Foreign_Key = u.ID 
          ORDER BY o.order_ID
        ''');
        return {'status': 'success', 'count': results.length, 'orders': results};
      } catch (e) {
        return {'status': 'error', 'message': 'Ошибка БД: $e', 'orders': []};
      }
    });

    // 5. Заказы пользователя
    app.get('/api/users/:id/orders', (req, res) {
      final userId = int.tryParse(req.params['id'] ?? '');
      if (userId == null) return {'error': 'Неверный ID пользователя'};

      print('✅ GET /api/users/$userId/orders');
      try {
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
      } catch (e) {
        return {'error': 'Ошибка БД: $e'};
      }
    });

    // 6. JSON тест
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

    // 🚀 Запускаем сервер
    final port = 8080;
    final server = await app.listen(port, '0.0.0.0');

    print('\n' + '='*50);
    print('🎉 СЕРВЕР ЗАПУЩЕН!');
    print('='*50);
    print('📍 Локальный адрес: http://localhost:$port');
    print('📍 Внешний адрес:   http://212.193.63.116:$port');
    print('📁 База данных:     $dbPath');
    print('💻 Платформа:       ${Platform.operatingSystem}');
    print('📡 API endpoints:');
    print('   - GET /appleserver');
    print('   - GET /api/users');
    print('   - GET /api/users/:id');
    print('   - GET /api/orders');
    print('   - GET /api/users/:id/orders');
    print('   - GET /appleserver/json');
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
    exit(1);
  }
}
