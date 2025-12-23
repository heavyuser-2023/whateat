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
    String name = '';
    if (map['name'] != null) {
      name = map['name'] is List ? (map['name'] as List).join(', ') : map['name'].toString();
    }

    String description = '';
    if (map['description'] != null) {
      description = map['description'] is List ? (map['description'] as List).join(' ') : map['description'].toString();
    }

    String source = '';
    if (map['source'] != null) {
      source = map['source'] is List ? (map['source'] as List).join(', ') : map['source'].toString();
    }

    return FoodRecommendation(
      name: name,
      description: description,
      compatibilityScore: map['compatibilityScore']?.toDouble() ?? 0.0,
      source: source,
    );
  }
}
