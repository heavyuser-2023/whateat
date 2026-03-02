import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../database/database_helper.dart';
import '../models/meal.dart';
import '../widgets/photo_viewer_screen.dart';
import 'package:flutter/rendering.dart';

class MealHistoryScreen extends StatefulWidget {
  final bool refreshOnShow;
  
  const MealHistoryScreen({
    Key? key, 
    this.refreshOnShow = false,
  }) : super(key: key);

  @override
  _MealHistoryScreenState createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> with WidgetsBindingObserver {
  List<Meal> _meals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('MealHistoryScreen - initState 호출'); // 디버그 로그
    
    // 초기 로딩 상태 설정
    _isLoading = true;
    
    // 화면이 완전히 로드된 후 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('MealHistoryScreen - 화면 로드 완료, 데이터 불러오기 시작');
      _loadMealHistory();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 로드가 실패했을 때를 대비해 여기서도 로드 시도
    if (_meals.isEmpty && !_isLoading) {
      print('MealHistoryScreen - 식사 기록이 비어있어 다시 불러오기 시도');
      _loadMealHistory();
    }
  }
  
  @override
  void didUpdateWidget(MealHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 위젯이 업데이트될 때 최신 데이터 로드
    if (widget.refreshOnShow) {
      print('MealHistoryScreen - didUpdateWidget: refreshOnShow=true'); // 디버그 로그
      // 상태 초기화 후 데이터 로드
      setState(() {
        _isLoading = true;
      });
      _loadMealHistory();
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 다시 활성화될 때 데이터 새로고침
    if (state == AppLifecycleState.resumed) {
      print('MealHistoryScreen - 앱 활성화 감지: 데이터 새로고침'); // 디버그 로그
      _loadMealHistory();
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadMealHistory() async {
    // 필요 시 로딩 중복 실행 허용 (첫 로딩이 실패할 경우)
    if (_isLoading) {
      print('이미 로딩 중이지만 계속 진행합니다.'); // 디버그 로그
    }
    
    try {
      setState(() => _isLoading = true);
      print('식사 기록 불러오기 시작 - ${DateTime.now()}'); // 디버그 로그
      
      // 먼저 이전 목록 초기화
      List<Meal> allMeals = [];
      Set<int> loadedIds = {}; // 이미 로드된 ID를 추적
      
      // 1. SQLite에서 식사 기록 불러오기
      try {
        final dbMeals = await DatabaseHelper.instance.getMeals();
        print('SQLite에서 불러온 식사 기록 수: ${dbMeals.length}'); // 디버그 로그
        
        for (final meal in dbMeals) {
          if (meal.id != null) {
            loadedIds.add(meal.id!);
            allMeals.add(meal);
          } else {
            print('경고: SQLite에서 ID가 없는 식사 기록 발견'); // 디버그 로그
            allMeals.add(meal);
          }
        }
      } catch (e) {
        print('SQLite 식사 기록 불러오기 오류: $e'); // 디버그 로그
      }
      
      // 2. SharedPreferences에서 식사 기록 불러오기
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? mealsJson = prefs.getString('saved_meals');
        
        if (mealsJson != null && mealsJson.isNotEmpty) {
          print('SharedPreferences 데이터 크기: ${mealsJson.length}'); // 디버그 로그
          
          try {
            final List<dynamic> mealsList = jsonDecode(mealsJson);
            print('SharedPreferences 파싱된 식사 수: ${mealsList.length}'); // 디버그 로그
            
            // 저장된 모든 식사 기록 출력 (디버깅용)
            for (int i = 0; i < mealsList.length; i++) {
              try {
                final meal = mealsList[i];
                print('SharedPreferences 식사 #$i - ID: ${meal['id'] ?? 'null'}, 이름: ${meal['name'] ?? 'unknown'}');
              } catch (e) {
                print('식사 항목 #$i 정보 출력 오류: $e');
              }
            }
            
            if (mealsList.isNotEmpty) {
              final localMeals = mealsList.map((map) {
                try {
                  return Meal.fromMap(map as Map<String, dynamic>);
                } catch (e) {
                  print('개별 식사 항목 파싱 오류: $e');
                  return null;
                }
              }).whereType<Meal>().toList(); // null 값 필터링
              
              print('변환된 로컬 식사 기록 수: ${localMeals.length}'); // 디버그 로그
              
              // 중복되지 않는 식사 기록만 추가 (ID 기준)
              for (final localMeal in localMeals) {
                // ID가 있고 이미 로드된 ID 목록에 있는 경우 건너뜀
                if (localMeal.id != null && loadedIds.contains(localMeal.id)) {
                  print('중복 식사 ID 발견: ${localMeal.id}'); // 디버그 로그
                  continue;
                }
                
                // 새로운 기록 추가
                allMeals.add(localMeal);
                print('로컬 저장소에서 식사 추가: ${localMeal.name} (ID: ${localMeal.id})'); // 디버그 로그
                
                // ID가 있는 경우 로드된 ID 목록에 추가
                if (localMeal.id != null) {
                  loadedIds.add(localMeal.id!);
                }
              }
            }
          } catch (e) {
            print('로컬 저장 식사 기록 파싱 오류: $e');
          }
        } else {
          print('SharedPreferences에 저장된 식사 기록 없음'); // 디버그 로그
        }
      } catch (e) {
        print('SharedPreferences 접근 오류: $e');
      }
      
      // 날짜 기준 정렬 (최신순)
      allMeals.sort((a, b) => b.date.compareTo(a.date));
      print('정렬 전 전체 식사 수: ${allMeals.length}'); // 디버그 로그
      
      // 중복 제거 한번 더 확인 (ID 기준)
      final uniqueMeals = <Meal>[];
      final uniqueIds = <int?>{};
      
      for (final meal in allMeals) {
        if (meal.id == null || !uniqueIds.contains(meal.id)) {
          uniqueMeals.add(meal);
          if (meal.id != null) {
            uniqueIds.add(meal.id);
          }
        }
      }
      
      print('고유 ID 수: ${uniqueIds.length}, 고유 식사 수: ${uniqueMeals.length}'); // 디버그 로그
      
      // 모든 식사의 ID 목록 출력 (디버깅용)
      String idList = 'ID 목록: ';
      for (final id in uniqueIds) {
        idList += '${id ?? 'null'}, ';
      }
      print(idList); // 디버그 로그
      
      // 화면 갱신
      if (mounted) {
        setState(() {
          _meals = uniqueMeals;
          _isLoading = false;
        });
      }
      
      print('최종 불러온 식사 기록 수: ${uniqueMeals.length} - ${DateTime.now()}'); // 디버그 로그
      
      // 이미지 파일 존재 여부 확인
      _checkImageExistence();
      
      // 데이터가 없으면 기본 메시지 설정
      if (_meals.isEmpty && mounted) {
        setState(() {
          _meals = [];
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('식사 기록 불러오기 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('식사 기록을 불러오는 중 오류가 발생했습니다: $e');
      }
    }
  }
  
  // 이미지 파일 존재 여부 확인
  void _checkImageExistence() {
    for (final meal in _meals) {
      final file = File(meal.imagePath);
      final exists = file.existsSync();
      if (!exists) {
        print('경고: 이미지 파일 없음 - ${meal.imagePath}'); // 디버그 로그
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  Future<void> _deleteMeal(int id) async {
    try {
      print('식사 기록 삭제 시작, ID: $id'); // 디버그 로그
      
      // SQLite에서 삭제
      await DatabaseHelper.instance.deleteMeal(id);
      print('SQLite에서 식사 기록 삭제 완료, ID: $id'); // 디버그 로그
      
      // SharedPreferences에서도 삭제
      await _deleteMealFromLocalStorage(id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('식사 기록이 삭제되었습니다')),
      );
      _loadMealHistory();
    } catch (e) {
      print('식사 삭제 오류: $e');
      _showErrorDialog('식사 기록을 삭제하는 중 오류가 발생했습니다.');
    }
  }
  
  // SharedPreferences에서 식사 기록 삭제
  Future<void> _deleteMealFromLocalStorage(int id) async {
    try {
      print('로컬 저장소에서 식사 삭제 시작, ID: $id'); // 디버그 로그
      final prefs = await SharedPreferences.getInstance();
      final String? mealsJson = prefs.getString('saved_meals');
      
      if (mealsJson != null && mealsJson.isNotEmpty) {
        try {
          final List<dynamic> mealsList = jsonDecode(mealsJson);
          print('로컬 저장소 기존 식사 수: ${mealsList.length}'); // 디버그 로그
          
          // 해당 ID를 가진 식사 제외
          final filteredMeals = mealsList.where((meal) {
            try {
              final Map<String, dynamic> mealMap = meal as Map<String, dynamic>;
              return mealMap['id'] != id;
            } catch (e) {
              print('식사 항목 파싱 오류 (삭제 중): $e');
              return true; // 오류 발생 시 해당 항목 유지
            }
          }).toList();
          
          // 다시 저장
          await prefs.setString('saved_meals', jsonEncode(filteredMeals));
          print('로컬 저장소에서 식사 기록 삭제 완료, ID: $id');
          print('로컬 저장소 남은 식사 수: ${filteredMeals.length}'); // 디버그 로그
        } catch (e) {
          print('로컬 저장소 데이터 파싱 오류 (삭제 중): $e');
        }
      } else {
        print('로컬 저장소에 저장된 식사 기록 없음'); // 디버그 로그
      }
    } catch (e) {
      print('로컬 저장소에서 식사 삭제 오류: $e');
      // 에러가 발생해도 앱 실행은 계속되도록 예외를 삼킴
    }
  }

  @override
  Widget build(BuildContext context) {
    // 상태 표시줄 높이 가져오기
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    // AppBar 높이 가져오기 (기본값 사용)
    const double appBarHeight = kToolbarHeight;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // AppBar가 밝으므로 어두운 아이콘
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.85),
          elevation: 0,
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            '식사 기록',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF0FDF8), // Light mint default
                Color(0xFFF8F9FB), // Background default
              ],
              stops: [0.0, 0.4],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BFA5)))
                : _meals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu_rounded, size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              '아직 기록된 식사가 없습니다',
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 16, bottom: 40),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _meals.length,
                        itemBuilder: (context, index) {
                          final meal = _meals[index];
                          return _buildMealCard(meal);
                        },
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealCard(Meal meal) {
    // 이미지 존재 확인
    bool imageExists = false;
    bool hasImageData = meal.imageData != null && meal.imageData!.isNotEmpty;
    
    // 파일 존재 확인 (imageData가 없는 경우)
    if (!hasImageData && meal.imagePath.isNotEmpty) {
      try {
        final file = File(meal.imagePath);
        imageExists = file.existsSync();
        if (!imageExists) {
          print('이미지 파일을 찾을 수 없음: ${meal.imagePath}');
        }
      } catch (e) {
        print('이미지 파일 확인 오류: $e');
      }
    }
    
    // 이미지를 보여줄 수 있는지 여부
    bool canShowImage = hasImageData || imageExists;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 이미지 영역 - GestureDetector로 감싸기
          GestureDetector(
            onTap: canShowImage
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoViewerScreen(
                          imageData: hasImageData ? Uint8List.fromList(meal.imageData!) : null,
                          imagePath: !hasImageData && imageExists ? meal.imagePath : null,
                        ),
                      ),
                    );
                  }
                : null,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: hasImageData
                      ? Image.memory(
                          Uint8List.fromList(meal.imageData!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                        )
                      : imageExists
                        ? Image.file(
                            File(meal.imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                ),
                // 날짜 뱃지
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        )
                      ]
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('yyyy.MM.dd').format(meal.date),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 내용 영역
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        meal.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE57373)),
                      onPressed: () => _confirmDelete(meal),
                      tooltip: '삭제',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  meal.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                const Text(
                  '고려한 건강 상태',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: meal.healthConditions
                      .map((condition) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFB2DFDB)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.health_and_safety_rounded, size: 14, color: Color(0xFF00897B)),
                                const SizedBox(width: 4),
                                Text(
                                  condition,
                                  style: const TextStyle(
                                    color: Color(0xFF00897B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF8F9FB),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            '이미지 없음',
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Meal meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('식사 기록 삭제'),
        content: const Text('이 식사 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMeal(meal.id!);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 