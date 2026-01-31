// ============================================================================
// ORDER CARD WIDGET - Карточка заказа (Frontend UI)
// ============================================================================
// Назначение: Отображает один заказ в списке с кнопками действий
// Используется в: OrderListScreen → ListView.builder
// ============================================================================

import 'package:flutter/material.dart'; // Flutter UI
import '../models/order_model.dart'; // Модель заказа

class OrderCard extends StatelessWidget {
  // -------------------------------------------------------------------------
  // ПАРАМЕТРЫ ВИДЖЕТА
  // -------------------------------------------------------------------------
  
  final OrderModel order;           // Данные заказа для отображения
  final VoidCallback? onTap;        // Callback при клике на карточку (null = отключено)
  final VoidCallback? onDelete;     // Callback при удалении заказа
  final VoidCallback? onEdit;       // ✅ НОВЫЙ: Callback при редактировании
  final int index;                  // Порядковый номер заказа в списке

  const OrderCard({
    Key? key,
    required this.order,
    this.onTap,
    this.onDelete,
    this.onEdit,                    // ✅ НОВЫЙ параметр
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Цвета для аватаров заказов (циклически повторяются)
    final colors = [
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.blue,
    ];
    
    // Выбираем цвет по остатку от деления индекса на количество цветов
    final avatarColor = colors[index % colors.length];

    return Card(
      // Отступы карточки
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2, // Тень карточки
      
      child: InkWell(
        // InkWell - делает карточку кликабельной с эффектом волны
        onTap: onTap, // null = карточка не кликабельная
        borderRadius: BorderRadius.circular(8),
        
        child: Padding(
          padding: const EdgeInsets.all(12),
          
          // -----------------------------------------------------------------------
          // СТРУКТУРА КАРТОЧКИ: Row (Аватар | Данные | Кнопки)
          // -----------------------------------------------------------------------
          child: Row(
            children: [
              
              // -------------------------------------------------------------------
              // БЛОК 1: АВАТАР ЗАКАЗА (круг с иконкой)
              // -------------------------------------------------------------------
              CircleAvatar(
                backgroundColor: avatarColor,
                radius: 24,
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16), // Отступ между аватаром и данными
              
              // -------------------------------------------------------------------
              // БЛОК 2: ДАННЫЕ ЗАКАЗА (номер, сумма, пользователь)
              // -------------------------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Номер заказа (жирный шрифт)
                    Text(
                      'Заказ #${order.orderId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Сумма заказа (серый цвет)
                    Text(
                      '${order.orderAmount.toStringAsFixed(2)} ₽',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    // Имя пользователя (если есть)
                    if (order.userName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        order.userName!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // -------------------------------------------------------------------
              // БЛОК 3: КНОПКИ ДЕЙСТВИЙ (Редактировать, Удалить)
              // -------------------------------------------------------------------
              
              // ✅ КНОПКА РЕДАКТИРОВАНИЯ (если onEdit передан)
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: Colors.blue,
                  onPressed: onEdit, // Вызываем callback
                  tooltip: 'Редактировать заказ',
                ),
              
              // КНОПКА УДАЛЕНИЯ (если onDelete передан)
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  onPressed: () => _showDeleteConfirmation(context),
                  tooltip: 'Удалить заказ',
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // МЕТОД: Показать диалог подтверждения удаления
  // ==========================================================================
  
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Удалить заказ?'),
          content: Text(
            'Вы действительно хотите удалить заказ #${order.orderId}? '
            'Это действие нельзя отменить.',
          ),
          actions: [
            // Кнопка "Отмена"
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Отмена'),
            ),
            
            // Кнопка "Удалить" (красная)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onDelete?.call(); // Вызываем callback удаления
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
  }
}
