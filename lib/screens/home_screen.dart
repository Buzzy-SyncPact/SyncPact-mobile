import 'dart:io';
import 'package:flutter/material.dart';
import 'selected_folders_screen.dart';
import 'folder_selection_screen.dart';
import 'connection_advertising_screen.dart';
import 'package:syncpact_mobile/components/elevation_card.dart';
import 'package:syncpact_mobile/components/elevation_option_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void createApplicationStorageDirectory() {
    String parentDirectoryPath = '/storage/emulated/0';
    String newDirectoryName = 'SyncPact';

    Directory parentDirectory = Directory(parentDirectoryPath);
    Directory newDirectory =
        Directory('${parentDirectory.path}/$newDirectoryName');

    if (!newDirectory.existsSync()) {
      newDirectory.createSync();
      print('New directory created: ${newDirectory.path}');
    } else {
      print('Directory already exists: ${newDirectory.path}');
    }
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedCard(
                text:
                    "SyncPact is designed to synchronize, backup, and mirror the contents of a folder across multiple Android devices. ",
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
                onTap: () {
                  createApplicationStorageDirectory();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FolderSelectionScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedOptionCard(
                      icon: Icons.devices_other,
                      text: "Select data to synchronize",
                      title: "Source Device"),
                )),
            const SizedBox(height: 16),
            GestureDetector(
                onTap: () {
                  createApplicationStorageDirectory();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ConnectionAdvertisingScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedOptionCard(
                      icon: Icons.backup,
                      text: "Find a device to backup",
                      title: "Backup Device"),
                )),
            const SizedBox(height: 16),
            GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SelectedFoldersScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedOptionCard(
                      icon: Icons.folder_copy,
                      text: "Selected folders ",
                      title: "Folders"),
                )),
          ],
        ),
      ),
    );
  }
}
