import 'package:flutter/material.dart';

class ElevatedCard extends StatelessWidget {
  final String text;

  const ElevatedCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10.0,
      shadowColor: Color.fromARGB(255, 21, 21, 21),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      color: Colors.deepPurpleAccent,
      child: Padding(
        padding: EdgeInsets.all(18.0),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ),
    );
  }
}
