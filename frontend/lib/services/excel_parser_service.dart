// ============================================================================
// СЕРВИС: ExcelParserService - парсинг Excel файлов
// ============================================================================
// Назначение: Извлечение данных монтажников из Excel файлов
// Использует: spreadsheet_decoder (поддержка кэшированных значений формул)
// Формат: Читает ФИО из колонки "full_name" и сумму из "order_amount"

import 'dart:typed_data'; // Для работы с байтами файла
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart'; // ✅ НОВЫЙ ПАКЕТ

// ============================================================================
// МОДЕЛЬ: ParsedInstallerData - данные одного монтажника
// ============================================================================
class ParsedInstallerData {
  final String fullName;       // ФИО монтажника из колонки full_name
  final double totalAmount;    // Готовая сумма из колонки order_amount
  final int rowNumber;         // Номер строки в Excel (для отладки)

  ParsedInstallerData({
    required this.fullName,
    required this.totalAmount,
    required this.rowNumber,
  });

  // Преобразование в JSON для отправки на сервер
  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'orderAmount': totalAmount,
      };
}

// ============================================================================
// МОДЕЛЬ: ExcelParseResult - результат парсинга всего файла
// ============================================================================
class ExcelParseResult {
  final List<ParsedInstallerData> installers; // Список монтажников
  final List<String> errors;                  // Список ошибок валидации
  final int totalRowsProcessed;               // Всего обработано строк

  ExcelParseResult({
    required this.installers,
    required this.errors,
    required this.totalRowsProcessed,
  });
}

// ============================================================================
// СЕРВИС: ExcelParserService
// ============================================================================
class ExcelParserService {
  // ==========================================================================
  // ОСНОВНОЙ МЕТОД: Парсинг Excel файла
  // ==========================================================================
  // fileBytes - байты Excel файла (.xlsx)
  // Возвращает: ExcelParseResult с данными монтажников и ошибками
  
  Future<ExcelParseResult> parseExcelFile(Uint8List fileBytes) async {
    try {
      print('📂 ExcelParserService: Начинаем парсинг файла...');
      
      // Декодируем Excel файл из байтов
      final decoder = SpreadsheetDecoder.decodeBytes(fileBytes);
      
      // Получаем первый лист (обычно это "Лист1" или "Sheet1")
      final sheetName = decoder.tables.keys.first;
      final sheet = decoder.tables[sheetName];
      
      print('📄 Лист: "$sheetName"');
      print('📏 Размер: ${sheet?.rows.length} строк × ${sheet?.maxCols} колонок');

      // Проверка: лист не должен быть пустым
      if (sheet == null || sheet.rows.isEmpty) {
        return ExcelParseResult(
          installers: [],
          errors: ['Файл пуст или не содержит данных'],
          totalRowsProcessed: 0,
        );
      }

      // Шаг 1: Найти строку с заголовками
      final headerInfo = _findHeaderRow(sheet.rows);
      
      if (headerInfo == null) {
        return ExcelParseResult(
          installers: [],
          errors: ['Не найдены заголовки "full_name" и "order_amount"'],
          totalRowsProcessed: 0,
        );
      }

      final fullNameIndex = headerInfo['fullNameIndex'] as int;
      final orderAmountIndex = headerInfo['orderAmountIndex'] as int;
      final headerRowIndex = headerInfo['headerRowIndex'] as int;

      print('✅ Найдены заголовки:');
      print('   full_name: колонка $fullNameIndex');
      print('   order_amount: колонка $orderAmountIndex');
      print('   Строка заголовков: ${headerRowIndex + 1}');

      // Шаг 2: Парсим данные
      final parseResult = _parseDataRows(
        sheet.rows,
        fullNameIndex,
        orderAmountIndex,
        headerRowIndex,
      );

      return parseResult;
      
    } catch (e, stackTrace) {
      print('❌ Ошибка парсинга: $e');
      print('Stack trace: $stackTrace');
      return ExcelParseResult(
        installers: [],
        errors: ['Ошибка чтения файла: $e'],
        totalRowsProcessed: 0,
      );
    }
  }

