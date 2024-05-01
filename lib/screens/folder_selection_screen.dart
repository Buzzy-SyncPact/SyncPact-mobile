import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'selected_folders_screen.dart';
import 'package:syncpact_mobile/services/synchronization_engine.dart';
import 'connection_discovering_screen.dart';
import 'dart:io';

class FolderSelectionScreen extends StatefulWidget {
  const FolderSelectionScreen({super.key});

  @override
  _FolderSelectionScreenState createState() => _FolderSelectionScreenState();
}

class _FolderSelectionScreenState extends State<FolderSelectionScreen> {
  late Folder selected_folder;
  List<FileSystemEntity> files = [];

  @override
  void initState() {
    super.initState();
    pickDirectory();
  }

  void pickDirectory() async {
    try {
      String? folderPath = await FilePicker.platform.getDirectoryPath();
      fetchFiles(folderPath!);
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchFiles(String folderPath) async {
    // Retrieve the list of files inside the selected folder
    print('--- --- --- $folderPath');
    Directory folder = Directory(folderPath);
    List<FileSystemEntity> entities = await folder.list().toList();

    // Filter and store only the files
    List<File> fileList = entities.whereType<File>().toList();

    setState(() {
      files = fileList;
      selected_folder = Folder(folder.path.split('/').last, folder);
    });
  }

  Future<void> moveFolder(String sourcePath, String destinationPath) async {
    final sourceDirectory = Directory(sourcePath);
    final destinationDirectory = Directory(destinationPath);

    // Create the destination directory if it doesn't exist
    if (!destinationDirectory.existsSync()) {
      await destinationDirectory.create(recursive: true);
    }

    // Get a list of files and directories inside the source directory
    final filesList = sourceDirectory.listSync();

    // Move each file and directory to the destination directory
    for (var fileOrDir in filesList) {
      final fileName = fileOrDir.path.split('/').last;
      final newPath = '${destinationDirectory.path}/$fileName';
      fileOrDir.renameSync(newPath);
    }

    // Remove the empty source directory
    await sourceDirectory.delete();
    await fetchFiles(destinationPath);
    SynchronizationEngine().startMonitoring(destinationDirectory.path);
  }

  void navigateToConnectionDiscoveringScreen() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConnectionDiscoveringScreen(
          directory_name: selected_folder.folderName,
          files: files,
        ),
      ),
    );
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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: const Text(
                  "Selected Folders",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
          Expanded(
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                FileSystemEntity file = files[index];
                String fileName = file.path.split('/').last;
                IconData fileIcon;
                if (file is File) {
                  fileIcon = Icons.insert_drive_file;
                } else if (file is Directory) {
                  fileIcon = Icons.folder;
                } else {
                  fileIcon = Icons.attachment;
                }

                return ListTile(
                  leading: Icon(fileIcon),
                  title: Text(fileName),
                  onTap: () {},
                );
              },
            ),
          )
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            await moveFolder(selected_folder.directory.path,
                '/storage/emulated/0/SyncPact/${selected_folder.folderName}');
            navigateToConnectionDiscoveringScreen();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
          child: const Text(
            'Continue',
            style: TextStyle(color: Colors.white, fontSize: 16.0),
          ),
        ),
      ),
    );
  }
}
