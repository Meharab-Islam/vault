import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
        ),
      ),
      home: const FileHiderScreen(),
    );
  }
}

class FileHiderScreen extends StatefulWidget {
  const FileHiderScreen({super.key});

  @override
  State<FileHiderScreen> createState() => _FileHiderScreenState();
}

class _FileHiderScreenState extends State<FileHiderScreen> {
  List<File> _hiddenImages = [];
  List<File> _hiddenVideos = [];
  List<File> _hiddenAudios = [];
  List<File> _hiddenOthers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndLoadFiles();
  }

  Future<void> _requestPermissionsAndLoadFiles() async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      await _loadHiddenFiles();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permissions are required to manage media.'),
            action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Directory> _getHiddenDirectory(String category) async {
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final hiddenDir = Directory(path.join(appDocumentsDir.path, '.vault', category));
    if (!await hiddenDir.exists()) {
      await hiddenDir.create(recursive: true);
    }
    return hiddenDir;
  }

  Future<void> _loadHiddenFiles() async {
    setState(() => _isLoading = true);
    final imagesDir = await _getHiddenDirectory('images');
    final videosDir = await _getHiddenDirectory('videos');
    final audiosDir = await _getHiddenDirectory('audios');
    final othersDir = await _getHiddenDirectory('others');

    setState(() {
      _hiddenImages = imagesDir.listSync().whereType<File>().toList();
      _hiddenVideos = videosDir.listSync().whereType<File>().toList();
      _hiddenAudios = audiosDir.listSync().whereType<File>().toList();
      _hiddenOthers = othersDir.listSync().whereType<File>().toList();
      _isLoading = false;
    });
  }

