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

// 캡슐 종류 데이터 모델
class CapsuleItem {
  final String id;
  final String name;
  final String assetFileName; // assets/models/ 내 파일명
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

// 사용 가능한 캡슐 목록 (나중에 여기에 추가)
const List<CapsuleItem> kAvailableCapsules = [
  CapsuleItem(
    id: 'default',
    name: '기본 타임캡슐',
    assetFileName: 'cube.glb',
    icon: Icons.inventory_2_outlined,
    color: Color(0xFFA14040),
  ),
];

class ArScreen extends StatefulWidget {
  const ArScreen({super.key});

  @override
  State<ArScreen> createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> with TickerProviderStateMixin {
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;

  final List<ARNode> _nodes = [];
  final List<ARAnchor> _anchors = [];

  bool _modelReady = false;
  bool _capsulePlaced = false;
  bool _isBurying = false;
  bool _burialDone = false;

  CapsuleItem _selectedCapsule = kAvailableCapsules.first;

  // 묻기 애니메이션 컨트롤러
  late AnimationController _buryController;
  late Animation<double> _buryAnimation;

  ARNode? _placedNode;
  ARAnchor? _placedAnchor;

  @override
  void initState() {
    super.initState();
    _buryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _buryAnimation = CurvedAnimation(
      parent: _buryController,
      curve: Curves.easeIn,
    );
    _prepareModel(_selectedCapsule);
  }

  @override
  void dispose() {
    _buryController.dispose();
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
      handlePans: true,
      handleRotation: true,
    );
    _arObjectManager!.onInitialize();
    _arSessionManager!.onPlaneOrPointTap = _onPlaneTapped;
  }

  Future<void> _onPlaneTapped(List<ARHitTestResult> hitTestResults) async {
    if (hitTestResults.isEmpty) return;
    if (!_modelReady) return;
    if (_capsulePlaced) return; // 이미 배치된 경우 무시
    if (_burialDone) return;

    final planeHit = hitTestResults.firstWhere(
      (r) => r.type == ARHitTestResultType.plane,
      orElse: () => hitTestResults.first,
    );

    final anchor = ARPlaneAnchor(transformation: planeHit.worldTransform);
    final didAddAnchor = await _arAnchorManager!.addAnchor(anchor);
    if (didAddAnchor != true) return;

    final node = ARNode(
      type: NodeType.fileSystemAppFolderGLB,
      uri: _selectedCapsule.assetFileName,
      scale: vm.Vector3(0.15, 0.15, 0.15),
      position: vm.Vector3(0.0, 0.0, 0.0),
      rotation: vm.Vector4(1.0, 0.0, 0.0, 0.0),
    );

    final didAddNode = await _arObjectManager!.addNode(node, planeAnchor: anchor);
    if (didAddNode == true) {
      _placedNode = node;
      _placedAnchor = anchor;
      _anchors.add(anchor);
      _nodes.add(node);
      if (mounted) setState(() => _capsulePlaced = true);
    }
  }

  // 묻기 실행
  Future<void> _buryTimecapsule() async {
    if (_placedNode == null || _isBurying) return;
    setState(() => _isBurying = true);

    // Y 위치를 단계적으로 내려서 땅속으로 들어가는 효과
    const steps = 10;
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;

      // 노드 제거 후 새 위치로 재추가
      await _arObjectManager!.removeNode(_placedNode!);
      final newY = -0.02 * i;
      final updatedNode = ARNode(
        type: NodeType.fileSystemAppFolderGLB,
        uri: _selectedCapsule.assetFileName,
        scale: vm.Vector3(
          0.15 * (1 - i / steps * 0.3),
          0.15 * (1 - i / steps * 0.3),
          0.15 * (1 - i / steps * 0.3),
        ),
        position: vm.Vector3(0.0, newY, 0.0),
        rotation: vm.Vector4(1.0, 0.0, 0.0, 0.0),
      );
      final added = await _arObjectManager!.addNode(updatedNode, planeAnchor: _placedAnchor as ARPlaneAnchor);
      if (added == true) _placedNode = updatedNode;
    }

    // 최종 제거
    if (_placedNode != null) {
      await _arObjectManager!.removeNode(_placedNode!);
      _placedNode = null;
    }

    if (mounted) {
      setState(() {
        _isBurying = false;
        _burialDone = true;
        _capsulePlaced = false;
      });
    }
  }

  // 다시 배치
  void _reset() {
    setState(() {
      _capsulePlaced = false;
      _burialDone = false;
      _isBurying = false;
      _placedNode = null;
      _placedAnchor = null;
    });
    _nodes.clear();
    _anchors.clear();
  }

  // 캡슐 선택 바텀시트
  void _showCapsuleSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...kAvailableCapsules.map((capsule) => _buildCapsuleCard(capsule)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCapsuleCard(CapsuleItem capsule) {
    final isSelected = capsule.id == _selectedCapsule.id;
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        if (capsule.id != _selectedCapsule.id) {
          setState(() => _selectedCapsule = capsule);
          await _prepareModel(capsule);
        }
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
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          _buildTopBar(),
          _buildGuideText(),
          if (_capsulePlaced && !_isBurying) _buildBuryButton(),
          if (_burialDone) _buildBurialDoneOverlay(),
          _buildCapsuleSelectButton(),
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
    String text;
    if (_burialDone) {
      text = '타임캡슐이 묻혔습니다!';
    } else if (_isBurying) {
      text = '묻는 중...';
    } else if (_capsulePlaced) {
      text = '캡슐을 확인하고 묻기 버튼을 누르세요.';
    } else if (!_modelReady) {
      text = '캡슐 준비 중...';
    } else {
      text = '평평한 바닥을 향해 천천히 움직여주세요.';
    }

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

  Widget _buildBuryButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _buryTimecapsule,
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text('여기에 묻기', style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA14040),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black54,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('취소', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBurialDoneOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFFA14040), size: 56),
                const SizedBox(height: 12),
                const Text(
                  '타임캡슐이 묻혔습니다!',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
        ],
      ),
    );
  }

  // 캡슐 선택 버튼 (우하단)
  Widget _buildCapsuleSelectButton() {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 50, right: 20),
          child: FloatingActionButton.extended(
            onPressed: _showCapsuleSelector,
            backgroundColor: const Color(0xFF1A1A1A).withOpacity(0.85),
            icon: Icon(
              _selectedCapsule.icon,
              color: _selectedCapsule.color,
            ),
            label: Text(
              _selectedCapsule.name,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}
