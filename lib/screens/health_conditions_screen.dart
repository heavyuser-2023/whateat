import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/health_condition.dart';
import 'camera_screen.dart';

class HealthConditionsScreen extends StatefulWidget {
  const HealthConditionsScreen({Key? key}) : super(key: key);

  @override
  _HealthConditionsScreenState createState() => _HealthConditionsScreenState();
}

class _HealthConditionsScreenState extends State<HealthConditionsScreen> {
  final List<HealthCondition> _healthConditions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHealthConditions();
  }

  Future<void> _loadHealthConditions() async {
    try {
      final conditions = await DatabaseHelper.instance.getHealthConditions();
      setState(() {
        _healthConditions.clear();
        _healthConditions.addAll(conditions);
        _isLoading = false;
      });
    } catch (e) {
      print('건강 상태 불러오기 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 카테고리별로 건강 상태 그룹화
    final Map<String, List<HealthCondition>> categorizedConditions = {
      '기본 건강 상태': _healthConditions.where((c) => c.id <= 5).toList(),
      '암 관련 건강 상태': _healthConditions.where((c) => c.id >= 6 && c.id <= 8 || c.id >= 11 && c.id <= 15).toList(),
      '체중 & 체형 관리': _healthConditions.where((c) => c.id >= 9 && c.id <= 10).toList(),
    };

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('맞춤 건강 상태 선택'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF4FBF4),
              Color(0xFFE8F5E9),
              Color(0xFFE0F2F1),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    // 상단 안내 카드
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.health_and_safety,
                            color: Color(0xFF34A853),
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '나에게 맞는 건강 관리 옵션을 선택해 주세요',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF202124),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '선택한 건강 상태에 따라 최적의 식단을 추천해 드립니다',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    // 건강 상태 목록
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: categorizedConditions.length,
                        itemBuilder: (context, index) {
                          final category = categorizedConditions.keys.elementAt(index);
                          final conditions = categorizedConditions[category]!;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 카테고리 제목
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF34A853).withOpacity(0.1),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getCategoryIcon(category),
                                        color: const Color(0xFF34A853),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        category,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF34A853),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // 조건 목록
                                ...conditions.map((condition) => _buildConditionTile(condition)).toList(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // 하단 버튼
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF34A853), Color(0xFF4285F4)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF34A853).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            final selectedConditions = _healthConditions
                                .where((condition) => condition.isSelected)
                                .toList();
                            
                            if (selectedConditions.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    '최소한 하나 이상의 건강 상태를 선택해주세요',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                              return;
                            }
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CameraScreen(
                                  selectedHealthConditions: selectedConditions,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                '다음',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
  
  Widget _buildConditionTile(HealthCondition condition) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: condition.isSelected 
            ? const Color(0xFF34A853).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        title: Text(
          condition.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: condition.isSelected 
                ? const Color(0xFF34A853)
                : const Color(0xFF202124),
          ),
        ),
        subtitle: Text(
          condition.description,
          style: TextStyle(
            fontSize: 13,
            color: condition.isSelected 
                ? const Color(0xFF34A853).withOpacity(0.8)
                : Colors.grey[600],
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: condition.isSelected 
                ? const Color(0xFF34A853).withOpacity(0.2)
                : const Color(0xFF34A853).withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForCondition(condition.id),
            color: condition.isSelected 
                ? const Color(0xFF34A853)
                : Colors.grey[600],
            size: 24,
          ),
        ),
        value: condition.isSelected,
        activeColor: const Color(0xFF34A853),
        checkColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onChanged: (bool? value) async {
          final updatedCondition = condition.copyWith(
            isSelected: value ?? false,
          );
          
          await DatabaseHelper.instance
              .updateHealthCondition(updatedCondition);
          
          setState(() {
            final index = _healthConditions.indexWhere((c) => c.id == condition.id);
            if (index != -1) {
              _healthConditions[index] = updatedCondition;
            }
          });
        },
      ),
    );
  }
  
  IconData _getIconForCondition(int id) {
    switch (id) {
      case 1: return Icons.medical_information;  // 콜레스테롤
      case 2: return Icons.monitor_heart;        // 당뇨
      case 3: return Icons.favorite;             // 고혈압
      case 4: return Icons.sick;                 // 위장 질환
      case 5: return Icons.warning_amber;        // 알레르기
      case 6:                                    // 유방암
      case 7:                                    // 대장암
      case 8:                                    // 폐암
      case 11:                                   // 위암
      case 12:                                   // 간암
      case 13:                                   // 췌장암
      case 14:                                   // 갑상선암
      case 15: return Icons.healing;             // 전립선암
      case 9: return Icons.fitness_center;       // 근육질 몸만들기
      case 10: return Icons.line_weight;         // 살빼기
      default: return Icons.health_and_safety;   // 기본 아이콘
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '기본 건강 상태':
        return Icons.favorite;
      case '암 관련 건강 상태':
        return Icons.healing;
      case '체중 & 체형 관리':
        return Icons.fitness_center;
      default:
        return Icons.health_and_safety;
    }
  }
} 