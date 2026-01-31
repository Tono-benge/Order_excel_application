// ============================================================================
// МОДЕЛЬ ДАННЫХ: ЗАКАЗ (Order Model)
// ============================================================================
// Назначение: Представляет один заказ из базы данных (Table2)
// Соответствие БД: orderId → order_ID, orderAmount → order_amount,
//                  userForeignKey → UserID_Foreign_Key
// ============================================================================

class OrderModel {
  // -------------------------------------------------------------------------
  // ПОЛЯ МОДЕЛИ (Properties)
  // -------------------------------------------------------------------------
  
  // ID заказа (первичный ключ из Table2)
  // Генерируется автоматически SQLite через AUTOINCREMENT
  final int orderId;
  
  // Сумма заказа в рублях (например: 1500.0, 2500.50)
  // REAL в SQLite → double в Dart
  final double orderAmount;
  
  // ID пользователя - внешний ключ на Table1
  // Связывает заказ с пользователем
  final int userForeignKey;
  
  // ✅ ВАЖНО: Имя пользователя - ОПЦИОНАЛЬНОЕ поле (может быть null)
  // Приходит только когда сервер делает LEFT JOIN с Table1
  // При создании заказа сервер НЕ возвращает это поле!
  // String? - знак вопроса означает что может быть null
  final String? userName;

  // -------------------------------------------------------------------------
  // КОНСТРУКТОР
  // -------------------------------------------------------------------------
  // required - обязательные параметры
  // this.userName - опциональный (может не передаваться)
  
  OrderModel({
    required this.orderId,
    required this.orderAmount,
    required this.userForeignKey,
    this.userName, // ✅ БЕЗ required - может быть null
  });

  // -------------------------------------------------------------------------
  // МЕТОД: Создать модель из JSON (Десериализация)
  // -------------------------------------------------------------------------
  // Преобразует ответ сервера (JSON) в объект OrderModel
  // json - Map с данными от сервера
  
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      // Парсинг orderId - обрабатываем разные варианты названий полей
      // Сервер может вернуть "orderID", "order_ID" или "orderId"
      orderId: json['orderID'] ?? 
               json['order_ID'] ?? 
               json['orderId'] ?? 
               0, // По умолчанию 0 если поля нет
      
      // Парсинг orderAmount - обрабатываем разные типы
      // Может прийти как double, int или String
      orderAmount: _parseDouble(
        json['orderamount'] ?? 
        json['order_amount'] ?? 
        json['orderAmount'] ?? 
        0.0
      ),
      
      // Парсинг userForeignKey
      userForeignKey: json['UserIDForeignKey'] ?? 
                      json['UserID_Foreign_Key'] ?? 
                      json['userforeignkey'] ?? 
                      0,
      
      // ✅ userName может быть null - это нормально!
      // Используем оператор as String? для безопасного приведения типа
      userName: json['fullname'] as String? ?? 
                json['full_name'] as String? ?? 
                json['userName'] as String?,
    );
  }

  // -------------------------------------------------------------------------
  // ВСПОМОГАТЕЛЬНЫЙ МЕТОД: Безопасное преобразование в double
  // -------------------------------------------------------------------------
  // value - может быть double, int, String или null
  // Возвращает double или 0.0 при ошибке
  
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) {
      return value; // Уже double - возвращаем как есть
    }
    
    if (value is int) {
      return value.toDouble(); // Преобразуем int → double
    }
    
    if (value is String) {
      // Пытаемся распарсить строку → double
      return double.tryParse(value) ?? 0.0;
    }
    
    return 0.0; // Неизвестный тип - возвращаем 0.0
  }

  // -------------------------------------------------------------------------
  // МЕТОД: Преобразовать модель в JSON (Сериализация)
  // -------------------------------------------------------------------------
  // Используется при отправке данных на сервер (например при создании)
  
  Map<String, dynamic> toJson() {
    return {
      'orderID': orderId,
      'orderamount': orderAmount,
      'UserIDForeignKey': userForeignKey,
      // ✅ userName не отправляем - сервер его не принимает при создании
      // Он формируется на сервере через JOIN
    };
  }

  // -------------------------------------------------------------------------
  // МЕТОД: Строковое представление для отладки
  // -------------------------------------------------------------------------
  // Вызывается когда делаешь print(orderModel)
  
  @override
  String toString() {
    return 'OrderModel(orderId: $orderId, orderAmount: $orderAmount, '
           'userForeignKey: $userForeignKey, userName: $userName)';
  }

  // -------------------------------------------------------------------------
  // МЕТОД: Копирование с изменением полей
  // -------------------------------------------------------------------------
  // Создаёт копию объекта с возможностью изменить некоторые поля
  // Полезно для обновления данных без мутации оригинального объекта
  
  OrderModel copyWith({
    int? orderId,
    double? orderAmount,
    int? userForeignKey,
    String? userName,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      orderAmount: orderAmount ?? this.orderAmount,
      userForeignKey: userForeignKey ?? this.userForeignKey,
      userName: userName ?? this.userName,
    );
  }
}
