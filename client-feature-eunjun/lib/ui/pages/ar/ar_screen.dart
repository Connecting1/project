import 'dart:async';
import 'dart:io';

import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class CapsuleItem {
  final String id;
  final String name;
  final String assetFileName;
  final IconData icon;
  final Color color;

  const CapsuleItem({
    required this.id,
    required this.name,
    required this.assetFileName,
    required this.icon,
    required this.color,
  });
}

const List<CapsuleItem> kAvailableCapsules = [
  CapsuleItem(
    id: 'default',
    name: '기본 타임캡슐',
    assetFileName: 'cube.glb',
    icon: Icons.inventory_2_outlined,
    color: Color(0xFFA14040),
  ),
];

enum _CapsuleState {
  idle,       // 캡슐 미선택
  floating,   // 공중에 떠있음 (드래그 가능)
  falling,    // 낙하 중
  burying,    // 땅속으로 들어가는 중
  done,       // 완료
}

class ArScreen extends StatefulWidget {
  const ArScreen({super.key});

  @override
  State<ArScreen> createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> {
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;

  bool _modelReady = false;
  _CapsuleState _capsuleState = _CapsuleState.idle;
  CapsuleItem _selectedCapsule = kAvailableCapsules.first;

  // 현재 AR에 있는 노드
  ARNode? _currentNode;
  ARAnchor? _currentAnchor;

  // 공중 떠 있는 위치 (world 좌표)
  vm.Vector3 _floatPosition = vm.Vector3(0.0, 0.0, -0.5);
  double _currentScale = 0.15;

  // 드래그 시작 위치
  Offset? _dragStartOffset;
  vm.Vector3? _dragStartPosition;

  @override
  void initState() {
    super.initState();
    _prepareModel(_selectedCapsule);
  }

  @override
  void dispose() {
    _arSessionManager?.dispose();
    super.dispose();
  }

  Future<void> _prepareModel(CapsuleItem capsule) async {
    setState(() => _modelReady = false);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${capsule.assetFileName}');
      final data = await rootBundle.load('assets/models/${capsule.assetFileName}');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      if (mounted) setState(() => _modelReady = true);
    } catch (e) {
      debugPrint('Model prepare error: $e');
    }
  }

  void _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    _arSessionManager = arSessionManager;
    _arObjectManager = arObjectManager;
    _arAnchorManager = arAnchorManager;

