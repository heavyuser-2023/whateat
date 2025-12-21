import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/meal.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../utils/logger.dart';
import '../models/food_analysis_result.dart'; // New Import

class FoodRecognitionService {
  static final FoodRecognitionService _instance = FoodRecognitionService._internal();
  factory FoodRecognitionService() => _instance;
  FoodRecognitionService._internal();
  
  final String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  
  // Get platform specific locale (Fixed deprecated window.locale)
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
      
      final promptText = '''
이 이미지에 있는 음식을 분석하고 다음 건강 상태에 적합한지 평가해주세요: $healthConditionsText.

제공된 이미지를 분석하여 다음 정보를 정확히 JSON 형식으로 반환해주세요:
1. 인식된 음식 이름 (recognized_food)
2. 건강 상태를 고려한 음식 평가 (evaluation) - **객관적이고 과학적인 근거**에 기반하여 작성해주세요.
3. 이 식단에서 건강 상태에 적합한 음식 추천 목록 (recommendations) **인식된 음식 이름만을 포함하여** 작성해주세요.
4. 각 추천 음식의 근거가 되는 신뢰할 수 있는 출처 URL (source) - **학술 자료, 공신력 있는 기관의 공식 자료 등 검증 가능한 출처만 사용하고, 없다면 '출처 정보 없음'으로 표시하세요. 개인 블로그나 일반 웹사이트는 절대 포함하지 마세요.**

**중요:** 메뉴에서 주 요리 위주로 분석하고, 반찬, 음료, 디저트 등 부수적인 항목은 제외해주세요.
**매우 중요:** 모든 평가는 **객관적이고 과학적인 근거**에 기반해야 합니다. **근거 없는 주장은 절대 포함하지 마세요.**

recommendations는 다음 필드를 포함한 JSON 객체 배열로 구성해주세요:
- name: 추천 음식 이름
- description: 왜 이 음식이 추천되는지 설명 (근거 기반)
- compatibilityScore: 0.0 ~ 1.0 사이의 적합도 점수
- source: 해당 추천의 검증 가능한 공식 출처 URL 또는 '출처 정보 없음'

예시 응답 형식:
{
  "recognized_food": "인식된 음식 이름",
  "evaluation": "건강 상태를 고려한 전반적인 평가 (과학적 근거 기반)",
  "recommendations": [
    {
      "name": "추천 음식 1",
      "description": "추천 이유 설명 (근거 기반)",
      "compatibilityScore": 0.9,
      "source": "https://www.nhlbi.nih.gov/health/educational/lose_wt/eat/dash.htm"
    }
  ]
}

$langInstruction
''';

      final payload = jsonEncode({
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
        // Safety settings omitted for brevity, default is fine usually or add back if strictness needed
      });

      AppLogger.info('Calling Gemini API... (Language: $langCode)');
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: { 'Content-Type': 'application/json' },
        body: payload,
      );

      AppLogger.info('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return _parseFullGeminiResponse(jsonResponse);
      } else {
        AppLogger.error('API Call Failed: ${response.statusCode} - ${response.body}');
        
        return FoodAnalysisResult(
          recognizedFood: '메뉴 분석 (API 호출 실패)',
          evaluation: 'API 연결에 문제가 있었습니다. 메뉴를 다시 분석해주세요.',
          recommendations: []
        );
      }
    } catch (e, stack) {
      AppLogger.error('Food recognition error', e, stack);
      return FoodAnalysisResult(
        recognizedFood: '메뉴를 분석할 수 없습니다',
        evaluation: '분석에 실패했습니다. 다른 메뉴로 다시 시도해주세요.',
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