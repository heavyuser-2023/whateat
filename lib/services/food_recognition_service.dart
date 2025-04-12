import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/meal.dart';

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
  
  final String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent';
  
  // .env 파일에서 API 키를 로드
  String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
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
      // 이미지를 base64로 인코딩
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 건강 상태 조건이 너무 길면 프롬프트 최적화
      String promptText = "이 음식 메뉴 이미지를 분석해주세요.";
      
      if (healthConditions.length > 3) {
        // 건강 조건이 많은 경우 가장 중요한 조건 3개만 명시적으로 언급
        promptText += " 특히 다음 건강 상태에 적합한지 중점적으로 평가해주세요: ${healthConditions.take(3).join(', ')}";
        promptText += " 그리고 나머지 ${healthConditions.length - 3}개 건강 조건들(${healthConditions.skip(3).join(', ')})도 함께 고려해주세요.";
      } else {
        promptText += " 다음 건강 상태에 맞는 선택을 알려주세요: ${healthConditions.join(', ')}.";
      }
      
      promptText += " 중요: 메뉴에 있는 음식들 중에서만 추천해주세요. 다른 음식은 추천하지 마세요.";
      promptText += " 평가 후 메뉴 내에서 건강 상태에 적합한 음식을 5가지 순위를 매겨 추천해 주세요.";
      promptText += " JSON 형식으로 응답해주세요: {\"recognized_food\": \"인식된 메뉴 이름\", \"evaluation\": \"건강 상태에 대한 평가\", \"recommendations\": [{\"name\": \"메뉴에서 추천하는 음식 이름\", \"description\": \"추천 이유\", \"compatibilityScore\": 0.95}, ...]}";
      
      print('최종 프롬프트: $promptText'); // 디버그 로그

      // API 호출을 위한 요청 본문 생성
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
          "maxOutputTokens": 2048,  // 토큰 수 증가
        }
      });

      // 실제 API 호출
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: payload,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Gemini API 응답 파싱하여 분석 결과 생성
        return _parseFullGeminiResponse(jsonResponse);
      } else {
        print('API 호출 실패: ${response.statusCode} - ${response.body}');
        throw Exception('API 호출 실패: ${response.reasonPhrase}');
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
            
            if (data.containsKey('recommendations') && data['recommendations'] is List) {
              final List<dynamic> recommendationsList = data['recommendations'];
              print('추천 목록 수: ${recommendationsList.length}'); // 디버그용 로그
              
              recommendations = recommendationsList.map((item) {
                final name = item['name'] ?? '추천 음식';
                final description = item['description'] ?? '설명 없음';
                double compatibilityScore = 0.5;  // 기본값 설정
                
                try {
                  // 호환성 점수를 다양한 형식으로 처리
                  if (item['compatibilityScore'] is double) {
                    compatibilityScore = item['compatibilityScore'];
                  } else if (item['compatibilityScore'] is int) {
                    compatibilityScore = (item['compatibilityScore'] as int).toDouble();
                  } else if (item['compatibilityScore'] != null) {
                    // 문자열이나 다른 형식을 처리
                    compatibilityScore = double.tryParse(item['compatibilityScore'].toString()) ?? 0.5;
                  }
                } catch (e) {
                  print('호환성 점수 파싱 오류: $e');
                  // 오류 발생 시 기본값 사용
                }
                
                print('추천: $name, 점수: $compatibilityScore'); // 디버그용 로그
                
                return FoodRecommendation(
                  name: name,
                  description: description,
                  compatibilityScore: compatibilityScore,
                );
              }).toList();
            } else {
              print('추천 목록을 찾을 수 없거나 형식이 잘못됨: ${data['recommendations']}'); // 디버그용 로그
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
              ));
            }
          }
        }
        
        if (recommendations.isEmpty) {
          // 추천 항목이 없다면 일부 텍스트를 사용하여 더미 데이터 생성
          recommendations.add(FoodRecommendation(
            name: '건강한 대체 음식',
            description: evaluation,
            compatibilityScore: 0.9,
          ));
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
} 