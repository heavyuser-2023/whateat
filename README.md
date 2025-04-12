# 왓이트 (WhatEat)

건강 상태에 맞는 맞춤형 식단을 추천받는 앱입니다.

## 주요 기능

- 건강 상태 선택: 콜레스테롤, 당뇨, 고혈압 등 건강 상태를 선택할 수 있습니다.
- 음식 사진 촬영/선택: 카메라로 음식 사진을 촬영하거나 갤러리에서 선택할 수 있습니다.
- Google Gemini AI를 활용한 음식 분석: 음식 사진을 분석하여 건강 상태에 맞는 음식을 추천합니다.
- 식사 기록 저장: 선택한 추천 음식을 로컬 데이터베이스에 저장합니다.
- 식사 기록 조회: 과거 식사 기록을 확인할 수 있습니다.

## Google Gemini API 설정

앱에서 Google Gemini API를 사용하기 위해 다음 단계를 따라주세요:

1. [Google AI Studio](https://makersuite.google.com/app/apikey) 또는 [Google Cloud Console](https://console.cloud.google.com/)에서 API 키를 생성합니다.
2. `lib/services/food_recognition_service.dart` 파일에서 `apiKey` 변수에 발급받은 API 키를 입력합니다.
3. API 호출 부분의 주석을 해제하여 실제 API 호출이 가능하도록 합니다.

```dart
// food_recognition_service.dart 예시
static const String apiKey = 'YOUR_API_KEY'; // 여기에 발급받은 API 키를 입력하세요
```

## 설치 및 실행

```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

## 앱 권한 요구사항

- 카메라: 음식 사진 촬영을 위해 필요합니다.
- 사진 라이브러리: 갤러리에서 이미지를 선택하기 위해 필요합니다.
