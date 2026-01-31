// ============================================================================
// ЭКРАН СПИСКА ПОЛЬЗОВАТЕЛЕЙ (User List Screen)
// ============================================================================
// Назначение: Отображает список всех пользователей из базы данных
// Позволяет: искать, добавлять пользователей, переходить к их заказам
// Связь с БД: Через UserProvider получает данные из Table1 (SQLite)
// ✅ НОВОЕ: Передаёт callback функцию в HomeScreen для кнопки "+"
// ============================================================================



// ----------------------------------------------------------------------------
// БЛОК ИМПОРТОВ (Dependencies)
// ----------------------------------------------------------------------------
// Каждый import подключает функциональность из других файлов/пакетов


import 'package:flutter/material.dart'; // Flutter Material - базовые виджеты для UI (Scaffold, AppBar, ListView и т.д.)

// Provider - система управления состоянием (State Management)
// Позволяет виджетам "слушать" изменения данных и автоматически перерисовываться
import 'package:provider/provider.dart';

// UserProvider - наш класс который управляет списком пользователей
// Хранит данные, делает запросы к API, обрабатывает поиск
// Файл: lib/providers/user_provider.dart
import '../providers/user_provider.dart';



// UserCard - виджет карточки одного пользователя (визуальное отображение)
// Файл: lib/widgets/user_card.dart
import '../widgets/user_card.dart';



// SearchBarWidget - виджет строки поиска с debounce
// Файл: lib/widgets/search_bar_widget.dart
import '../widgets/search_bar_widget.dart';



// PaginationWidget - виджет пагинации (переключение страниц 1, 2, 3...)
// Файл: lib/widgets/pagination_widget.dart
import '../widgets/pagination_widget.dart';



// OrderListScreen - экран списка заказов (для перехода к заказам пользователя)
// Файл: lib/screens/order_list_screen.dart
import 'order_list_screen.dart';



// UserModel - модель данных пользователя (для типа параметра в _showEditUserDialog)
// Файл: lib/models/user_model.dart
import '../models/user_model.dart';




// ----------------------------------------------------------------------------
// ГЛАВНЫЙ ВИДЖЕТ ЭКРАНА (StatefulWidget)
// ----------------------------------------------------------------------------
// StatefulWidget - виджет с изменяемым состоянием (может перерисовываться)
// Используем его потому что экран загружает данные при открытии



class UserListScreen extends StatefulWidget {
  // ✅ НОВОЕ: Callback функция для передачи метода _showAddUserDialog в HomeScreen
  // Позволяет HomeScreen вызывать диалог добавления при нажатии кнопки "+"
  // Function(VoidCallback) - функция которая принимает функцию без параметров
  final Function(VoidCallback)? onAddButtonCallback;
  
  // Конструктор виджета
  // const - компилятор оптимизирует память (виджет неизменяемый)
  // Key? key - уникальный идентификатор виджета для Flutter (опциональный)
  // ✅ this.onAddButtonCallback - опциональный параметр для callback
  const UserListScreen({
    Key? key,
    this.onAddButtonCallback,
  }) : super(key: key);



  // createState() создаёт объект State который хранит изменяемые данные
  @override
  State<UserListScreen> createState() => _UserListScreenState();
}



// ----------------------------------------------------------------------------
// STATE КЛАСС (Хранит изменяемое состояние экрана)
// ----------------------------------------------------------------------------
// Приватный класс (начинается с _) - доступен только в этом файле



class _UserListScreenState extends State<UserListScreen> {
  
  // -------------------------------------------------------------------------
  // LIFECYCLE МЕТОД: initState()
  // -------------------------------------------------------------------------
  // Вызывается ОДИН РАЗ при первом создании виджета
  // Идеально для загрузки начальных данных
  
