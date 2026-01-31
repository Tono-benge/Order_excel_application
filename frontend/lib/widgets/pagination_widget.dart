 /*Виджет пагинации - Frontend UI)
Назначение: Кнопки навигации между страницами с индикатором текущей позиции
 */

 // ========== ИМПОРТЫ ==========
import 'package:flutter/material.dart'; // Основные виджеты Flutter

// Виджет пагинации (навигация по страницам)
class PaginationWidget extends StatelessWidget {
  final int currentPage;        // Текущая страница (начинается с 0)
  final int totalPages;         // Общее количество страниц
  final VoidCallback onNext;    // Действие при нажатии "Вперед"
  final VoidCallback onPrevious; // Действие при нажатии "Назад"
  final Function(int) onPageSelect; // Действие при выборе конкретной страницы

  const PaginationWidget({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onPrevious,
    required this.onPageSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Если страниц нет или только одна, не показываем пагинацию
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Центрируем содержимое
        children: [
          
          // ========== КНОПКА "НАЗАД" ==========
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 0 ? onPrevious : null, // Отключаем на первой странице
            tooltip: 'Предыдущая страница',
            
            // Делаем кнопку неактивной (серой) на первой странице
            color: currentPage > 0 ? Colors.blue : Colors.grey,
          ),
          
          const SizedBox(width: 8),
          
          // ========== НОМЕРА СТРАНИЦ ==========
          // Показываем не все страницы, а только ближайшие (чтобы не захламлять)
          ..._buildPageNumbers(),
          
          const SizedBox(width: 8),
          
          // ========== КНОПКА "ВПЕРЕД" ==========
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages - 1 ? onNext : null, // Отключаем на последней
            tooltip: 'Следующая страница',
            color: currentPage < totalPages - 1 ? Colors.blue : Colors.grey,
          ),
        ],
      ),
    );
  }

  // ========== ГЕНЕРАЦИЯ НОМЕРОВ СТРАНИЦ ==========
  List<Widget> _buildPageNumbers() {
    List<Widget> pageButtons = [];
    
    // Логика отображения страниц:
    // - Если страниц <= 7, показываем все
    // - Если больше, показываем: 1 ... 4 [5] 6 ... 10
    
    if (totalPages <= 7) {
      // Показываем все страницы
      for (int i = 0; i < totalPages; i++) {
        pageButtons.add(_buildPageButton(i));
      }
    } else {
      // Логика для большого количества страниц
      
      // Всегда показываем первую страницу
      pageButtons.add(_buildPageButton(0));
      
      // Определяем диапазон страниц вокруг текущей
      int start = (currentPage - 1).clamp(1, totalPages - 2);
      int end = (currentPage + 1).clamp(1, totalPages - 2);
      
      // Если между первой и диапазоном есть пропуск, добавляем "..."
      if (start > 1) {
        pageButtons.add(_buildEllipsis());
      }
      
      // Добавляем страницы вокруг текущей
      for (int i = start; i <= end; i++) {
        pageButtons.add(_buildPageButton(i));
      }
      
      // Если между диапазоном и последней есть пропуск, добавляем "..."
      if (end < totalPages - 2) {
        pageButtons.add(_buildEllipsis());
      }
      
      // Всегда показываем последнюю страницу
      pageButtons.add(_buildPageButton(totalPages - 1));
    }
    
    return pageButtons;
  }

  // ========== КНОПКА С НОМЕРОМ СТРАНИЦЫ ==========
  Widget _buildPageButton(int pageIndex) {
    final isActive = pageIndex == currentPage; // Это текущая страница?
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => onPageSelect(pageIndex),
        borderRadius: BorderRadius.circular(8),
        
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            // Если страница активна, заливаем синим цветом
            color: isActive ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? Colors.blue : Colors.grey.shade300,
              width: 1,
            ),
          ),
          
          alignment: Alignment.center,
          
          child: Text(
            '${pageIndex + 1}', // Отображаем страницы начиная с 1 (а не с 0)
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  // ========== ТРОЕТОЧИЕ (ПРОПУСК СТРАНИЦ) ==========
  Widget _buildEllipsis() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '...',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
