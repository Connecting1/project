import 'dart:async';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
import 'package:flutter/animation.dart' show Curves;

class CapsuleComponent extends SpriteComponent {
  CapsuleComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2(32, 40),
          anchor: Anchor.bottomCenter,
        );

  @override
  Future<void> onLoad() async {
    try {
      final image = await Flame.images.load('capsule/south.png');
      sprite = Sprite(image);
    } catch (_) {
      sprite = Sprite(await _makePlaceholder());
    }
  }

  static Future<ui.Image> _makePlaceholder() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 32, 40),
      ui.Paint()..color = const ui.Color(0xFFA14040),
    );
    return recorder.endRecording().toImage(32, 40);
  }

  // Drop from [startY] to [target], then bounce.
  Future<void> fallTo(Vector2 target) {
    final completer = Completer<void>();
    position = Vector2(target.x, target.y - 200);
    add(MoveToEffect(
      target,
      EffectController(
        duration: 0.6,
        curve: Curves.bounceOut,
      ),
      onComplete: () => completer.complete(),
    ));
    return completer.future;
  }
}
