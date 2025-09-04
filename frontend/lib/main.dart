import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';

void main() => runApp(const InLabApp());

class InLabApp extends StatelessWidget {
  const InLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InLab',
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
