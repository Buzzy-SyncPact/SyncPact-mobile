import 'package:flutter/material.dart';

class ElevatedOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String text;

  const ElevatedOptionCard(
      {required this.icon, required this.text, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 10.0,
        // shadowColor: Colors.black.withOpacity(0.0),
        shadowColor: Color.fromARGB(255, 21, 21, 21),
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        color: Color.fromARGB(255, 255, 255, 255),
        child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              children: <Widget>[
                Expanded(
                    flex: 1,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(icon, size: 80, color: Colors.white),
                    )),
                SizedBox(width: 20.0),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 21, 21, 21),
                        ),
                        textAlign: TextAlign.start,
                      ),
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 17.0,
                          color: Color.fromARGB(255, 21, 21, 21),
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                ),
              ],
            )));
  }
}
