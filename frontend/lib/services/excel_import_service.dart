// ============================================================================
// СЕРВИС: ExcelImportService - парсинг и обработка файлов Excel
// ============================================================================
// Назначение: Загружает .xlsx файлы, парсит их, валидирует данные
// Используется: На клиенте для обработки файлов перед отправкой на сервер
// ✅ ИСПОЛЬЗУЕТ: spreadsheet_decoder - автоматически вычисляет формулы Excel!

import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import '../models/import_row_model.dart';
import '../models/column_mapping_model.dart';
// ✅ ВАЖНО: НЕ импортируем dart:io (не работает на Web)

class ExcelImportService {
  
  // =========================================================================
  // НОВЫЙ МЕТОД: Анализ структуры Excel файла (автоопределение колонок)
  // =========================================================================
  // fileBytes - байты файла Excel
  // Возвращает: ColumnMapping с автоматически определёнными индексами колонок
  // Назначение: Анализирует заголовки и данные для поиска колонок ФИО и Суммы
  // Используется: ПЕРЕД парсингом для настройки маппинга (как в Salesforce)
  // ✅ ВЫЧИСЛЯЕТ ФОРМУЛЫ АВТОМАТИЧЕСКИ!
  
  static Future<ColumnMapping?> analyzeExcelStructure({
    required List<int> fileBytes,
  }) async {
    print('🔍 ExcelImportService: Анализируем структуру файла...');
    
    try {
      // -----------------------------------------------------------------------
      // Шаг 1: Декодируем Excel файл с помощью spreadsheet_decoder
      // ✅ spreadsheet_decoder автоматически вычисляет формулы!
      // -----------------------------------------------------------------------
      final decoder = SpreadsheetDecoder.decodeBytes(fileBytes);
      final sheet = decoder.tables.keys.first;
      final table = decoder.tables[sheet]!;
      final rows = table.maxRows;
      
      if (rows < 2) {
        print('❌ Недостаточно строк для анализа (минимум 2: заголовок + данные)');
        return null;
      }

      print('✅ Файл открыт: $rows строк');

      // -----------------------------------------------------------------------
      // Шаг 2: Читаем заголовки (первая строка)
      // -----------------------------------------------------------------------
      final headerRow = table.rows[0];
      final List<String> headers = [];
      
      for (var cell in headerRow) {
        final value = cell?.toString() ?? '';
        headers.add(value);
      }
      
      print('📊 Найдено колонок: ${headers.length}');
      if (headers.isNotEmpty) {
        print('📋 Заголовки: ${headers.take(10).join(", ")}${headers.length > 10 ? "..." : ""}');
      }
      
      // -----------------------------------------------------------------------
      // Шаг 3: Пытаемся автоматически найти колонку с ФИО
      // -----------------------------------------------------------------------
      int fullNameIndex = -1;
      
      // Ключевые слова для поиска колонки с ФИО (как в Enterprise ETL)
      final nameKeywords = [
        'фио', 'имя', 'name', 'fullname', 'full name',
        'клиент', 'customer', 'пользователь', 'user',
        'full_name', 'fullname'
      ];
      
      for (int i = 0; i < headers.length; i++) {
        final header = headers[i].toLowerCase().trim();
        if (nameKeywords.any((keyword) => header.contains(keyword))) {
          fullNameIndex = i;
          print('✅ Колонка ФИО найдена автоматически: ${ColumnMapping.getColumnLetter(i)} ("${headers[i]}")');
          break;
        }
      }

      // -----------------------------------------------------------------------
      // Шаг 4: Пытаемся автоматически найти колонку с суммой
      // -----------------------------------------------------------------------
      int amountIndex = -1;
      
      // Ключевые слова для поиска колонки с суммой
      final amountKeywords = [
        'сумма', 'amount', 'sum', 'total', 'цена', 'price',
        'стоимость', 'cost', 'заказ', 'order',
        'order_amount', 'orderamount'
      ];
      
      for (int i = 0; i < headers.length; i++) {
        final header = headers[i].toLowerCase().trim();
        if (amountKeywords.any((keyword) => header.contains(keyword))) {
          amountIndex = i;
          print('✅ Колонка Сумма найдена автоматически: ${ColumnMapping.getColumnLetter(i)} ("${headers[i]}")');
          break;
        }
      }

      // -----------------------------------------------------------------------
      // Шаг 5: Если не нашли по заголовкам, анализируем данные (типы)
      // -----------------------------------------------------------------------
      if (fullNameIndex == -1 || amountIndex == -1) {
        print('⚠️ Автоопределение по заголовкам не удалось, анализируем типы данных...');
        
        // Читаем вторую строку (первая строка данных после заголовка)
        if (rows > 1) {
          final dataRow = table.rows[1];
          
          for (int i = 0; i < dataRow.length; i++) {
            final value = dataRow[i];
            
            // ✅ ИСПРАВЛЕНО: Ищем числовую колонку для суммы (если ещё не нашли)
            if (amountIndex == -1 && value != null) {
              try {
                final numValue = double.parse(value.toString());
                if (numValue > 0) {
                  amountIndex = i;
                  print('✅ Колонка Сумма найдена по типу данных: ${ColumnMapping.getColumnLetter(i)} (числовое значение: $numValue)');
                }
              } catch (_) {
                // Не число, пропускаем
              }
            }
            
            // ✅ ИСПРАВЛЕНО: Ищем текстовую колонку для ФИО (если ещё не нашли)
            if (fullNameIndex == -1 && value != null) {
              final stringValue = value.toString().trim();
              if (stringValue.length > 3) {
                if (double.tryParse(stringValue) == null) {
                  fullNameIndex = i;
                  print('✅ Колонка ФИО найдена по типу данных: ${ColumnMapping.getColumnLetter(i)} (текст: "$stringValue")');
                }
              }
            }
          }
        }
      }

      // -----------------------------------------------------------------------
      // Шаг 6: Если так и не нашли, используем дефолтные значения
      // -----------------------------------------------------------------------
      if (fullNameIndex == -1) {
        fullNameIndex = 1; // Колонка B (по умолчанию)
        print('⚠️ Колонка ФИО не определена, используем дефолт: ${ColumnMapping.getColumnLetter(fullNameIndex)}');
      }
      
      if (amountIndex == -1) {
        amountIndex = 5; // Колонка F (по умолчанию)
        print('⚠️ Колонка Сумма не определена, используем дефолт: ${ColumnMapping.getColumnLetter(amountIndex)}');
      }

      // -----------------------------------------------------------------------
      // Шаг 7: Создаём список всех доступных колонок для UI
      // -----------------------------------------------------------------------
      final availableColumns = List.generate(
        headers.length,
        (i) {
          final letter = ColumnMapping.getColumnLetter(i);
          final header = headers[i].trim();
          return header.isEmpty 
              ? '$letter - Колонка ${i + 1}' 
              : '$letter - $header';
        },
      );

      print('📋 Доступные колонки для выбора: ${availableColumns.take(5).join(", ")}${availableColumns.length > 5 ? "..." : ""}');

      // -----------------------------------------------------------------------
// -----------------------------------------------------------------------
// Шаг 8: Создаём превью первой строки данных (для UI)
// ✅ УЛУЧШЕННАЯ ФИЛЬТРАЦИЯ служебных строк + ПРЕВЬЮ
// -----------------------------------------------------------------------
Map<String, String>? previewData;

// ✅ ИСПРАВЛЕНО: Ищем первую строку с РЕАЛЬНЫМИ данными
int previewRowIndex = -1;
for (int i = 1; i < rows; i++) {
  final testRow = table.rows[i];
  
  if (fullNameIndex >= 0 && fullNameIndex < testRow.length) {
    final fullNameValue = testRow[fullNameIndex]?.toString() ?? '';
    
    // ✅ УЛУЧШЕННАЯ ПРОВЕРКА: Это НЕ служебная строка?
    final isServiceRow = 
        fullNameValue.trim().isEmpty ||
        fullNameValue == '???' ||
        fullNameValue.toLowerCase().contains('параметр') ||
        fullNameValue.toLowerCase().contains('заголовок') ||
        fullNameValue.toLowerCase().contains('full_name') ||
        fullNameValue.toLowerCase().contains('комментарий') ||
        fullNameValue.toLowerCase().contains('заказ, комментарий') ||
        fullNameValue.toLowerCase() == 'заказ' ||
        fullNameValue.trim().length <= 3 ||
        double.tryParse(fullNameValue) != null;
    
    if (!isServiceRow) {
      // ✅ ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА: Есть ли сумма в этой строке?
      if (amountIndex >= 0 && amountIndex < testRow.length) {
        final amountValue = testRow[amountIndex]?.toString() ?? '';
        
        try {
          final amount = double.parse(amountValue);
          if (amount > 0) {
            previewRowIndex = i;
            print('✅ Найдена первая строка с данными: строка ${i + 1} (индекс $i)');
            print('   ФИО: "$fullNameValue" | Сумма: $amount₽');
            break;
          }
        } catch (_) {
          continue;
        }
      }
    }
  }
}

// ✅ ВОССТАНОВЛЕНО: Создание превью данных!
if (previewRowIndex >= 0) {
  final dataRow = table.rows[previewRowIndex];
  previewData = {};
  
  for (int i = 0; i < dataRow.length && i < headers.length; i++) {
    final cellValue = dataRow[i];
    
    // ✅ spreadsheet_decoder УЖЕ вычислил формулу!
    final value = cellValue?.toString() ?? '';
    
    final columnLetter = ColumnMapping.getColumnLetter(i);
    previewData[columnLetter] = value.isEmpty ? '(пусто)' : value;
  }

  print('✅ Превью данных создано для ${previewData.length} колонок из строки ${previewRowIndex + 1}');
} else {
  print('⚠️ Не удалось найти строку с данными для превью');
}

// -----------------------------------------------------------------------
// Шаг 8-1: Определяем строку начала данных
// -----------------------------------------------------------------------
int dataStartRow = previewRowIndex >= 0 ? previewRowIndex : 1;
print('✅ Данные начинаются со строки ${dataStartRow + 1} (индекс $dataStartRow)');

      
      // -----------------------------------------------------------------------
      // Шаг 9: Возвращаем результат анализа
      // -----------------------------------------------------------------------
      final mapping = ColumnMapping(
        fullNameColumnIndex: fullNameIndex,
        orderAmountColumnIndex: amountIndex,
        availableColumns: availableColumns,
        previewData: previewData,
        dataStartRowIndex: dataStartRow,
      );
      
      print('✅ Анализ завершён: $mapping');
      
      return mapping;
      
    } catch (e, stackTrace) {
      print('❌ ExcelImportService analyzeExcelStructure ERROR: $e');
      print('❌ StackTrace: $stackTrace');
      return null;
    }
  }

