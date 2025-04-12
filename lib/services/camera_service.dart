import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (photo == null) return null;
      
      // 이미지를 앱 저장소에 저장
      final File savedImage = await _saveImage(File(photo.path));
      return savedImage;
    } catch (e) {
      print('사진 촬영 중 오류 발생: $e');
      return null;
    }
  }

  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      
      if (image == null) return null;
      
      // 이미지를 앱 저장소에 저장
      final File savedImage = await _saveImage(File(image.path));
      return savedImage;
    } catch (e) {
      print('갤러리에서 이미지 선택 중 오류 발생: $e');
      return null;
    }
  }

  Future<File> _saveImage(File image) async {
    try {
      // 앱 문서 디렉토리 가져오기
      final Directory documentsDir = await getApplicationDocumentsDirectory();
      
      // 파일명 생성 (현재 시간 기준)
      final String fileName = 'food_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // 앱 저장소에 저장할 경로 생성
      final String filePath = join(documentsDir.path, fileName);
      
      // 파일 복사
      return await image.copy(filePath);
    } catch (e) {
      print('이미지 저장 중 오류 발생: $e');
      // 원본 이미지 반환
      return image;
    }
  }
} 