// lib/app/views/others_tab.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/file_hider_controller.dart';
import '../widgets/file_grid.dart';

class OthersTab extends StatelessWidget {
  const OthersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FileHiderController>();
    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
      return FileGrid(files: controller.hiddenOthers, category: 'others');
    });
  }
}
