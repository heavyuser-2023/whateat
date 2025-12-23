import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/meal.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../utils/logger.dart';
import '../models/food_analysis_result.dart';
import 'prompt_config.dart';

class FoodRecognitionService {
  static final FoodRecognitionService _instance = FoodRecognitionService._internal();
  factory FoodRecognitionService() => _instance;
  
  final Dio _dio = Dio();

  FoodRecognitionService._internal() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        AppLogger.info('API Request: ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.info('API Response: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        AppLogger.error('API Error: ${e.message}', e, e.stackTrace);
        return handler.next(e);
      },
    ));
  }
  
  final String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  
  // Get platform specific locale
  String get currentLanguageCode {
    final String deviceLocale = ui.PlatformDispatcher.instance.locale.languageCode;
    AppLogger.info('Detected device locale: $deviceLocale');
    return deviceLocale;
  }
  
  String getLanguageInstruction(String languageCode) {
    switch (languageCode) {
      case 'ko':
        return "반드시 한국어로 응답해주세요.";
      case 'en':
        return "Please respond in English.";
      case 'ja':
        return "必ず日本語で回答してください。";
      case 'zh':
        return "请用中文回答。";
      default:
        return "Please respond in $languageCode.";
    }
  }
  
  String get apiKey {
    String? key = dotenv.env['GOOGLE_API_KEY'];
    if (key == null || key.isEmpty) {
        AppLogger.warning('API Key is missing or empty');
    }
    return key ?? '';
  }
  
  String get apiUrl => '$baseUrl?key=$apiKey';

  Future<List<FoodRecommendation>> recognizeFoodAndGetRecommendations(
    File imageFile,
    List<String> healthConditions,
  ) async {
    final result = await analyzeFoodImage(imageFile, healthConditions);
    return result.recommendations;
  }

  Future<FoodAnalysisResult> analyzeFoodImage(
    File imageFile,
    List<String> healthConditions,
  ) async {
    try {
      const int maxImageSizeInBytes = 4 * 1024 * 1024; // 4MB limit
      final Uint8List imageBytes = await _compressImage(imageFile, maxImageSizeInBytes);
      final String base64Image = base64Encode(imageBytes);
      
      String langCode = currentLanguageCode;
      String langInstruction = getLanguageInstruction(langCode);
      
      final String healthConditionsText = healthConditions.isEmpty 
          ? '특별한 건강 상태가 없음'
          : healthConditions.join(', ');
      
      final promptText = FoodRecognitionPrompts.foodAnalysisPrompt(healthConditionsText, langInstruction);

      final payload = {
        "contents": [
          {
            "role": "user",
            "parts": [
              { "text": promptText },
              { "inline_data": { "mime_type": "image/jpeg", "data": base64Image } }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.4,
          "topK": 32,
          "topP": 0.95,
          "maxOutputTokens": 8192,
        },
      };

      AppLogger.info('Calling Gemini API via Dio... (Language: $langCode)');
      
      final response = await _dio.post(
        apiUrl,
        data: payload,
        options: Options(headers: { 'Content-Type': 'application/json' }),
      );

      if (response.statusCode == 200) {
        return _parseFullGeminiResponse(response.data);
      } else {
        AppLogger.error('API Call Failed: ${response.statusCode} - ${response.data}');
        
        return FoodAnalysisResult(
          recognizedFood: '메뉴 분석 (API 호출 실패)',
          evaluation: 'API 연결에 문제가 있었습니다. 메뉴를 다시 분석해 주세요.',
          recommendations: []
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Dio error during food recognition', e);
      String errorMsg = '분석에 실패했습니다. 네트워크 연결을 확인하고 다시 시도해 주세요.';
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = '연결 시간이 초과되었습니다. 다시 시도해 주세요.';
      }
      return FoodAnalysisResult(
        recognizedFood: '분석 오류',
        evaluation: errorMsg,
        recommendations: []
      );
    } catch (e, stack) {
      AppLogger.error('Food recognition error', e, stack);
      return FoodAnalysisResult(
        recognizedFood: '메뉴를 분석할 수 없습니다',
        evaluation: '분석 중 기술적인 오류가 발생했습니다. 다른 메뉴로 다시 시도해 주세요.',
        recommendations: []
      );
    }
  }

  FoodAnalysisResult _parseFullGeminiResponse(Map<String, dynamic> response) {
    try {
      if (response['candidates'] == null || 
          response['candidates'].isEmpty || 
          response['candidates'][0]['content'] == null) {
            
        final finishReason = response['candidates']?[0]?['finishReason'] ?? 'UNKNOWN';
        AppLogger.warning('Invalid API Response (FinishReason: $finishReason)');
        
        return FoodAnalysisResult(
          recognizedFood: '오류',
          evaluation: 'API 응답을 처리하는 중 오류가 발생했습니다. (Reason: $finishReason)',
          recommendations: [],
        );
      }

      final String content = response['candidates'][0]['content']['parts'][0]['text'];
      AppLogger.info('Response Content Length: ${content.length}');

      // Extract JSON
      final RegExp jsonRegExp = RegExp(r'```(json)?\s*(\{.*?\})\s*```', dotAll: true);
      String jsonString;
      final match = jsonRegExp.firstMatch(content);

      if (match != null) {
        jsonString = match.group(2)!;
      } else if (content.trim().startsWith('{') && content.trim().endsWith('}')) {
        jsonString = content.trim();
      } else {
        AppLogger.warning('Could not find JSON in response');
        return FoodAnalysisResult(
          recognizedFood: '오류',
          evaluation: 'API 응답에서 JSON 데이터를 추출하지 못했습니다.',
          recommendations: [],
        );
      }

      final Map<String, dynamic> jsonResponse = jsonDecode(jsonString);

      final List<dynamic> recommendationsList = jsonResponse['recommendations'] ?? [];
      final List<FoodRecommendation> recommendations = recommendationsList
          .map((item) => FoodRecommendation.fromMap(item))
          .toList();

      String recognizedFoodString = '음식 이름 없음';
      if (jsonResponse['recognized_food'] != null) {
        if (jsonResponse['recognized_food'] is List) {
          recognizedFoodString = (jsonResponse['recognized_food'] as List).join(', ');
        } else {
          recognizedFoodString = jsonResponse['recognized_food'].toString();
        }
      }

      return FoodAnalysisResult(
        recognizedFood: recognizedFoodString,
        evaluation: jsonResponse['evaluation'] ?? '평가 정보 없음',
        recommendations: recommendations,
      );
    } catch (e, stack) {
      AppLogger.error('Response parsing error', e, stack);
      return FoodAnalysisResult(
        recognizedFood: '오류',
        evaluation: 'API 응답 파싱 중 오류가 발생했습니다: $e',
        recommendations: [],
      );
    }
  }

  Future<Uint8List> _compressImage(File imageFile, int maxSizeInBytes) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      if (bytes.length <= maxSizeInBytes) {
        return bytes;
      }
      
      AppLogger.info('Compressing image: ${bytes.length} bytes');
      
      int quality = 90;
      if (bytes.length > maxSizeInBytes * 2) quality = 70;
      if (bytes.length > maxSizeInBytes * 4) quality = 50;
      
      final Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: quality,
      );
      
      if (compressedBytes == null) {
        AppLogger.warning('Compression failed, using original');
        return bytes;
      }
      
      AppLogger.info('Compressed to: ${compressedBytes.length} bytes (Quality: $quality)');
      return compressedBytes;
    } catch (e) {
      AppLogger.error('Image compression error', e);
      return await imageFile.readAsBytes();
    }
  }
}