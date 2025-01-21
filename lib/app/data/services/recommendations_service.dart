import 'package:get/get.dart';
import 'package:marinette/app/data/services/face_shape_analyzer.dart';
import 'package:marinette/app/data/services/color_type_analyzer.dart';

class RecommendationsService {
  static List<String> getMakeupRecommendations(
      FaceShape shape, ColorType colorType) {
    List<String> recommendations = [];
    recommendations.addAll(_getMakeupShapeRecommendations(shape));
    recommendations.addAll(_getMakeupColorRecommendations(colorType));
    return recommendations;
  }

  static List<String> _getMakeupShapeRecommendations(FaceShape shape) {
    switch (shape) {
      case FaceShape.oval:
        return [
          'makeup_shape_oval'.tr,
          'makeup_shape_oval_2'.tr,
          'makeup_shape_oval_3'.tr,
          'makeup_shape_oval_4'.tr,
          'makeup_shape_oval_5'.tr
        ];

      case FaceShape.round:
        return [
          'makeup_shape_round'.tr,
          'makeup_shape_round_2'.tr,
          'makeup_shape_round_3'.tr,
          'makeup_shape_round_4'.tr,
          'makeup_shape_round_5'.tr
        ];

      case FaceShape.square:
        return [
          'makeup_shape_square'.tr,
          'makeup_shape_square_2'.tr,
          'makeup_shape_square_3'.tr,
          'makeup_shape_square_4'.tr,
          'makeup_shape_square_5'.tr
        ];

      case FaceShape.heart:
        return [
          'makeup_shape_heart'.tr,
          'makeup_shape_heart_2'.tr,
          'makeup_shape_heart_3'.tr,
          'makeup_shape_heart_4'.tr,
          'makeup_shape_heart_5'.tr
        ];

      case FaceShape.diamond:
        return [
          'makeup_shape_diamond'.tr,
          'makeup_shape_diamond_2'.tr,
          'makeup_shape_diamond_3'.tr,
          'makeup_shape_diamond_4'.tr,
          'makeup_shape_diamond_5'.tr
        ];

      case FaceShape.rectangle:
        return [
          'makeup_shape_rectangle'.tr,
          'makeup_shape_rectangle_2'.tr,
          'makeup_shape_rectangle_3'.tr,
          'makeup_shape_rectangle_4'.tr,
          'makeup_shape_rectangle_5'.tr
        ];
    }
  }

  static List<String> _getMakeupColorRecommendations(ColorType colorType) {
    switch (colorType) {
      case ColorType.spring:
        return [
          'makeup_color_spring'.tr,
          'makeup_color_spring_2'.tr,
          'makeup_color_spring_3'.tr,
          'makeup_color_spring_4'.tr,
          'makeup_color_spring_5'.tr
        ];

      case ColorType.summer:
        return [
          'makeup_color_summer'.tr,
          'makeup_color_summer_2'.tr,
          'makeup_color_summer_3'.tr,
          'makeup_color_summer_4'.tr,
          'makeup_color_summer_5'.tr
        ];

      case ColorType.autumn:
        return [
          'makeup_color_autumn'.tr,
          'makeup_color_autumn_2'.tr,
          'makeup_color_autumn_3'.tr,
          'makeup_color_autumn_4'.tr,
          'makeup_color_autumn_5'.tr
        ];

      case ColorType.winter:
        return [
          'makeup_color_winter'.tr,
          'makeup_color_winter_2'.tr,
          'makeup_color_winter_3'.tr,
          'makeup_color_winter_4'.tr,
          'makeup_color_winter_5'.tr
        ];
    }
  }

  static List<String> getHairstyleRecommendations(
      FaceShape shape, ColorType colorType) {
    List<String> recommendations = [];
    recommendations.addAll(_getHairstyleShapeRecommendations(shape));
    recommendations.addAll(_getHairColorRecommendations(colorType));
    return recommendations;
  }

  static List<String> _getHairstyleShapeRecommendations(FaceShape shape) {
    switch (shape) {
      case FaceShape.oval:
        return [
          'hairstyle_oval'.tr,
          'hairstyle_oval_2'.tr,
          'hairstyle_oval_3'.tr,
          'hairstyle_oval_4'.tr,
          'hairstyle_oval_5'.tr
        ];

      case FaceShape.round:
        return [
          'hairstyle_round'.tr,
          'hairstyle_round_2'.tr,
          'hairstyle_round_3'.tr,
          'hairstyle_round_4'.tr,
          'hairstyle_round_5'.tr
        ];

      case FaceShape.square:
        return [
          'hairstyle_square'.tr,
          'hairstyle_square_2'.tr,
          'hairstyle_square_3'.tr,
          'hairstyle_square_4'.tr,
          'hairstyle_square_5'.tr
        ];

      case FaceShape.heart:
        return [
          'hairstyle_heart'.tr,
          'hairstyle_heart_2'.tr,
          'hairstyle_heart_3'.tr,
          'hairstyle_heart_4'.tr,
          'hairstyle_heart_5'.tr
        ];

      case FaceShape.diamond:
        return [
          'hairstyle_diamond'.tr,
          'hairstyle_diamond_2'.tr,
          'hairstyle_diamond_3'.tr,
          'hairstyle_diamond_4'.tr,
          'hairstyle_diamond_5'.tr
        ];

      case FaceShape.rectangle:
        return [
          'hairstyle_rectangle'.tr,
          'hairstyle_rectangle_2'.tr,
          'hairstyle_rectangle_3'.tr,
          'hairstyle_rectangle_4'.tr,
          'hairstyle_rectangle_5'.tr
        ];
    }
  }

