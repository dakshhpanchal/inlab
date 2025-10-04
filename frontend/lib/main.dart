import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'package:flutter/services.dart';
void main() => runApp(const InLabApp());

class InLabApp extends StatefulWidget {
  const InLabApp({super.key});

  @override
  State<InLabApp> createState() => _InLabAppState();
}

class _InLabAppState extends State<InLabApp> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _initDeepLinking();
  }

  void _initDeepLinking() {
    // Set up a method channel to handle deep links
    const platform = MethodChannel('com.example.inlab/deeplink');
    
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final String url = call.arguments;
        print("Received deep link: $url");
        
        final uri = Uri.parse(url);
        final token = uri.queryParameters['token'];
        
        if (token != null && token.isNotEmpty) {
          setState(() {
            _token = token;
          });
          print("Token received via deep link: ${token.substring(0, 20)}...");
          
          // Navigate to home screen
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
      return null;
    });
  }

  void _handleDeepLink(String url) {
    print("Handling deep link: $url");
    
    final uri = Uri.parse(url);
    final token = uri.queryParameters['token'];
    
    if (token != null && token.isNotEmpty) {
      setState(() {
        _token = token;
      });
      print("Token received: ${token.substring(0, 20)}...");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InLab',
      theme: ThemeData(primarySwatch: Colors.indigo),
      // If we have a token, go to home screen, otherwise login
      home: _token != null ? const HomeScreen() : const LoginScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}