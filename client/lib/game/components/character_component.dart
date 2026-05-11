import 'dart:async';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
import 'package:flutter/animation.dart' show Curves;

class CharacterComponent extends SpriteAnimationComponent {
  CharacterComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2(48, 48),
          anchor: Anchor.bottomCenter,
        );

  @override
  Future<void> onLoad() async {
    try {
      final frames = await Future.wait([
        Flame.images.load('character/frame_000.png'),
        Flame.images.load('character/frame_001.png'),
        Flame.images.load('character/frame_002.png'),
        Flame.images.load('character/frame_003.png'),
      ]);
      animation = SpriteAnimation.spriteList(
        frames.map((img) => Sprite(img)).toList(),
        stepTime: 0.15,
      );
    } catch (_) {
      animation = SpriteAnimation.spriteList(
        [Sprite(await _makePlaceholder())],
        stepTime: 1,
      );
    }
  }

  static Future<ui.Image> _makePlaceholder() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 48, 48),
      ui.Paint()..color = const ui.Color(0xFFFF80AB),
    );
    final picture = recorder.endRecording();
    return picture.toImage(48, 48);
  }

  Future<void> walkTo(Vector2 target) {
    final completer = Completer<void>();
    add(MoveToEffect(
      target,
      EffectController(duration: 0.8, curve: Curves.easeInOut),
      onComplete: () => completer.complete(),
    ));
    return completer.future;
  }

  Future<void> carryTo(Vector2 target) => walkTo(target);
}
