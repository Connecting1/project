import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';

class StorageComponent extends SpriteComponent with TapCallbacks {
  int _storedCount = 0;

  StorageComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2(64, 80),
          anchor: Anchor.bottomCenter,
        );

  @override
  Future<void> onLoad() async {
    try {
      final image = await Flame.images.load('storage/cabinet.png');
      sprite = Sprite(image);
    } catch (_) {
      sprite = Sprite(await _makePlaceholder());
    }
  }

  static Future<ui.Image> _makePlaceholder() async {
    final recorder = ui.PictureRecorder();
    final c = ui.Canvas(recorder);
    // Simple cabinet shape
    final brown = ui.Paint()..color = const ui.Color(0xFF8B6914);
    final dark = ui.Paint()..color = const ui.Color(0xFF5C4510);
    c.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(4, 8, 56, 68),
        const ui.Radius.circular(3),
      ),
      brown,
    );
    c.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(8, 12, 24, 28),
        const ui.Radius.circular(2),
      ),
      dark,
    );
    c.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(36, 12, 24, 28),
        const ui.Radius.circular(2),
      ),
      dark,
    );
    return recorder.endRecording().toImage(64, 80);
  }

  void addCapsule() {
    _storedCount++;
  }

  int get storedCount => _storedCount;

  @override
  void onTapDown(TapDownEvent event) {
    // TODO: show capsule list
  }
}
