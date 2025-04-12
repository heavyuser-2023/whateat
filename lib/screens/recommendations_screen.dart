import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_pkg;
import '../models/meal.dart';
import '../services/food_recognition_service.dart';
import '../database/database_helper.dart';
import 'meal_history_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  final File imageFile;
  final List<String> healthConditions;

  const RecommendationsScreen({
    Key? key,
    required this.imageFile,
    required this.healthConditions,
  }) : super(key: key);

  @override
  _RecommendationsScreenState createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final FoodRecognitionService _foodService = FoodRecognitionService();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<FoodRecommendation> _recommendations = [];
  String? _selectedFoodName;
  String _recognizedFood = '';
  String _evaluation = '';

  @override
  void initState() {
    super.initState();
    _analyzeFood();
  }

  Future<void> _analyzeFood() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      print('메뉴 이미지 분석 시작...'); // 디버그용 로그
      print('건강 조건: ${widget.healthConditions.join(', ')}'); // 디버그용 로그
      
      // 건강 조건이 너무 많으면 경고
      if (widget.healthConditions.length > 5) {
        print('주의: 건강 조건이 5개를 초과합니다. ${widget.healthConditions.length}개 조건');
      }
      
      // 새로운 확장된 분석 메서드 사용
      final analysisResult = await _foodService.analyzeFoodImage(
        widget.imageFile,
        widget.healthConditions,
      );
      
      print('분석 결과: 인식된 메뉴: ${analysisResult.recognizedFood}'); // 디버그용 로그
      print('분석 결과: 평가: ${analysisResult.evaluation}'); // 디버그용 로그
      print('분석 결과: 추천 개수: ${analysisResult.recommendations.length}'); // 디버그용 로그
      
      // 추천 결과 로깅
      for (var rec in analysisResult.recommendations) {
        print('추천: ${rec.name}, 점수: ${rec.compatibilityScore}'); // 디버그용 로그
      }
      
      // 추천 결과가 없거나 모델이 적절하게 응답하지 않았을 때 기본 처리
      if (analysisResult.recommendations.isEmpty) {
        print('추천 결과가 없습니다. 일반적인 건강식 추천으로 대체합니다.');
        // 모의 데이터 생성
        final defaultRecommendations = [
          FoodRecommendation(
            name: "샐러드", 
            description: "여러 건강 상태에 도움이 되는 가벼운 식사입니다.", 
            compatibilityScore: 0.95
          ),
          FoodRecommendation(
            name: "현미밥", 
            description: "정제되지 않은 통곡물로 영양가가 높습니다.", 
            compatibilityScore: 0.85
          ),
          FoodRecommendation(
            name: "찐 생선", 
            description: "지방이 적고 단백질이 풍부합니다.", 
            compatibilityScore: 0.80
          )
        ];
        
        setState(() {
          _recommendations = defaultRecommendations;
          _recognizedFood = analysisResult.recognizedFood.isEmpty ? 
              "메뉴 분석 결과" : analysisResult.recognizedFood;
          _evaluation = analysisResult.evaluation.isEmpty ? 
              "선택하신 건강 상태에 맞는 일반적인 추천입니다." : analysisResult.evaluation;
          _isLoading = false;
        });
      } else {
        setState(() {
          _recommendations = analysisResult.recommendations;
          _recognizedFood = analysisResult.recognizedFood;
          _evaluation = analysisResult.evaluation;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('메뉴 분석 오류: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '메뉴를 분석하는 중 오류가 발생했습니다: $e';
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMeal(String foodName) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 이미지를 앱 저장소에 복사
      final documentsDir = await getApplicationDocumentsDirectory();
      final fileName = 'meal_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImagePath = path_pkg.join(documentsDir.path, fileName);
      
      await widget.imageFile.copy(savedImagePath);

      // 해당 추천 항목 가져오기
      final selectedRecommendation = _recommendations.firstWhere(
        (recommendation) => recommendation.name == foodName,
      );

      // 식사 정보 저장
      final meal = Meal(
        name: selectedRecommendation.name,
        description: selectedRecommendation.description,
        imagePath: savedImagePath,
        date: DateTime.now(),
        healthConditions: widget.healthConditions,
      );

      await DatabaseHelper.instance.insertMeal(meal);

      setState(() {
        _isLoading = false;
        _selectedFoodName = foodName;
      });

      // 저장 완료 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('식사 정보가 저장되었습니다')),
      );
    } catch (e) {
      print('식사 저장 오류: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('식사 정보를 저장하는 중 오류가 발생했습니다.');
    }
  }

  void _viewMealHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (BuildContext context) => const MealHistoryScreen()),
    );
  }
  
  void _retryAnalysis() {
    _analyzeFood();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('분석 결과'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _viewMealHistory,
            tooltip: '식사 기록 보기',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('메뉴 이미지 분석 중...', style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : _hasError
              ? _buildErrorView()
              : _buildResultView(),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage.isEmpty 
                  ? '메뉴를 분석하는 중 오류가 발생했습니다.' 
                  : _errorMessage.replaceAll('이미지', '메뉴').replaceAll('추천 음식', '메뉴 내 추천 음식'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retryAnalysis,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 분석하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultView() {
    // 추천 음식 목록을 compatibilityScore 기준으로 정렬
    final sortedRecommendations = List<FoodRecommendation>.from(_recommendations)
      ..sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
      
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 이미지 영역
          Container(
            height: 180,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // 분석 결과 영역
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '인식된 메뉴: $_recognizedFood',
                  style: const TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '건강 평가: $_evaluation',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  '고려된 건강 조건: ${widget.healthConditions.join(", ")}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // 추천 음식 제목
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '이 메뉴에서 건강에 좋은 음식 순위',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // 다시 분석 버튼
          if (_recommendations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: _retryAnalysis,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 분석하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          
          // 추천 음식 목록
          _recommendations.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32.0),
                  alignment: Alignment.center,
                  child: const Text(
                    '이 메뉴에서 건강 상태에 적합한 음식을 찾을 수 없습니다.\n다른 메뉴를 다시 시도해보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
                  itemCount: sortedRecommendations.length,
                  itemBuilder: (BuildContext context, int index) {
                    final recommendation = sortedRecommendations[index];
                    final isSelected = recommendation.name == _selectedFoodName;
                    final rank = index + 1; // 1부터 시작하는 순위
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      color: isSelected ? Colors.green.shade100 : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _getRankColor(rank),
                                  foregroundColor: Colors.white,
                                  radius: 20,
                                  child: Text(
                                    '$rank',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    recommendation.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getCompatibilityColor(recommendation.compatibilityScore).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '적합도 ${(recommendation.compatibilityScore * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: _getCompatibilityColor(recommendation.compatibilityScore),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '추천 이유:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  recommendation.description,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.fromLTRB(0, 0, 8.0, 8.0),
                            child: isSelected
                                ? TextButton.icon(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    label: const Text('저장됨', style: TextStyle(color: Colors.green)),
                                    onPressed: null,
                                  )
                                : TextButton.icon(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                                    label: const Text('식사로 저장'),
                                    onPressed: () => _saveMeal(recommendation.name),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Color _getCompatibilityColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }
  
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade700; // 금메달 색상
      case 2:
        return Colors.blueGrey.shade400; // 은메달 색상
      case 3:
        return Colors.brown.shade300; // 동메달 색상
      default:
        return Colors.green;
    }
  }
} 