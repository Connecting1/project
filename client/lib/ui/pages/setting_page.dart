import 'package:flutter/material.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '설정',
          style: TextStyle(color: Color(0xFF2E2B2A), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2E2B2A)),
      ),
      body: const Center(
        child: Text(
          '설정 화면',
          style: TextStyle(color: Color(0xFF2E2B2A), fontSize: 16),
        ),
      ),
    );
  }
}
