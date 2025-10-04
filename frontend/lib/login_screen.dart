import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

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
      final baseUrl = Platform.isAndroid ? 'http://192.168.1.8:3001' : 'http://localhost:3001';
      final authUrl = "$baseUrl/auth/github";
      
      print("Opening: $authUrl");
      
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        await launchUrl(
          Uri.parse(authUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch $authUrl');
      }
      
    } catch (e) {
      print("Error launching browser: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to open browser: $e")),
      );
    } finally {
      // Don't set loading to false here - we're waiting for the deep link
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