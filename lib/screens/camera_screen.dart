import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/health_condition.dart';
import '../services/camera_service.dart';
import 'recommendations_screen.dart';
import 'package:flutter/rendering.dart';

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
    // 상태 표시줄 높이 가져오기
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // AppBar가 어두우므로 밝은 아이콘
      child: Scaffold(
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
        body: Stack( // Stack으로 감싸기
          children: [
             // 메인 콘텐츠 (기존 body 내용)
             Padding(
               padding: EdgeInsets.only(top: 0), // AppBar가 불투명하므로 추가 상단 패딩 불필요
               child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: _selectedImage == null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                                    margin: const EdgeInsets.symmetric(horizontal: 40.0), // 좌우 여백 추가
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50, // 연한 녹색 배경
                                      borderRadius: BorderRadius.circular(12.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    ),
                                    child: Text(
                                      '아래 버튼을 눌러 메뉴판 또는 음식 사진을 촬영하거나 선택해주세요',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.green.shade800, // 진한 녹색 텍스트
                                        fontWeight: FontWeight.w500, // 약간 두껍게
                                        height: 1.4, // 줄 간격
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
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
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.photo_library),
                                label: const Text('갤러리에서 선택'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
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
             ),
            // 상단 그라데이션 오버레이 (AppBar 색상과 조화롭게)
            // AppBar가 불투명하고 색상이 진해서 필요 없을 수 있음
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: statusBarHeight, // 상태 표시줄 높이만큼만
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.20),
                      Colors.black.withOpacity(0.0),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 