  static List<String> _getHairColorRecommendations(ColorType colorType) {
    switch (colorType) {
      case ColorType.spring:
        return [
          'haircolor_spring'.tr,
          'haircolor_spring_2'.tr,
          'haircolor_spring_3'.tr
        ];

      case ColorType.summer:
        return [
          'haircolor_summer'.tr,
          'haircolor_summer_2'.tr,
          'haircolor_summer_3'.tr
        ];

      case ColorType.autumn:
        return [
          'haircolor_autumn'.tr,
          'haircolor_autumn_2'.tr,
          'haircolor_autumn_3'.tr
        ];

      case ColorType.winter:
        return [
          'haircolor_winter'.tr,
          'haircolor_winter_2'.tr,
          'haircolor_winter_3'.tr
        ];
    }
  }

  static List<String> getSkincareRecommendations(ColorType colorType) {
    List<String> baseRecommendations = [
      'skincare_recommendation_1'.tr,
      'skincare_recommendation_2'.tr,
      'skincare_recommendation_3'.tr,
      'skincare_recommendation_4'.tr,
      'skincare_recommendation_5'.tr
    ];

    List<String> colorTypeRecommendations =
        _getSkincareColorRecommendations(colorType);

    return [...baseRecommendations, ...colorTypeRecommendations];
  }

  static List<String> _getSkincareColorRecommendations(ColorType type) {
    switch (type) {
      case ColorType.spring:
        return [
          'skincare_spring'.tr,
          'skincare_spring_2'.tr,
          'skincare_spring_3'.tr,
          'skincare_spring_4'.tr,
          'skincare_spring_5'.tr
        ];

      case ColorType.summer:
        return [
          'skincare_summer'.tr,
          'skincare_summer_2'.tr,
          'skincare_summer_3'.tr,
          'skincare_summer_4'.tr,
          'skincare_summer_5'.tr
        ];

      case ColorType.autumn:
        return [
          'skincare_autumn'.tr,
          'skincare_autumn_2'.tr,
          'skincare_autumn_3'.tr,
          'skincare_autumn_4'.tr,
          'skincare_autumn_5'.tr
        ];

      case ColorType.winter:
        return [
          'skincare_winter'.tr,
          'skincare_winter_2'.tr,
          'skincare_winter_3'.tr,
          'skincare_winter_4'.tr,
          'skincare_winter_5'.tr
        ];
    }
  }

  static String getSeasonalRecommendation() {
    final now = DateTime.now();
    final month = now.month;

    // Зима (грудень, січень, лютий)
    if (month == 12 || month == 1 || month == 2) {
      return 'season_winter'.tr;
    }
    // Весна (березень, квітень, травень)
    else if (month >= 3 && month <= 5) {
      return 'season_spring'.tr;
    }
    // Літо (червень, липень, серпень)
    else if (month >= 6 && month <= 8) {
      return 'season_summer'.tr;
    }
    // Осінь (вересень, жовтень, листопад)
    else {
      return 'season_autumn'.tr;
    }
  }

  static List<String> getPersonalizedTips({
    required FaceShape faceShape,
    required ColorType colorType,
  }) {
    List<String> tips = [];

    // Додаємо специфічні поради щодо макіяжу
    tips.add(_getPersonalizedMakeupTip(faceShape, colorType));

    // Додаємо пораду щодо догляду за волоссям
    tips.add(_getPersonalizedHairTip(faceShape));

    // Додаємо сезонну пораду
    tips.add(getSeasonalRecommendation());

    return tips;
  }

  static String _getPersonalizedMakeupTip(
      FaceShape faceShape, ColorType colorType) {
    // Базова порада щодо форми обличчя
    String tip = 'personalized_makeup_base'.tr;

    // Додаємо специфіку для форми обличчя
    switch (faceShape) {
      case FaceShape.oval:
        tip += 'personalized_makeup_oval'.tr;
        break;
      case FaceShape.round:
        tip += 'personalized_makeup_round'.tr;
        break;
      case FaceShape.square:
        tip += 'personalized_makeup_square'.tr;
        break;
      case FaceShape.heart:
        tip += 'personalized_makeup_heart'.tr;
        break;
      case FaceShape.diamond:
        tip += 'personalized_makeup_diamond'.tr;
        break;
      case FaceShape.rectangle:
        tip += 'personalized_makeup_rectangle'.tr;
        break;
    }

    // Додаємо пораду щодо кольоротипу
    tip += '. ';
    switch (colorType) {
      case ColorType.spring:
        tip += 'personalized_makeup_spring'.tr;
        break;
      case ColorType.summer:
        tip += 'personalized_makeup_summer'.tr;
        break;
      case ColorType.autumn:
        tip += 'personalized_makeup_autumn'.tr;
        break;
      case ColorType.winter:
        tip += 'personalized_makeup_winter'.tr;
        break;
    }

    return tip;
  }

  static String _getPersonalizedHairTip(FaceShape faceShape) {
    String tip = 'personalized_hair'.tr;

    switch (faceShape) {
      case FaceShape.oval:
        return tip + 'personalized_hair_oval'.tr;
      case FaceShape.round:
        return tip + 'personalized_hair_round'.tr;
      case FaceShape.square:
        return tip + 'personalized_hair_square'.tr;
      case FaceShape.heart:
        return tip + 'personalized_hair_heart'.tr;
      case FaceShape.diamond:
        return tip + 'personalized_hair_diamond'.tr;
      case FaceShape.rectangle:
        return tip + 'personalized_hair_rectangle'.tr;
    }
  }
}