  // ==========================================================================
  // МЕТОД: Поиск строки с заголовками
  // ==========================================================================
  // Ищет строку, содержащую "full_name" и "order_amount"
  
  Map<String, dynamic>? _findHeaderRow(List<List<dynamic>> rows) {
    print('🔍 Ищем заголовки в первых 10 строках...');
    
    // Проходим по первым 10 строкам
    for (int i = 0; i < rows.length && i < 10; i++) {
      final row = rows[i];
      
      int? fullNameIndex;
      int? orderAmountIndex;

      // Проверяем каждую ячейку в строке
      for (int j = 0; j < row.length; j++) {
        final cellValue = row[j]?.toString().toLowerCase() ?? '';
        
        // Ищем колонку "full_name" или "фио"
        if (cellValue.contains('full_name') || cellValue.contains('фио')) {
          fullNameIndex = j;
          print('   Найдена колонка full_name: индекс $j (строка ${i + 1})');
        }
        
        // Ищем колонку "order_amount"
        if (cellValue.contains('order_amount')) {
          orderAmountIndex = j;
          print('   Найдена колонка order_amount: индекс $j (строка ${i + 1})');
        }
      }

      // Если обе колонки найдены - возвращаем результат
      if (fullNameIndex != null && orderAmountIndex != null) {
        return {
          'fullNameIndex': fullNameIndex,
          'orderAmountIndex': orderAmountIndex,
          'headerRowIndex': i,
        };
      }
    }

    print('❌ Заголовки не найдены!');
    return null;
  }

  // ==========================================================================
  // МЕТОД: Проверка, является ли строка ФИО монтажника
  // ==========================================================================
  // Логика: ФИО заполнено, НЕ содержит служебных слов/адресов
  
  bool _isInstallerRow(String fullNameCell) {
    if (fullNameCell.trim().isEmpty) {
      return false;
    }

    // Список ключевых слов, которые указывают на НЕ-монтажника
    final excludeKeywords = [
      'заказ',          // "Заказ клиента..."
      'параметры',      // "Параметры:"
      'итого',          // "Итого"
      'комментарий',    // "Заказ, Комментарий"
      'период',         // "Период:"
      'процент',        // "Процент..."
      'москва',         // ✅ Адреса
      'улица',          // ✅
      'деревня',        // ✅
      'город',          // ✅
      'область',        // ✅
      'го',             // ✅ (городской округ)
      'ул.',            // ✅ (сокращение)
      'д.',             // ✅ (дом)
      'кв.',            // ✅ (квартира)
      'сокол',          // ✅ (СТ Сокол)
      'снт',            // ✅ (садовое товарищество)
      'жк',             // ✅ (жилой комплекс)
    ];

    final lowerCase = fullNameCell.toLowerCase();
    for (final keyword in excludeKeywords) {
      if (lowerCase.contains(keyword)) {
        return false; // Это НЕ монтажник
      }
    }

    // ✅ ПРОВЕРКА 1: ФИО должно содержать минимум 2 слова (Фамилия Имя)
    final words = fullNameCell.trim().split(RegExp(r'\s+'));
    if (words.length < 2) {
      return false;
    }

    // ✅ ПРОВЕРКА 2: Не должно быть запятых (признак адреса)
    if (fullNameCell.contains(',')) {
      return false;
    }

    // ✅ ПРОВЕРКА 3: Не должно быть цифр (признак адреса)
    if (fullNameCell.contains(RegExp(r'\d'))) {
      return false;
    }

    // ✅ Если дошли сюда - это ФИО монтажника
    return true;
  }

  // ==========================================================================
  // МЕТОД: Парсинг строк с данными
  // ==========================================================================
  // ✅ КЛЮЧЕВОЕ ОТЛИЧИЕ: spreadsheet_decoder автоматически читает
  //    кэшированные значения формул (если Excel сохранил результат)
  
