import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class RoomBackground extends Component with HasGameRef<FlameGame> {
  static const int _nCols = 7;
  static const int _nRows = 6;

  ui.Image? _floorTile;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      final sprite = await Sprite.load('tiles/floor_tile.png');
      _floorTile = sprite.image;
    } catch (_) {
      // PNG 없으면 코드 그리드로 폴백
    }
  }

  // 셀 (col, row)의 앞쪽 꼭짓점(south tip) 반환
  // anchor: Anchor.bottomCenter 기준 배치 좌표
  Vector2 floorCell(int col, int row, Vector2 s) {
    final top   = Vector2(s.x / 2,       s.y * 0.40);
    final right = Vector2(s.x * 0.86,    s.y * 0.52);
    final left  = Vector2(s.x * 0.14,    s.y * 0.52);
    final a1 = (right - top) / _nCols.toDouble();
    final a2 = (left  - top) / _nRows.toDouble();
    return top + a1 * (col + 1.0) + a2 * (row + 1.0);
  }

  @override
  void render(Canvas canvas) {
    final s = gameRef.size;
    final cx = s.x / 2;
    const offsetY = 0.0;

    final floorTop    = Offset(cx,          s.y * 0.40 + offsetY);
    final floorRight  = Offset(s.x * 0.86,  s.y * 0.52 + offsetY);
    final floorBottom = Offset(cx,          s.y * 0.64 + offsetY);
    final floorLeft   = Offset(s.x * 0.14,  s.y * 0.52 + offsetY);

    const wallHeight = 220.0;
    final floorTopUp   = Offset(floorTop.dx,   floorTop.dy   - wallHeight);
    final floorLeftUp  = Offset(floorLeft.dx,  floorLeft.dy  - wallHeight);
    final floorRightUp = Offset(floorRight.dx, floorRight.dy - wallHeight);

    _drawBackground(canvas, s);

    final leftWall = Path()
      ..moveTo(floorLeft.dx,   floorLeft.dy)
      ..lineTo(floorTop.dx,    floorTop.dy)
      ..lineTo(floorTopUp.dx,  floorTopUp.dy)
      ..lineTo(floorLeftUp.dx, floorLeftUp.dy)
      ..close();

    final rightWall = Path()
      ..moveTo(floorTop.dx,     floorTop.dy)
      ..lineTo(floorRight.dx,   floorRight.dy)
      ..lineTo(floorRightUp.dx, floorRightUp.dy)
      ..lineTo(floorTopUp.dx,   floorTopUp.dy)
      ..close();

    final floor = Path()
      ..moveTo(floorTop.dx,    floorTop.dy)
      ..lineTo(floorRight.dx,  floorRight.dy)
      ..lineTo(floorBottom.dx, floorBottom.dy)
      ..lineTo(floorLeft.dx,   floorLeft.dy)
      ..close();

    canvas.drawPath(leftWall,  Paint()..color = const Color(0xFFEDD9B4));
    canvas.drawPath(rightWall, Paint()..color = const Color(0xFFD9BC8E));
    canvas.drawPath(floor,     Paint()..color = const Color(0xFFC4A265));

    if (_floorTile != null) {
      _drawTileFloor(canvas, floorTop, floorRight, floorLeft);
    } else {
      _drawFloorGrid(canvas, floorTop, floorRight, floorBottom, floorLeft);
    }

    _drawWindow(canvas, floorTopUp, floorRightUp);
    _drawBeam(canvas, floorLeft, floorTop, floorTopUp, floorLeftUp);

    final stroke = Paint()
      ..color = const Color(0xFF6B3F25)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter;

    canvas.drawPath(leftWall,  stroke);
    canvas.drawPath(rightWall, stroke);
    canvas.drawPath(floor, Paint()
      ..color = const Color(0xFF5E341D)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke);
  }

  void _drawTileFloor(Canvas canvas, Offset top, Offset right, Offset left) {
    final tile = _floorTile!;
    const tw = 32.0;
    const th = 32.0;

    final a1x = (right.dx - top.dx) / _nCols;
    final a1y = (right.dy - top.dy) / _nCols;
    final a2x = (left.dx  - top.dx) / _nRows;
    final a2y = (left.dy  - top.dy) / _nRows;

    for (int row = 0; row < _nRows; row++) {
      for (int col = 0; col < _nCols; col++) {
        final ax = top.dx + col * a1x + row * a2x;
        final ay = top.dy + col * a1y + row * a2y;

        // PNG 픽셀 → 다이아몬드 셀 아핀 변환
        canvas.save();
        canvas.transform(Float64List.fromList([
          a1x / tw, a1y / tw, 0, 0,
          a2x / th, a2y / th, 0, 0,
          0, 0, 1, 0,
          ax, ay, 0, 1,
        ]));
        canvas.drawImage(tile, Offset.zero, Paint());
        canvas.restore();
      }
    }
  }

  void _drawBackground(Canvas canvas, Vector2 s) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s.x, s.y),
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFFFFD9A0), Color(0xFF2B1B14)],
          radius: 0.95,
        ).createShader(Rect.fromCircle(
          center: Offset(s.x / 2, s.y * 0.48),
          radius: 360,
        )),
    );
  }

  void _drawFloorGrid(Canvas canvas, Offset top, Offset right, Offset bottom, Offset left) {
    final p = Paint()
      ..color = const Color(0xFF754221).withOpacity(0.5)
      ..strokeWidth = 1.0;

    for (int i = 1; i < 7; i++) {
      final t = i / 7;
      canvas.drawLine(
        Offset(left.dx + (bottom.dx - left.dx) * t, left.dy + (bottom.dy - left.dy) * t),
        Offset(top.dx  + (right.dx  - top.dx)  * t, top.dy  + (right.dy  - top.dy)  * t),
        p,
      );
    }
    for (int i = 1; i < 6; i++) {
      final t = i / 6;
      canvas.drawLine(
        Offset(top.dx   + (left.dx   - top.dx)   * t, top.dy   + (left.dy   - top.dy)   * t),
        Offset(right.dx + (bottom.dx - right.dx) * t, right.dy + (bottom.dy - right.dy) * t),
        p,
      );
    }
  }

  void _drawWindow(Canvas canvas, Offset topUp, Offset rightUp) {
    final v = rightUp - topUp;
    final tl = Offset(topUp.dx + v.dx * 0.55, topUp.dy + v.dy * 0.55 + 65);
    final tr = Offset(tl.dx + v.dx * 0.1, tl.dy + v.dy * 0.1);
    const h = 45.0;
    final window = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(tr.dx, tr.dy + h)
      ..lineTo(tl.dx, tl.dy + h)
      ..close();
    canvas.drawPath(window, Paint()..color = const Color(0xFFFFF4D8));
    canvas.drawPath(window, Paint()
      ..color = const Color(0xFF704426)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke);
  }

  void _drawBeam(Canvas canvas, Offset floorLeft, Offset floorTop, Offset wallTopRight, Offset wallTopLeft) {
    final midLeftY  = (floorLeft.dy  + wallTopLeft.dy)  / 2;
    final midRightY = (floorTop.dy   + wallTopRight.dy) / 2;
    canvas.drawLine(
      Offset(floorLeft.dx,  midLeftY),
      Offset(floorTop.dx,   midRightY),
      Paint()
        ..color = const Color(0xFF8B5E34)
        ..strokeWidth = 4,
    );
  }

  @override
  int get priority => -1;
}