Future<void> _hideMediaFiles(List<AssetEntity> assets, String category) async {
  if (assets.isEmpty) return;

  final hiddenDir = await _getHiddenDirectory(category);
  int successCount = 0;
  int failureCount = 0;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Hiding files... Please wait.'), duration: Duration(minutes: 5)),
  );

  List<String> assetIdsToDelete = [];

  for (final asset in assets) {
    try {
      final file = await asset.originFile; // use `originFile` for full-quality
      if (file == null) {
        debugPrint("Asset file is null: ${asset.id}");
        failureCount++;
        continue;
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final newPath = path.join(hiddenDir.path, fileName);

      await file.copy(newPath);
      assetIdsToDelete.add(asset.id);
      successCount++;

    } catch (e) {
      debugPrint("Error copying asset ${asset.id}: $e");
      failureCount++;
    }
  }

  // Delete original media from gallery using PhotoManager
  if (assetIdsToDelete.isNotEmpty) {
    try {
      await PhotoManager.editor.deleteWithIds(assetIdsToDelete);
    } catch (e) {
      debugPrint("Error deleting from gallery: $e");
    }
  }

  if (mounted) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (failureCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to hide $failureCount file(s).')),
      );
    } else if (successCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successCount file(s) hidden successfully!')),
      );
    }
  }

  await _loadHiddenFiles();
}


  Future<void> _pickAndHideMedia(RequestType type, String category) async {
    final List<AssetEntity>? assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        requestType: type,
        maxAssets: 100,
        themeColor: Colors.deepPurple,
      ),
    );

    if (assets != null && assets.isNotEmpty) {
      await _hideMediaFiles(assets, category);
    }
  }

  Future<void> _pickAndHideAudios() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
    if (result != null) {
      await _hideGenericFiles(result.paths.whereType<String>().map((p) => File(p)).toList(), 'audios');
    }
  }

  Future<void> _pickAndHideOtherFiles() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: true);
    if (result != null) {
      await _hideGenericFiles(result.paths.whereType<String>().map((p) => File(p)).toList(), 'others');
    }
  }

  Future<void> _hideGenericFiles(List<File> files, String category) async {
    final hiddenDir = await _getHiddenDirectory(category);
    int successCount = 0;
    for (final file in files) {
      try {
        final newPath = path.join(hiddenDir.path, '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}');
        await file.copy(newPath);
        await file.delete();
        successCount++;
      } catch (e) {
        debugPrint("Failed to hide file ${file.path}: $e");
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hid $successCount file(s).')));
    }
    await _loadHiddenFiles();
  }

  Future<void> _unhideMediaFile(File file, String category) async {
    try {
      final AssetEntity? newFile;
      if (category == 'images') {
        newFile = await PhotoManager.editor.saveImage(await file.readAsBytes(), title: path.basename(file.path), filename: path.basename(file.path)+"vault");
      } else {
        newFile = await PhotoManager.editor.saveVideo(file, title: path.basename(file.path));
      }

      if (newFile != null) {
        await file.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File restored to gallery successfully!')));
        }
      } else {
        throw Exception("Failed to save file to gallery.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error restoring file: $e')));
      }
    }
    await _loadHiddenFiles();
  }

  Future<void> _unhideGenericFile(File file) async {
    try {
      final List<Directory>? downloadsDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
      if (downloadsDirs == null || downloadsDirs.isEmpty) {
        throw Exception("Could not find Downloads directory");
      }
      final downloadsDir = downloadsDirs.first;
      final newPath = path.join(downloadsDir.path, path.basename(file.path));

      await file.copy(newPath);
      await file.delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File restored to Downloads.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error restoring file: $e')));
    }
    await _loadHiddenFiles();
  }

  void _showUnhideDialog(File file, String category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restore File?'),
          content: Text('Do you want to restore "${path.basename(file.path)}" to your gallery/downloads?'),
          actions: <Widget>[
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
            TextButton(child: const Text('Restore'), onPressed: () {
              Navigator.of(context).pop();
              if (category == 'images' || category == 'videos') {
                _unhideMediaFile(file, category);
              } else {
                _unhideGenericFile(file);
              }
            }),
          ],
        );
      },
    );
  }

  Widget _buildAddFileMenu() {
    return PopupMenuButton<Function>(
      onSelected: (function) => function(),
      itemBuilder: (context) => [
        PopupMenuItem(value: () => _pickAndHideMedia(RequestType.image, 'images'), child: const ListTile(leading: Icon(Icons.image), title: Text('Hide Images'))),
        PopupMenuItem(value: () => _pickAndHideMedia(RequestType.video, 'videos'), child: const ListTile(leading: Icon(Icons.videocam), title: Text('Hide Videos'))),
        PopupMenuItem(value: _pickAndHideAudios, child: const ListTile(leading: Icon(Icons.audiotrack), title: Text('Hide Audio'))),
        PopupMenuItem(value: _pickAndHideOtherFiles, child: const ListTile(leading: Icon(Icons.insert_drive_file), title: Text('Hide Other Files'))),
      ],
      icon: const Icon(Icons.add_circle, size: 30),
      tooltip: 'Add files to vault',
    );
  }

  Widget _buildThumbnail(File file, String category) {
    switch (category) {
      case 'images':
        return Image.file(file, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
      case 'videos':
        return Container(color: Colors.black, child: const Icon(Icons.play_circle_filled, color: Colors.white, size: 50));
      case 'audios':
        return Container(color: Colors.purple.shade900, child: const Icon(Icons.music_note, color: Colors.white, size: 50));
      default:
        return Container(color: Colors.blueGrey.shade900, child: const Icon(Icons.description, color: Colors.white, size: 50));
    }
  }

  Widget _buildFileGrid(List<File> files, String category) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (files.isEmpty) return Center(child: Text('No hidden $category.', style: TextStyle(color: Colors.grey[600])));

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8.0, mainAxisSpacing: 8.0),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return GestureDetector(
          onTap: () => _showUnhideDialog(file, category),
          child: GridTile(
            footer: GridTileBar(backgroundColor: Colors.black54, title: Text(path.basename(file.path), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
            child: ClipRRect(borderRadius: BorderRadius.circular(8.0), child: _buildThumbnail(file, category)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Secure Vault'),
          actions: [_buildAddFileMenu(), const SizedBox(width: 10)],
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.image), text: 'Images'),
            Tab(icon: Icon(Icons.videocam), text: 'Videos'),
            Tab(icon: Icon(Icons.audiotrack), text: 'Audio'),
            Tab(icon: Icon(Icons.folder_zip), text: 'Others'),
          ]),
        ),
        body: TabBarView(children: [
          _buildFileGrid(_hiddenImages, 'images'),
          _buildFileGrid(_hiddenVideos, 'videos'),
          _buildFileGrid(_hiddenAudios, 'audios'),
          _buildFileGrid(_hiddenOthers, 'others'),
        ]),
      ),
    );
  }
}