  ExcelParseResult _parseDataRows(
    List<List<dynamic>> rows,
    int fullNameIndex,
    int orderAmountIndex,
    int headerRowIndex,
  ) {
    final List<ParsedInstallerData> installers = [];
    final List<String> errors = [];
    int totalRowsProcessed = 0;

    print('');
    print('🔍 Начинаем парсинг данных...');
    print('   Начинаем со строки: ${headerRowIndex + 3} (пропускаем заголовки)');

    // Начинаем со строки после заголовков (пропускаем строку "Заказ, Комментарий")
    for (int i = headerRowIndex + 2; i < rows.length; i++) {
      final row = rows[i];
      
      // Защита от выхода за границы массива
      if (fullNameIndex >= row.length) {
        continue;
      }
      
      // Извлекаем значения
      final fullNameCell = row[fullNameIndex]?.toString().trim() ?? '';
      final orderAmountCell = orderAmountIndex < row.length 
          ? row[orderAmountIndex] 
          : null;

      // Пропускаем полностью пустые строки
      if (fullNameCell.isEmpty && orderAmountCell == null) {
        continue;
      }

      print('');
      print('  Строка ${i + 1}:');
      print('    ФИО: "$fullNameCell"');
      print('    Сумма: $orderAmountCell (тип: ${orderAmountCell.runtimeType})');

      // ✅ Проверяем, является ли это строкой монтажника
      if (_isInstallerRow(fullNameCell)) {
        
        // ✅ КЛЮЧЕВОЕ ОТЛИЧИЕ: spreadsheet_decoder автоматически возвращает
        //    КЭШИРОВАННОЕ ЗНАЧЕНИЕ формулы (если оно есть в файле)
        final amount = _parseAmount(orderAmountCell);
        
        if (amount != null && amount > 0) {
          // Добавляем монтажника
          installers.add(ParsedInstallerData(
            fullName: fullNameCell,
            totalAmount: amount,
            rowNumber: i + 1,
          ));
          
          totalRowsProcessed++;
          print('    ✅ Найден монтажник: $fullNameCell → ${amount.toStringAsFixed(2)} ₽');
          
        } else if (amount != null && amount <= 0) {
          errors.add('Строка ${i + 1}: Сумма должна быть > 0 (ФИО: "$fullNameCell", сумма: $amount)');
          print('    ⚠️ Ошибка: сумма <= 0');
          
        } else {
          errors.add('Строка ${i + 1}: Не удалось распарсить сумму для "$fullNameCell" (значение: $orderAmountCell)');
          print('    ⚠️ Ошибка: не удалось распарсить сумму');
        }
      } else {
        print('    ⏭️ Пропуск: НЕ строка монтажника');
      }
    }

    print('');
    print('✅ Парсинг завершен:');
    print('   Найдено монтажников: ${installers.length}');
    print('   Ошибок: ${errors.length}');
    print('   Обработано строк: $totalRowsProcessed');

    return ExcelParseResult(
      installers: installers,
      errors: errors,
      totalRowsProcessed: totalRowsProcessed,
    );
  }

  // ==========================================================================
  // МЕТОД: Парсинг суммы из ячейки
  // ==========================================================================
  // ✅ КЛЮЧЕВОЕ ПРЕИМУЩЕСТВО: spreadsheet_decoder автоматически возвращает
  //    кэшированное значение формулы (число), а НЕ саму формулу (текст)
  
  double? _parseAmount(dynamic value) {
    if (value == null) {
      return null;
    }

    // ✅ ГЛАВНОЕ ОТЛИЧИЕ: spreadsheet_decoder возвращает РЕЗУЛЬТАТ формулы,
    //    а не саму формулу. То есть вместо "SUM(O9:O19)" мы получим 40632.3
    
    // Если уже число
    if (value is num) {
      return value.toDouble();
    }
    
    // Если текст - пытаемся распарсить
    if (value is String) {
      // Убираем пробелы и запятые (формат "40 632,30" -> "40632.30")
      final cleaned = value.replaceAll(' ', '').replaceAll(',', '.');
      return double.tryParse(cleaned);
    }
    
    return null;
  }
}
