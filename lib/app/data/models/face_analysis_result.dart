class FaceAnalysisResult {
  final String faceShape;
  final String colorType;
  final List<String> makeupRecommendations;
  final List<String> hairstyleRecommendations;
  final List<String> skincareRecommendations;

  FaceAnalysisResult({
    required this.faceShape,
    required this.colorType,
    required this.makeupRecommendations,
    required this.hairstyleRecommendations,
    required this.skincareRecommendations,
  });
}
