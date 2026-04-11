import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

class CapsuleItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const CapsuleItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

const List<CapsuleItem> kAvailableCapsules = [
  CapsuleItem(
    id: 'default',
    name: '기본 타임캡슐',
    icon: Icons.inventory_2_outlined,
    color: Color(0xFFA14040),
  ),
];

enum _CapsuleState {
  idle,     // 캡슐 미선택
  floating, // 공중에 떠있음
  falling,  // 낙하 중
  burying,  // 땅속으로 들어가는 중
  done,     // 완료
}

class ArScreen extends StatefulWidget {
  const ArScreen({super.key});

  @override
  State<ArScreen> createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> {
  UnityWidgetController? _unityController;
  _CapsuleState _capsuleState = _CapsuleState.idle;
  CapsuleItem _selectedCapsule = kAvailableCapsules.first;

  void _onUnityCreated(UnityWidgetController controller) {
    _unityController = controller;
  }

  // Unity → Flutter: 상태 변화 수신
  void _onUnityMessage(message) {
    if (!mounted) return;
    switch (message.toString()) {
      case 'Floating':
        setState(() => _capsuleState = _CapsuleState.floating);
        break;
      case 'Falling':
        setState(() => _capsuleState = _CapsuleState.falling);
        break;
      case 'Burying':
        setState(() => _capsuleState = _CapsuleState.burying);
        break;
      case 'BuryComplete':
        setState(() => _capsuleState = _CapsuleState.done);
        break;
    }
  }

  // Flutter → Unity: 캡슐 소환 명령
  void _spawnCapsule() {
    _unityController?.postMessage(
      'TimecapsuleManager',
      'SpawnCapsule',
      _selectedCapsule.id,
    );
    setState(() => _capsuleState = _CapsuleState.floating);
  }

  void _showCapsuleSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '캡슐 선택',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...kAvailableCapsules.map((c) => _buildCapsuleCard(c)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapsuleCard(CapsuleItem capsule) {
    final isSelected = capsule.id == _selectedCapsule.id;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        setState(() => _selectedCapsule = capsule);
        _spawnCapsule();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? capsule.color.withOpacity(0.2)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? capsule.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: capsule.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(capsule.icon, color: capsule.color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                capsule.name,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: capsule.color, size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Unity AR 뷰 (카메라 + AR + 타임캡슐 렌더링 담당)
          UnityWidget(
            onUnityCreated: _onUnityCreated,
            onUnityMessage: _onUnityMessage,
            fullscreen: false,
            useAndroidViewSurface: false,
          ),
          _buildTopBar(),
          _buildGuideText(),
          if (_capsuleState == _CapsuleState.done) _buildDoneOverlay(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideText() {
    final text = switch (_capsuleState) {
      _CapsuleState.idle => '아래 캡슐 버튼을 눌러 선택하세요.',
      _CapsuleState.floating => '드래그하여 원하는 위치로 이동 후 손을 떼세요.',
      _CapsuleState.falling => '타임캡슐이 떨어지고 있습니다...',
      _CapsuleState.burying => '땅속으로 들어가고 있습니다...',
      _CapsuleState.done => '타임캡슐이 묻혔습니다!',
    };
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 64),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton.extended(
                heroTag: 'capsule_select',
                onPressed: (_capsuleState == _CapsuleState.idle ||
                        _capsuleState == _CapsuleState.floating)
                    ? _showCapsuleSelector
                    : null,
                backgroundColor: const Color(0xFF1A1A1A).withOpacity(0.85),
                icon: Icon(_selectedCapsule.icon, color: _selectedCapsule.color),
                label: Text(
                  _selectedCapsule.name,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              if (_capsuleState == _CapsuleState.idle) ...[
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'spawn',
                  onPressed: _spawnCapsule,
                  backgroundColor: const Color(0xFFA14040),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoneOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFFA14040), size: 56),
            const SizedBox(height: 12),
            const Text(
              '타임캡슐이 묻혔습니다!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA14040),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('완료', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
