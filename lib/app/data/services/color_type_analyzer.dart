import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:marinette/app/data/services/skin_color_analyzer.dart';

enum ColorType {
  spring, // Тепле-яскраве
  summer, // Холодне-м'яке
  autumn, // Тепле-м'яке
  winter, // Холодне-яскраве
}

class ColorTypeAnalyzer {
  static Future<ColorType> analyzeColorType(String imagePath, Face face) async {
    try {
      final skinTone = await SkinColorAnalyzer.analyzeSkinTone(imagePath, face);

      // Визначаємо кольоротип на основі характеристик кольору шкіри
      bool isWarm = skinTone.warmth > 0.5;
      bool isBright = skinTone.saturation > 0.4;
      bool isLight = skinTone.lightness > 0.5;

      // Основна логіка визначення кольоротипу:
      if (isWarm) {
        // Теплі кольоротипи
        if (isBright && isLight) {
          return ColorType.spring; // Тепле-яскраве
        } else {
          return ColorType.autumn; // Тепле-м'яке
        }
      } else {
        // Холодні кольоротипи
        if (isBright) {
          return ColorType.winter; // Холодне-яскраве
        } else {
          return ColorType.summer; // Холодне-м'яке
        }
      }
    } catch (e) {
      // У випадку помилки повертаємо spring як найбільш універсальний тип
      return ColorType.spring;
    }
  }

  static Map<String, List<String>> getColorPalette(ColorType colorType) {
    switch (colorType) {
      case ColorType.spring:
        return {
          'основні': ['Теплий жовтий', 'Кораловий', 'Персиковий', 'Золотистий'],
          'акцентні': ['Яскраво-зелений', 'Бірюзовий', 'Світло-рожевий'],
          'уникати': ['Чорний', 'Сірий', 'Приглушені холодні відтінки'],
        };
      case ColorType.summer:
        return {
          'основні': ['Холодний рожевий', 'Лавандовий', 'Блакитний', 'Сірий'],
          'акцентні': ['М\'ята', 'Бузковий', 'Сріблястий'],
          'уникати': ['Помаранчевий', 'Коричневий', 'Яскраві теплі відтінки'],
        };
      case ColorType.autumn:
        return {
          'основні': ['Теракотовий', 'Хакі', 'Гірчичний', 'Коричневий'],
          'акцентні': ['Бронзовий', 'Оливковий', 'Мідний'],
          'уникати': ['Яскраво-рожевий', 'Сріблястий', 'Холодні пастельні'],
        };
      case ColorType.winter:
        return {
          'основні': ['Чистий білий', 'Чорний', 'Темно-синій', 'Сапфіровий'],
          'акцентні': ['Смарагдовий', 'Фуксія', 'Яскраво-червоний'],
          'уникати': ['Бежевий', 'Помаранчевий', 'Приглушені теплі відтінки'],
        };
    }
  }

  static Map<String, List<String>> getMakeupColors(ColorType colorType) {
    switch (colorType) {
      case ColorType.spring:
        return {
          'помада': ['Кораловий', 'Персиковий', 'Теплий рожевий'],
          'рум\'яна': ['Персиковий', 'Абрикосовий', 'Золотистий'],
          'тіні': ['Золотисто-коричневий', 'Бронзовий', 'Теплий зелений'],
        };
      case ColorType.summer:
        return {
          'помада': ['Холодний рожевий', 'Малиновий', 'Сливовий'],
          'рум\'яна': ['Рожевий', 'Лавандовий', 'Світло-малиновий'],
          'тіні': ['Сірий', 'Блакитний', 'Рожево-коричневий'],
        };
      case ColorType.autumn:
        return {
          'помада': ['Теракотовий', 'Мідний', 'Коричневий'],
          'рум\'яна': ['Теракотовий', 'Бронзовий', 'Теплий коричневий'],
          'тіні': ['Золотисто-коричневий', 'Хакі', 'Мідний'],
        };
      case ColorType.winter:
        return {
          'помада': ['Яскраво-червоний', 'Фуксія', 'Бордовий'],
          'рум\'яна': ['Холодний рожевий', 'Вишневий', 'Малиновий'],
          'тіні': ['Димчастий', 'Синій', 'Сріблястий'],
        };
    }
  }
}
