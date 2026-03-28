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
import 'package:vector_math/vector_math_64.dart' as vm;

class ArScreen extends StatefulWidget {
  const ArScreen({super.key});

  @override
  State<ArScreen> createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> {
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;

  final List<ARNode> _nodes = [];
  final List<ARAnchor> _anchors = [];

  bool _planeDetected = false;

  // 테스트용: ar_flutter_plugin 공식 예제에서 사용하는 웹 GLB
  static const String _testModelUrl =
      'https://github.com/KhronosGroup/glTF-Sample-Models/raw/main/2.0/Duck/glTF-Binary/Duck.glb';

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

    final planeHit = hitTestResults.firstWhere(
      (r) => r.type == ARHitTestResultType.plane,
      orElse: () => hitTestResults.first,
    );

    final anchor = ARPlaneAnchor(transformation: planeHit.worldTransform);
    final didAddAnchor = await _arAnchorManager!.addAnchor(anchor);
    if (didAddAnchor != true) return;
    _anchors.add(anchor);

    // webGLB 테스트: 인터넷 GLB 로드
    final node = ARNode(
      type: NodeType.webGLB,
      uri: _testModelUrl,
      scale: vm.Vector3(0.2, 0.2, 0.2),
      position: vm.Vector3(0.0, 0.0, 0.0),
      rotation: vm.Vector4(1.0, 0.0, 0.0, 0.0),
    );

    debugPrint('Adding webGLB node: $_testModelUrl');
    final didAddNode = await _arObjectManager!.addNode(node, planeAnchor: anchor);
    debugPrint('addNode result: $didAddNode');
    if (didAddNode == true) {
      _nodes.add(node);
      if (mounted) {
        setState(() {
          _planeDetected = true;
        });
      }
    }
  }

  Future<void> _clearAll() async {
    for (final node in _nodes) {
      await _arObjectManager!.removeNode(node);
    }
    for (final anchor in _anchors) {
      await _arAnchorManager!.removeAnchor(anchor);
    }
    _nodes.clear();
    _anchors.clear();
    if (mounted) {
      setState(() {
        _planeDetected = false;
      });
    }
  }

  @override
  void dispose() {
    _arSessionManager?.dispose();
    super.dispose();
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
          if (_planeDetected) _buildClearButton(),
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
              _planeDetected
                  ? '바닥을 감지했습니다. 탭하면 오리 모델을 놓습니다.'
                  : '평평한 바닥을 향해 천천히 움직여주세요.',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: ElevatedButton.icon(
          onPressed: _clearAll,
          icon: const Icon(Icons.delete_outline),
          label: const Text('전체 지우기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black54,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    );
  }
}
