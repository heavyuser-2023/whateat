import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'providers/health_condition_provider.dart';
import 'services/initialization_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  // Widget binding init
  WidgetsFlutterBinding.ensureInitialized();
  
  // Portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => HealthConditionProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }
  
  Future<void> _startInitialization() async {
    await InitializationService().initializeApp();
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      InitializationService().onAppReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '왓이트 - 건강한 식단 추천',
      theme: AppTheme.lightTheme,
      home: _isInitialized ? const HomeScreen() : const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
