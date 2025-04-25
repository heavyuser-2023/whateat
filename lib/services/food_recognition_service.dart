import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/meal.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FoodAnalysisResult {
  final String recognizedFood;
  final String evaluation;
  final List<FoodRecommendation> recommendations;

  FoodAnalysisResult({
    required this.recognizedFood, 
    required this.evaluation,
    required this.recommendations
  });
}

class FoodRecognitionService {
  static final FoodRecognitionService _instance = FoodRecognitionService._internal();
  factory FoodRecognitionService() => _instance;
  FoodRecognitionService._internal();
  
  final String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  
  // 현재 앱의 언어 코드를 가져오는 메서드
  String get currentLanguageCode {
    // 기기의 현재 로케일 언어 코드 가져오기
    final String deviceLocale = ui.window.locale.languageCode;
    print('감지된 기기 언어 코드: $deviceLocale');
    return deviceLocale;
  }
  
  // 언어 코드에 따른 프롬프트 지시문 생성
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
  
  // .env 파일에서 API 키를 로드
  String get apiKey {
    // 먼저 GEMINI_API_KEY 시도
    String? key = dotenv.env['GEMINI_API_KEY'];
    // 없으면 GOOGLE_API_KEY 시도
    if (key == null || key.isEmpty) {
      key = dotenv.env['GOOGLE_API_KEY'];
    }
    // 디버깅용 로그
    print('API 키 로드: ${key?.substring(0, 5)}... (${key?.length ?? 0}자)');
    return key ?? '';
  }
  
  // API URL을 생성
  String get apiUrl => '$baseUrl?key=$apiKey';

  // 기존 분석 메서드는 이전 호환성을 위해 유지
  Future<List<FoodRecommendation>> recognizeFoodAndGetRecommendations(
    File imageFile,
    List<String> healthConditions,
  ) async {
    final result = await analyzeFoodImage(imageFile, healthConditions);
    return result.recommendations;
  }

  // 확장된 분석 메서드 추가
  Future<FoodAnalysisResult> analyzeFoodImage(
    File imageFile,
    List<String> healthConditions,
  ) async {
    try {
      const int maxImageSizeInBytes = 4 * 1024 * 1024; // 4MB 제한
      final Uint8List imageBytes = await _compressImage(imageFile, maxImageSizeInBytes);
      final String base64Image = base64Encode(imageBytes);
      
      // 언어 감지 및 언어 코드에 맞는 지시문 설정
      String langCode = currentLanguageCode;
      String langInstruction = getLanguageInstruction(langCode);
      
      // 건강 상태 문자열로 변환
      final String healthConditionsText = healthConditions.isEmpty 
          ? '특별한 건강 상태가 없음'
          : healthConditions.join(', ');
      
      final promptText = '''
이 이미지에 있는 음식을 분석하고 다음 건강 상태에 적합한지 평가해주세요: $healthConditionsText.

제공된 이미지를 분석하여 다음 정보를 정확히 JSON 형식으로 반환해주세요:
1. 인식된 음식 이름 (recognized_food)
2. 건강 상태를 고려한 음식 평가 (evaluation) - **객관적이고 과학적인 근거**에 기반하여 작성해주세요.
3. 이 식단에서 건강 상태에 적합한 음식 추천 목록 (recommendations) **인식된 음식 이름만을 포함하여** 작성해주세요.
4. 각 추천 음식에 대한 **근거가 되는** 출처 정보 (source) - **반드시 과학적 근거(논문, 연구 결과 등) 또는 공신력 있는 기관(정부 건강 부처, 주요 학회 등)의 공식 발표 자료에 기반한 외부 링크(URL)를 정확하게 포함해주세요.** 만약 **검증 가능한 공식 출처 URL을 찾을 수 없다면, 반드시 '출처 정보 없음' 문자열만 반환해주세요.** **개인 블로그나 일반 웹사이트 링크는 절대 포함하지 마세요.**

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
    },
    {
      "name": "추천 음식 2",
      "description": "추천 이유 설명 (근거 기반)",
      "compatibilityScore": 0.7,
      "source": "출처 정보 없음" // 출처가 없는 경우 명확히 표시
    },
    {
      "name": "추천 음식 3",
      "description": "추천 이유 설명 (근거 기반)",
      "compatibilityScore": 0.8,
      "source": "https://pubmed.ncbi.nlm.nih.gov/XXXXXXXX/"
    }
  ]
}

$langInstruction
''';

      // API 요청 JSON 구조 생성
      final payload = jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": [
              {
                "text": promptText
              },
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.4,
          "topK": 32,
          "topP": 0.95,
          "maxOutputTokens": 2048,
        },
        "safety_settings": [
          {
            "category": "HARM_CATEGORY_HARASSMENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            "category": "HARM_CATEGORY_HATE_SPEECH",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          }
        ]
      });