  @override
  void initState() {
    super.initState(); // Вызываем родительский метод (обязательно!)
    
    // WidgetsBinding.instance.addPostFrameCallback() - выполняет код
    // ПОСЛЕ того как виджет полностью отрисуется на экране
    // Это нужно чтобы Provider был уже доступен в дереве виджетов
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ НОВОЕ: Передаём функцию _showAddUserDialog в HomeScreen
      // widget.onAddButtonCallback?.call() - вызываем callback если он не null
      // Передаём _showAddUserDialog чтобы HomeScreen мог её вызвать
      widget.onAddButtonCallback?.call(_showAddUserDialog);
      
      // context.read<UserProvider>() - получаем UserProvider БЕЗ подписки
      // .read() используем когда нужно ОДИН РАЗ вызвать метод
      // .fetchUsers() - загружает пользователей из API (Alfred сервера)
      context.read<UserProvider>().fetchUsers();
    });
  }



  // -------------------------------------------------------------------------
  // МЕТОД build() - СТРОИТ UI ЭКРАНА
  // -------------------------------------------------------------------------
  // Вызывается каждый раз когда Flutter нужно перерисовать виджет
  // BuildContext context - "адрес" виджета в дереве виджетов Flutter
  
  @override
  Widget build(BuildContext context) {
    
    // -----------------------------------------------------------------------
    // SCAFFOLD - КАРКАС ЭКРАНА
    // -----------------------------------------------------------------------
    // Scaffold - базовая структура экрана (AppBar + Body)
    // ✅ ИЗМЕНЕНО: Удалён floatingActionButton (теперь кнопка "+" в HomeScreen)
    
    return Scaffold(
      
      // ---------------------------------------------------------------------
      // APP BAR - ВЕРХНЯЯ ПАНЕЛЬ
      // ---------------------------------------------------------------------
      appBar: AppBar(
        // title - заголовок в центре/слева AppBar
        title: const Text('Пользователи'),
        
        // backgroundColor - цвет фона AppBar
        backgroundColor: Colors.blue,
        
        // foregroundColor - цвет текста и иконок в AppBar
        foregroundColor: Colors.white,
        
        // actions - список виджетов справа в AppBar (кнопки, иконки)
        actions: [
          // IconButton - кнопка с иконкой
          IconButton(
            icon: const Icon(Icons.refresh), // Иконка обновления
            
            // onPressed - callback который вызывается при нажатии
            onPressed: () {
              // context.read<UserProvider>() - получаем Provider БЕЗ подписки
              // .fetchUsers() - перезагружаем список пользователей с сервера
              context.read<UserProvider>().fetchUsers();
            },
            
            // tooltip - всплывающая подсказка при наведении (web/desktop)
            tooltip: 'Обновить',
          ),
        ],
      ),
      
      // ---------------------------------------------------------------------
      // BODY - ОСНОВНОЕ СОДЕРЖИМОЕ ЭКРАНА
      // ---------------------------------------------------------------------
      // Consumer<UserProvider> - слушает изменения в UserProvider
      // Когда Provider вызывает notifyListeners() - этот блок перерисовывается
      
      body: Consumer<UserProvider>(
        // builder - функция которая строит UI используя данные из Provider
        // context - контекст виджета
        // userProvider - экземпляр UserProvider с данными
        // child - не используем (для оптимизации статичных частей UI)
        builder: (context, userProvider, child) {
          
          // -----------------------------------------------------------------
          // СОСТОЯНИЕ 1: ЗАГРУЗКА (Loading State)
          // -----------------------------------------------------------------
          // Показываем индикатор загрузки если:
          // - isLoading == true (идёт запрос к серверу)
          // - users.isEmpty (ещё нет данных)
          
          if (userProvider.isLoading && userProvider.users.isEmpty) {
            return const Center(
              // CircularProgressIndicator - крутящийся индикатор загрузки
              child: CircularProgressIndicator(),
            );
          }
          
          // -----------------------------------------------------------------
          // СОСТОЯНИЕ 2: ОШИБКА (Error State)
          // -----------------------------------------------------------------
          // Показываем сообщение об ошибке если:
          // - errorMessage != null (произошла ошибка при запросе)
          
          if (userProvider.errorMessage != null) {
            return Center(
              // Column - вертикальный столбец виджетов
              child: Column(
                // mainAxisAlignment - выравнивание по вертикали
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon - иконка ошибки
                  Icon(
                    Icons.error_outline,
                    size: 64, // Размер иконки
                    color: Colors.red.shade300, // Светло-красный цвет
                  ),
                  
                  // SizedBox - пустое пространство для отступа
                  const SizedBox(height: 16),
                  
                  // Text - текст сообщения об ошибке
                  Text(
                    userProvider.errorMessage!, // ! - уверены что не null
                    textAlign: TextAlign.center, // Выравнивание по центру
                    style: const TextStyle(fontSize: 16),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ElevatedButton - кнопка с тенью (приподнятая)
                  ElevatedButton.icon(
                    onPressed: () {
                      // Очищаем ошибку и перезагружаем данные
                      userProvider.clearError();
                      userProvider.fetchUsers();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Попробовать снова'),
                  ),
                ],
              ),
            );
          }
          
          // -----------------------------------------------------------------
          // СОСТОЯНИЕ 3: ПУСТОЙ РЕЗУЛЬТАТ ПОИСКА
          // -----------------------------------------------------------------
          // Показываем "Ничего не найдено" только если:
          // - В базе ЕСТЬ пользователи (users.isNotEmpty)
          // - Но поиск их отфильтровал (filteredUsers.isEmpty)
          // - И есть поисковый запрос (searchQuery.isNotEmpty)
          
          if (userProvider.filteredUsers.isEmpty) {
            // Проверяем: есть ли пользователи в базе?
            if (userProvider.users.isNotEmpty && 
                userProvider.searchQuery.isNotEmpty) {
              // Есть пользователи, но поиск ничего не нашёл
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Иконка "поиск не дал результатов"
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Сообщение с текстом запроса
                    Text(
                      'Ничего не найдено по запросу "${userProvider.searchQuery}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Кнопка для очистки поиска
                    TextButton.icon(
                      onPressed: () {
                        // clearSearch() - очищает searchQuery
                        // и показывает всех пользователей снова
                        userProvider.clearSearch();
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Очистить поиск'),
                    ),
                  ],
                ),
              );
            } else {
              // База данных пустая (нет пользователей вообще)
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Нет пользователей',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }
          }
          
          // -----------------------------------------------------------------
          // СОСТОЯНИЕ 4: УСПЕШНАЯ ЗАГРУЗКА - ПОКАЗЫВАЕМ СПИСОК
          // -----------------------------------------------------------------
          // Column - вертикальный столбец с элементами экрана
          
          return Column(
            children: [
              
              // ---------------------------------------------------------------
              // СТРОКА ПОИСКА (Search Bar)
              // ---------------------------------------------------------------
              // Позволяет фильтровать пользователей по имени
              
              SearchBarWidget(
                hintText: 'Поиск пользователей...', // Подсказка в поле
                
                // onSearch - callback который вызывается при вводе текста
                // query - текст который ввёл пользователь
                onSearch: (query) {
                  // searchUsers() в Provider фильтрует список
                  userProvider.searchUsers(query);
                },
                
                // onClear - callback при нажатии кнопки очистки
                onClear: () {
                  // clearSearch() - сбрасывает фильтр, показывает всех
                  userProvider.clearSearch();
                },
              ),
              
              // ---------------------------------------------------------------
              // СЧЁТЧИК НАЙДЕННЫХ ПОЛЬЗОВАТЕЛЕЙ
              // ---------------------------------------------------------------
              // Padding - добавляет отступы вокруг виджета
              
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  // Показываем количество найденных пользователей
                  'Найдено: ${userProvider.filteredUsers.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              
              // ---------------------------------------------------------------
              // СПИСОК ПОЛЬЗОВАТЕЛЕЙ (ListView)
              // ---------------------------------------------------------------
              // Expanded - занимает всё доступное пространство
              
              Expanded(
                // ListView.builder - прокручиваемый список
                // builder - создаёт виджет для каждого элемента по требованию
                // Эффективен для больших списков (создаёт только видимые элементы)
                child: ListView.builder(
                  // itemCount - количество элементов в списке
                  // paginatedUsers - список пользователей текущей страницы (10 шт)
                  itemCount: userProvider.paginatedUsers.length,
                  
                  // itemBuilder - функция которая строит виджет для каждого элемента
                  // context - контекст
                  // index - номер элемента (0, 1, 2, ...)
                  itemBuilder: (context, index) {
                    // Получаем пользователя по индексу
                    final user = userProvider.paginatedUsers[index];
                    
                    // Вычисляем глобальный индекс (номер на всех страницах)
                    // Например: страница 2, элемент 3 → 20 + 3 = 23
                    final globalIndex = 
                        userProvider.currentPage * userProvider.itemsPerPage + index;
                    
                    // Возвращаем карточку пользователя
                    return UserCard(
                      user: user, // Объект UserModel с данными
                      index: globalIndex, // Номер для отображения
                      onDelete: () => _showDeleteUserDialog(user),


                      // onTap - callback при нажатии на карточку
                      onTap: () {
                        // Переходим к экрану заказов этого пользователя
                        navigateToUserOrders(user.id, user.fullName);
                      },
                      
                      // onEdit - callback при нажатии кнопки редактирования
                      onEdit: () {
                        // Показываем диалог редактирования
                        _showEditUserDialog(user);
                      },
                    );
                  },
                ),
              ),
              
              // ---------------------------------------------------------------
              // ПАГИНАЦИЯ (Pagination)
              // ---------------------------------------------------------------
              // Кнопки переключения страниц (< 1 2 3 ... >)
              
              PaginationWidget(
                currentPage: userProvider.currentPage, // Текущая страница
                totalPages: userProvider.totalPages, // Всего страниц
                
                // onNext - переход на следующую страницу
                onNext: userProvider.nextPage,
                
                // onPrevious - переход на предыдущую страницу
                onPrevious: userProvider.previousPage,
                
                // onPageSelect - переход на конкретную страницу
                // page - номер выбранной страницы
                onPageSelect: (page) {
                  userProvider.goToPage(page);
                },
              ),
            ],
          );
        },
      ),
      
      // ✅ УДАЛЕНО: floatingActionButton - теперь кнопка "+" находится в HomeScreen
      // ✅ УДАЛЕНО: floatingActionButtonLocation - больше не нужно
  
    );
  }
  
  // ===========================================================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ (Helper Methods)
  // ===========================================================================
  
  // ---------------------------------------------------------------------------
  // МЕТОД: Показать диалог добавления пользователя
  // ---------------------------------------------------------------------------
  // ✅ ИЗМЕНЕНО: Метод теперь вызывается из HomeScreen через callback
  
  void _showAddUserDialog() {
    // TextEditingController - контроллер для текстового поля
    // Позволяет читать введённый текст
    final TextEditingController nameController = TextEditingController();
    
    // showDialog() - показывает всплывающее окно поверх экрана
    showDialog(
      context: context, // Контекст для отображения
      
      // builder - функция которая строит виджет диалога
      // dialogContext - контекст диалога (отдельный от экрана!)
      builder: (BuildContext dialogContext) {
        // AlertDialog - стандартный диалог с заголовком, содержимым, кнопками
        return AlertDialog(
          title: const Text('Новый пользователь'), // Заголовок
          
          // content - содержимое диалога
          content: TextField(
            controller: nameController, // Привязываем контроллер
            decoration: const InputDecoration(
              labelText: 'ФИО', // Подпись над полем
              hintText: 'Иван Иванович', // Подсказка в пустом поле
              border: OutlineInputBorder(), // Рамка вокруг поля
            ),
            autofocus: true, // Автоматически фокусируемся на поле
          ),
          
          // actions - кнопки внизу диалога
          actions: [
            // Кнопка "Отмена"
            TextButton(
              onPressed: () {
                // Navigator.pop() - закрывает диалог
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Отмена'),
            ),
            
            // Кнопка "Добавить"
            ElevatedButton(
              onPressed: () async {
                // Получаем текст из поля и убираем пробелы по краям
                final name = nameController.text.trim();
                
                // Валидация: проверяем что имя не пустое
                if (name.isEmpty) {
                  // ScaffoldMessenger - показывает SnackBar (уведомление внизу)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Введите имя пользователя'),
                    ),
                  );
                  return; // Прерываем выполнение
                }
                
                // Закрываем диалог
                Navigator.of(dialogContext).pop();
                
                try {
                  // context.read<UserProvider>() - получаем Provider
                  // await - ждём завершения асинхронной операции
                  // createUser() - отправляет POST запрос на сервер
                  await context.read<UserProvider>().createUser(name);
                  
                  // if (mounted) - проверяем что виджет ещё существует
                  // (не был удалён пока ждали ответ сервера)
                  if (mounted) {
                    // Показываем уведомление об успехе
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Пользователь "$name" добавлен'),
                      ),
                    );
                  }
                } catch (e) {
                  // catch - ловим ошибку если запрос упал
                  if (mounted) {
                    // Показываем уведомление об ошибке
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка: $e'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }
  
  // ---------------------------------------------------------------------------
  // МЕТОД: Показать диалог редактирования пользователя
  // ---------------------------------------------------------------------------
  // user - объект UserModel пользователя которого нужно отредактировать
  
  void _showEditUserDialog(UserModel user) {
    // TextEditingController с ТЕКУЩИМ значением имени пользователя
    // text: user.fullName - предзаполняем поле существующим именем
    final TextEditingController nameController = 
        TextEditingController(text: user.fullName);
    
    // showDialog() - показываем всплывающее окно
    showDialog(
      context: context,
      
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // Заголовок показывает кого редактируем
          title: Text('Редактировать: ${user.fullName}'),
          
          // TextField для ввода нового имени
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'ФИО',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person), // Иконка человечка слева
            ),
            autofocus: true, // Сразу фокус на поле
          ),
          
          actions: [
            // Кнопка "Отмена"
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Отмена'),
            ),
            
            // Кнопка "Сохранить"
            ElevatedButton(
              onPressed: () async {
                // Получаем новое имя
                final name = nameController.text.trim();
                
                // Валидация: проверяем что имя не пустое
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Введите имя пользователя'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return; // Прерываем выполнение
                }
                
                // Валидация: минимум 3 символа
                if (name.length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Имя должно содержать минимум 3 символа'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Закрываем диалог
                Navigator.of(dialogContext).pop();
                
                try {
                  // Получаем UserProvider и вызываем updateUser()
                  final userProvider = context.read<UserProvider>();
                  
                  // await - ждём завершения PUT запроса к серверу
                  await userProvider.updateUser(user.id, name);
                  
                  // Проверяем что виджет ещё существует
                  if (mounted) {
                    // Показываем уведомление об успехе (зелёный SnackBar)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Пользователь "$name" обновлён'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // Ловим ошибку если запрос упал
                  if (mounted) {
                    // Показываем уведомление об ошибке (красный SnackBar)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }
  
  // ---------------------------------------------------------------------------
  // МЕТОД: Переход к экрану заказов пользователя
  // ---------------------------------------------------------------------------
  // userId - ID пользователя из Table1
  // userName - ФИО пользователя для отображения в AppBar
  
  void navigateToUserOrders(int userId, String userName) {
    // Navigator.push() - открывает новый экран поверх текущего
    Navigator.push(
      context,
      // MaterialPageRoute - стандартная анимация перехода между экранами
      MaterialPageRoute(
        builder: (context) => OrderListScreen(
          userId: userId, // Передаём ID пользователя
          userName: userName, // Передаём имя для заголовка
        ),
      ),
    );
  }
  
  // ---------------------------------------------------------------------------
  // МЕТОД: Показать диалог подтверждения удаления пользователя
  // ---------------------------------------------------------------------------
  
  void _showDeleteUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Удалить пользователя?'),
          
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Вы уверены что хотите удалить пользователя?',
                style: TextStyle(fontSize: 16),
              ),
              
              const SizedBox(height: 12),
              
              // Карточка с данными пользователя
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.red.shade900,
                            ),
                          ),
                          Text(
                            'ID: ${user.id}',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                '⚠️ Это действие нельзя отменить!',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          actions: [
            // Кнопка "Отмена"
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Отмена'),
            ),
            
            // Кнопка "Удалить"
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                try {
                  final userProvider = context.read<UserProvider>();
                  await userProvider.deleteUser(user.id);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Пользователь "${user.fullName}" удалён'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка удаления: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
  }


} // ← Закрывающая скобка класса _UserListScreenState
