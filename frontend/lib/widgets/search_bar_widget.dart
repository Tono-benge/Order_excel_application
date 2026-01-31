// ВИДЖЕТ СТРОКИ ПОИСКА С DEBOUNCE (ЗАДЕРЖКОЙ)
// Назначение: Умный поиск — срабатывает только когда пользователь перестал печатать
// Это улучшает UX и снижает нагрузку на систему [web:107][web:111]

import 'package:flutter/material.dart';
import 'dart:async'; // Для Timer

// StatefulWidget - виджет с изменяемым состоянием
class SearchBarWidget extends StatefulWidget {
  // Текст-подсказка в пустом поле
  final String hintText;
  
  // Callback который вызывается после задержки
  final Function(String) onSearch;
  
  // Callback для очистки
  final VoidCallback? onClear;
  
  // Задержка в миллисекундах перед поиском (по умолчанию 500мс)
  // Это debounce время — поиск сработает только если пользователь 
  // не печатает 500мс [web:107][web:110]
  final int debounceDuration;

  const SearchBarWidget({
    Key? key,
    required this.hintText,
    required this.onSearch,
    this.onClear,
    this.debounceDuration = 500, // 0.5 секунды - стандарт [web:107]
  }) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  // Контроллер для управления текстовым полем
  final TextEditingController _controller = TextEditingController();
  
  // Timer для debounce - отложенное выполнение поиска [web:107][web:111]
  Timer? _debounceTimer;

  @override
  void dispose() {
    // Отменяем таймер если виджет удаляется
    _debounceTimer?.cancel();
    // Освобождаем память контроллера
    _controller.dispose();
    super.dispose();
  }

  // Функция которая запускает поиск с задержкой [web:107][web:110]
  void _onSearchChanged(String query) {
    // Отменяем предыдущий таймер если пользователь продолжает печатать
    // Это ключевой момент debounce! [web:107]
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    // Запускаем новый таймер на 500мс (или другое значение)
    _debounceTimer = Timer(
      Duration(milliseconds: widget.debounceDuration),
      () {
        // Этот код выполнится только если пользователь 
        // НЕ печатал 500мс [web:107][web:110]
        widget.onSearch(query);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: _controller,
        
        // onChanged вызывается при каждом символе
        onChanged: (value) {
          // Запускаем debounce вместо мгновенного поиска [web:107]
          _onSearchChanged(value);
          
          // Обновляем UI для показа/скрытия кнопки очистки
          setState(() {});
        },
        
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          
          // Иконка лупы слева
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          
          // Кнопка очистки справа (показывается только когда есть текст)
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    // Отменяем активный таймер
                    _debounceTimer?.cancel();
                    
                    // Очищаем поле
                    _controller.clear();
                    
                    // Мгновенно показываем все элементы (без debounce)
                    // Потому что очистка — это завершённое действие [web:113]
                    widget.onSearch('');
                    widget.onClear?.call();
                    
                    // Скрываем кнопку очистки
                    setState(() {});
                  },
                )
              : null,
          
          // Стили рамки
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }
}
