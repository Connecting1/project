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
  bool _modelReady = false;

  static const String _modelFileName = 'cube.glb';

  @override
  void initState() {
    super.initState();
    _prepareModel();
  }

  // ar_flutter_plugin의 fileSystemAppFolderGLB는 내부적으로
  // context.getFilesDir() + "/app_flutter/" + uri 경로를 사용함
  // path_provider의 getApplicationDocumentsDirectory()가 바로 그 경로
  Future<void> _prepareModel() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      debugPrint('app_flutter dir: ${dir.path}');

      final file = File('${dir.path}/$_modelFileName');
      debugPrint('model path: ${file.path}');
      debugPrint('model exists: ${file.existsSync()}');

      if (!file.existsSync()) {
        debugPrint('Copying model from assets...');
        final data = await rootBundle.load('assets/models/$_modelFileName');
        final bytes = data.buffer.asUint8List();
        await file.writeAsBytes(bytes, flush: true);
        debugPrint('Model copied, size: ${bytes.length} bytes');
      } else {
        debugPrint('Model already exists, size: ${file.lengthSync()} bytes');
      }

      if (mounted) {
        setState(() {
          _modelReady = true;
        });
      }
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
    if (!_modelReady) {
      debugPrint('Model not ready yet');
      return;
    }

    final planeHit = hitTestResults.firstWhere(
      (r) => r.type == ARHitTestResultType.plane,
      orElse: () => hitTestResults.first,
    );

    final anchor = ARPlaneAnchor(transformation: planeHit.worldTransform);
    final didAddAnchor = await _arAnchorManager!.addAnchor(anchor);
    if (didAddAnchor != true) return;
    _anchors.add(anchor);

    debugPrint('Placing node with uri: $_modelFileName');
    final node = ARNode(
      type: NodeType.fileSystemAppFolderGLB,
      uri: _modelFileName,
      scale: vm.Vector3(0.15, 0.15, 0.15),
      position: vm.Vector3(0.0, 0.0, 0.0),
      rotation: vm.Vector4(1.0, 0.0, 0.0, 0.0),
    );

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
                  ? '바닥을 감지했습니다. 탭하면 큐브를 놓습니다.'
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
