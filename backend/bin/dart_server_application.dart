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

  // 🔧 ПУТЬ К БАЗЕ ДАННЫХ ДЛЯ СЕРВЕРА
  final dbPath = '/var/www/myapp/database/andrey_payments.db';
  print('🌐 РЕЖИМ: СЕРВЕР (Ubuntu)');
  print('📁 Путь к базе данных: $dbPath');
  
  try {
    // Проверяем существует ли файл
    final dbFile = File(dbPath);
    if (!dbFile.existsSync()) {
      print('❌ Файл базы не найден: $dbPath');
      print('⚠️  Создаю пустую базу...');
    }
    
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
      print('👥 Пользователей: $usersCount, Заказов: $ordersCount');
    } catch (e) {
      print('⚠️  Ошибка при проверке данных: $e');
      print('ℹ️  Возможно таблицы пусты или не созданы');
    }

    // 1. Тестовый эндпоинт
    app.get('/appleserver', (req, res) {
      print('✅ GET /appleserver');
      return '✅ Сервер работает! База: ${dbPath.split('/').last}';
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

    // 3. Все заказы
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

    // 4. JSON тест
    app.get('/appleserver/json', (req, res) {
      print('✅ GET /appleserver/json');
      return {
        'message': 'hello world',
        'status': 'success',
        'timestamp': DateTime.now().toIso8601String(),
        'server': 'Apple Server',
        'database': dbPath.split('/').last,
        'platform': 'Linux Server',
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
    print('📡 API endpoints:');
    print('   - GET /appleserver');
    print('   - GET /api/users');
    print('   - GET /api/orders');
    print('   - GET /appleserver/json');
    print('='*50);
    print('⏹️  Для остановки: Ctrl+C');
    print('='*50);

    await server;
    
  } catch (e, stackTrace) {
    print('\n❌❌❌ ОШИБКА ❌❌❌');
    print('Ошибка: $e');
    print('StackTrace: $stackTrace');
    print('\n🔧 РЕШЕНИЕ:');
    print('1. Проверьте путь к БД: $dbPath');
    print('2. Проверьте права: chmod 644 $dbPath');
    print('3. Установите зависимости: dart pub get');
    exit(1);
  }
}
