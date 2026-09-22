import 'package:flutter/widgets.dart';

/// The app owns this player so navigation never cuts off a button's short tail.
class UiSounds extends InheritedWidget {
  const UiSounds({super.key, required super.child, required this.play});
  final void Function(String)? play;

  static void effect(BuildContext context, [String cue = 'ui_tap']) =>
      context.getInheritedWidgetOfExactType<UiSounds>()?.play?.call(cue);

  @override
  bool updateShouldNotify(UiSounds oldWidget) => play != oldWidget.play;
}
