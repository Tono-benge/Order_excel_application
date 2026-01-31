// ============================================================================
// ГЛАВНЫЙ ЭКРАН ПРИЛОЖЕНИЯ (Home Screen)
// ============================================================================
// Назначение: Основной экран приложения с навигацией между разделами
// Использует: BottomNavigationBar для переключения между Пользователями и Заказами
// Связь: UserListScreen и OrderListScreen
// Кастомный bottomNavigationBar: Кнопки + BottomNavigationBar в одной строке
// ============================================================================

// ============================================================================
// ИМПОРТЫ
// ============================================================================

// Flutter Material - базовые компоненты UI
import 'package:flutter/material.dart';
import 'user_list_screen.dart'; // экран списка Пользователей
import 'order_list_screen.dart'; // экран списка заказов
import 'import_excel_screen.dart'; // для работы с экселькой

// ============================================================================
// ГЛАВНЫЙ ВИДЖЕТ (StatefulWidget)
// ============================================================================
// StatefulWidget - нужен нам потому что состояние (выбранный индекс)
// может изменяться при нажатии кнопок в BottomNavigationBar

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ============================================================================
// STATE КЛАСС
// ============================================================================

class _HomeScreenState extends State<HomeScreen> {
  // =========================================================================
  // ПЕРЕМЕННЫЕ СОСТОЯНИЯ
  // =========================================================================

  // selectedIndex - какой экран сейчас активен (0 = Пользователи, 1 = Заказы)
  int selectedIndex = 0;

  // ✅ НОВОЕ: Callback функции для вызова диалогов из дочерних экранов
  // Будут установлены через onAddButtonCallback при создании экранов
  VoidCallback? _userAddCallback;
  VoidCallback? _orderAddCallback;

  // =========================================================================
  // МЕТОД build() - СТРОИТ UI
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // -----------------------------------------------------------------------
      // BODY - ОСНОВНОЕ СОДЕРЖИМОЕ
      // -----------------------------------------------------------------------
      // IndexedStack - показывает только один экран из списка screens
      // по индексу selectedIndex
      // Преимущество: экраны сохраняют своё состояние при переключении

      body: IndexedStack(
        // index - какой экран показывать (0, 1, 2, ...)
        index: selectedIndex,

        // children - список всех экранов (как в стопке карточек)
        // ✅ ИЗМЕНЕНО: Передаём callback функции в экраны
        children: [
          UserListScreen(
            onAddButtonCallback: (callback) {
              _userAddCallback = callback;
            },
          ), // [0] - Пользователи

          OrderListScreen(
            onAddButtonCallback: (callback) {
              _orderAddCallback = callback;
            },
          ), // [1] - Заказы
        ],
      ),

      // -----------------------------------------------------------------------
      // BOTTOM NAVIGATION BAR - КАСТОМНАЯ НИЖНЯЯ ПАНЕЛЬ Все кнопки в одной строке
      // -----------------------------------------------------------------------

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // ═══════════════════════════════════════════════════════════
                // КНОПКА: Импорт Excel (слева)
                // ═══════════════════════════════════════════════════════════
                Tooltip(
                  message:
                      'Импорт из файла Excel', // Текст всплывающей подсказки
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ImportExcelScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Импорт'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // ═══════════════════════════════════════════════════════════
                // КНОПКА: Добавить (+)
                // ═══════════════════════════════════════════════════════════
                FloatingActionButton(
                  heroTag: 'add_button',
                  mini: true, // ✅ Делаем кнопку меньше
                  onPressed: () {
                    if (selectedIndex == 0) {
                      _userAddCallback?.call();
                    } else {
                      _orderAddCallback?.call();
                    }
                  },
                  tooltip: selectedIndex == 0
                      ? 'Добавить пользователя'
                      : 'Добавить заказ',
                  child: const Icon(Icons.add),
                ),

                const SizedBox(width: 16),

                // ═══════════════════════════════════════════════════════════
                // ВЕРТИКАЛЬНЫЙ РАЗДЕЛИТЕЛЬ
                // ═══════════════════════════════════════════════════════════
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                ),

                const SizedBox(width: 8),

                // ═══════════════════════════════════════════════════════════
                // НАВИГАЦИЯ: Пользователи и Заказы
                // ═══════════════════════════════════════════════════════════
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ─────────────────────────────────────────────────────
                      // ВКЛАДКА: Пользователи
                      // ─────────────────────────────────────────────────────
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedIndex = 0;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: selectedIndex == 0
                                      ? Colors.blue
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  color: selectedIndex == 0
                                      ? Colors.blue
                                      : Colors.grey,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Пользователи',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selectedIndex == 0
                                        ? Colors.blue
                                        : Colors.grey,
                                    fontWeight: selectedIndex == 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ─────────────────────────────────────────────────────
                      // ВКЛАДКА: Заказы
                      // ─────────────────────────────────────────────────────
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedIndex = 1;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: selectedIndex == 1
                                      ? Colors.blue
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  color: selectedIndex == 1
                                      ? Colors.blue
                                      : Colors.grey,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Заказы',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selectedIndex == 1
                                        ? Colors.blue
                                        : Colors.grey,
                                    fontWeight: selectedIndex == 1
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
