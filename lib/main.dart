import 'package:flutter/material.dart';
import 'screens/health_conditions_screen.dart';
import 'screens/meal_history_screen.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database/database_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'providers/health_condition_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // 데이터베이스 초기화
    await _resetDatabaseIfNeeded();
    
    // 상태 표시줄 다시 표시
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  
  // 데이터베이스 초기화 함수
  Future<void> _resetDatabaseIfNeeded() async {
    try {
      // 데이터베이스 경로 가져오기
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'what_eat.db');
      
      // 데이터베이스 존재 여부 확인
      final bool exists = await databaseExists(path);
      
      if (!exists) {
        // 데이터베이스가 존재하지 않는 경우에만 새로 생성
        print('데이터베이스가 존재하지 않아 새로 생성합니다.');
        await DatabaseHelper.instance.database;
        print('새로운 데이터베이스 생성됨');
      } else {
        print('기존 데이터베이스가 존재합니다. 초기화 작업을 건너뜁니다.');
        // 데이터베이스 연결만 확인
        await DatabaseHelper.instance.database;
      }
    } catch (e) {
      print('데이터베이스 초기화 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '왓이트 - 건강한 식단 추천',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF34A853),
          primary: const Color(0xFF34A853),
          secondary: const Color(0xFF4285F4),
          tertiary: const Color(0xFFFFA726),
          error: const Color(0xFFEA4335),
          background: const Color(0xFFF4F9F4),
          surface: Colors.white,
          onPrimary: Colors.white,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF202124)),
          displayMedium: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF202124)),
          displaySmall: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF202124)),
          titleLarge: TextStyle(fontWeight: FontWeight.w600, color: const Color(0xFF202124)),
          titleMedium: TextStyle(fontWeight: FontWeight.w600, color: const Color(0xFF202124)),
          bodyLarge: TextStyle(color: const Color(0xFF5F6368)),
          bodyMedium: TextStyle(color: const Color(0xFF5F6368)),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF34A853),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF34A853),
            side: const BorderSide(color: Color(0xFF34A853), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF34A853),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFF34A853)),
          titleTextStyle: TextStyle(color: Color(0xFF34A853), fontSize: 20, fontWeight: FontWeight.w600),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF34A853),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFE8F5E9),
          selectedColor: const Color(0xFF34A853),
          labelStyle: TextStyle(color: const Color(0xFF34A853)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: _showSplash ? const SplashView() : const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 스플래시 화면을 StatelessWidget으로 변경
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // 상태 표시줄 숨기기 (전체 화면 효과)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/splash.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 텍스트 오버레이
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
              margin: const EdgeInsets.symmetric(horizontal: 40.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '잠시만 기다려 주세요...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> main() async {
  // 위젯 플러터 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  // Google Mobile Ads SDK 초기화
  await MobileAds.instance.initialize();
  
  // 앱 방향을 세로로만 설정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 앱 실행 전 데이터베이스 초기화
  try {
    print('데이터베이스 초기화 시작');
    final db = await DatabaseHelper.instance.database;
    print('데이터베이스 초기화 완료: $db');
    
    // 이미지 저장용 디렉토리 생성
    final appDir = await getApplicationDocumentsDirectory();
    final mealImagesDir = Directory('${appDir.path}/meal_images');
    if (!mealImagesDir.existsSync()) {
      await mealImagesDir.create(recursive: true);
      print('식사 이미지 디렉토리 생성: ${mealImagesDir.path}');
    } else {
      print('식사 이미지 디렉토리 존재 확인: ${mealImagesDir.path}');
      // 디렉토리 내 파일 목록 확인
      final files = mealImagesDir.listSync();
      print('식사 이미지 디렉토리 내 파일 수: ${files.length}');
    }
    
    // SharedPreferences 초기화 확인
    final prefs = await SharedPreferences.getInstance();
    final meals = prefs.getString('saved_meals');
    if (meals != null) {
      print('SharedPreferences에 저장된 식사 기록 발견: ${meals.length} 바이트');
      
      // 식사 기록이 유효한 JSON인지 확인
      try {
        final List<dynamic> mealsList = jsonDecode(meals);
        print('저장된 식사 기록 수: ${mealsList.length}개');
      } catch (e) {
        print('저장된 식사 기록 형식이 잘못됨, 초기화 진행: $e');
        await prefs.setString('saved_meals', '[]');
      }
    } else {
      print('SharedPreferences에 저장된 식사 기록 없음, 기본값 설정');
      await prefs.setString('saved_meals', '[]');
    }
  } catch (e) {
    print('앱 초기화 중 오류 발생: $e');
  }
  
  // .env 파일 로드 및 확인
  try {
    await dotenv.load(fileName: 'assets/config/.env');
    print('환경 변수 로드됨: ${dotenv.env.keys.join(", ")}');
    
    if (dotenv.env['GOOGLE_API_KEY'] == null && dotenv.env['GEMINI_API_KEY'] == null) {
      print('경고: API 키가 로드되지 않았습니다. .env 파일을 확인하세요.');
    } else {
      print('API 키 길이: ${(dotenv.env['GOOGLE_API_KEY'] ?? dotenv.env['GEMINI_API_KEY'] ?? '').length}자');
    }
  } catch (e) {
    print('환경 변수 로드 오류: $e');
  }
  
  // 네이티브 스플래시 화면을 즉시 제거하기 위한 설정
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // ChangeNotifierProvider로 감싸서 HealthConditionProvider 제공
  runApp(
    ChangeNotifierProvider(
      create: (context) => HealthConditionProvider(),
      child: const MyApp(),
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MealHistoryScreen()),
              );
            },
            tooltip: '식사 기록 보기',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF4FBF4),
              const Color(0xFFE8F5E9),
              const Color(0xFFE0F2F1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // 앱 로고 및 제목
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 앱 로고
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor.withOpacity(0.1), Colors.white.withOpacity(0.5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/whateat_icon.png',
                              width: 120,
                              height: 120,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // 앱 제목
                        Text(
                          '왓이트',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 앱 설명
                        Text(
                          '건강 상태에 맞는 맞춤형 식단을 추천받으세요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // 시작하기 버튼
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HealthConditionsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restaurant_menu, size: 24),
                      label: const Text(
                        '식단 추천 받기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 기능 소개 카드
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildFeatureItem(
                          Icons.health_and_safety,
                          '건강 상태 맞춤',
                          '나의 건강 상태에 맞는 최적의 식단을 추천해 드립니다.'
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildFeatureItem(
                          Icons.camera_alt,
                          '메뉴 사진 촬영',
                          '음식 사진으로 메뉴를 분석하고 건강에 좋은 음식을 찾아드립니다.'
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildFeatureItem(
                          Icons.recommend,
                          '맞춤형 추천',
                          '암, 콜레스테롤, 다이어트 등 다양한 건강 조건을 고려합니다.'
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF34A853).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF34A853),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF202124),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
