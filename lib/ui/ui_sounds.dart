import 'package:flutter/widgets.dart';

/// The cues the shop screens (Upgrades and the crew) play, from the sound
/// bank: a choice, a purchase, a bird unlocked or picked, and a key that
/// cannot be pressed yet.
abstract final class ShopCues {
  /// Looking at another socket or bird.
  static const select = 'ui_toggle';

  /// An upgrade level bought, and the last level of one.
  static const upgrade = 'streak', maxed = 'wing';

  /// A bird bought, and a bird picked to fly.
  static const birdUnlock = 'unlock', birdEquip = 'sprint_ready';

  /// A greyed key pressed before the wallet can pay.
  static const denied = 'ammo_empty';
}

/// The app owns this player so navigation never cuts off a button's short tail.
/// It also speaks the story's recorded lines over the menu music.
class UiSounds extends InheritedWidget {
  const UiSounds({
    super.key,
    required super.child,
    required this.play,
    this.speak,
    this.hush,
  });
  final void Function(String)? play;

  /// Says a recorded line over the menu music, cutting off the one before.
  final void Function(String asset)? speak;

  /// Stops the line being said.
  final VoidCallback? hush;

  static void effect(BuildContext context, [String cue = 'ui_tap']) =>
      context.getInheritedWidgetOfExactType<UiSounds>()?.play?.call(cue);

  static void say(BuildContext context, String asset) =>
      context.getInheritedWidgetOfExactType<UiSounds>()?.speak?.call(asset);

  /// The way to stop a line, looked up ahead of time so a widget can use it
  /// as it is disposed.
  static VoidCallback? hushOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<UiSounds>()?.hush;

  @override
  bool updateShouldNotify(UiSounds oldWidget) =>
      play != oldWidget.play ||
      speak != oldWidget.speak ||
      hush != oldWidget.hush;
}
