// ============================================================================
// MODEL: ImportRow - модель строки из Excel файла
// ============================================================================
// Назначение: Представление одной строки данных после парсинга Excel
// Используется: В ImportProvider для хранения списка импортированных данных
// Паттерн: Immutable Data Model с mutable полем isSelected

class ImportRow {
  // =========================================================================
  // ПОЛЯ МОДЕЛИ
  // =========================================================================

  final int rowNumber; // Номер строки в Excel (для отладки)
  final String fullName; // ФИО из колонки B
  final double orderAmount; // Сумма заказа из колонки F/O
  final bool
      isDuplicate; // ✅ Флаг дубля (теперь final - изменяется через copyWith)
  final String? error; // Сообщение об ошибке валидации (null = валидная)

  // =========================================================================
  // КОНСТРУКТОР
  // =========================================================================

  ImportRow({
    required this.rowNumber,
    required this.fullName,
    required this.orderAmount,
    this.isDuplicate = false, // По умолчанию не дубль
    this.error,
  });

  // =========================================================================
  // ГЕТТЕР: Проверка валидности (нет ошибок)
  // =========================================================================

  bool get isValid => error == null;

  // =========================================================================
  // ✅ НОВЫЙ МЕТОД: copyWith() - создание копии с изменёнными полями
  // =========================================================================
  // Назначение: Позволяет изменять final поля (например, isDuplicate)
  // Использование: row.copyWith(isDuplicate: true)

  ImportRow copyWith({
    int? rowNumber,
    String? fullName,
    double? orderAmount,
    bool? isDuplicate, // ✅ Теперь можем изменять через copyWith
    String? error,
  }) {
    return ImportRow(
      rowNumber: rowNumber ?? this.rowNumber,
      fullName: fullName ?? this.fullName,
      orderAmount: orderAmount ?? this.orderAmount,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      error: error ?? this.error,
    );
  }

  // =========================================================================
  // МЕТОД: toString() - для отладки
  // =========================================================================

  @override
  String toString() {
    return 'ImportRow(row: $rowNumber, name: $fullName, amount: $orderAmount, dup: $isDuplicate, err: $error)';
  }

  // =========================================================================
  // МЕТОД: toJson() - конвертация в JSON для отправки на сервер
  // =========================================================================

  Map<String, dynamic> toJson() {
    return {
      'rowNumber': rowNumber,
      'fullName': fullName,
      'orderAmount': orderAmount,
    };
  }
}
