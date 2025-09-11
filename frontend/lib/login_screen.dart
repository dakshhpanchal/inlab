import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'dart:io';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _loginWithGitHub() async {
    setState(() => _isLoading = true);

    try {
      final baseUrl =
          Platform.isAndroid ? 'http://10.0.2.2:3001' : 'http://localhost:3001';

      // Start GitHub OAuth login flow
      final result = await FlutterWebAuth2.authenticate(
        url: "$baseUrl/auth/github",
        callbackUrlScheme: "myapp",
      );

      // Extract token from redirect URL
      final token = Uri.parse(result).queryParameters['token'];
      print("Got JWT: $token");

      if (token != null) {
        // Save token securely (SharedPreferences / secure storage)
        // For now, just navigate
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        throw Exception("No token received");
      }
    } catch (e) {
      print("Login error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Complete login in GitHub...'),
                ],
              )
            : ElevatedButton(
                onPressed: _loginWithGitHub,
                child: const Text('Login with GitHub'),
              ),
      ),
    );
  }
}
