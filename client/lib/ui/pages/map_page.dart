import 'package:flutter/material.dart';
import 'ar_screen.dart';

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ArScreen()),
          );
        },
        backgroundColor: const Color(0xFFA14040),
        child: const Icon(Icons.view_in_ar, color: Colors.white),
      ),
    );
  }
}
