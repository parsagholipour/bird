import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// Keyboard play. Beakbound is built for a finger; these let a keyboard
/// reach what a finger can, on a Chromebook or a tablet with a keyboard.
///
/// In flight, Space, W or Up flaps; holding D or Right charges a shot and
/// letting go throws it; A or Left sprints; Esc or P pauses and resumes.
/// Fly Together splits the same keys between its two players. Everywhere
/// else, Tab and the arrow keys move between keys, Enter or Space presses
/// one, and Esc goes back ([EscapeBack]).

/// What a key does in a solo flight.
enum FlightKey { flap, shoot, sprint, pause }

abstract final class FlightKeys {
  /// The flight action [key] stands for, if any. A key held with Ctrl, Alt
  /// or Meta is left to the system.
  static FlightKey? of(LogicalKeyboardKey key) {
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed) {
      return null;
    }
    return switch (key) {
      LogicalKeyboardKey.space ||
      LogicalKeyboardKey.keyW ||
      LogicalKeyboardKey.arrowUp => FlightKey.flap,
      LogicalKeyboardKey.keyD ||
      LogicalKeyboardKey.arrowRight => FlightKey.shoot,
      LogicalKeyboardKey.keyA ||
      LogicalKeyboardKey.arrowLeft => FlightKey.sprint,
      LogicalKeyboardKey.escape || LogicalKeyboardKey.keyP => FlightKey.pause,
      _ => null,
    };
  }

  /// Keys that press an on-screen key, such as skipping a knockout.
  static bool presses(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter;
}

/// Whether the player is on a keyboard: the last input was a key, so the
/// focus rings show. Hints then name keys instead of taps.
bool get keyboardInUse =>
    FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

/// Esc as the back key, around the app's navigator.
///
/// Esc first asks the router to go back, as the system back button does: a
/// dialog closes, and a screen that guards its back (a flight, the map, the
/// builder) decides what back means. When nothing takes it, Esc presses the
/// current screen's own back or close key, its newest [BackKeyTarget]: most
/// menus go back only by that key. On the title screen Esc does nothing,
/// so it never closes the app.
class EscapeBack extends StatefulWidget {
  const EscapeBack({super.key, required this.popRoute, required this.child});

  /// Goes back the way the system back button does; true when something
  /// took it.
  final Future<bool> Function() popRoute;
  final Widget child;

  @override
  State<EscapeBack> createState() => _EscapeBackState();
}

class _EscapeBackState extends State<EscapeBack> {
  final _targets = <_BackKeyTargetState>[];
  bool _going = false;

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent && !_going) unawaited(_back());
    return KeyEventResult.handled;
  }

  Future<void> _back() async {
    _going = true;
    try {
      if (await widget.popRoute()) return;
      for (final target in _targets.reversed) {
        if (target.pressable) {
          target.widget.onBack();
          return;
        }
      }
    } finally {
      _going = false;
    }
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: _key,
    child: widget.child,
  );
}

/// Makes [onBack] what Esc presses while [child] is on the current screen
/// and not hidden (see [EscapeBack]). The newest one wins, so a panel's
/// close key goes before its screen's back key.
class BackKeyTarget extends StatefulWidget {
  const BackKeyTarget({super.key, required this.onBack, required this.child});
  final VoidCallback onBack;
  final Widget child;

  @override
  State<BackKeyTarget> createState() => _BackKeyTargetState();
}

class _BackKeyTargetState extends State<BackKeyTarget> {
  _EscapeBackState? _scope;
  ModalRoute<Object?>? _route;
  bool _shown = true;

  bool get pressable => mounted && _shown && (_route?.isCurrent ?? true);

  @override
  void initState() {
    super.initState();
    _scope = context.findAncestorStateOfType<_EscapeBackState>();
    _scope?._targets.add(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    _shown = TickerMode.valuesOf(context).enabled;
  }

  @override
  void dispose() {
    _scope?._targets.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A sticker that takes taps (a map level, a card) made reachable from a
/// keyboard: Tab and the arrow keys bring the focus to it, Enter or Space
/// press it, and the keys' gold ring shows around it while a keyboard
/// holds the focus. A mouse over it shows the hand.
///
/// A null [onPressed] keeps it out of the keyboard's way.
class KeyTap extends StatefulWidget {
  const KeyTap({
    super.key,
    required this.onPressed,
    required this.child,
    this.shape = BoxShape.circle,
    this.radius,
    this.spread = 7,
    this.autofocus = false,
    this.onFocused,
  });
  final VoidCallback? onPressed;
  final Widget child;

  /// The ring's outline: a circle, or a rectangle with [radius] corners.
  final BoxShape shape;
  final BorderRadius? radius;

  /// How far the ring reaches past [child]'s box.
  final double spread;

  /// Takes the keyboard focus once it can be pressed, and again whenever it
  /// turns true, unless something else on its screen has the focus.
  final bool autofocus;

  /// Called when it takes the focus, such as to bring it into view.
  final VoidCallback? onFocused;

  @override
  State<KeyTap> createState() => _KeyTapState();
}

class _KeyTapState extends State<KeyTap> {
  final _focus = FocusNode(debugLabel: 'KeyTap');
  bool _ring = false;

  bool get _wantsFocus => widget.autofocus && widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    if (_wantsFocus) _autofocus();
  }

  @override
  void didUpdateWidget(KeyTap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wanted = oldWidget.autofocus && oldWidget.onPressed != null;
    if (_wantsFocus && !wanted) _autofocus();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  // Focus's own autofocus happens once in a widget's life; this one comes
  // back, such as when a card over the map closes.
  void _autofocus() => WidgetsBinding.instance.addPostFrameCallback((_) {
    final scope = _focus.enclosingScope;
    if (mounted && _wantsFocus && scope != null && scope.focusedChild == null) {
      _focus.requestFocus();
    }
  });

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return FocusableActionDetector(
      focusNode: _focus,
      enabled: enabled,
      descendantsAreFocusable: false,
      includeFocusSemantics: false,
      mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      onShowFocusHighlight: (value) => setState(() => _ring = value),
      onFocusChange: (value) {
        if (value) widget.onFocused?.call();
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: widget.shape,
          borderRadius: widget.shape == BoxShape.circle ? null : widget.radius,
          boxShadow: [
            if (_ring)
              BoxShadow(color: SkyColors.gold, spreadRadius: widget.spread),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
