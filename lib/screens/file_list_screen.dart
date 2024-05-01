import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';

class FileListScreen extends StatefulWidget {
  const FileListScreen({super.key});

  @override
  _FileListScreenState createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  List<File> files = [];
  Timer? fileCheckTimer;

  @override
  void initState() {
    super.initState();
    startFileCheckTimer();
  }

  @override
  void dispose() {
    fileCheckTimer?.cancel();
    super.dispose();
  }

  void startFileCheckTimer() {
    fileCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchFiles();
    });
  }

  Future<void> fetchFiles() async {
    try {
      String appDir = (await getExternalStorageDirectory())!.absolute.path;
      final filesDir = Directory(appDir);
      List<FileSystemEntity> entities = await filesDir.list().toList();

      List<File> updatedFiles = entities.whereType<File>().toList();
      print(updatedFiles);

      setState(() {
        files = updatedFiles;
      });
    } catch (e) {
      print('Error fetching files: $e');
    }
  }

  IconData getFileIcon(String extension) {
    final mimeType = lookupMimeType('file.$extension');
    if (mimeType != null) {
      final fileType = mimeType.split('/')[0];
      switch (fileType) {
        case 'image':
          return Icons.image;
        case 'audio':
          return Icons.audiotrack;
        case 'video':
          return Icons.videocam;
        case 'application':
          return Icons.insert_drive_file;
      }
    }
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "SyncPact",
          style: TextStyle(
            fontSize: 25.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: const Text(
                  "File List",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
          const SyncStatusWidget(
            lastSyncTime: 'Last synced: 10:30 AM',
            isSyncing: false,
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                File file = files[index];
                String fileName = file.path.split('/').last;
                String fileExtension = fileName.split('.').last;
                return ListTile(
                  leading: Icon(getFileIcon(fileExtension)),
                  title: Text(fileName),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SyncStatusWidget extends StatelessWidget {
  final String lastSyncTime;
  final bool isSyncing;

  const SyncStatusWidget({
    super.key,
    required this.lastSyncTime,
    required this.isSyncing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isSyncing ? Icons.refresh : Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 8.0),
              Text(
                lastSyncTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (isSyncing)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
        ],
      ),
    );
  }
}
