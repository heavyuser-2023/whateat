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
    
    if (dotenv.env['GOOGLE_API_KEY'] == null) {
      print('경고: API 키가 로드되지 않았습니다. .env 파일을 확인하세요.');
    } else {
      print('API 키 길이: ${(dotenv.env['GOOGLE_API_KEY'] ?? '').length}자');
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
    // 상태 표시줄 높이 가져오기
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // 기본 상태 표시줄 스타일
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
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
        body: Stack( // Stack으로 감싸기
          children: [
            // 메인 콘텐츠 (기존 body)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF4FBF4).withOpacity(0.8),
                    const Color(0xFFE8F5E9).withOpacity(0.9),
                    const Color(0xFFE0F2F1),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
              child: SafeArea(
                // SafeArea는 그라데이션 오버레이 아래의 콘텐츠에만 적용
                top: false, // 상단 SafeArea는 직접 처리하므로 false
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(top: statusBarHeight + kToolbarHeight, left: 24.0, right: 24.0, bottom: 20.0), // AppBar 높이만큼 추가 패딩
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // 앱 아이콘/로고
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8), // 약간 투명한 흰색 배경
                          borderRadius: BorderRadius.circular(24.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: Image.asset(
                            'assets/images/whateat_icon.png', // 경로 수정
                            height: 90,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 앱 이름 또는 제목
                      Text(
                        '왓이트',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary, // 테마 색상 적용
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // 부제목
                      Text(
                        '건강 상태에 맞는 맞춤형 식단을 추천받으세요',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black54, // 약간 어두운 회색
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      // AI 분석 결과 안내 문구
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '※ 본 앱의 음식 정보 및 추천은 인공지능(AI) 분석 결과로, 참고용 정보입니다. 의료적 진단, 치료, 처방을 대체하지 않으며, 건강에 관한 중요한 결정은 반드시 전문 의료진과 상담하시기 바랍니다.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12, // 폰트 크기 조정
                            color: Colors.grey[700], // 좀 더 진한 회색
                            height: 1.4, // 줄 간격 조정
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // 식단 추천 받기 버튼
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary, // 시작 색상
                              Theme.of(context).colorScheme.secondary, // 끝 색상
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HealthConditionsScreen()),
                            );
                          },
                          icon: const Icon(Icons.restaurant_menu, color: Colors.white),
                          label: const Text(
                            '식단 추천 받기',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, // 그라데이션 배경 사용
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 상단 그라데이션 오버레이
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: statusBarHeight + 20, // 상태 표시줄 높이 + 약간의 추가 영역
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.20), // 상단은 약간 어둡게
                      Colors.black.withOpacity(0.0), // 하단은 투명하게
                    ],
                    stops: const [0.0, 1.0], // 0.0에서 1.0으로 자연스럽게 사라짐
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
