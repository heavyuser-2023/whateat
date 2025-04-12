class HealthCondition {
  final int id;
  final String name;
  final String description;
  bool isSelected;

  HealthCondition({
    required this.id,
    required this.name,
    required this.description,
    this.isSelected = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isSelected': isSelected ? 1 : 0,
    };
  }

  factory HealthCondition.fromMap(Map<String, dynamic> map) {
    return HealthCondition(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      isSelected: map['isSelected'] == 1,
    );
  }

  HealthCondition copyWith({
    int? id,
    String? name,
    String? description,
    bool? isSelected,
  }) {
    return HealthCondition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

// 기본 건강 상태 리스트
List<HealthCondition> defaultHealthConditions = [
  HealthCondition(
    id: 1, 
    name: '콜레스테롤', 
    description: '콜레스테롤이 높은 음식 제한이 필요함',
  ),
  HealthCondition(
    id: 2, 
    name: '당뇨', 
    description: '혈당 지수가 높은 음식 제한이 필요함',
  ),
  HealthCondition(
    id: 3, 
    name: '고혈압', 
    description: '나트륨이 높은 음식 제한이 필요함',
  ),
  HealthCondition(
    id: 4, 
    name: '위장 질환', 
    description: '자극적인 음식 제한이 필요함',
  ),
  HealthCondition(
    id: 5, 
    name: '알레르기', 
    description: '특정 음식에 알레르기가 있음',
  ),
  HealthCondition(
    id: 6, 
    name: '유방암', 
    description: '유방암 환자를 위한 식단 필요',
  ),
  HealthCondition(
    id: 7, 
    name: '대장암', 
    description: '대장암 환자를 위한 식단 필요',
  ),
  HealthCondition(
    id: 8, 
    name: '폐암', 
    description: '폐암 환자를 위한 식단 필요',
  ),
  HealthCondition(
    id: 9, 
    name: '근육질 몸만들기', 
    description: '근육량 증가를 위한 고단백 식단 필요',
  ),
  HealthCondition(
    id: 10, 
    name: '살빼기', 
    description: '체중 감량을 위한 저칼로리 식단 필요',
  ),
  HealthCondition(
    id: 11, 
    name: '위암', 
    description: '위암 환자를 위한 식단 필요',
  ),
  HealthCondition(
    id: 12, 
    name: '간암', 
    description: '간암 환자를 위한 식단 필요',
  ),
  HealthCondition(
    id: 13, 
    name: '췌장암', 
    description: '췌장암 환자를 위한 식단 필요',
  ),
  HealthCondition(
    id: 14, 
    name: '갑상선암', 
    description: '갑상선암 환자를 위한 식단 필요',
  ),
  HealthCondition(
    id: 15, 
    name: '전립선암', 
    description: '전립선암 환자를 위한 식단 필요',
  ),
]; 