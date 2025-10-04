import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http; // ADD THIS IMPORT
import 'dart:io';
import 'package:flutter/services.dart';

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
      final baseUrl = Platform.isAndroid ? 'http://10.0.2.2:3001' : 'http://localhost:3001';
      
      print("Starting OAuth with URL: $baseUrl/auth/github");
      print("Callback scheme: myapp");

      final result = await FlutterWebAuth2.authenticate(
        url: "$baseUrl/auth/github",
        callbackUrlScheme: "myapp",
        options: const FlutterWebAuth2Options(
          preferEphemeral: false,
        ),
      ).timeout(Duration(seconds: 60), onTimeout: () {
        throw Exception('OAuth timeout');
      });

      print("SUCCESS! Callback result: $result");
      
      // ... rest of your token handling code
      
    } on PlatformException catch (e) {
      print("PlatformException DETAILS:");
      print("Code: ${e.code}");
      print("Message: ${e.message}");
      print("Details: ${e.details}");
      
      if (e.code == 'CANCELED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login canceled - check deep link configuration')),
        );
      }
    } catch (e) {
      print("General error: $e");
    } finally {
      setState(() => _isLoading = false);
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