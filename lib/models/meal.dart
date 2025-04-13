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
    try {
      // ID 처리 (null이거나 숫자 타입이 아닌 경우 처리)
      int? id;
      if (map['id'] != null) {
        id = map['id'] is int ? map['id'] : int.tryParse(map['id'].toString());
      }
      
      // 날짜 처리
      DateTime date;
      try {
        date = DateTime.parse(map['date']);
      } catch (e) {
        print('날짜 파싱 오류: ${map['date']}');
        date = DateTime.now(); // 기본값 사용
      }
      
      // 건강 조건 목록 처리
      List<String> healthConditions = [];
      try {
        if (map['healthConditions'] != null) {
          var decodedConditions = jsonDecode(map['healthConditions']);
          if (decodedConditions is List) {
            healthConditions = List<String>.from(decodedConditions);
          }
        }
      } catch (e) {
        print('건강 조건 파싱 오류: ${map['healthConditions']}');
        // 기본 빈 목록 사용
      }
      
      return Meal(
        id: id,
        name: map['name'] ?? '알 수 없는 식사',
        description: map['description'] ?? '',
        imagePath: map['imagePath'] ?? '',
        date: date,
        healthConditions: healthConditions,
      );
    } catch (e) {
      print('Meal 객체 생성 중 오류: $e');
      // 최소한의 기본 정보로 객체 생성 (앱 크래시 방지)
      return Meal(
        id: null,
        name: '데이터 오류',
        description: '식사 정보를 불러오는 중 오류가 발생했습니다.',
        imagePath: '',
        date: DateTime.now(),
        healthConditions: [],
      );
    }
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