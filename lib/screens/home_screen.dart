import 'package:flutter/material.dart';
import 'package:mixlists_project/screens/all_mixlists_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: .spaceEvenly,
          children: [
            Text(
              "The Mixlists Project",
              style: TextStyle(
                fontSize: 48,
                fontWeight: .bold,
                color: Colors.blueGrey,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AllMixlistsScreen()),
                );
              },
              child: Text("View All Mixlists"),
            ),
          ],
        ),
      ),
    );
  }
}
