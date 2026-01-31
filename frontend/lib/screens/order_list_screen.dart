// ============================================================================
// ORDER LIST SCREEN - Экран списка заказов (Frontend UI)
// ============================================================================
// Назначение: Отображает список всех заказов или заказов конкретного пользователя
// Функционал: поиск, фильтрация, пагинация, создание, редактирование, удаление
// ✅ НОВОЕ: Передаёт callback функцию в HomeScreen для кнопки "+"
// ============================================================================


// ========== ИМПОРТЫ ==========
import 'package:flutter/material.dart';       // Основные виджеты Flutter
import 'package:provider/provider.dart';      // Доступ к Provider'ам


import '../models/order_model.dart';          // Модель заказа
import '../models/user_model.dart';           // Модель пользователя
import '../widgets/order_card.dart';          // Карточка заказа
import '../widgets/search_bar_widget.dart';   // Поисковая строка
import '../widgets/pagination_widget.dart';   // Пагинация


import '../providers/user_provider.dart';     // Provider пользователей
import '../providers/order_provider.dart';    // Provider заказов


// ============================================================================
// STATEFUL WIDGET - Экран с изменяемым состоянием
// ============================================================================


class OrderListScreen extends StatefulWidget {
  final int? userId;      // ID пользователя (если открыт экран "заказы конкретного пользователя")
  final String? userName; // Имя пользователя для заголовка
  
  // ✅ НОВОЕ: Callback функция для передачи метода _showAddOrderDialog в HomeScreen
  // Позволяет HomeScreen вызывать диалог добавления при нажатии кнопки "+"
  // Function(VoidCallback) - функция которая принимает функцию без параметров
  final Function(VoidCallback)? onAddButtonCallback;


  const OrderListScreen({
    super.key,
    this.userId,
    this.userName,
    this.onAddButtonCallback, // ✅ НОВЫЙ параметр
  });


  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}


// ============================================================================
// STATE CLASS - Состояние экрана
// ============================================================================


class _OrderListScreenState extends State<OrderListScreen> {
  
  // ==========================================================================
  // LIFECYCLE МЕТОД: Инициализация при создании виджета
  // ==========================================================================
  
