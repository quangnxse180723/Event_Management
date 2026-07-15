import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

import '../widgets/main_layout.dart';

class DisplayQRScreen extends StatelessWidget {
  final int sessionId;
  final String sessionTitle;

  const DisplayQRScreen({
    Key? key,
    required this.sessionId,
    required this.sessionTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String qrData = jsonEncode({'session_id': sessionId});

    return MainLayout(
      appBar: AppBar(
        title: const Text('Mã QR Điểm danh'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              sessionTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 280.0,
            ),
            const SizedBox(height: 24),
            const Text(
              'Đưa mã này cho sinh viên quét để điểm danh',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
