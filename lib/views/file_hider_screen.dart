import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as path;

import '../service/file_hider_service.dart';

class FileHiderScreen extends StatefulWidget {
  const FileHiderScreen({super.key});

  @override
  State<FileHiderScreen> createState() => _FileHiderScreenState();
}

class _FileHiderScreenState extends State<FileHiderScreen> {
  final FileHiderService _fileHiderService = FileHiderService();

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

  Future<void> _loadHiddenFiles() async {
    setState(() => _isLoading = true);

    // Assuming you changed _getHiddenDirectory in service to public getHiddenDirectory
    final imagesDir = await _fileHiderService.getHiddenDirectory('images');
    final videosDir = await _fileHiderService.getHiddenDirectory('videos');
    final audiosDir = await _fileHiderService.getHiddenDirectory('audios');
    final othersDir = await _fileHiderService.getHiddenDirectory('others');

    setState(() {
      _hiddenImages = imagesDir.listSync().whereType<File>().toList();
      _hiddenVideos = videosDir.listSync().whereType<File>().toList();
      _hiddenAudios = audiosDir.listSync().whereType<File>().toList();
      _hiddenOthers = othersDir.listSync().whereType<File>().toList();
      _isLoading = false;
    });
  }

  // Use service methods for hiding files
  Future<void> _pickAndHideMedia(RequestType type, String category) async {
    await _fileHiderService.pickAndHideMediaFiles(context, type, category);
    await _loadHiddenFiles();
  }

  Future<void> _pickAndHideAudios() async {
    await _fileHiderService.pickAndHideAudios();
    await _loadHiddenFiles();
  }

  Future<void> _pickAndHideOtherFiles() async {
    await _fileHiderService.pickAndHideOtherFiles();
    await _loadHiddenFiles();
  }

  Widget _buildAddFileMenu() {
    return PopupMenuButton<Function>(
      onSelected: (function) => function(),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: () => _pickAndHideMedia(RequestType.image, 'images'),
          child: const ListTile(leading: Icon(Icons.image), title: Text('Hide Images')),
        ),
        PopupMenuItem(
          value: () => _pickAndHideMedia(RequestType.video, 'videos'),
          child: const ListTile(leading: Icon(Icons.videocam), title: Text('Hide Videos')),
        ),
        PopupMenuItem(
          value: _pickAndHideAudios,
          child: const ListTile(leading: Icon(Icons.audiotrack), title: Text('Hide Audio')),
        ),
        PopupMenuItem(
          value: _pickAndHideOtherFiles,
          child: const ListTile(leading: Icon(Icons.insert_drive_file), title: Text('Hide Other Files')),
        ),
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
        return Container(color: Colors.black, child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 50));
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 8.0, mainAxisSpacing: 8.0),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return GestureDetector(
          onTap: () => _showUnhideDialog(file, category),
          child: GridTile(
            footer: GridTileBar(
              backgroundColor: Colors.black54,
              title: Text(path.basename(file.path), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            ),
            child: ClipRRect(borderRadius: BorderRadius.circular(8.0), child: _buildThumbnail(file, category)),
          ),
        );
      },
    );
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
              _unhideFile(file, category);
            }),
          ],
        );
      },
    );
  }

  Future<void> _unhideFile(File file, String category) async {
    if (category == 'images' || category == 'videos') {
      await _fileHiderService.unhideMediaFile(file, category);
    } else {
      await _fileHiderService.unhideGenericFile(file);
    }
    await _loadHiddenFiles();
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
