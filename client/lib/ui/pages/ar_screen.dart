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
    name: '\uae30\ubcf8 \ud0c0\uc784\ucea1\uc290',
    icon: Icons.inventory_2_outlined,
    color: Color(0xFFA14040),
  ),
];

enum _CapsuleState { idle, floating, falling, burying, done }

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

  void _onUnityMessage(UnityWidgetController controller, String message) {
    if (!mounted) return;
    switch (message) {
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

  void _spawnCapsule() {
    _unityController?.postMessage(
        'TimecapsuleManager', 'SpawnCapsule', _selectedCapsule.id);
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
              const Text('\ucf61\uc290 \uc120\ud0dd',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
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
              child: Text(capsule.name,
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
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
          UnityWidget(
            onUnityCreated: _onUnityCreated,
            onUnityMessage: _onUnityMessage,
            fullscreen: false,
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
      _CapsuleState.idle => '\uc544\ub798 \ucf61\uc290 \ubc84\ud2bc\uc744 \ub220\ub7ec \uc120\ud0dd\ud558\uc138\uc694.',
      _CapsuleState.floating =>
        '\ub4dc\ub798\uadf8\ud558\uc5ec \uc6d0\ud558\ub294 \uc704\uce58\ub85c \uc774\ub3d9 \ud6c4 \uc190\uc744 \ub418\uc138\uc694.',
      _CapsuleState.falling => '\ud0c0\uc784\ucf61\uc290\uc774 \ub5a8\uc5b4\uc9c0\uace0 \uc788\uc2b5\ub2c8\ub2e4...',
      _CapsuleState.burying => '\ub545\uc18d\uc73c\ub85c \ub4e4\uc5b4\uac00\uace0 \uc788\uc2b5\ub2c8\ub2e4...',
      _CapsuleState.done => '\ud0c0\uc784\ucf61\uc290\uc774 \ubb3b\ud600\uc2b5\ub2c8\ub2e4!',
    };
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 64),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(text,
                style:
                    const TextStyle(color: Colors.white, fontSize: 13)),
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
                backgroundColor:
                    const Color(0xFF1A1A1A).withOpacity(0.85),
                icon: Icon(_selectedCapsule.icon,
                    color: _selectedCapsule.color),
                label: Text(_selectedCapsule.name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13)),
              ),
              if (_capsuleState == _CapsuleState.idle) ...
                [
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
            const Icon(Icons.check_circle,
                color: Color(0xFFA14040), size: 56),
            const SizedBox(height: 12),
            const Text(
              '\ud0c0\uc784\ucf61\uc290\uc774 \ubb3b\ud600\uc2b5\ub2c8\ub2e4!',
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
              child: const Text('\uc644\ub8cc',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
