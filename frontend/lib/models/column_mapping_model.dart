// =========================================================================
// МОДЕЛЬ: Маппинг колонок Excel → Поля базы данных
// =========================================================================
// Используется для сохранения соответствия между колонками Excel
// и полями в базе данных (как в Salesforce, SAP)

class ColumnMapping {
  // -----------------------------------------------------------------------
  // ОСНОВНЫЕ ПОЛЯ
  // -----------------------------------------------------------------------
  
  /// Индекс колонки с ФИО в Excel (0 = A, 1 = B, 2 = C...)
  final int fullNameColumnIndex;
  
  /// Индекс колонки с суммой заказа в Excel
  final int orderAmountColumnIndex;
  
  /// Название шаблона маппинга (для сохранения/загрузки)
  final String? templateName;
  
  /// Метки колонок из Excel (для отображения: "A", "B", "C"...)
  final List<String> availableColumns;
  
  /// Превью первой строки данных (для подтверждения)
  final Map<String, String>? previewData;
  final int dataStartRowIndex;
  // -----------------------------------------------------------------------
  // КОНСТРУКТОР
  // -----------------------------------------------------------------------
  
  const ColumnMapping({
    required this.fullNameColumnIndex,
    required this.orderAmountColumnIndex,
    this.templateName,
    this.availableColumns = const [],
    this.previewData,
  this.dataStartRowIndex = 1,
  });

  // -----------------------------------------------------------------------
  // МЕТОДЫ: Копирование с изменениями
  // -----------------------------------------------------------------------
  
  /// Создаёт копию объекта с изменёнными полями
  ColumnMapping copyWith({
    int? fullNameColumnIndex,
    int? orderAmountColumnIndex,
    String? templateName,
    List<String>? availableColumns,
    Map<String, String>? previewData,
  }) {
    return ColumnMapping(
      fullNameColumnIndex: fullNameColumnIndex ?? this.fullNameColumnIndex,
      orderAmountColumnIndex: orderAmountColumnIndex ?? this.orderAmountColumnIndex,
      templateName: templateName ?? this.templateName,
      availableColumns: availableColumns ?? this.availableColumns,
      previewData: previewData ?? this.previewData,
    );
  }

  // -----------------------------------------------------------------------
  // МЕТОДЫ: Сериализация (JSON)
  // -----------------------------------------------------------------------
  
  /// Конвертация в JSON для сохранения в SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'fullNameColumnIndex': fullNameColumnIndex,
      'orderAmountColumnIndex': orderAmountColumnIndex,
      'templateName': templateName,
      'availableColumns': availableColumns,
      'previewData': previewData,
    };
  }

  /// Создание объекта из JSON
  factory ColumnMapping.fromJson(Map<String, dynamic> json) {
    return ColumnMapping(
      fullNameColumnIndex: json['fullNameColumnIndex'] as int,
      orderAmountColumnIndex: json['orderAmountColumnIndex'] as int,
      templateName: json['templateName'] as String?,
      availableColumns: (json['availableColumns'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      previewData: (json['previewData'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as String)),
    );
  }

  // -----------------------------------------------------------------------
  // МЕТОДЫ: Валидация
  // -----------------------------------------------------------------------
  
  /// Проверяет что индексы колонок валидны
  bool isValid() {
    return fullNameColumnIndex >= 0 && 
           orderAmountColumnIndex >= 0 &&
           fullNameColumnIndex != orderAmountColumnIndex;
  }

  /// Получить букву колонки по индексу (0 → "A", 1 → "B"...)
  static String getColumnLetter(int index) {
    if (index < 0) return '?';
    if (index < 26) {
      return String.fromCharCode(65 + index); // A-Z
    }
    // Для колонок AA, AB и т.д.
    return String.fromCharCode(65 + (index ~/ 26) - 1) +
           String.fromCharCode(65 + (index % 26));
  }

  // -----------------------------------------------------------------------
  // ПЕРЕОПРЕДЕЛЕНИЕ: toString для отладки
  // -----------------------------------------------------------------------
  
  @override
  String toString() {
    return 'ColumnMapping(ФИО: ${getColumnLetter(fullNameColumnIndex)}, '
           'Сумма: ${getColumnLetter(orderAmountColumnIndex)})';
  }
}
