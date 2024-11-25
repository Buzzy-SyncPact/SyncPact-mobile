import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'dart:io';

const rootDirectoryPath = "/storage/emulated/0/SyncPact";

class ConnectionDiscoveringScreen extends StatefulWidget {
  final _ConnectionDiscoveringScreenState state =
      _ConnectionDiscoveringScreenState();
  String directory_name;
  List<FileSystemEntity> files;

  @override
  _ConnectionDiscoveringScreenState createState() => state;

  ConnectionDiscoveringScreen({
    super.key,
    required this.directory_name,
    required this.files,
  });

  void sendPayload(String fileName) {
    state.sendPayload(fileName);
  }

  void sendFile(String filePath) {
    state.sendFile(filePath);
  }
}

class _ConnectionDiscoveringScreenState
    extends State<ConnectionDiscoveringScreen> {
  final String userName = Random().nextInt(10000).toString();
  final Strategy strategy = Strategy.P2P_STAR;
  static Map<String, ConnectionInfo> endpointMap = {};
  Set<String> discoveredEndpoints = {};
  bool isBackup = true;

  String? tempFileUri; //reference to the file currently being transferred
  Map<int, String> map = {}; //store filename mapped to corresponding payloadId

  @override
  void initState() {
    super.initState();
    startDiscovery();
  }

  Future<void> startDiscovery() async {
    try {
      bool startDiscovery = await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          if (!discoveredEndpoints.contains(id)) {
            discoveredEndpoints.add(id);
            // show dialog automatically to request connection
            showDialog(
              context: context,
              builder: (builder) {
                return AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text("Id: $id"),
                      SizedBox(
                        height: 10,
                      ),
                      Text("Name: $name"),
                      SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                        child: const Text(
                          "Request Connection",
                          style: TextStyle(color: Colors.white, fontSize: 16.0),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Nearby().requestConnection(
                            userName,
                            id,
                            onConnectionInitiated: (id, info) {
                              onConnectionInit(id, info);
                            },
                            onConnectionResult: (id, status) {},
                            onDisconnected: (id) {
                              setState(() {
                                endpointMap.remove(id);
                              });
                              showSnackbar("Device Disconnected");
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
        onEndpointLost: (id) {
          showSnackbar("Device Disconnected");
        },
      );
      showSnackbar("DISCOVERING Devices");
    } catch (e) {
      print(e);
    }
  }

  Future<void> stopDiscovery() async {
    await Nearby().stopDiscovery();
  }

  Future<bool> moveFile(String uri, String fileName) async {
    String parentDir = "/storage/emulated/0/SyncPact";
    final b = await Nearby().copyFileAndDeleteOriginal(
        uri, '$parentDir/${widget.directory_name}/$fileName');

    Directory dir =
        Directory('/storage/emulated/0/SyncPact/${widget.directory_name}');
    final files = (await dir.list(recursive: true).toList())
        .map((f) => f.path)
        .toList()
        .join('\n');
    return b;
  }

  Future<void> sendAllFiles() async {
    print("--- --- --- Start sending all files");
    for (var file in widget.files) {
      print("--- --- --- Start sending ${file.path}");
      // Sending files using sendFilePayload
      for (MapEntry<String, ConnectionInfo> m in endpointMap.entries) {
        int payloadId = await Nearby().sendFilePayload(m.key, file.path);
        Nearby().sendBytesPayload(
            m.key,
            Uint8List.fromList(
                "$payloadId:${file.path.split('/').last}".codeUnits));
      }
    }
    showSnackbar("Backup Success.");
    print("--- --- --- Files sending Completed");
  }

  void sendFile(String filePath) async {
    print("--- --- --- --- Send File: $filePath");
    // Sending file using sendFilePayload
    for (MapEntry<String, ConnectionInfo> m in endpointMap.entries) {
      int payloadId = await Nearby().sendFilePayload(m.key, filePath);
      Nearby().sendBytesPayload(
          m.key,
          Uint8List.fromList(
              "$payloadId:${filePath.split('/').last}".codeUnits));
    }
  }

  void sendPayload(String payload) async {
    for (MapEntry<String, ConnectionInfo> m in endpointMap.entries) {
      Nearby().sendBytesPayload(m.key, Uint8List.fromList(payload.codeUnits));
    }
  }

  void sync() async {
    for (var file in widget.files) {
      print("--- --- ---${file.path.split('/').last}");
      String payload = file.path.split('/').last;
      sendPayload(payload);
    }
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
              Text("Id: $id"),
              SizedBox(
                height: 10,
              ),
              Text("Name: ${info.endpointName}"),
              SizedBox(
                height: 10,
              ),
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
                        // showSnackbar(endid + ": " + str);
                        if (str.contains('Removed-')) {
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
                              showSnackbar("File doesn't exist");
                            }
                          } else {
                            //add to map if not already
                            map[payloadId] = fileName;
                          }
                        }
                      } else if (payload.type == PayloadType.FILE) {
                        showSnackbar("File transfer started");
                        tempFileUri = payload.uri;
                      }
                    },
                    onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
                      if (payloadTransferUpdate.status ==
                          PayloadStatus.IN_PROGRESS) {
                        print(payloadTransferUpdate.bytesTransferred);
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.FAILURE) {
                        print("failed");
                        showSnackbar("FAILED to transfer file");
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.SUCCESS) {
                        if (map.containsKey(payloadTransferUpdate.id)) {
                          //rename the file now
                          String name = map[payloadTransferUpdate.id]!;
                          moveFile(tempFileUri!, name);
                        } else {
                          //bytes not received till yet
                          map[payloadTransferUpdate.id] = "";
                        }
                      }
                    },
                  );
                  sendPayload("Directory Name -${widget.directory_name}");
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
                  "Connection Discover",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
          Expanded(
            child: ListView.builder(
              itemCount: endpointMap.length,
              itemBuilder: (context, index) {
                final String id = endpointMap.keys.elementAt(index);
                final ConnectionInfo info = endpointMap[id]!;

                return ListTile(
                  title: Text(info.endpointName),
                  subtitle: Text("ID: $id"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isBackup = true;
                          });
                          await sendAllFiles();
                          isBackup
                              ? sendPayload("Start Backup")
                              : sendPayload("Start Sync");
                        },
                        child: const Text("Start Backup"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isBackup = false;
                          });
                          // sync();
                          await sendAllFiles();
                          isBackup
                              ? sendPayload("Start Backup")
                              : sendPayload("Start Sync");
                        },
                        child: const Text("Sync"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Text(
              "Number of connected devices: ${endpointMap.length}",
              style: TextStyle(
                fontSize: 18,
                color: Color.fromARGB(255, 45, 7, 54),
              ),
            ),
          ),
          SizedBox(
            height: 16.0,
          )
        ],
      ),
    );
  }
}
