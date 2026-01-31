//Карточка пользователя - Frontend UI)
//Назначение: Переиспользуемый виджет для отображения одного пользователя в списке.
// ========== ИМПОРТЫ ==========
import 'package:flutter/material.dart'; // Основные виджеты Flutter
import '../models/user_model.dart';     // Модель пользователя



// Виджет карточки пользователя (как на скриншоте)
class UserCard extends StatelessWidget {
  final UserModel user;           // Данные пользователя
  final VoidCallback onTap;       // Действие при нажатии на карточку
  final VoidCallback? onEdit;     // Действие при нажатии кнопки редактирования (опционально)
  final VoidCallback? onDelete;   // ✅ НОВОЕ: Действие при удалении (опционально)
  final int index;                // Номер в списке (для аватара)



  // Конструктор с обязательными параметрами
  const UserCard({
    Key? key,
    required this.user,
    required this.onTap,
    this.onEdit,                  // Опциональный параметр
    this.onDelete,                // ✅ НОВОЕ: Опциональный параметр
    required this.index,
  }) : super(key: key);



  @override
  Widget build(BuildContext context) {
    // Список цветов для аватаров (циклически повторяется)
    final colors = [
      Colors.purple.shade200,
      Colors.blue.shade200,
      Colors.green.shade200,
      Colors.orange.shade200,
      Colors.pink.shade200,
    ];
    
    // Выбираем цвет по остатку от деления (чтобы цикл повторялся)
    final avatarColor = colors[index % colors.length];



    return Card(
      // Card - это виджет с тенью и скругленными углами
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2, // Высота тени (глубина карточки)
      
      child: InkWell(
        // InkWell добавляет эффект "ripple" при нажатии
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        
        child: Padding(
          padding: const EdgeInsets.all(12),
          
          child: Row(
            children: [
              // ========== АВАТАР С НОМЕРОМ ==========
              CircleAvatar(
                backgroundColor: avatarColor,
                radius: 24, // Радиус круга
                child: Text(
                  '${index + 1}', // Номер пользователя (начинается с 1)
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(width: 16), // Отступ между аватаром и текстом
              
              // ========== ИНФОРМАЦИЯ О ПОЛЬЗОВАТЕЛЕ ==========
              Expanded(
                // Expanded заставляет виджет занять всё доступное пространство
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Выравнивание влево
                  children: [
                    // ФИО пользователя
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // ID пользователя (серый текст)
                    Text(
                      'ID: ${user.id}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // ========== КНОПКА РЕДАКТИРОВАНИЯ (если передан onEdit) ==========
              // Кнопка редактирования появляется только если onEdit не null
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: Colors.blue,
                  iconSize: 22,
                  onPressed: onEdit, // Вызываем callback редактирования
                  tooltip: 'Редактировать пользователя',
                ),
              
              // ========== КНОПКА УДАЛЕНИЯ (если передан onDelete) ==========
              // ✅ НОВОЕ: Кнопка удаления появляется только если onDelete не null
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  iconSize: 22,
                  onPressed: onDelete, // Вызываем callback удаления
                  tooltip: 'Удалить пользователя',
                ),
              
              // ========== ИКОНКА "ВПЕРЕД" ==========
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
