// lib/app/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'PlayfairDisplay',
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'PlayfairDisplay'),
          displayMedium: TextStyle(fontFamily: 'PlayfairDisplay'),
          displaySmall: TextStyle(fontFamily: 'PlayfairDisplay'),
          headlineLarge: TextStyle(fontFamily: 'PlayfairDisplay'),
          headlineMedium: TextStyle(fontFamily: 'PlayfairDisplay'),
          headlineSmall: TextStyle(fontFamily: 'PlayfairDisplay'),
          titleLarge: TextStyle(fontFamily: 'PlayfairDisplay'),
          titleMedium: TextStyle(fontFamily: 'PlayfairDisplay'),
          titleSmall: TextStyle(fontFamily: 'PlayfairDisplay'),
          bodyLarge: TextStyle(fontFamily: 'PlayfairDisplay'),
          bodyMedium: TextStyle(fontFamily: 'PlayfairDisplay'),
          bodySmall: TextStyle(fontFamily: 'PlayfairDisplay'),
        ),
        cardTheme: const CardTheme(
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.pink,
            textStyle: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.pink,
            textStyle: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.pink,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.pink,
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'PlayfairDisplay',
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'PlayfairDisplay'),
          displayMedium: TextStyle(fontFamily: 'PlayfairDisplay'),
          displaySmall: TextStyle(fontFamily: 'PlayfairDisplay'),
          headlineLarge: TextStyle(fontFamily: 'PlayfairDisplay'),
          headlineMedium: TextStyle(fontFamily: 'PlayfairDisplay'),
          headlineSmall: TextStyle(fontFamily: 'PlayfairDisplay'),
          titleLarge: TextStyle(fontFamily: 'PlayfairDisplay'),
          titleMedium: TextStyle(fontFamily: 'PlayfairDisplay'),
          titleSmall: TextStyle(fontFamily: 'PlayfairDisplay'),
          bodyLarge: TextStyle(fontFamily: 'PlayfairDisplay'),
          bodyMedium: TextStyle(fontFamily: 'PlayfairDisplay'),
          bodySmall: TextStyle(fontFamily: 'PlayfairDisplay'),
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        cardTheme: CardTheme(
          color: Colors.grey[900],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.pink,
            textStyle: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.pink,
            textStyle: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF121212),
          foregroundColor: Colors.pink,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.pink,
          ),
          iconTheme: IconThemeData(color: Colors.grey[200]),
        ),
      );
}
