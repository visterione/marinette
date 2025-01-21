class BeautyTrend {
  final String title;
  final String description;
  final String season; // 'winter', 'spring', 'summer', 'autumn'

  const BeautyTrend({
    required this.title,
    required this.description,
    required this.season,
  });
}

const List<BeautyTrend> beautyTrends = [
  // Spring Trends
  BeautyTrend(
    title: 'glass_skin',
    description: 'glass_skin_description',
    season: 'spring',
  ),
  BeautyTrend(
    title: 'pastel_eyeshadows',
    description: 'pastel_eyeshadows_description',
    season: 'spring',
  ),
  BeautyTrend(
    title: 'natural_blush',
    description: 'natural_blush_description',
    season: 'spring',
  ),

  // Summer Trends
  BeautyTrend(
    title: 'sunburnt_blush',
    description: 'sunburnt_blush_description',
    season: 'summer',
  ),
  BeautyTrend(
    title: 'glazed_skin',
    description: 'glazed_skin_description',
    season: 'summer',
  ),
  BeautyTrend(
    title: 'waterproof_makeup',
    description: 'waterproof_makeup_description',
    season: 'summer',
  ),

  // Autumn Trends
  BeautyTrend(
    title: 'soft_matte_skin',
    description: 'soft_matte_skin_description',
    season: 'autumn',
  ),
  BeautyTrend(
    title: 'berry_lips',
    description: 'berry_lips_description',
    season: 'autumn',
  ),
  BeautyTrend(
    title: 'copper_eyes',
    description: 'copper_eyes_description',
    season: 'autumn',
  ),

  // Winter Trends
  BeautyTrend(
    title: 'glossy_lips',
    description: 'glossy_lips_description',
    season: 'winter',
  ),
  BeautyTrend(
    title: 'frosted_looks',
    description: 'frosted_looks_description',
    season: 'winter',
  ),
  BeautyTrend(
    title: 'rich_hydration',
    description: 'rich_hydration_description',
    season: 'winter',
  ),
];
