import 'dart:io';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';

class FileHiderController extends GetxController {
  // Observable lists for hidden files
  var hiddenImages = <File>[].obs;
  var hiddenVideos = <File>[].obs;
  var hiddenAudios = <File>[].obs;
  var hiddenOthers = <File>[].obs;
  var isLoading = false.obs;

  // Method to get vault directory path per category
  Future<Directory> _getHiddenDirectory(String category) async {
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final hiddenDir = Directory(path.join(appDocumentsDir.path, '.vault', category));
    if (!await hiddenDir.exists()) {
      await hiddenDir.create(recursive: true);
    }
    return hiddenDir;
  }

  // Load all hidden files into observable lists
  Future<void> loadHiddenFiles() async {
    isLoading.value = true;
    final imagesDir = await _getHiddenDirectory('images');
    final videosDir = await _getHiddenDirectory('videos');
    final audiosDir = await _getHiddenDirectory('audios');
    final othersDir = await _getHiddenDirectory('others');

    hiddenImages.value = imagesDir.listSync().whereType<File>().toList();
    hiddenVideos.value = videosDir.listSync().whereType<File>().toList();
    hiddenAudios.value = audiosDir.listSync().whereType<File>().toList();
    hiddenOthers.value = othersDir.listSync().whereType<File>().toList();

    isLoading.value = false;
  }

  // Restore image or video file back to gallery
  Future<void> unhideMediaFile(File file, String category) async {
    try {
      AssetEntity? newFile;
      if (category == 'images') {
        newFile = await PhotoManager.editor.saveImage(
          await file.readAsBytes(),
          title: path.basename(file.path),
          filename: path.basename(file.path) + "_vault",
        );
      } else if (category == 'videos') {
        newFile = await PhotoManager.editor.saveVideo(
          file,
          title: path.basename(file.path),
        );
      }

      if (newFile != null) {
        await file.delete();
        Get.snackbar('Success', 'File restored to gallery successfully!');
        await loadHiddenFiles();
      } else {
        throw Exception("Failed to save file to gallery.");
      }
    } catch (e) {
      Get.snackbar('Error', 'Error restoring file: $e');
    }
  }

  // Restore generic file (audio/others) back to Downloads folder
  Future<void> unhideGenericFile(File file) async {
    try {
      final List<Directory>? downloadsDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
      if (downloadsDirs == null || downloadsDirs.isEmpty) {
        throw Exception("Could not find Downloads directory");
      }
      final downloadsDir = downloadsDirs.first;
      final newPath = path.join(downloadsDir.path, path.basename(file.path));

      await file.copy(newPath);
      await file.delete();
      Get.snackbar('Success', 'File restored to Downloads.');
      await loadHiddenFiles();
    } catch (e) {
      Get.snackbar('Error', 'Error restoring file: $e');
    }
  }
}
