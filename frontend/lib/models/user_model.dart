//Модель пользователя - Frontend
//Назначение: Модель данных для пользователя (монтажника). Используется во Flutter приложении для работы с данными из Table1.
// Модель данных пользователя (соответствует Table1 в БД)
class UserModel {
  final int id;              // ID пользователя из БД
  final String fullName;     // ФИО монтажника

  // Конструктор модели
  UserModel({
    required this.id,
    required this.fullName,
  });

  // Создание модели из JSON (приходит с сервера)
  // Используется когда получаем данные через API
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['ID'] as int,                    // Берем ID из поля 'ID'
      fullName: json['full_name'] as String,    // Берем имя из поля 'full_name'
    );
  }

  // Преобразование модели в JSON (для отправки на сервер)
  // Используется при создании нового пользователя
  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,  // Отправляем только имя (ID генерирует БД)
    };
  }

  // Копирование модели с возможностью изменения отдельных полей
  // Полезно для редактирования данных
  UserModel copyWith({
    int? id,
    String? fullName,
  }) {
    return UserModel(
      id: id ?? this.id,                  // Если новый id не передан, используем текущий
      fullName: fullName ?? this.fullName,
    );
  }

  // Строковое представление для отладки
  @override
  String toString() => 'UserModel(id: $id, fullName: $fullName)';
}
