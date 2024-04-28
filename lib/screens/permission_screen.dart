import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'home_screen.dart';
import 'dart:math';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool locationPermissionGranted = false;
  bool externalStoragePermissionGranted = false;
  bool bluetoothPermissionGranted = false;
  bool locationEnabled = false;
  final String userName = Random().nextInt(10000).toString();
  final Strategy strategy = Strategy.P2P_STAR;
  Map<String, ConnectionInfo> endpointMap = {};

  @override
  void initState() {
    super.initState();
    checkPermissions();
    checkLocationEnabled();
  }

  void checkPermissions() async {
    bool locationGranted = await Permission.location.isGranted;
    // bool storageGranted = await Permission.storage.isGranted;
    bool bluetoothGranted = await Permission.bluetooth.isGranted;
    bool storageGranted =
        await Permission.manageExternalStorage.request().isGranted;

    setState(() {
      locationPermissionGranted = locationGranted;
      externalStoragePermissionGranted = storageGranted;
      bluetoothPermissionGranted = bluetoothGranted;
    });
  }

  void checkLocationEnabled() async {
    // bool enabled = await Nearby().checkLocationEnabled();
    bool enabled = await Permission.location.isGranted;
    setState(() {
      locationEnabled = enabled;
    });
  }

  Future<void> navigateToFileShareScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  void openSettings() async {
    await openAppSettings();
  }

  Future<void> requestLocationPermission() async {
    // bool isLocationPermissionGranted = await Nearby().askLocationPermission();
    PermissionStatus locationPermissionStatus =
        await Permission.location.request();
    bool isLocationPermissionGranted =
        locationPermissionStatus == PermissionStatus.granted;
    if (isLocationPermissionGranted) {
      setState(() {
        locationPermissionGranted = true;
      });
    }
  }

  Future<void> requestStoragePermission() async {
    // Nearby().askExternalStoragePermission();
    // await Permission.storage.request();
    await Permission.manageExternalStorage.request();
    setState(() {
      externalStoragePermissionGranted = true;
    });
    // bool c = await  Nearby().checkExternalStoragePermission();
    // bool c = await Permission.storage.isGranted;
    bool c = await Permission.manageExternalStorage.request().isGranted;
    print(c);
  }

  Future<void> requestBluetoothPermission() async {
    // Nearby().askBluetoothPermission();
    [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan
    ].request();

    setState(() {
      bluetoothPermissionGranted = true;
    });
    // bool isBluetoothPermissionGranted = await Nearby().checkBluetoothPermission();
    bool isBluetoothPermissionGranted = !(await Future.wait([
      // Check
      Permission.bluetooth.isGranted,
      Permission.bluetoothAdvertise.isGranted,
      Permission.bluetoothConnect.isGranted,
      Permission.bluetoothScan.isGranted,
    ]))
        .any((element) => false);
    print(isBluetoothPermissionGranted);
  }

  Future<void> startAdvertising() async {
    try {
      await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: onConnectionInit,
        onConnectionResult: (id, status) {
          showSnackbar(status);
        },
        onDisconnected: (id) {
          showSnackbar(
              "Disconnected: ${endpointMap[id]!.endpointName}, id $id");
          setState(() {
            endpointMap.remove(id);
          });
        },
      );
      showSnackbar("ADVERTISING");
    } catch (exception) {
      print('button pressed!');
      showSnackbar(exception);
    }
  }

  void showSnackbar(dynamic a) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(a.toString()),
    ));
  }

  void onConnectionInit(String id, ConnectionInfo info) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return Center(
          child: Column(
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
                      // Handle payload received
                    },
                    onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
                      // Handle payload transfer updates
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
                    showSnackbar(e);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color getTextColor(bool permissionGranted) {
    return permissionGranted ? Colors.black45 : Colors.white;
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add Permissions",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            ListTile(
              title: const Text("Location Permission"),
              trailing: ElevatedButton(
                onPressed: locationPermissionGranted
                    ? null
                    : requestLocationPermission,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent),
                child: const Text(
                  "Grant Permission",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              onTap:
                  locationPermissionGranted ? null : requestLocationPermission,
            ),
            ListTile(
              title: const Text(
                "Granted",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              leading: Checkbox(
                value: locationPermissionGranted,
                onChanged: null,
              ),
            ),
            ListTile(
              title: const Text("External Storage Permission"),
              trailing: ElevatedButton(
                onPressed: externalStoragePermissionGranted
                    ? null
                    : requestStoragePermission,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent),
                child: const Text(
                  "Grant Permission",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              onTap: externalStoragePermissionGranted
                  ? null
                  : requestStoragePermission,
            ),
            ListTile(
              title: const Text(
                "Granted",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              leading: Checkbox(
                value: externalStoragePermissionGranted,
                onChanged: null,
              ),
            ),
            ListTile(
              title: const Text("Bluetooth Permission (Android 12+)"),
              trailing: ElevatedButton(
                onPressed: bluetoothPermissionGranted
                    ? null
                    : requestBluetoothPermission,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent),
                child: const Text(
                  "Grant Permission",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              onTap: bluetoothPermissionGranted
                  ? null
                  : requestBluetoothPermission,
            ),
            ListTile(
              title: const Text(
                "Granted",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              leading: Checkbox(
                value: bluetoothPermissionGranted,
                onChanged: null,
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              "Location Enabled",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            ListTile(
              title: Text(locationEnabled ? "Enabled" : "Disabled"),
              leading: Checkbox(
                value: locationEnabled,
                onChanged: null,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Align(
                alignment: FractionalOffset.bottomCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 350,
                      child: ElevatedButton(
                        onPressed: (locationPermissionGranted &&
                                // externalStoragePermissionGranted &&
                                bluetoothPermissionGranted)
                            ? navigateToFileShareScreen
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                        child: const Text(
                          "Continue",
                          style: TextStyle(color: Colors.white, fontSize: 18.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
