import 'dart:io';
import 'package:flutter/material.dart';
import '../models/health_condition.dart';
import '../services/camera_service.dart';
import 'recommendations_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<HealthCondition> selectedHealthConditions;

  const CameraScreen({
    Key? key,
    required this.selectedHealthConditions,
  }) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _takePicture() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final image = await _cameraService.takePicture();
      
      setState(() {
        _selectedImage = image;
        _isLoading = false;
      });
    } catch (e) {
      print('사진 촬영 오류: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('사진을 촬영하는 중 오류가 발생했습니다.');
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final image = await _cameraService.pickImageFromGallery();
      
      setState(() {
        _selectedImage = image;
        _isLoading = false;
      });
    } catch (e) {
      print('이미지 선택 오류: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('이미지를 선택하는 중 오류가 발생했습니다.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _analyzeImage() {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 음식 사진을 촬영하거나 선택해주세요')),
      );
      return;
    }

    // 건강 상태 이름 리스트 추출
    final healthConditionNames = widget.selectedHealthConditions
        .map((condition) => condition.name)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationsScreen(
          imageFile: _selectedImage!,
          healthConditions: healthConditionNames,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '음식 사진 촬영',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: _selectedImage == null
                        ? const Text(
                            '아래 버튼을 눌러 음식 사진을 촬영하거나 선택해주세요',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          )
                        : Image.file(_selectedImage!),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _takePicture,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('사진 촬영'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('갤러리에서 선택'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 32.0,
                  ),
                  child: ElevatedButton(
                    onPressed: _analyzeImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text(
                      '음식 분석하기',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
} 