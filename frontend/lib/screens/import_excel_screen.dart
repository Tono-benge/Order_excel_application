// Экран для импорта данных из Excel файла
// Показывает превью данных перед загрузкой в БД

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Для выбора файлов
import '../services/excel_parser_service.dart'; // Наш парсер
import '../services/api_service.dart'; // Для отправки данных на сервер

class ImportExcelScreen extends StatefulWidget {
  const ImportExcelScreen({Key? key}) : super(key: key);

  @override
  State<ImportExcelScreen> createState() => _ImportExcelScreenState();
}

class _ImportExcelScreenState extends State<ImportExcelScreen> {
  // Сервисы
  final ExcelParserService _parserService = ExcelParserService();
  final ApiService _apiService = ApiService();

  // Состояние
  ExcelParseResult? _parseResult; // Результат парсинга
  bool _isLoading = false; // Индикатор загрузки
  bool _isUploading = false; // Индикатор отправки на сервер

  // Метод для выбора и парсинга Excel файла
  Future<void> _pickAndParseFile() async {
    try {
      // Шаг 1: Открываем диалог выбора файла
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'], // Только Excel файлы
        withData: true, // Загружаем содержимое файла
      );

      // Проверка: файл выбран
      if (result == null || result.files.isEmpty) {
        return;
      }

      final fileBytes = result.files.first.bytes;
      
      // Проверка: файл содержит данные
      if (fileBytes == null) {
        _showError('Не удалось прочитать файл');
        return;
      }

      // Шаг 2: Показываем индикатор загрузки
      setState(() {
        _isLoading = true;
        _parseResult = null;
      });

      // Шаг 3: Парсим Excel файл
      final parseResult = await _parserService.parseExcelFile(fileBytes);

      // Шаг 4: Показываем результаты
      setState(() {
        _parseResult = parseResult;
        _isLoading = false;
      });

      // Если есть ошибки - показываем диалог
      if (parseResult.errors.isNotEmpty) {
        _showErrorsDialog(parseResult.errors);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Ошибка при обработке файла: $e');
    }
  }

  // Метод для отправки данных на сервер
  Future<void> _uploadToServer() async {
    if (_parseResult == null || _parseResult!.installers.isEmpty) {
      _showError('Нет данных для загрузки');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Формируем JSON для отправки
      final data = {
        'installers': _parseResult!.installers.map((i) => i.toJson()).toList(),
      };

      // Отправляем POST запрос на /api/orders/import-aggregated
      final response = await _apiService.post('/api/orders/import-aggregated', data);

      // Проверяем ответ сервера
      if (response['status'] == 'success') {
        _showSuccess(
          'Успешно загружено:\n'
          '- Пользователей создано: ${response['usersCreated']}\n'
          '- Заказов добавлено: ${response['ordersCreated']}',
        );
        
        // Очищаем превью
        setState(() {
          _parseResult = null;
        });
      } else {
        _showError('Ошибка сервера: ${response['message']}');
      }
    } catch (e) {
      _showError('Ошибка отправки данных: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // UI методы для показа диалогов
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Успешно'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  void _showErrorsDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Предупреждения валидации'),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: errors.length,
            itemBuilder: (context, index) => ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: Text(errors[index]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Импорт из Excel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Кнопка выбора файла
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndParseFile,
              icon: const Icon(Icons.file_upload),
              label: const Text('Выбрать Excel файл'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 20),

            // Индикатор загрузки
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Обработка файла...'),
                  ],
                ),
              ),

            // Превью данных
            if (_parseResult != null && !_isLoading)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Заголовок с информацией
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Найдено монтажников: ${_parseResult!.installers.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Обработано строк: ${_parseResult!.totalRowsProcessed}'),
                            if (_parseResult!.errors.isNotEmpty)
                              Text(
                                'Предупреждений: ${_parseResult!.errors.length}',
                                style: const TextStyle(color: Colors.orange),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 10),

                    // Таблица с превью
                    Expanded(
                      child: Card(
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('ФИО монтажника')),
                              DataColumn(label: Text('Общая сумма')),
                              DataColumn(label: Text('Кол-во заказов')),
                            ],
                            rows: _parseResult!.installers.map((installer) {
                              return DataRow(cells: [
                                DataCell(Text(installer.fullName)),
                                DataCell(Text(
                                  '${installer.totalAmount.toStringAsFixed(2)} ₽',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                )),
                                DataCell(Text('${installer.rowNumber}')),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Кнопка загрузки в БД
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _uploadToServer,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: Text(_isUploading ? 'Загрузка...' : 'Загрузить в БД'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
