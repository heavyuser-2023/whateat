import 'dart:io'; // File 사용을 위해 추가
import 'dart:typed_data'; // Uint8List 사용을 위해 추가
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 누락된 import 추가
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter/rendering.dart';

class PhotoViewerScreen extends StatelessWidget {
  final Uint8List? imageData; // 메모리 이미지 데이터
  final String? imagePath; // 파일 경로

  // imageData 또는 imagePath 중 하나는 반드시 존재해야 함
  const PhotoViewerScreen({
    super.key,
    this.imageData,
    this.imagePath,
  }) : assert(imageData != null || imagePath != null);

  @override
  Widget build(BuildContext context) {
    // 상태 표시줄 높이 가져오기
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    // AppBar 높이 가져오기
    const double appBarHeight = kToolbarHeight;

    // imageData가 있으면 MemoryImage, 없으면 FileImage 사용
    final ImageProvider imageProvider = imageData != null
        ? MemoryImage(imageData!)
        : FileImage(File(imagePath!));

    // Hero 애니메이션을 위한 고유 태그 생성 (경로나 데이터 기반)
    final heroTag = imagePath ?? imageData.hashCode.toString();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // 배경이 어두우므로 밝은 아이콘
      child: Scaffold(
        extendBodyBehindAppBar: true, // AppBar 뒤로 body 확장 유지
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white), // 아이콘 색상 변경
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack( // Stack으로 감싸기
          children: [
            // 메인 콘텐츠 (PhotoViewGallery)
            // Stack 내에서는 Expanded 불필요, PhotoViewGallery가 전체 영역 차지
            Container(
              color: Colors.black, // 명시적으로 배경색 설정
              child: PhotoViewGallery.builder(
                itemCount: 1,
                builder: (context, index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: imageProvider, // 수정된 imageProvider 사용
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 2.0,
                    heroAttributes: PhotoViewHeroAttributes(tag: heroTag), // 고유 태그 사용
                  );
                },
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent, // Stack의 Container 배경색 사용
                ),
                pageController: PageController(), // 단일 이미지이므로 기본 PageController 사용
                // 로딩 중 표시할 위젯 (선택 사항)
                loadingBuilder: (context, event) => const Center(
                  child: SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // 로딩 색상 변경
                    ),
                  ),
                ),
              ),
            ),
            // 상단 그라데이션 오버레이
            // 검은 배경에서는 필수적이지 않을 수 있으나, 일관성 및 이미지 상단 밝은 부분 대비용
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: statusBarHeight + 20, // 상태 표시줄 높이 + 약간의 추가 영역
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.40), // 배경이 검으므로 좀 더 강하게
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