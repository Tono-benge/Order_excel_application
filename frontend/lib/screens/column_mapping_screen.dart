// =========================================================================
// ЭКРАН: Настройка маппинга колонок Excel
// =========================================================================
// Позволяет пользователю выбрать какие колонки содержат
// ФИО и Сумму заказа (как в Salesforce Data Import)

import 'package:flutter/material.dart';
import '/models/column_mapping_model.dart';

class ColumnMappingScreen extends StatefulWidget {
  final ColumnMapping initialMapping;
  final List<int> fileBytes;

  const ColumnMappingScreen({
    Key? key,
    required this.initialMapping,
    required this.fileBytes,
  }) : super(key: key);

  @override
  State<ColumnMappingScreen> createState() => _ColumnMappingScreenState();
}

class _ColumnMappingScreenState extends State<ColumnMappingScreen> {
  late ColumnMapping currentMapping;

  @override
  void initState() {
    super.initState();
    currentMapping = widget.initialMapping;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // -----------------------------------------------------------------------
      // APP BAR
      // -----------------------------------------------------------------------
      appBar: AppBar(
        title: const Text('Настройка колонок'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      // -----------------------------------------------------------------------
      // BODY
      // -----------------------------------------------------------------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------------
            // 1. Инструкция
            // -----------------------------------------------------------------
            Card(
              elevation: 2,
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Выберите колонки',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Укажите в каких колонках Excel находятся ФИО пользователя и сумма заказа.',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // 2. Выбор колонки ФИО
            // -----------------------------------------------------------------
            _buildColumnSelector(
              label: 'Колонка "ФИО пользователя"',
              icon: Icons.person,
              currentIndex: currentMapping.fullNameColumnIndex,
              availableColumns: currentMapping.availableColumns,
              onChanged: (newIndex) {
                setState(() {
                  currentMapping = currentMapping.copyWith(
                    fullNameColumnIndex: newIndex,
                  );
                });
              },
            ),

            const SizedBox(height: 20),

            // -----------------------------------------------------------------
            // 3. Выбор колонки Сумма
            // -----------------------------------------------------------------
            _buildColumnSelector(
              label: 'Колонка "Сумма заказа"',
              icon: Icons.currency_ruble_sharp,
              currentIndex: currentMapping.orderAmountColumnIndex,
              availableColumns: currentMapping.availableColumns,
              onChanged: (newIndex) {
                setState(() {
                  currentMapping = currentMapping.copyWith(
                    orderAmountColumnIndex: newIndex,
                  );
                });
              },
            ),

            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // 4. Превью данных
            // -----------------------------------------------------------------
            if (currentMapping.previewData != null) ...[
              const Text(
                'Превью первой строки:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPreviewRow(
                        'ФИО',
                        currentMapping.previewData![
                          ColumnMapping.getColumnLetter(
                            currentMapping.fullNameColumnIndex,
                          )
                        ] ?? '—',
                        Icons.person,
                      ),
                      const Divider(height: 24),
                      _buildPreviewRow(
                        'Сумма',
                        currentMapping.previewData![
                          ColumnMapping.getColumnLetter(
                            currentMapping.orderAmountColumnIndex,
                          )
                        ] ?? '—',
                        Icons.currency_ruble_sharp,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // 5. Кнопки действий
            // -----------------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: currentMapping.isValid()
                        ? () {
                            // Возвращаем выбранный маппинг
                            Navigator.pop(context, currentMapping);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Продолжить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ
  // ===========================================================================

  /// Создаёт селектор колонки с выпадающим списком
  Widget _buildColumnSelector({
    required String label,
    required IconData icon,
    required int currentIndex,
    required List<String> availableColumns,
    required Function(int) onChanged,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: currentIndex,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: List.generate(
                availableColumns.length,
                (index) => DropdownMenuItem(
                  value: index,
                  child: Text(availableColumns[index]),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Создаёт строку превью данных
  Widget _buildPreviewRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
