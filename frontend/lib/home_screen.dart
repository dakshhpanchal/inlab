import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'qr_scan_screen.dart';
import 'attendance_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  
  const HomeScreen({super.key, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.8:3001/auth/me'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
          isLoading = false;
        });
        print('User data: $userData');
      } else {
        print('Failed to fetch user data: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InLab Home'),
        actions: [
          if (userData != null)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('User Profile'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Username: ${userData!['username']}'),
                        Text('Name: ${userData!['name'] ?? 'N/A'}'),
                        Text('Email: ${userData!['email'] ?? 'N/A'}'),
                        if (userData!['avatar_url'] != null)
                          Image.network(userData!['avatar_url']!, height: 50),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (userData != null) ...[
                    Text('Welcome, ${userData!['name']}!',
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 20),
                  ],
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QRScanScreen(token: widget.token),
                        ),
                      );
                    },
                    child: const Text('Scan QR to Check In/Out'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AttendanceScreen(token: widget.token),
                        ),
                      );
                    },
                    child: const Text('View Attendance'),
                  ),
                ],
              ),
      ),
    );
  }
}