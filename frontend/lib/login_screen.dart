import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // This is for the 'json' decoder


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _waitingForAuth = false;

  Future<void> _loginWithGitHub() async {
    setState(() {
      _isLoading = true;
      _waitingForAuth = true;
    });

    try {
      final baseUrl = Platform.isAndroid ? 'http://10.0.2.2:3001' : 'http://localhost:3001';
      final authorizationUrl = '$baseUrl/auth/github';
      
      // Open the GitHub login page in the browser
      if (await canLaunchUrl(Uri.parse(authorizationUrl))) {
        await launchUrl(Uri.parse(authorizationUrl));
        
        // Start polling to check if user is authenticated
        _startAuthPolling();
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        _isLoading = false;
        _waitingForAuth = false;
      });
    }
  }

  void _startAuthPolling() {
    print('Starting auth polling...');
    Future.delayed(Duration(seconds: 2), () async {
      if (!context.mounted || !_waitingForAuth) {
        print('Polling stopped');
        return;
      }
      
      try {
        print('Checking auth status...');
        final baseUrl = Platform.isAndroid ? 'http://10.0.2.2:3001' : 'http://localhost:3001';
        
        // Try to get a token first
        final tokenResponse = await http.get(
          Uri.parse('$baseUrl/auth/token'),
          headers: {'Accept': 'application/json'},
        );
        
        if (tokenResponse.statusCode == 200) {
          final tokenData = json.decode(tokenResponse.body);
          final token = tokenData['token'];
          
          // Store the token for future requests
          // You might want to use shared_preferences for this
          print('Got token: $token');
          
          // Verify the token
          final verifyResponse = await http.get(
            Uri.parse('$baseUrl/auth/verify-token?token=$token'),
            headers: {'Accept': 'application/json'},
          );
          
          if (verifyResponse.statusCode == 200) {
            final user = json.decode(verifyResponse.body);
            print('User authenticated: ${user['username']}');
            
            // Navigate to home screen
            Navigator.pushReplacementNamed(context, '/home');
            return;
          }
        }
        
        // If we get here, keep polling
        print('Not authenticated yet, continuing polling...');
        _startAuthPolling();
      } catch (e) {
        print('Polling error: $e');
        // Keep polling even if there's an error
        _startAuthPolling();
      }
    });
  }

  @override
  void dispose() {
    _waitingForAuth = false; // Stop polling when screen is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Complete login in your browser...'),
                  SizedBox(height: 10),
                  Text('Then return to this app', style: TextStyle(fontSize: 12)),
                ],
              )
            : ElevatedButton(
                onPressed: _isLoading ? null : _loginWithGitHub,
                child: const Text('Login with GitHub'),
              ),
      ),
    );
  }
}