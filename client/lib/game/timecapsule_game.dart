import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'components/room_background.dart';
import 'components/character_component.dart';
import 'components/capsule_component.dart';
import 'components/storage_component.dart';

class TimecapsuleGame extends FlameGame {
  late final RoomBackground _background;
  late final CharacterComponent _character;
  late final StorageComponent _storage;
  bool _isAnimating = false;

  // Grid cell positions (col, row) on the 9x9 grid
  static const int _charCol = 4;
  static const int _charRow = 7;
  static const int _storageCol = 1;
  static const int _storageRow = 4;
  static const int _capsuleDropCol = 4;
  static const int _capsuleDropRow = 4;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;

    // Origin = top diamond corner of the grid, centered horizontally
    final origin = Vector2(size.x / 2, 40);

    _background = RoomBackground()..setOrigin(origin);

    final charPos = _background.cellCenter(_charCol, _charRow);
    _character = CharacterComponent(position: charPos);

    final storagePos = _background.cellCenter(_storageCol, _storageRow);
    _storage = StorageComponent(position: storagePos);

    await addAll([_background, _storage, _character]);
  }

  Future<void> onCapsuleRegistered() async {
    if (_isAnimating) return;
    _isAnimating = true;

    // 1. Drop capsule from above
    final dropTarget = _background.cellCenter(_capsuleDropCol, _capsuleDropRow);
    final capsule = CapsuleComponent(position: dropTarget);
    await add(capsule);
    await capsule.fallTo(dropTarget);

    // 2. Character walks to capsule
    await _character.walkTo(dropTarget);

    // 3. Hide capsule (character picks it up), carry to storage
    capsule.removeFromParent();
    final storagePos = _background.cellCenter(_storageCol, _storageRow);
    await _character.carryTo(storagePos);

    // 4. Store and return to idle position
    _storage.addCapsule();
    final idlePos = _background.cellCenter(_charCol, _charRow);
    await _character.walkTo(idlePos);

    _isAnimating = false;
  }
}
