import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QRScanScreen extends StatefulWidget {
  final String token;
  
  const QRScanScreen({super.key, required this.token});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  MobileScannerController cameraController = MobileScannerController();
  String scannedData = "";
  bool _isTorchOn = false;
  bool _isProcessing = false;
  bool _hasScanned = false;
  CameraFacing _cameraFacing = CameraFacing.back;

  void _processQRCode(String data) async {
    if (_isProcessing || _hasScanned) return;
    
    setState(() {
      _isProcessing = true;
      scannedData = data;
      _hasScanned = true;
    });

    try {
      String labId = data.trim();
      
      final response = await http.post(
        Uri.parse('http://192.168.1.8:3001/api/attendance/toggle'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'lab_id': labId,
          'notes': 'Scanned via QR code',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _showResultDialog(responseData);
      } else {
        _showErrorDialog('Failed to process attendance: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showResultDialog(Map<String, dynamic> responseData) {
    final action = responseData['action']; // 'check_in' or 'check_out'
    final message = responseData['message'];
    final attendance = responseData['attendance'];
    final duration = responseData['duration'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              action == 'check_in' ? Icons.login : Icons.logout,
              color: action == 'check_in' ? Colors.green : Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(
              action == 'check_in' ? 'Checked In!' : 'Checked Out!',
              style: TextStyle(
                color: action == 'check_in' ? Colors.green : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lab: ${attendance['lab_id']}'),
            const SizedBox(height: 8),
            Text('Time: ${_formatTime(attendance['check_in_time'])}'),
            if (action == 'check_out') ...[
              const SizedBox(height: 8),
              Text('Check-out: ${_formatTime(attendance['check_out_time'])}'),
              const SizedBox(height: 8),
              Text('Duration: $duration', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
          if (action == 'check_in') 
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetScanner();
              },
              child: const Text('Scan Another'),
            ),
        ],
      ),
    );
  }

  String _formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
      scannedData = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            color: Colors.white,
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
              await cameraController.toggleTorch();
            },
          ),
          IconButton(
            color: Colors.white,
            icon: Icon(_cameraFacing == CameraFacing.back 
                ? Icons.camera_rear 
                : Icons.camera_front),
            onPressed: () async {
              setState(() {
                _cameraFacing = _cameraFacing == CameraFacing.back
                    ? CameraFacing.front
                    : CameraFacing.back;
              });
              await cameraController.switchCamera();
            },
          ),
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.refresh),
            onPressed: _resetScanner,
            tooltip: 'Reset Scanner',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null && !_isProcessing && !_hasScanned) {
                        _processQRCode(barcode.rawValue!);
                      }
                    }
                  },
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Processing...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                _buildScannerOverlay(),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _hasScanned 
                              ? 'Scanned: $scannedData' 
                              : 'Scan QR code to check in/out',
                          style: const TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _hasScanned 
                              ? 'Processing completed' 
                              : 'Scan the same QR again to check out',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: const Border(
          top: BorderSide(color: Colors.white, width: 2),
          bottom: BorderSide(color: Colors.white, width: 2),
          left: BorderSide(color: Colors.white, width: 2),
          right: BorderSide(color: Colors.white, width: 2),
        ),
      ),
      child: CustomPaint(
        painter: ScannerOverlayPainter(),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const borderLength = 20.0;

    canvas.drawLine(Offset.zero, const Offset(borderLength, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, borderLength), paint);
    
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - borderLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, borderLength), paint);
    
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - borderLength), paint);
    canvas.drawLine(Offset(0, size.height), Offset(borderLength, size.height), paint);
    
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - borderLength), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - borderLength, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}