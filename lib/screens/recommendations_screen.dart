import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/meal.dart';
import '../services/food_recognition_service.dart';
import '../database/database_helper.dart';
import 'meal_history_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoogleBannerAd extends StatefulWidget {
  final String adType;
  
  const GoogleBannerAd({
    Key? key,
    this.adType = 'normal',
  }) : super(key: key);

  @override
  State<GoogleBannerAd> createState() => _GoogleBannerAdState();
}

class _GoogleBannerAdState extends State<GoogleBannerAd> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    // 테스트 광고 ID - 실제 앱에서는 AdMob에서 발급받은 실제 ID로 변경 필요
    final adUnitId = Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/6300978111'  // 안드로이드 테스트 ID
        : 'ca-app-pub-3940256099942544/2934735716'; // iOS 테스트 ID

    // 광고 사이즈 설정 (BANNER, LARGE_BANNER, MEDIUM_RECTANGLE, FULL_BANNER, LEADERBOARD)
    final adSize = widget.adType == 'large' ? AdSize.mediumRectangle : AdSize.banner;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('배너 광고 로드 성공');
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('배너 광고 로드 실패: ${error.message}');
          ad.dispose();
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd == null || !_isAdLoaded) {
      return Container(
        height: widget.adType == 'large' ? 250 : 60,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('광고 로딩 중...', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

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
  Set<String> _selectedFoodNames = {};
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
        print('추천 결과가 없습니다.');
        
        setState(() {
          _recommendations = []; // 빈 추천 목록 유지
          _recognizedFood = analysisResult.recognizedFood.isEmpty ? 
              "메뉴 분석 결과" : analysisResult.recognizedFood;
          _evaluation = analysisResult.evaluation.isEmpty ? 
              "이 메뉴에서 건강 상태에 적합한 음식을 찾을 수 없습니다." : analysisResult.evaluation;
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

  Future<void> _saveMeal() async {
    print('식사 저장 시작'); // 디버그 로그
    
    try {
      setState(() {
        _isLoading = true;
      });

      // 사용자가 최소 하나의 음식 항목을 선택했는지 확인
      if (_selectedFoodNames.isEmpty) {
        _showErrorDialog('저장할 음식을 한 개 이상 선택해주세요');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 원본 이미지 파일 접근 확인
      if (!await widget.imageFile.exists()) {
        print('원본 이미지 파일이 존재하지 않음: ${widget.imageFile.path}');
        _showErrorDialog('이미지 파일이 없어 저장할 수 없습니다');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // 앱 내부 저장소 디렉토리 경로 획득
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String mealImagesPath = path_pkg.join(appDir.path, 'meal_images');
      
      // 디렉토리 생성 (없는 경우)
      final Directory mealImagesDir = Directory(mealImagesPath);
      if (!await mealImagesDir.exists()) {
        await mealImagesDir.create(recursive: true);
      }
      
      // 저장할 이미지 경로
      final String savedImagePath = path_pkg.join(mealImagesPath, fileName);

      // 이미지 파일 복사
      await widget.imageFile.copy(savedImagePath);
      print('이미지 저장됨: $savedImagePath'); // 디버그 로그
      
      // 이미지 데이터 읽기
      List<int> imageData = await widget.imageFile.readAsBytes();
      print('이미지 데이터 크기: ${imageData.length} 바이트'); // 디버그 로그

      // 식사 정보 객체 생성
      final meal = Meal(
        name: _selectedFoodNames.join(', '),
        description: _recommendations
            .where((rec) => _selectedFoodNames.contains(rec.name))
            .map((rec) => '${rec.name}: ${rec.description}')
            .join('\n\n'),
        imagePath: savedImagePath,
        imageData: imageData,
        date: DateTime.now(),
        healthConditions: widget.healthConditions,
      );

      // 데이터베이스에 저장
      final int mealId = await DatabaseHelper.instance.insertMeal(meal);
      print('저장된 식사 ID: $mealId'); // 디버그 로그
      
      // 식사 목록 업데이트 (SharedPreferences)
      await _updateMealRecords();
      
      setState(() {
        _isLoading = false;
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
      _showErrorDialog('식사 정보를 저장하는 중 오류가 발생했습니다: $e');
    }
  }

  void _viewMealHistory() {
    print('식사 기록 화면으로 이동'); // 디버그 로그
    
    // 식사 저장 중이면 완료될 때까지 기다림
    if (_isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('식사 저장 중입니다. 잠시 기다려주세요.')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => const MealHistoryScreen(refreshOnShow: true),
      ),
    ).then((_) {
      // 식사 기록 화면에서 돌아왔을 때 UI 갱신 (필요시)
      print('식사 기록 화면에서 돌아옴'); // 디버그 로그
      setState(() {});
    });
  }
  
  void _retryAnalysis() {
    _analyzeFood();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '분석 결과',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: _viewMealHistory,
            tooltip: '식사 기록 보기',
          ),
          if (_recommendations.isNotEmpty && _selectedFoodNames.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveMeal,
              tooltip: '선택한 음식을 저장',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('메뉴 이미지 분석 중...', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  // 로딩 중 Google AdMob 배너 광고 추가
                  const GoogleBannerAd(),
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
    // 추천 음식 목록을 건강에 좋은 음식과 차선책으로 분리
    final goodFoods = _recommendations.where((rec) => !rec.name.toLowerCase().contains('차선책')).toList()
      ..sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
    
    final alternativeFoods = _recommendations.where((rec) => rec.name.toLowerCase().contains('차선책')).toList()
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
          
          // 첫 번째 Google AdMob 배너 광고 추가
          const GoogleBannerAd(),
          
          // 다시 분석 버튼 (모든 추천이 없을 때)
          if (_recommendations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // 추천 음식 제목
                  Text(
                    '추천 결과',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.white,
                          offset: Offset(0, 0),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '이 메뉴에서 건강 상태에 적합한 음식을 찾을 수 없습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '다른 메뉴를 다시 시도해보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _retryAnalysis,
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 분석하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          
          // 건강에 좋은 음식 섹션
          if (goodFoods.isNotEmpty) ...[
            // 건강에 좋은 음식 제목
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '이 메뉴에서 건강에 좋은 음식 순위',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.white,
                      offset: Offset(0, 0),
                      blurRadius: 3,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // 건강에 좋은 음식 목록
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
              itemCount: goodFoods.length,
              itemBuilder: (BuildContext context, int index) {
                return _buildFoodCard(goodFoods[index], index + 1, false);
              },
            ),
          ],
          
          // 두 번째 Google AdMob 배너 광고 추가 (좀 더 큰 사이즈)
          const GoogleBannerAd(adType: 'large'),
          
          // 차선책 음식 섹션
          if (alternativeFoods.isNotEmpty) ...[
            // 차선책 음식 제목
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(top: 8.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade50, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Text(
                '이 메뉴에서 차선책 추천',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.white,
                      offset: Offset(0, 0),
                      blurRadius: 3,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // 차선책 음식 목록
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
              itemCount: alternativeFoods.length,
              itemBuilder: (BuildContext context, int index) {
                return _buildFoodCard(alternativeFoods[index], null, true);
              },
            ),
          ],
        ],
      ),
    );
  }

  // 음식 카드 위젯 생성 메서드
  Widget _buildFoodCard(FoodRecommendation recommendation, int? rank, bool isAlternative) {
    final isSelected = _selectedFoodNames.contains(recommendation.name);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: isSelected 
        ? Colors.green.shade100 
        : isAlternative 
          ? Colors.amber.shade50 
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: Row(
              children: [
                isAlternative 
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber,
                      size: 24,
                    ),
                  )
                : CircleAvatar(
                    backgroundColor: rank != null ? _getRankColor(rank) : Colors.green,
                    foregroundColor: Colors.white,
                    radius: 20,
                    child: Text(
                      rank != null ? '$rank' : '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    isAlternative 
                      ? recommendation.name.replaceFirst('차선책: ', '') 
                      : recommendation.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAlternative 
                      ? Colors.amber.withOpacity(0.2)
                      : _getCompatibilityColor(recommendation.compatibilityScore).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isAlternative
                    ? const Text(
                        '차선책',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Text(
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
                    onPressed: () {
                      setState(() {
                        _selectedFoodNames.remove(recommendation.name);
                      });
                    },
                  )
                : TextButton.icon(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                    label: const Text('선택하기'),
                    onPressed: () {
                      setState(() {
                        _selectedFoodNames.add(recommendation.name);
                      });
                    },
                  ),
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

  // 식사 레코드 목록 업데이트
  Future<void> _updateMealRecords() async {
    try {
      // 모든 식사 기록 가져오기
      final meals = await DatabaseHelper.instance.getMeals();
      
      // SharedPreferences 인스턴스 가져오기
      final prefs = await SharedPreferences.getInstance();
      
      // ID 목록 생성
      final List<int> mealIds = meals.map((meal) => meal.id!).toList();
      
      // SharedPreferences에 저장
      await prefs.setString('meal_records', jsonEncode(mealIds));
      print('식사 기록 업데이트됨: ${mealIds.length}개 항목');
    } catch (e) {
      print('식사 기록 업데이트 중 오류: $e');
    }
  }
} 