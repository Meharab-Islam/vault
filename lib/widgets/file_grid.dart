import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import '../controllers/file_hider_controller.dart';

class FileGrid extends StatelessWidget {
  final List<File> files;
  final String category;

  const FileGrid({super.key, required this.files, required this.category});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FileHiderController>();

    if (files.isEmpty) {
      return Center(child: Text('No hidden $category files'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: files.length,
      itemBuilder: (_, i) {
        final file = files[i];
        return GestureDetector(
          onTap: () => _showUnhideDialog(context, file, category, controller),
          child: GridTile(
            footer: GridTileBar(
              backgroundColor: Colors.black54,
              title: Text(
                path.basename(file.path),
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildThumbnail(file, category),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(File file, String category) {
    switch (category) {
      case 'images':
        return Image.file(file, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
      case 'videos':
        return Container(
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
          ),
        );
      case 'audios':
        return Container(
          color: Colors.purple.shade900,
          child: const Center(
            child: Icon(Icons.music_note, color: Colors.white, size: 50),
          ),
        );
      default:
        return Container(
          color: Colors.blueGrey.shade900,
          child: const Center(
            child: Icon(Icons.insert_drive_file, color: Colors.white, size: 50),
          ),
        );
    }
  }

  void _showUnhideDialog(BuildContext context, File file, String category, FileHiderController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore File?'),
        content: Text('Do you want to restore "${path.basename(file.path)}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (category == 'images' || category == 'videos') {
                controller.unhideMediaFile(file, category);
              } else {
                controller.unhideGenericFile(file);
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}
