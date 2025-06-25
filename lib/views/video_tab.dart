// lib/app/views/video_tab.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/file_hider_controller.dart';
import '../widgets/file_grid.dart';

class VideoTab extends StatelessWidget {
  const VideoTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FileHiderController>();
    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
      return FileGrid(files: controller.hiddenVideos, category: 'videos');
    });
  }
}