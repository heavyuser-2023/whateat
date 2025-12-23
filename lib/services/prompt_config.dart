class FoodRecognitionPrompts {
  static String foodAnalysisPrompt(String healthConditionsText, String langInstruction) {
    return '''
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
  }
}
