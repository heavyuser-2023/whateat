import 'dart:convert';
import 'dart:io';

class Meal {
  final int? id;
  final String name;
  final String description;
  final String imagePath;
  final List<int>? imageData;
  final DateTime date;
  final List<String> healthConditions;

  Meal({
    this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    this.imageData,
    required this.date,
    required this.healthConditions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'imageData': imageData,
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
      
      // 이미지 경로 처리
      String imagePath = map['imagePath'] ?? '';
      
      // 이미지 데이터 처리
      List<int>? imageData;
      if (map['imageData'] != null) {
        imageData = List<int>.from(map['imageData']);
      }
      
      // 이미지 경로 유효성 확인
      if (imagePath.isNotEmpty) {
        try {
          final file = File(imagePath);
          final exists = file.existsSync();
          if (!exists) {
            print('경고: 이미지 파일 없음 - $imagePath');
            
            // 파일이 존재하지 않아도 앱이 중단되지 않도록 경로는 그대로 유지
            // 화면에서 이미지 로드 시 플레이스홀더를 표시할 수 있도록 함
          }
        } catch (e) {
          print('이미지 파일 확인 중 오류 발생: $e');
        }
      } else {
        print('경고: 이미지 경로가 비어 있음');
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
        imagePath: imagePath,
        imageData: imageData,
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
        imageData: null,
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
    List<int>? imageData,
    DateTime? date,
    List<String>? healthConditions,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      imageData: imageData ?? this.imageData,
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