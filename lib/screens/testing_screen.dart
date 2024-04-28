import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'selected_folders_screen.dart';

class TestingScreen extends StatefulWidget {
  const TestingScreen({super.key});

  @override
  _TestingScreenState createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {
  List<Folder> folders = [];

  @override
  void initState() {
    super.initState();
    fetchDirectories();
  }

  void fetchDirectories() async {
    // Request the necessary permissions
    var status = await Permission.storage.request();

    if (status.isGranted) {
      // Permission granted, proceed with picking the directory
      final directoryPath = await FilePicker.platform.getDirectoryPath();

      if (directoryPath != null) {
        listFilesAndDirectories(directoryPath);
      } else {
        print('No directory selected.');
      }
    } else {
      print('Permission not granted.');
    }

    try {
      // Open the file picker to select a folder
      String? folderPath = await FilePicker.platform.getDirectoryPath();

      if (folderPath != null) {
        // Retrieve the list of files inside the selected folder
        Directory folder = Directory(folderPath);
        List<FileSystemEntity> entities = await folder.list().toList();
        print(entities);

        // Filter and store only the directories
        List<Folder> folderList = entities
            .whereType<Directory>()
            .map((directory) =>
                Folder(directory.path.split('/').last, directory))
            .toList();

        setState(() {
          folders = folderList;
        });
      }
    } catch (e) {
      // Handle any error that occurs during folder selection
      print('Error: $e');
    }
  }

  void listFilesAndDirectories(String directoryPath) {
    try {
      final directory = Directory(directoryPath);
      List<FileSystemEntity> entities = directory.listSync(recursive: true);

      for (FileSystemEntity entity in entities) {
        if (entity is File) {
          print('File: ${entity.path}');
        } else if (entity is Directory) {
          print('Directory: ${entity.path}');
        }
      }
    } catch (e) {
      print('Error while listing files and directories: $e');
    }
  }

  void navigateToSelectedFoldersScreen() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectedFoldersScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Selected Files',
          style: TextStyle(
            fontSize: 25.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: folders.length,
        itemBuilder: (context, index) {
          Folder folder = folders[index];

          return ListTile(
            leading: const Icon(Icons.folder),
            title: Text(folder.folderName),
            onTap: () {
              // Handle folder selection if needed
              navigateToSelectedFoldersScreen();
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            navigateToSelectedFoldersScreen();
          },
          child: const Text('Backup'),
        ),
      ),
    );
  }
}
