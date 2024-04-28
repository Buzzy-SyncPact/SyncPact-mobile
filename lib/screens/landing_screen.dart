import 'package:flutter/material.dart';
import 'permission_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.deepPurpleAccent,
        body: SafeArea(
            child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'SyncPact',
                style: TextStyle(
                  fontSize: 30.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 50),
              Image.asset(
                'assets/landing_img.png',
                width: 300,
              ),
              const SizedBox(height: 32),
              Text(
                'Synchronize your data easily without the need of internet connectivity',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PermissionScreen()),
                    );
                  },
                  icon: const Icon(Icons.double_arrow),
                  color: Colors.deepPurple[700],
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}