    _arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handlePans: false, // 직접 드래그 처리
      handleRotation: false,
    );
    _arObjectManager!.onInitialize();
  }

  // 콴로드로 떠 있는 노드 수정
  Future<void> _updateFloatingNode(vm.Vector3 position, {double? scale}) async {
    if (_arObjectManager == null) return;
    final s = scale ?? _currentScale;

    // 기존 노드 제거
    if (_currentNode != null) {
      await _arObjectManager!.removeNode(_currentNode!);
      _currentNode = null;
    }
    if (_currentAnchor != null) {
      await _arAnchorManager!.removeAnchor(_currentAnchor!);
      _currentAnchor = null;
    }

    // 새 위치에 열린 앱컨커로 배치
    // 위치를 Matrix4 중 translation으로 설정
    final matrix = vm.Matrix4.translation(position);
    final anchor = ARPlaneAnchor(transformation: matrix);
    final added = await _arAnchorManager!.addAnchor(anchor);
    if (added != true) return;

    final node = ARNode(
      type: NodeType.fileSystemAppFolderGLB,
      uri: _selectedCapsule.assetFileName,
      scale: vm.Vector3(s, s, s),
      position: vm.Vector3(0.0, 0.0, 0.0),
      rotation: vm.Vector4(1.0, 0.0, 0.0, 0.0),
    );
    final nodeAdded = await _arObjectManager!.addNode(node, planeAnchor: anchor);
    if (nodeAdded == true) {
      _currentNode = node;
      _currentAnchor = anchor;
      _floatPosition = position;
    }
  }

  // 캡슐 선택 시 공중에 소환
  Future<void> _spawnCapsule() async {
    if (!_modelReady) return;
    // 커메라 앞 0.5m 공중
    final spawnPos = vm.Vector3(0.0, 0.0, -0.5);
    await _updateFloatingNode(spawnPos);
    if (mounted) setState(() => _capsuleState = _CapsuleState.floating);
  }

  // 드래그 시작
  void _onDragStart(DragStartDetails details) {
    if (_capsuleState != _CapsuleState.floating) return;
    _dragStartOffset = details.globalPosition;
    _dragStartPosition = _floatPosition.clone();
  }

  // 드래그 업데이트
  void _onDragUpdate(DragUpdateDetails details) {
    if (_capsuleState != _CapsuleState.floating) return;
    if (_dragStartOffset == null || _dragStartPosition == null) return;

    final dx = (details.globalPosition.dx - _dragStartOffset!.dx) * 0.002;
    final dy = (details.globalPosition.dy - _dragStartOffset!.dy) * 0.002;

    final newPos = vm.Vector3(
      _dragStartPosition!.x + dx,
      _dragStartPosition!.y - dy, // 위로 드래그하면 위로
      _dragStartPosition!.z,
    );
    _updateFloatingNode(newPos);
  }

  // 드래그 종료 → 낙하 애니메이션
  void _onDragEnd(DragEndDetails details) {
    if (_capsuleState != _CapsuleState.floating) return;
    setState(() => _capsuleState = _CapsuleState.falling);
    _startFallAnimation();
  }

  // 낙하 애니메이션: Y를 단계적으로 낮춤
  Future<void> _startFallAnimation() async {
    const steps = 12;
    const fallDistance = 0.5; // 0.5m 낙하
    final startY = _floatPosition.y;

    for (int i = 1; i <= steps; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 40));
      final newY = startY - (fallDistance * i / steps);
      await _updateFloatingNode(
        vm.Vector3(_floatPosition.x, newY, _floatPosition.z),
      );
    }

    // 바닥 도달 → 매복 애니메이션
    if (mounted) setState(() => _capsuleState = _CapsuleState.burying);
    await _startBuryAnimation();
  }

  // 매복 애니메이션: Y 낮추면서 스케일 감소
  Future<void> _startBuryAnimation() async {
    const steps = 10;
    final startY = _floatPosition.y;

    for (int i = 1; i <= steps; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 60));
      final newY = startY - 0.02 * i;
      final newScale = _currentScale * (1 - i / steps * 0.8);
      await _updateFloatingNode(
        vm.Vector3(_floatPosition.x, newY, _floatPosition.z),
        scale: newScale,
      );
    }

    // 완전히 제거
    if (_currentNode != null) {
      await _arObjectManager!.removeNode(_currentNode!);
      _currentNode = null;
    }
    if (_currentAnchor != null) {
      await _arAnchorManager!.removeAnchor(_currentAnchor!);
      _currentAnchor = null;
    }

    if (mounted) setState(() => _capsuleState = _CapsuleState.done);
  }

  void _reset() {
    if (_currentNode != null) _arObjectManager?.removeNode(_currentNode!);
    if (_currentAnchor != null) _arAnchorManager?.removeAnchor(_currentAnchor!);
    _currentNode = null;
    _currentAnchor = null;
    setState(() {
      _capsuleState = _CapsuleState.idle;
      _currentScale = 0.15;
    });
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
              const Text('캡슐 선택',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...kAvailableCapsules.map((capsule) => _buildCapsuleCard(capsule)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapsuleCard(CapsuleItem capsule) {
    final isSelected = capsule.id == _selectedCapsule.id;
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        setState(() => _selectedCapsule = capsule);
        _reset();
        await _prepareModel(capsule);
        await _spawnCapsule();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? capsule.color.withOpacity(0.2) : const Color(0xFF2A2A2A),
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
            if (isSelected) Icon(Icons.check_circle, color: capsule.color, size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onPanStart: _onDragStart,
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ARView(
              onARViewCreated: _onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            ),
            _buildTopBar(),
            _buildGuideText(),
            if (_capsuleState == _CapsuleState.done) _buildDoneOverlay(),
            _buildBottomBar(),
          ],
        ),
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
      _CapsuleState.idle => _modelReady ? '아래 캡슐 버튼을 눠러 선택하세요.' : '캡슐 준비 중...',
      _CapsuleState.floating => '드래그하여 원하는 위치로 이동 후 손을 되세요.',
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
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
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
              // 캡슐 선택 버튼
              FloatingActionButton.extended(
                heroTag: 'capsule_select',
                onPressed: (_capsuleState == _CapsuleState.idle ||
                        _capsuleState == _CapsuleState.floating)
                    ? _showCapsuleSelector
                    : null,
                backgroundColor: const Color(0xFF1A1A1A).withOpacity(0.85),
                icon: Icon(_selectedCapsule.icon, color: _selectedCapsule.color),
                label: Text(_selectedCapsule.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
              if (_capsuleState == _CapsuleState.idle && _modelReady) ...
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
            const Icon(Icons.check_circle, color: Color(0xFFA14040), size: 56),
            const SizedBox(height: 12),
            const Text('타임캡슐이 묻혔습니다!',
                style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA14040),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('완료', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
