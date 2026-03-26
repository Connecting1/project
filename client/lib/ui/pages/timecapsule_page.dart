import 'package:flutter/material.dart';

class TimecapsulePage extends StatelessWidget {
  const TimecapsulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '캡슐 현황',
          style: TextStyle(color: Color(0xFF2E2B2A), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2E2B2A)),
      ),
      body: const Center(
        child: Text(
          '캡슐 현황 화면',
          style: TextStyle(color: Color(0xFF2E2B2A), fontSize: 16),
        ),
      ),
    );
  }
}
