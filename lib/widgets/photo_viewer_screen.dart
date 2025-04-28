import 'dart:io'; // File 사용을 위해 추가
import 'dart:typed_data'; // Uint8List 사용을 위해 추가
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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
    // imageData가 있으면 MemoryImage, 없으면 FileImage 사용
    final ImageProvider imageProvider = imageData != null
        ? MemoryImage(imageData!)
        : FileImage(File(imagePath!));

    // Hero 애니메이션을 위한 고유 태그 생성 (경로나 데이터 기반)
    final heroTag = imagePath ?? imageData.hashCode.toString();

    return Scaffold(
      appBar: AppBar(
        // 투명한 AppBar 또는 뒤로 가기 버튼만 있는 AppBar
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // 아이콘 색상 변경
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // AppBar 뒤까지 콘텐츠 표시
      extendBodyBehindAppBar: true,
      body: PhotoViewGallery.builder(
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
          color: Colors.black, // 배경색 설정
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
    );
  }
} 