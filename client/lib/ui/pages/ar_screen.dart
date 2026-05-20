import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

class CapsuleItem {
  final String id;
  final String name;
  final String? imagePath;
  final IconData icon;
  final Color color;

  const CapsuleItem({
    required this.id,
    required this.name,
    this.imagePath,
    required this.icon,
    required this.color,
  });
}

const List<CapsuleItem> kAvailableCapsules = [
  CapsuleItem(
    id: 'default',
    name: '기본 타임캡슐',
    imagePath: 'assets/images/capsule/base/south.png',
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
      builder: (context) => _CapsuleSelectorSheet(
        capsules: kAvailableCapsules,
        selected: _selectedCapsule,
        onSelected: (capsule) => setState(() => _selectedCapsule = capsule),
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
      _CapsuleState.floating =>
        '드래그하여 원하는 위치로 이동 후 손을 되세요.',
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
            child: Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
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
                icon: _selectedCapsule.imagePath != null
                    ? Image.asset(
                        _selectedCapsule.imagePath!,
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            Icon(_selectedCapsule.icon,
                                color: _selectedCapsule.color),
                      )
                    : Icon(_selectedCapsule.icon, color: _selectedCapsule.color),
                label: Text(_selectedCapsule.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
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
              child: const Text('완료',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapsuleSelectorSheet extends StatefulWidget {
  final List<CapsuleItem> capsules;
  final CapsuleItem selected;
  final ValueChanged<CapsuleItem> onSelected;

  const _CapsuleSelectorSheet({
    required this.capsules,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<_CapsuleSelectorSheet> createState() => _CapsuleSelectorSheetState();
}

class _CapsuleSelectorSheetState extends State<_CapsuleSelectorSheet> {
  late CapsuleItem _preview;

  @override
  void initState() {
    super.initState();
    _preview = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('캡슐 선택',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Large preview
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: _preview.imagePath != null
                    ? Image.asset(
                        _preview.imagePath!,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            Icon(_preview.icon, color: _preview.color, size: 72),
                      )
                    : Icon(_preview.icon, color: _preview.color, size: 72),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _preview.name,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            // Horizontal thumbnail strip
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.capsules.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final c = widget.capsules[i];
                  final isActive = c.id == _preview.id;
                  return GestureDetector(
                    onTap: () => setState(() => _preview = c),
                    child: Container(
                      width: 72,
                      decoration: BoxDecoration(
                        color: isActive
                            ? c.color.withOpacity(0.2)
                            : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? c.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: c.imagePath != null
                            ? Image.asset(
                                c.imagePath!,
                                height: 48,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    Icon(c.icon, color: c.color, size: 32),
                              )
                            : Icon(c.icon, color: c.color, size: 32),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSelected(_preview);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA14040),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('선택',
                    style: TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