  @override
  void initState() {
    super.initState();


    // Загружаем заказы после первой отрисовки
    // addPostFrameCallback - гарантирует что context доступен
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ НОВОЕ: Передаём функцию _showAddOrderDialog в HomeScreen
      // widget.onAddButtonCallback?.call() - вызываем callback если он не null
      // Передаём _showAddOrderDialog чтобы HomeScreen мог её вызвать
      widget.onAddButtonCallback?.call(_showAddOrderDialog);
      
      final orderProvider = context.read<OrderProvider>();


      // Если передан userId - загружаем только его заказы
      // Иначе - загружаем все заказы
      if (widget.userId != null) {
        orderProvider.fetchUserOrders(widget.userId!);
      } else {
        orderProvider.fetchOrders();
      }
    });
  }


  // ==========================================================================
  // BUILD МЕТОД: Построение UI
  // ==========================================================================


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ------------------------------------------------------------------------
      // APP BAR - Верхняя панель
      // ------------------------------------------------------------------------
      appBar: AppBar(
        title: Text(
          widget.userName != null 
              ? 'Заказы: ${widget.userName}' 
              : 'Все заказы',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Кнопка фильтра по пользователю
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showUserFilterDialog,
            tooltip: 'Фильтр по пользователю',
          ),
          // Кнопка обновления списка
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final orderProvider = context.read<OrderProvider>();
              if (widget.userId != null) {
                orderProvider.fetchUserOrders(widget.userId!);
              } else {
                orderProvider.fetchOrders();
              }
            },
            tooltip: 'Обновить',
          ),
        ],
      ),


      // ------------------------------------------------------------------------
      // BODY - Основной контент с Consumer для реактивности
      // ------------------------------------------------------------------------
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          
          // --------------------------------------------------------------------
          // СОСТОЯНИЕ 1: Загрузка (показываем индикатор)
          // --------------------------------------------------------------------
          if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }


          // --------------------------------------------------------------------
          // СОСТОЯНИЕ 2: Ошибка (показываем сообщение и кнопку повтора)
          // --------------------------------------------------------------------
          if (orderProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    orderProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      orderProvider.clearError();
                      if (widget.userId != null) {
                        orderProvider.fetchUserOrders(widget.userId!);
                      } else {
                        orderProvider.fetchOrders();
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Попробовать снова'),
                  ),
                ],
              ),
            );
          }


          // --------------------------------------------------------------------
          // СОСТОЯНИЕ 3: Пустой список (нет заказов)
          // --------------------------------------------------------------------
          if (orderProvider.filteredOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    orderProvider.searchQuery.isEmpty
                        ? 'Нет заказов'
                        : 'Ничего не найдено по запросу\n"${orderProvider.searchQuery}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }


          // --------------------------------------------------------------------
          // СОСТОЯНИЕ 4: Основной контент (список заказов)
          // --------------------------------------------------------------------
          return Column(
            children: [
              // Поисковая строка
              SearchBarWidget(
                hintText: 'Поиск по номеру заказа',
                onSearch: orderProvider.searchOrders,
                onClear: orderProvider.clearFilters,
              ),


              // Статистика (количество заказов и общая сумма)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem(
                      icon: Icons.receipt_long,
                      label: 'Всего заказов',
                      value: '${orderProvider.filteredOrders.length}',
                      color: Colors.blue,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    _buildInfoItem(
                      icon: Icons.currency_ruble_sharp,
                      label: 'Общая сумма',
                      value: '${orderProvider.totalAmount.toStringAsFixed(2)} ₽',
                      color: Colors.green,
                    ),
                  ],
                ),
              ),


              const SizedBox(height: 8),


              // Список заказов (с пагинацией)
              Expanded(
                child: ListView.builder(
                  itemCount: orderProvider.paginatedOrders.length,
                  itemBuilder: (context, index) {
                    final order = orderProvider.paginatedOrders[index];
                    final globalIndex =
                        orderProvider.currentPage * orderProvider.itemsPerPage + index;


                    return OrderCard(
                      order: order,
                      index: globalIndex,
                      onTap: () => _showOrderDetails(order),
                      
                      // Callback редактирования заказа
                      onEdit: () => _showEditOrderDialog(order),
                      
                      // Callback удаления заказа
                      onDelete: () async {
                        try {
                          await orderProvider.deleteOrder(order.orderId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Заказ #${order.orderId} удален')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ошибка удаления: $e')),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),


              // Виджет пагинации (переключение страниц)
              PaginationWidget(
                currentPage: orderProvider.currentPage,
                totalPages: orderProvider.totalPages,
                onNext: orderProvider.nextPage,
                onPrevious: orderProvider.previousPage,
                onPageSelect: orderProvider.goToPage,
              ),
            ],
          );
        },
      ),


      // ✅ УДАЛЕНО: floatingActionButton - теперь кнопка "+" находится в HomeScreen
      // ✅ УДАЛЕНО: floatingActionButtonLocation - больше не нужно



    );
  }


  // ==========================================================================
  // ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ
  // ==========================================================================


  // --------------------------------------------------------------------------
  // ВИДЖЕТ: Информационный элемент (для статистики)
  // --------------------------------------------------------------------------
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }


  // --------------------------------------------------------------------------
  // ВИДЖЕТ: Строка деталей (для диалога просмотра)
  // --------------------------------------------------------------------------
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
  }


  // ==========================================================================
  // ДИАЛОГИ (Dialogs)
  // ==========================================================================


  // --------------------------------------------------------------------------
  // ДИАЛОГ: Фильтр по пользователю
  // --------------------------------------------------------------------------
  void _showUserFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Фильтр по пользователю'),
          content: Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              // Загружаем пользователей если список пустой
              if (userProvider.users.isEmpty && !userProvider.isLoading) {
                userProvider.fetchUsers();
              }


              if (userProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }


              return SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Опция "Все пользователи" (сброс фильтра)
                    ListTile(
                      leading: const Icon(Icons.clear_all),
                      title: const Text('Все пользователи'),
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        context.read<OrderProvider>().filterByUser(null);
                      },
                    ),
                    const Divider(),
                    // Список пользователей
                    ...userProvider.users.map((user) {
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(user.fullName),
                        subtitle: Text('ID: ${user.id}'),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          context.read<OrderProvider>().filterByUser(user.id);
                        },
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }


  // --------------------------------------------------------------------------
  // ДИАЛОГ: Добавление нового заказа (упрощённая версия без автодополнения)
  // --------------------------------------------------------------------------
  // ✅ ИЗМЕНЕНО: Метод теперь приватный (_showAddOrderDialog)
  // и вызывается из HomeScreen через callback
  
  void _showAddOrderDialog() {
    final TextEditingController amountController = TextEditingController();
    int? selectedUserId; // ID выбранного пользователя


    // Загружаем пользователей
    final userProvider = context.read<UserProvider>();
    if (userProvider.users.isEmpty && !userProvider.isLoading) {
      userProvider.fetchUsers();
    }


    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Новый заказ'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ---------------------------------------------------------------
                    // ПОЛЕ: Сумма заказа
                    // ---------------------------------------------------------------
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Сумма заказа',
                        hintText: 'Например: 2500',
                        prefixText: '₽ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      autofocus: true,
                    ),


                    const SizedBox(height: 16),


                    // ---------------------------------------------------------------
                    // ВЫПАДАЮЩИЙ СПИСОК: Выбор монтажника
                    // ---------------------------------------------------------------
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        if (userProvider.isLoading) {
                          return const CircularProgressIndicator();
                        }


                        return DropdownButtonFormField<int>(
                          value: selectedUserId,
                          decoration: const InputDecoration(
                            labelText: 'Монтажник',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          hint: const Text('Выберите монтажника'),
                          isExpanded: true,
                          items: userProvider.users.map((user) {
                            return DropdownMenuItem<int>(
                              value: user.id,
                              child: Text(user.fullName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedUserId = value;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),


              // ----------------------------------------------------------------
              // КНОПКИ
              // ----------------------------------------------------------------
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amountText = amountController.text.trim();
                    final amount = double.tryParse(amountText);


                    // Валидация суммы
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Введите корректную сумму'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }


                    // Валидация пользователя
                    if (selectedUserId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Выберите монтажника'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }


                    Navigator.of(dialogContext).pop();


                    try {
                      // Создаём заказ через Provider
                      final orderProvider = context.read<OrderProvider>();
                      await orderProvider.createOrder(amount, selectedUserId!);


                      // Перезагружаем список
                      if (widget.userId != null) {
                        await orderProvider.fetchUserOrders(widget.userId!);
                      } else {
                        await orderProvider.fetchOrders();
                      }


                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Заказ на ${amount.toStringAsFixed(2)} ₽ создан',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ошибка: $e'),
                            backgroundColor: Colors.red,
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
      },
    );
  }


  // --------------------------------------------------------------------------
  // ДИАЛОГ: Редактирование заказа
  // --------------------------------------------------------------------------
  void _showEditOrderDialog(OrderModel order) {
    // Контроллер с ТЕКУЩИМ значением суммы
    final TextEditingController amountController =
        TextEditingController(text: order.orderAmount.toString());


    // ID текущего монтажника
    int? selectedUserId = order.userForeignKey;


    // Загружаем пользователей
    final userProvider = context.read<UserProvider>();
    if (userProvider.users.isEmpty && !userProvider.isLoading) {
      userProvider.fetchUsers();
    }


    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Редактировать заказ #${order.orderId}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ---------------------------------------------------------------
                    // ПОЛЕ: Сумма заказа (с текущим значением)
                    // ---------------------------------------------------------------
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Сумма заказа',
                        prefixText: '₽ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      autofocus: true,
                    ),


                    const SizedBox(height: 16),


                    // ---------------------------------------------------------------
                    // ВЫПАДАЮЩИЙ СПИСОК: Монтажник (с текущим выбранным)
                    // ---------------------------------------------------------------
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        if (userProvider.isLoading) {
                          return const CircularProgressIndicator();
                        }


                        return DropdownButtonFormField<int>(
                          value: selectedUserId,
                          decoration: const InputDecoration(
                            labelText: 'Монтажник',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          isExpanded: true,
                          items: userProvider.users.map((user) {
                            return DropdownMenuItem<int>(
                              value: user.id,
                              child: Text(user.fullName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedUserId = value;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),


              // ----------------------------------------------------------------
              // КНОПКИ
              // ----------------------------------------------------------------
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amountText = amountController.text.trim();
                    final amount = double.tryParse(amountText);


                    // Валидация суммы
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Введите корректную сумму'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }


                    // Валидация пользователя
                    if (selectedUserId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Выберите монтажника'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }


                    Navigator.of(dialogContext).pop();


                    try {
                      // Обновляем заказ через Provider
                      final orderProvider = context.read<OrderProvider>();
                      await orderProvider.updateOrder(
                        order.orderId,
                        amount,
                        selectedUserId!,
                      );


                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Заказ #${order.orderId} обновлён'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
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
      },
    );
  }


  // --------------------------------------------------------------------------
  // ДИАЛОГ: Просмотр деталей заказа
  // --------------------------------------------------------------------------
  void _showOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Заказ #${order.orderId}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Номер заказа:', '#${order.orderId}'),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Сумма:',
                '${order.orderAmount.toStringAsFixed(2)} ₽',
              ),
              const SizedBox(height: 8),
              if (order.userName != null)
                _buildDetailRow('Клиент:', order.userName!),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }
}
