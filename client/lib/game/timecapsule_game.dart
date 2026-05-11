import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'components/room_background.dart';
import 'components/character_component.dart';
import 'components/capsule_component.dart';
import 'components/storage_component.dart';

class TimecapsuleGame extends FlameGame {
  late RoomBackground _background;
  late CharacterComponent _character;
  late StorageComponent _storage;
  bool _isAnimating = false;

  // 타일 셀 좌표 (col, row) — 7열 × 6행 그리드
  // col 증가 → 오른쪽, row 증가 → 왼쪽
  static const int _storageCol = 0;
  static const int _storageRow = 3;
  static const int _charCol    = 3;
  static const int _charRow    = 4;
  static const int _dropCol    = 3;
  static const int _dropRow    = 1;

  late Vector2 _storagePos;
  late Vector2 _charIdlePos;
  late Vector2 _dropPos;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _background = RoomBackground();
    add(_background);

    // floorCell() → 셀 앞쪽 꼭짓점 (anchor: bottomCenter 기준)
    _storagePos   = _background.floorCell(_storageCol, _storageRow, size);
    _charIdlePos  = _background.floorCell(_charCol,    _charRow,    size);
    _dropPos      = _background.floorCell(_dropCol,    _dropRow,    size);

    _storage = StorageComponent()..position = _storagePos;
    add(_storage);

    // CharacterComponent anchor = Anchor.center → y를 spriteHeight/2 올림
    _character = CharacterComponent()
      ..position = Vector2(_charIdlePos.x, _charIdlePos.y - 55);
    add(_character);
  }

  Future<void> onCapsuleRegistered() async {
    if (_isAnimating) return;
    _isAnimating = true;

    // 1. 캡슐이 위에서 낙하
    final capsule = CapsuleComponent()
      ..position = Vector2(_dropPos.x, -60);
    add(capsule);
    await capsule.fallTo(_dropPos);

    // 2. 캐릭터가 캡슐 위치로 이동
    await _character.walkTo(Vector2(_dropPos.x, _dropPos.y - 55));

    // 3. 캡슐 집어들고 보관함으로 이동
    capsule.removeFromParent();
    await _character.carryTo(Vector2(_storagePos.x, _storagePos.y - 55));

    // 4. 보관함에 저장, 원위치 복귀
    _storage.addCapsule();
    await _character.walkTo(Vector2(_charIdlePos.x, _charIdlePos.y - 55));
    _character.setIdle();

    _isAnimating = false;
  }
}
