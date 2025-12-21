class FoodAnalysisResult {
  final String recognizedFood;
  final String evaluation;
  final List<FoodRecommendation> recommendations;

  FoodAnalysisResult({
    required this.recognizedFood, 
    required this.evaluation,
    required this.recommendations
  });
}

class FoodRecommendation {
  final String name;
  final String description;
  final double compatibilityScore;
  final String source;

  FoodRecommendation({
    required this.name,
    required this.description,
    required this.compatibilityScore,
    this.source = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'compatibilityScore': compatibilityScore,
      'source': source,
    };
  }

  factory FoodRecommendation.fromMap(Map<String, dynamic> map) {
    return FoodRecommendation(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      compatibilityScore: map['compatibilityScore']?.toDouble() ?? 0.0,
      source: map['source'] ?? '',
    );
  }
}