      // 실제 API 호출
      print('API 호출 URL: $apiUrl (요청 언어: $langCode)'); // 디버깅용 로그
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: payload,
      );

      print('API 응답 상태 코드: ${response.statusCode}'); // 디버깅용 로그

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Gemini API 응답 파싱하여 분석 결과 생성
        return _parseFullGeminiResponse(jsonResponse);
      } else {
        print('API 호출 실패: ${response.statusCode} - ${response.body}');
        print('API URL: $baseUrl');
        print('사용된 API 키 길이: ${apiKey.length}자');
        print('사용된 모델: gemini-2.0-flash');
        
        // 자세한 오류 정보 추출 시도
        try {
          final errorJson = jsonDecode(response.body);
          final errorMessage = errorJson['error']?['message'] ?? '알 수 없는 오류';
          print('API 오류 메시지: $errorMessage');
        } catch (e) {
          print('응답 본문 파싱 실패: $e');
        }
        
        // API 호출 실패 시 빈 결과 제공
        return FoodAnalysisResult(
          recognizedFood: '메뉴 분석 (API 호출 실패)',
          evaluation: 'API 연결에 문제가 있었습니다. 메뉴를 다시 분석해주세요.',
          recommendations: [] // 기본 차선책 제거
        );
      }
    } catch (e) {
      print('음식 인식 오류: $e');
      // 오류 발생 시 반환값 수정
      return FoodAnalysisResult(
        recognizedFood: '메뉴를 분석할 수 없습니다',
        evaluation: '분석에 실패했습니다. 다른 메뉴로 다시 시도해주세요.',
        recommendations: []
      );
    }
  }

  // 전체 Gemini API 응답을 파싱하는 메서드
  FoodAnalysisResult _parseFullGeminiResponse(Map<String, dynamic> response) {
    try {
      // Gemini API의 응답 구조에 맞게 파싱
      final String content = response['candidates'][0]['content']['parts'][0]['text'];
      print('API 응답 내용: $content'); // 디버그용 로그
      
      // JSON 형식으로 응답된 텍스트 추출
      final RegExp jsonRegExp = RegExp(r'(\{.*\})', dotAll: true);
      final match = jsonRegExp.firstMatch(content);
      
      if (match != null) {
        final jsonString = match.group(1);
        print('추출된 JSON 문자열: $jsonString'); // 디버그용 로그
        
        if (jsonString != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(jsonString);
            print('파싱된 데이터: $data'); // 디버그용 로그
            
            final String recognizedFood = data['recognized_food'] ?? '인식된 음식 정보 없음';
            final String evaluation = data['evaluation'] ?? '평가 정보 없음';
            
            List<FoodRecommendation> recommendations = [];
            
            // 추천 목록 파싱
            if (data.containsKey('recommendations') && data['recommendations'] is List) {
              final List<dynamic> recommendationsList = data['recommendations'];
              
              recommendations = recommendationsList.map((item) => FoodRecommendation(
                name: item['name'] ?? '이름 없음',
                description: item['description'] ?? '설명 없음',
                compatibilityScore: item['compatibilityScore'] is double 
                  ? item['compatibilityScore'] 
                  : double.parse(item['compatibilityScore'].toString()),
                source: item['source'] ?? '',
              )).toList();
            }
            
            if (recommendations.isEmpty) {
              // 추천 항목이 없다면 일부 텍스트를 사용하여 대안 항목 추가 가능성 검토
              // 평가 텍스트에서 가능한 대안이 있는지 확인
              if (evaluation.toLowerCase().contains("차선책") || 
                  evaluation.toLowerCase().contains("대체") || 
                  evaluation.toLowerCase().contains("그래도") || 
                  evaluation.toLowerCase().contains("차선")) {
                
                recommendations.add(FoodRecommendation(
                  name: '차선책: 메뉴에서 가장 덜 해로운 선택',
                  description: evaluation,
                  compatibilityScore: 0.6,
                  source: '',
                ));
              }
            }
            
            return FoodAnalysisResult(
              recognizedFood: recognizedFood,
              evaluation: evaluation,
              recommendations: recommendations
            );
          } catch (e) {
            print('JSON 파싱 오류: $e');
            // 파싱 오류 발생 시 더 자세한 정보 출력
            print('파싱 오류가 발생한 JSON 문자열: $jsonString');
          }
        }
      }
      
      print('응답에서 JSON 형식을 찾을 수 없습니다: $content');
      // 응답에서 일반 텍스트 형식으로 처리 시도
      try {
        // JSON이 아닌 일반 텍스트 응답에서 정보 추출 시도
        final List<String> lines = content.split('\n');
        String recognizedFood = '인식된 음식 정보 없음';
        String evaluation = '평가 정보 없음';
        List<FoodRecommendation> recommendations = [];
        
        // 간단한 텍스트 파싱 시도
        for (final line in lines) {
          if (line.toLowerCase().contains('인식된 음식') || 
              line.toLowerCase().contains('recognized food') || 
              line.toLowerCase().contains('음식:')) {
            recognizedFood = line.split(':').length > 1 ? line.split(':')[1].trim() : recognizedFood;
          } else if (line.toLowerCase().contains('평가') || 
                     line.toLowerCase().contains('evaluation') || 
                     line.toLowerCase().contains('건강 상태')) {
            evaluation = line;
          } else if (line.contains('1.') || line.contains('2.') || line.contains('3.')) {
            // 번호가 매겨진 추천 항목으로 보이는 경우
            final parts = line.split('.');
            if (parts.length > 1) {
              final name = parts[1].trim().split('-')[0].trim();
              final description = parts.length > 2 ? parts.sublist(2).join('.').trim() : '추천 음식';
              final score = 0.9 - (int.tryParse(parts[0].trim()) ?? 1) * 0.05; // 번호에 따라 점수 감소
              
              recommendations.add(FoodRecommendation(
                name: name,
                description: description,
                compatibilityScore: score,
                source: '',
              ));
            }
          }
        }
        
        if (recommendations.isEmpty) {
          // 추천 항목이 없다면 일부 텍스트를 사용하여 대안 항목 추가 가능성 검토
          // 평가 텍스트에서 가능한 대안이 있는지 확인
          if (evaluation.toLowerCase().contains("차선책") || 
              evaluation.toLowerCase().contains("대체") || 
              evaluation.toLowerCase().contains("그래도") || 
              evaluation.toLowerCase().contains("차선")) {
            
            recommendations.add(FoodRecommendation(
              name: '차선책: 메뉴에서 가장 덜 해로운 선택',
              description: evaluation,
              compatibilityScore: 0.6,
              source: '',
            ));
          }
        }
        
        return FoodAnalysisResult(
          recognizedFood: recognizedFood,
          evaluation: evaluation,
          recommendations: recommendations
        );
      } catch (e) {
        print('일반 텍스트 파싱 오류: $e');
      }
      
      return FoodAnalysisResult(
        recognizedFood: '메뉴 분석 결과를 해석할 수 없습니다',
        evaluation: '형식에 맞지 않는 응답을 받았습니다.',
        recommendations: []
      );
    } catch (e) {
      print('응답 파싱 오류: $e');
      return FoodAnalysisResult(
        recognizedFood: '메뉴 응답 파싱 중 오류 발생',
        evaluation: '메뉴 분석 결과를 처리하는 중 오류가 발생했습니다.',
        recommendations: []
      );
    }
  }

  // Gemini API 응답을 파싱하는 메서드 (이전 버전 호환)
  List<FoodRecommendation> _parseGeminiResponse(Map<String, dynamic> response) {
    try {
      // Gemini API의 응답 구조에 맞게 파싱
      final String content = response['candidates'][0]['content']['parts'][0]['text'];
      
      // JSON 형식으로 응답된 텍스트 추출
      // 응답에서 JSON 형식의 텍스트를 추출 (텍스트에서 JSON 부분만 추출)
      final RegExp jsonRegExp = RegExp(r'(\{.*\})', dotAll: true);
      final match = jsonRegExp.firstMatch(content);
      
      if (match != null) {
        final jsonString = match.group(1);
        
        if (jsonString != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(jsonString);
            
            if (data.containsKey('recommendations') && data['recommendations'] is List) {
              final List<dynamic> recommendationsList = data['recommendations'];
              
              return recommendationsList.map((item) => FoodRecommendation(
                name: item['name'],
                description: item['description'],
                compatibilityScore: item['compatibilityScore'] is double 
                  ? item['compatibilityScore'] 
                  : double.parse(item['compatibilityScore'].toString()),
              )).toList();
            }
          } catch (e) {
            print('JSON 파싱 오류: $e');
          }
        }
      }
      
      print('응답에서 JSON 형식을 찾을 수 없습니다: $content');
      return [];
    } catch (e) {
      print('응답 파싱 오류: $e');
      return [];
    }
  }

  // 이미지 압축 메서드
  Future<Uint8List> _compressImage(File imageFile, int maxSizeInBytes) async {
    try {
      // 원본 이미지 바이트 가져오기
      final bytes = await imageFile.readAsBytes();
      
      // 이미 제한 크기 이내라면 그대로 반환
      if (bytes.length <= maxSizeInBytes) {
        print('이미지가 이미 적합한 크기임: ${bytes.length} 바이트');
        return bytes;
      }
      
      print('이미지 압축 시작: 원본 크기 ${bytes.length} 바이트');
      
      // 압축 품질 계산 (파일 크기에 따라 동적으로 조정)
      int quality = 90;
      if (bytes.length > maxSizeInBytes * 2) {
        quality = 70;
      }
      if (bytes.length > maxSizeInBytes * 4) {
        quality = 50;
      }
      
      // 이미지 압축
      final Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: quality,
      );
      
      if (compressedBytes == null) {
        print('이미지 압축 실패, 원본 반환');
        return bytes;
      }
      
      print('이미지 압축 완료: ${compressedBytes.length} 바이트, 품질: $quality%');
      return compressedBytes;
    } catch (e) {
      print('이미지 압축 중 오류: $e');
      // 오류 발생 시 원본 이미지 반환
      return await imageFile.readAsBytes();
    }
  }
} 