import 'dart:convert';

class Meal {
  final int? id;
  final String name;
  final String description;
  final String imagePath;
  final DateTime date;
  final List<String> healthConditions;

  Meal({
    this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.date,
    required this.healthConditions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'date': date.toIso8601String(),
      'healthConditions': jsonEncode(healthConditions),
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      imagePath: map['imagePath'],
      date: DateTime.parse(map['date']),
      healthConditions: List<String>.from(jsonDecode(map['healthConditions'])),
    );
  }

  Meal copyWith({
    int? id,
    String? name,
    String? description,
    String? imagePath,
    DateTime? date,
    List<String>? healthConditions,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      date: date ?? this.date,
      healthConditions: healthConditions ?? this.healthConditions,
    );
  }
}

class FoodRecommendation {
  final String name;
  final String description;
  final double compatibilityScore;

  FoodRecommendation({
    required this.name,
    required this.description,
    required this.compatibilityScore,
  });

  factory FoodRecommendation.fromJson(Map<String, dynamic> json) {
    return FoodRecommendation(
      name: json['name'],
      description: json['description'],
      compatibilityScore: json['compatibilityScore'],
    );
  }
} 