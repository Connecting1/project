import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

class RoomBackground extends Component {
  static const int _gridSize = 9;
  static const double _tileW = 32;
  static const double _tileH = 32;

  late Sprite _floorSprite;
  bool _loaded = false;

  // Grid origin (top corner of the diamond grid)
  late Vector2 _origin;

  @override
  Future<void> onLoad() async {
    try {
      final image = await Flame.images.load('tiles/floor_tile.png');
      _floorSprite = Sprite(image);
      _loaded = true;
    } catch (_) {
      // Sprite not available yet — falls back to code-drawn floor
    }
  }

  void setOrigin(Vector2 origin) {
    _origin = origin;
  }

  @override
  void render(Canvas canvas) {
    if (!_loaded) {
      _renderCodeFloor(canvas);
      return;
    }
    _renderSpriteFloor(canvas);
  }

  void _renderSpriteFloor(Canvas canvas) {
    // Isometric step vectors for a 32x32 cube tile:
    //   Moving one column right  → screen (+16, +8)
    //   Moving one row forward   → screen (−16, +8)
    // Draw back-to-front so tiles overlap correctly.
    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        final double x = _origin.x + (col - row) * 16 - _tileW / 2;
        final double y = _origin.y + (col + row) * 8;
        _floorSprite.render(
          canvas,
          position: Vector2(x, y),
          size: Vector2(_tileW, _tileH),
        );
      }
    }
  }

  void _renderCodeFloor(Canvas canvas) {
    final tilePaint = Paint()..color = const Color(0xFFD4C5A9);
    final borderPaint = Paint()
      ..color = const Color(0xFFB8A88A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        final double cx = _origin.x + (col - row) * 16;
        final double cy = _origin.y + (col + row) * 8;

        final path = Path()
          ..moveTo(cx, cy)
          ..lineTo(cx + 16, cy + 8)
          ..lineTo(cx, cy + 16)
          ..lineTo(cx - 16, cy + 8)
          ..close();

        canvas.drawPath(path, tilePaint);
        canvas.drawPath(path, borderPaint);
      }
    }
  }

  // Returns the screen-space center of a grid cell.
  Vector2 cellCenter(int col, int row) {
    return Vector2(
      _origin.x + (col - row) * 16,
      _origin.y + (col + row) * 8 + 8,
    );
  }

  // Total pixel height of the grid (top corner → bottom corner).
  double get gridHeight => (_gridSize - 1) * 8 * 2 + 16;
}
