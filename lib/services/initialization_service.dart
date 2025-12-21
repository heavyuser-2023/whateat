import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../database/database_helper.dart';
import '../utils/logger.dart';

class InitializationService {
  static final InitializationService _instance = InitializationService._internal();
  factory InitializationService() => _instance;
  InitializationService._internal();

  /// Initializes all essential services.
  /// Returns only after critical initializations are complete.
  Future<void> initializeApp() async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('App initialization started...');

    try {
      // Load environment variables (Critical)
      await _loadEnv();

      // Ensure min splash duration (UX)
      final minSplashTime = Future.delayed(const Duration(seconds: 2));

      // Initialize disparate services in parallel where possible
      await Future.wait([
        _initMobileAds(),
        _initDatabase(),
        _initFileSystem(),
        _initSharedPreferences(),
      ]);

      AppLogger.info('All essential services initialized in ${stopwatch.elapsedMilliseconds}ms');

      // Wait for the minimum splash time
      await minSplashTime;
      
    } catch (e, stackTrace) {
      AppLogger.error('Initialization failed (attempting to continue)', e, stackTrace);
    } finally {
      stopwatch.stop();
    }
  }

  Future<void> _loadEnv() async {
    try {
      await dotenv.load(fileName: 'assets/config/.env');
    } catch (e) {
      AppLogger.error('Failed to load .env file', e);
      // Proceeding might be dangerous if API keys are missing, but we'll let the specific service handle it.
    }
  }

  Future<void> _initMobileAds() async {
    // Run in background, don't await strictly if not blocking
    MobileAds.instance.initialize().then((_) {
      AppLogger.info('MobileAds initialized');
    });
  }

  Future<void> _initDatabase() async {
    try {
      await _resetDatabaseIfNeeded();
      await DatabaseHelper.instance.database;
      AppLogger.info('Database ready');
    } catch (e) {
      AppLogger.error('Database initialization error', e);
    }
  }

  Future<void> _resetDatabaseIfNeeded() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'what_eat.db');
      final bool exists = await databaseExists(path);
      
      if (!exists) {
        AppLogger.info('Database does not exist, creating new instance.');
        await DatabaseHelper.instance.database;
      }
    } catch (e) {
      AppLogger.error('Database reset check error', e);
    }
  }

  Future<void> _initFileSystem() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mealImagesDir = Directory('${appDir.path}/meal_images');
    if (!mealImagesDir.existsSync()) {
      await mealImagesDir.create(recursive: true);
      AppLogger.info('Created meal_images directory');
    }
  }

  Future<void> _initSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('saved_meals') == null) {
      await prefs.setString('saved_meals', '[]');
      AppLogger.info('Initialized empty saved_meals in SharedPreferences');
    }
  }
  
  void onAppReady() {
     // Post-initialization UI adjustments
     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