  // =========================================================================
  // ОБНОВЛЁННЫЙ МЕТОД: Загрузить и распарсить Excel файл С МАППИНГОМ
  // ✅ ИСПОЛЬЗУЕТ spreadsheet_decoder - автоматически вычисляет формулы!
  // =========================================================================
  // fileBytes - байты файла (ОБЯЗАТЕЛЬНО на Web)
  // columnMapping - настройки маппинга колонок
  // Возвращает: List<ImportRow> с данными из Excel
  
  static Future<List<ImportRow>> parseExcelFile({
  required List<int>? fileBytes,
  ColumnMapping? columnMapping,
  int dataStartRowIndex = 1, // ← Дефолт (если маппинга нет)
}) async {
  print('📥 ExcelImportService: Начинаем парсинг файла');
  
  try {
    // Валидация
    if (fileBytes == null) {
      throw Exception('fileBytes не предоставлены! На Web необходимо передать байты файла.');
    }

    final decoder = SpreadsheetDecoder.decodeBytes(fileBytes);
    print('✅ Файл открыт успешно');
    
    final sheet = decoder.tables.keys.first;
    final table = decoder.tables[sheet]!;
    final rows = table.maxRows;
    
    print('📊 Листов в файле: ${decoder.tables.length}');
    print('📊 Строк в листе "$sheet": $rows');
    
    // ✅ ИСПРАВЛЕНО: Используем dataStartRowIndex из маппинга!
    final fullNameIndex = columnMapping?.fullNameColumnIndex ?? 1;
    final amountIndex = columnMapping?.orderAmountColumnIndex ?? 5;
    
    // ✅ КРИТИЧЕСКИ ВАЖНО: Берём начало данных из маппинга!
    final startRow = columnMapping?.dataStartRowIndex ?? dataStartRowIndex;
    
    print('✅ Используем маппинг колонок:');
    print('   ФИО: колонка ${ColumnMapping.getColumnLetter(fullNameIndex)} (индекс $fullNameIndex)');
    print('   Сумма: колонка ${ColumnMapping.getColumnLetter(amountIndex)} (индекс $amountIndex)');
    print('   Начало данных: строка ${startRow + 1} (индекс $startRow)'); // ← ДОБАВЛЕНО!
    
    final importRows = <ImportRow>[];
    
    // ✅ ИСПРАВЛЕНО: Используем startRow вместо dataStartRowIndex!
    for (int i = startRow; i < rows; i++) {
      print('🔍 Обрабатываем строку $i');
      
      final row = table.rows[i];
      
      final fullNameCell = row.length > fullNameIndex ? row[fullNameIndex] : null;
      final orderAmountCell = row.length > amountIndex ? row[amountIndex] : null;
      
      String? error;
      
      final fullNameValue = fullNameCell?.toString() ?? '';
      
      if (fullNameValue.trim().isEmpty) {
        error = 'ФИО пустое';
        print('❌ Строка $i: ошибка - ФИО пустое');
      }
      
      if (orderAmountCell == null) {
        error = 'Сумма пустая';
        print('❌ Строка $i: ошибка - Сумма пустая');
      }
      
      double? amount;
      if (orderAmountCell != null && error == null) {
        try {
          amount = double.parse(orderAmountCell.toString());
          
          if (amount <= 0) {
            error = 'Сумма должна быть больше 0';
            print('❌ Строка $i: ошибка - Сумма <= 0');
          }
        } catch (e) {
          error = 'Некорректная сумма (не число)';
          print('❌ Строка $i: ошибка - Не число: $e');
        }
      }
      
      if (error == null && amount != null) {
        final importRow = ImportRow(
          rowNumber: i + 1,
          fullName: fullNameValue.trim(),
          orderAmount: amount,
          isDuplicate: false,
          error: null,
        );
        
        importRows.add(importRow);
        print('✅ Строка $i: успешно добавлена - ${importRow.fullName} (${importRow.orderAmount}₽)');
      } else {
        final importRow = ImportRow(
          rowNumber: i + 1,
          fullName: fullNameValue.isNotEmpty ? fullNameValue : '???',
          orderAmount: amount ?? 0,
          isDuplicate: false,
          error: error,
        );
        
        importRows.add(importRow);
      }
    }
    
    print('✅ ExcelImportService: Парсинг завершён');
    print('📊 Всего строк: ${importRows.length}');
    print('📊 Валидных строк: ${importRows.where((r) => r.error == null).length}');
    print('📊 Строк с ошибками: ${importRows.where((r) => r.error != null).length}');
    
    return importRows;
    
  } catch (e, stackTrace) {
    print('❌ ExcelImportService parseExcelFile ERROR: $e');
    print('❌ StackTrace: $stackTrace');
    throw Exception('Ошибка парсинга файла: $e');
  }
}

  
  // =========================================================================
  // МЕТОД: Найти дубли в загруженных данных (БЕЗ ИЗМЕНЕНИЙ)
  // =========================================================================
  // rows - список строк из Excel
  // Возвращает: Map<String, List<ImportRow>> с дублями
  // Ключ Map - это уникальная комбинация "ФИО|Сумма"
  // Значение - список строк с одинаковыми данными
  
  static Map<String, List<ImportRow>> findDuplicates(List<ImportRow> rows) {
    print('🔍 ExcelImportService: Поиск дублей');
    
    Map<String, List<ImportRow>> duplicates = {};
    Map<String, ImportRow> seen = {};
    
    for (var row in rows) {
      if (row.error != null) continue;
      
      String key = '${row.fullName}|${row.orderAmount}';
      
      if (seen.containsKey(key)) {
        if (!duplicates.containsKey(key)) {
          duplicates[key] = [seen[key]!];
        }
        duplicates[key]!.add(row);
        print('⚠️ Найден дубль: $key (строки ${seen[key]!.rowNumber} и ${row.rowNumber})');
      } else {
        seen[key] = row;
      }
    }
    
    print('✅ Поиск завершён. Найдено дублей: ${duplicates.length} уникальных комбинаций');
    
    if (duplicates.isNotEmpty) {
      print('📋 Детали дублей:');
      duplicates.forEach((key, dupList) {
        print('   "$key" - найдено ${dupList.length} копий (строки: ${dupList.map((d) => d.rowNumber).join(", ")})');
      });
    }
    
    return duplicates;
  }
}
