import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // TODO: add GitHub login later
            Navigator.pushReplacementNamed(context, '/home'); // for now just navigate
          },
          child: const Text('Login with GitHub'),
        ),
      ),
    );
  }
}
