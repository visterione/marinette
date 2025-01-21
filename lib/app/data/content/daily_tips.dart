class DailyTip {
  final String tip;
  final String icon;

  const DailyTip({
    required this.tip,
    this.icon = '💡',
  });
}

const List<DailyTip> dailyTips = [
  DailyTip(
    tip: 'ice_cube_therapy',
    icon: '❄️',
  ),
  DailyTip(
    tip: 'apply_thinnest_to_thickest',
    icon: '🧴',
  ),
  DailyTip(
    tip: 'spf_on_cloudy_days',
    icon: '☀️',
  ),
  DailyTip(
    tip: 'stay_hydrated',
    icon: '💧',
  ),
  DailyTip(
    tip: 'clean_makeup_brushes',
    icon: '🖌️',
  ),
  DailyTip(
    tip: 'beauty_sleep',
    icon: '😴',
  ),
  DailyTip(
    tip: 'pat_dont_rub',
    icon: '👁️',
  ),
  DailyTip(
    tip: 'silk_pillowcase',
    icon: '🛏️',
  ),
  DailyTip(
    tip: 'face_masks_on_clean_skin',
    icon: '🎭',
  ),
  DailyTip(
    tip: 'dont_forget_neck',
    icon: '✨',
  ),
];
