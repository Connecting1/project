import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../../game/timecapsule_game.dart';

class TimecapsulePage extends StatefulWidget {
  const TimecapsulePage({super.key});

  @override
  State<TimecapsulePage> createState() => _TimecapsulePageState();
}

class _TimecapsulePageState extends State<TimecapsulePage> {
  late final TimecapsuleGame _game;

  @override
  void initState() {
    super.initState();
    _game = TimecapsuleGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '캡슐 현황',
          style: TextStyle(
            color: Color(0xFF2E2B2A),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2E2B2A)),
        actions: [
          // Debug button — remove before release
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: '캡슐 등록 테스트',
            onPressed: () => _game.onCapsuleRegistered(),
          ),
        ],
      ),
      body: GameWidget(game: _game),
    );
  }
}
