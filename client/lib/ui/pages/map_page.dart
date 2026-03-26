import 'package:flutter/material.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2E2B2A)),
      ),
      body: const Center(
        child: Text(
          '지도 화면',
          style: TextStyle(color: Color(0xFF2E2B2A), fontSize: 16),
        ),
      ),
    );
  }
}
