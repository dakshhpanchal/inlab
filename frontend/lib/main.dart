import 'package:flutter/material.dart';
import 'qr_scan_screen.dart';
void main() {
  runApp(const InLabApp());
}

class InLabApp extends StatelessWidget {
  const InLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InLab',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inlab Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QRScanScreen()),
                );// navigate to qr scanner
              },
              child: const Text('Scan QR'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('View Attendance'),
            ),
          ],
        ),
      ),
    );
  }
}
