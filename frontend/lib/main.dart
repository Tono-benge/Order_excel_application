// ========== ИМПОРТЫ ==========

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Относительные импорты внутри проекта:
import 'screens/home_screen.dart';
import 'providers/user_provider.dart';
import 'providers/order_provider.dart'; //Этот импорт нужен, чтобы в main.dart использовать класс OrderProvider.
import 'package:provider/provider.dart';
import 'providers/import_provider.dart';

// Точка входа в приложение
// main() - первая функция, которая вызывается при запуске
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImportProvider()),
        // остальные провайдеры
      ],
      child: const MyApp(),
    ),
  );
}

// Корневой виджет приложения
class MyApp extends StatelessWidget {
  const MyApp({super.key}); // ✅ ИСПРАВЛЕНО: super.key вместо Key? key

  @override
  Widget build(BuildContext context) {
    // ========== НАСТРОЙКА PROVIDER'ОВ ==========
    // MultiProvider позволяет зарегистрировать несколько Provider'ов сразу
    return MultiProvider(
      providers: [
        // Регистрируем UserProvider
        // ChangeNotifierProvider создает экземпляр Provider'а и управляет его жизненным циклом
        ChangeNotifierProvider(
          create: (context) => UserProvider(),
        ),

        // Регистрируем OrderProvider
        ChangeNotifierProvider(
          create: (context) => OrderProvider(),
        ),
      ],

      // ========== НАСТРОЙКА ПРИЛОЖЕНИЯ ==========
      child: MaterialApp(
        // MaterialApp - корневой виджет для Material Design приложений

        title: 'Управление заказами монтажников',

        // debugShowCheckedModeBanner: false убирает баннер "DEBUG" в правом верхнем углу
        debugShowCheckedModeBanner: false,

        // ========== ТЕМА ПРИЛОЖЕНИЯ ==========
        theme: ThemeData(
          // Основная цветовая схема  
          colorScheme: const ColorScheme.highContrastLight() ,

          // Настройка AppBar
          appBarTheme: const AppBarTheme(
            elevation: 2, // Высота тени
            centerTitle: true, // Центрировать заголовок
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          // Настройка FloatingActionButton
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),

          // ✅ ИСПРАВЛЕНО: CardTheme заменен на cardTheme с CardThemeData
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          // Настройка InputDecoration (текстовые поля)
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),

          // Использование Material 3 дизайна
          useMaterial3: true,
        ),

        // ========== ГЛАВНЫЙ ЭКРАН ==========
        home: const HomeScreen(),
      ),
    );
  }
}
