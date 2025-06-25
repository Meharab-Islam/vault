import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class FileHiderService {
  Future<Directory> getHiddenDirectory(String category) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = Directory(path.join(dir.path, '.vault', category));
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    return target;
  }

  Future<List<File>> getHiddenFiles(String category) async {
    final dir = await getHiddenDirectory(category);
    return dir.listSync().whereType<File>().toList();
  }

  Future<void> pickAndHideMediaFiles(BuildContext context, RequestType type, String category) async {
    final List<AssetEntity>? assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        requestType: type,
        maxAssets: 100,
        themeColor: Colors.deepPurple,
      ),
    );

    if (assets == null || assets.isEmpty) return;

    final hiddenDir = await getHiddenDirectory(category);
    List<String> assetIdsToDelete = [];

    for (final asset in assets) {
      try {
        final file = await asset.originFile;
        if (file == null) continue;

        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
        final newPath = path.join(hiddenDir.path, fileName);

        await file.copy(newPath);
        assetIdsToDelete.add(asset.id);
      } catch (_) {}
    }

    if (assetIdsToDelete.isNotEmpty) {
      try {
        await PhotoManager.editor.deleteWithIds(assetIdsToDelete);
      } catch (_) {}
    }
  }

  Future<void> pickAndHideAudios() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
    if (result != null) {
      await hideGenericFiles(result.paths.whereType<String>().map((p) => File(p)).toList(), 'audios');
    }
  }

  Future<void> pickAndHideOtherFiles() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: true);
    if (result != null) {
      await hideGenericFiles(result.paths.whereType<String>().map((p) => File(p)).toList(), 'others');
    }
  }

  Future<void> hideGenericFiles(List<File> files, String category) async {
    final hiddenDir = await getHiddenDirectory(category);
    for (final file in files) {
      try {
        final newPath = path.join(hiddenDir.path, '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}');
        await file.copy(newPath);
        await file.delete();
      } catch (_) {}
    }
  }

  Future<void> unhideMediaFile(File file, String category) async {
    if (category == 'images') {
      await PhotoManager.editor.saveImage(await file.readAsBytes(), title: path.basename(file.path), filename: path.basename(file.path));
    } else if (category == 'videos') {
      await PhotoManager.editor.saveVideo(file, title: path.basename(file.path));
    }
    await file.delete();
  }

  Future<void> unhideGenericFile(File file) async {
    final List<Directory>? downloadsDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
    if (downloadsDirs == null || downloadsDirs.isEmpty) throw Exception("Downloads directory not found");
    final downloadsDir = downloadsDirs.first;
    final newPath = path.join(downloadsDir.path, path.basename(file.path));
    await file.copy(newPath);
    await file.delete();
  }
}
