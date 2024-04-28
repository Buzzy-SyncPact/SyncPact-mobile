import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncpact_mobile/services/synchronization_engine.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:syncpact_mobile/components/animated_connection_icon.dart';

class ConnectionAdvertisingScreen extends StatefulWidget {
  final _ConnectionAdvertisingScreenState state =
      _ConnectionAdvertisingScreenState();

  ConnectionAdvertisingScreen({super.key});

  @override
  _ConnectionAdvertisingScreenState createState() => state;

  void sendPayload(String fileName) {
    state.sendPayload(fileName);
  }

  void sendFile(String filePath) {
    state.sendFile(filePath);
  }

  Map<String, ConnectionInfo> getEndPointMap() {
    return state.getEndPointMap();
  }
}

class _ConnectionAdvertisingScreenState
    extends State<ConnectionAdvertisingScreen> {
  final String userName = Random().nextInt(10000).toString();
  final Strategy strategy = Strategy.P2P_STAR;
  static Map<String, ConnectionInfo> endpointMap = {};
  bool isBackup = true;

  String? tempFileUri; //reference to the file currently being transferred
  static String? tempDirectoryName;
  static Map<int, String> map =
      {}; //store filename mapped to corresponding payloadId

  @override
  void initState() {
    super.initState();
    startAdvertising();
  }

  // @override
  // void dispose() {
  //   stopAdvertising();
  //   super.dispose();
  // }

  Map<String, ConnectionInfo> getEndPointMap() {
    return endpointMap;
  }

  Future<void> startAdvertising() async {
    try {
      bool a = await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: onConnectionInit,
        onConnectionResult: (id, status) {
          // showSnackbar("Starting network");
        },
        onDisconnected: (id) {
          showSnackbar(
              // "Disconnected: ${endpointMap[id]!.endpointName}, id $id");
              "Device Disconnected");
          setState(() {
            endpointMap.remove(id);
          });
        },
      );
      // showSnackbar("ADVERTISING: " + a.toString());
    } catch (exception) {
      // showSnackbar(exception);
      print(exception);
    }
  }

  Future<void> stopAdvertising() async {
    await Nearby().stopAdvertising();
  }

  void showSnackbar(dynamic a) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(a.toString()),
    ));
  }

  void onConnectionInit(String id, ConnectionInfo info) {
    showDialog(
      context: context,
      builder: (builder) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("id: $id"),
              Text("Token: ${info.authenticationToken}"),
              Text("Name${info.endpointName}"),
              Text("Incoming: ${info.isIncomingConnection}"),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                child: const Text(
                  "Accept Connection",
                  style: TextStyle(color: Colors.white, fontSize: 16.0),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    endpointMap[id] = info;
                  });
                  Nearby().acceptConnection(
                    id,
                    onPayLoadRecieved: (endid, payload) async {
                      if (payload.type == PayloadType.BYTES) {
                        String str = String.fromCharCodes(payload.bytes!);

                        if (str.contains('Directory Name -')) {
                          String parentDirectoryPath =
                              "/storage/emulated/0/SyncPact";
                          String newDirectoryName = str.split('-').last;
                          tempDirectoryName = newDirectoryName;
                          Directory newDirectory = Directory(
                              '$parentDirectoryPath/$newDirectoryName');
                          if (!(await newDirectory.exists())) {
                            newDirectory.create(recursive: true);
                            print(
                                '--- --- New directory created: ${newDirectory.path}');
                          } else {
                            print(
                                '--- --- Directory already exists: ${newDirectory.path}');
                          }
                        }

                        if (str.contains("Start sync")) {
                          setState(() {
                            isBackup = false;
                          });
                          SynchronizationEngine().startMonitoring(
                              '/storage/emulated/0/SyncPact/$tempDirectoryName');
                        } else {
                          setState(() {
                            isBackup = true;
                          });
                          SynchronizationEngine().startMonitoring(
                              '/storage/emulated/0/SyncPact/$tempDirectoryName');
                        }

                        if (str.contains('Removed-') && !isBackup) {
                          String filePath = str.split('-').last;
                          final file = File(filePath);
                          await file.delete();
                          print('--- --- File deleted successfully');
                        }

                        if (str.contains(':')) {
                          // used for file payload as file payload is mapped as
                          // payloadId:filename
                          int payloadId = int.parse(str.split(':')[0]);
                          String fileName = (str.split(':')[1]);

                          if (map.containsKey(payloadId)) {
                            if (tempFileUri != null) {
                              moveFile(tempFileUri!, fileName);
                            } else {
                              showSnackbar("--- --- --- File doesn't exist");
                            }
                          } else {
                            //add to map if not already
                            map[payloadId] = fileName;
                          }
                        }
                        // showSnackbar(endid + ": " + str);
                      } else if (payload.type == PayloadType.FILE) {
                        showSnackbar("File transfer started");
                        tempFileUri = payload.uri;
                      }
                    },
                    onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
                      if (payloadTransferUpdate.status ==
                          PayloadStatus.IN_PROGRESS) {
                        print("--- --- --- Payload transfer in progress.");
                        print(payloadTransferUpdate.bytesTransferred);
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.FAILURE) {
                        print("--- --- --- Payload transfer failed.");
                        showSnackbar("FAILED to transfer file");
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.SUCCESS) {
                        print("--- --- --- Payload transfer successful.");
                        // showSnackbar("File transfer successful");

                        if (map.containsKey(payloadTransferUpdate.id)) {
                          //rename the file now
                          String name = map[payloadTransferUpdate.id]!;
                          moveFile(tempFileUri!, name);
                        } else {
                          //bytes not received till yet
                          print("--- --- --- Bytes not received till yet");
                          map[payloadTransferUpdate.id] = "";
                        }
                      }
                    },
                  );
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                child: const Text(
                  "Reject Connection",
                  style: TextStyle(color: Colors.white, fontSize: 16.0),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await Nearby().rejectConnection(id);
                  } catch (e) {
                    // showSnackbar(e);
                    print(e);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void sendPayload(String payload) async {
    for (MapEntry<String, ConnectionInfo> m in endpointMap.entries) {
      Nearby().sendBytesPayload(m.key, Uint8List.fromList(payload.codeUnits));
      print("--- --- ---Payload sent successfully. payload: $payload");
    }
  }

  void sendFile(String filePath) async {
    print("--- --- --- --- Send File: $filePath");
    for (MapEntry<String, ConnectionInfo> m in endpointMap.entries) {
      int payloadId = await Nearby().sendFilePayload(m.key, filePath);
      Nearby().sendBytesPayload(
          m.key,
          Uint8List.fromList(
              "$payloadId:${filePath.split('/').last}".codeUnits));
    }
  }

  Future<bool> moveFile(String uri, String fileName) async {
    String parentDir = "/storage/emulated/0/SyncPact";
    final b = await Nearby().copyFileAndDeleteOriginal(
        uri, '$parentDir/$tempDirectoryName/$fileName');

    // showSnackbar("Moved file:" + b.toString());

    Directory dir =
        Directory('/storage/emulated/0/SyncPact/$tempDirectoryName');
    final files = (await dir.list(recursive: true).toList())
        .map((f) => f.path)
        .toList()
        .join('\n');
    // showSnackbar(files);
    // navigateToFileListScreen();
    return b;
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
                  "Device Connecting",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.devices_other,
                size: 30,
              ),
              const SizedBox(width: 10),
              Text(
                "Username: $userName",
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Expanded(
            child: Center(
              child: AnimatedConnectionIcon(),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Number of connected devices: ${endpointMap.length}",
            style: TextStyle(fontSize: 16.0),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
