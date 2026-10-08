import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../domain/built_code.dart';
import '../../domain/built_reach.dart';
import '../../domain/campaign_story.dart' show StoryMood;
import '../../domain/game_rules.dart';
import '../../domain/tracking.dart';
import '../../game/star_art.dart';
import '../../l10n/l10n.dart';
import '../../l10n/text/builder_text.dart';
import '../campaign_chrome.dart' show MapGlyph, MapKey;
import '../campaign_region_still.dart';
import '../control_glyphs.dart';
import '../fit_text.dart';
import '../match_hud.dart' show MatchPlate, matchInkEdge;
import '../story_boss_art.dart';
import '../theme.dart';
import '../ui_sounds.dart';

/// The Level Builder's shared pieces: the sticker keys of its toolbars, its
/// toasts and sheets, a level's facts as the shelf and the editor tell them,
/// and the small pictures (region stills, boss portraits) both show.

// ---------------------------------------------------------------------------
// Modes.

/// The control a built level of [mode] is flown with.
FlyControl builtControl(PlayMode mode) => switch (mode) {
  PlayMode.pushUp => FlyControl.pushUp,
  PlayMode.squat => FlyControl.squat,
  PlayMode.jump => FlyControl.jump,
  PlayMode.touch => FlyControl.tap,
};

/// A short name for [mode] on a chip: "Tap & Fly", "Push-ups", in [l]'s
/// language (the app's, [L10n.strings], when none is given).
String builtModeName(PlayMode mode, [AppLocalizations? l]) =>
    (l ?? L10n.strings).builtModeShort(mode);

/// The color a built level of [mode] wears: the mini games' own, and the
/// sky's blue for Tap & Fly.
Color builtModeColor(PlayMode mode) => switch (mode) {
  PlayMode.pushUp => SkyColors.yellow,
  PlayMode.squat => SkyColors.coral,
  PlayMode.jump => SkyColors.lavender,
  PlayMode.touch => SkyColors.skyDeep,
};

/// The play route's mode segment for [mode] (ignored for built levels, but
/// kept readable).
String builtRouteMode(PlayMode mode) => switch (mode) {
  PlayMode.pushUp => 'push-up', // l10n-ignore: route path
  PlayMode.squat => 'squat', // l10n-ignore: route path
  PlayMode.jump => 'jump', // l10n-ignore: route path
  PlayMode.touch => 'touch', // l10n-ignore: route path
};

/// Flies the built level [plan] for real, or as its creator's [test] flight
/// [from] a place on the route.
void flyBuilt(
  BuildContext context,
  BuiltPlan plan, {
  bool test = false,
  int? from,
}) {
  final query = [
    'built=${plan.id}',
    if (test) 'test=1',
    if (test && from != null) 'from=$from',
  ].join('&');
  context.go('/play/${builtRouteMode(plan.mode)}?$query');
}

/// A boss finale's name, in [l]'s language ([L10n.strings] by default):
/// the shared `l.bossName`.
String bossName(BossKind kind, [AppLocalizations? l]) =>
    (l ?? L10n.strings).bossName(kind);

/// The bosses a built level may end with.
final finaleBosses = [
  for (final kind in BossKind.values)
    if (kind.index < BossKind.endlessCycle) kind,
];

// ---------------------------------------------------------------------------
// A level's facts.

/// "42 s" or "1 min 05 s": how long the level takes to its line, in [l]'s
/// language ([L10n.strings] by default).
String builtLength(BuiltPlan plan, [AppLocalizations? l]) =>
    (l ?? L10n.strings).builtLength(BuiltReach.seconds(plan).round());

/// "12 push-ups", "1 squat", or null for a level flown without them, in
/// [l]'s language ([L10n.strings] by default).
String? builtReps(BuiltPlan plan, [AppLocalizations? l]) {
  final reps = BuiltReach.reps(plan);
  if (reps == null) return null;
  return (l ?? L10n.strings).builtReps(plan.mode, reps);
}

/// A fresh name for a new level of [mode], not one of [taken], in [l]'s
/// language ([L10n.strings] by default). Once saved it is the player's own
/// name, never translated again.
String newLevelName(
  PlayMode mode,
  Iterable<String> taken, [
  AppLocalizations? l,
]) {
  final words = l ?? L10n.strings;
  // A translation that runs long still leaves room for a number.
  final base = _fit(words.builtNewLevelName(mode), BuiltPlan.maxName - 3);
  final names = taken.toSet();
  if (!names.contains(base)) return base;
  for (var n = 2; ; n++) {
    var head = base;
    var name = words.builderNewLevelNumbered(head, n);
    while (name.length > BuiltPlan.maxName && head.isNotEmpty) {
      head = _fit(head, head.length - (name.length - BuiltPlan.maxName));
      name = words.builderNewLevelNumbered(head, n);
    }
    if (!names.contains(name)) return name;
  }
}

/// [text] cut (between characters) to at most [room] code units.
String _fit(String text, int room) {
  if (text.length <= room) return text;
  var out = '';
  for (final c in text.characters) {
    if (out.length + c.length > room) break;
    out += c;
  }
  return out.trimRight();
}

/// [name] with a suffix such as " remix", cut to fit [BuiltPlan.maxName]
/// (the fallback name in [l]'s language, [L10n.strings] by default).
String suffixedName(String name, String suffix, [AppLocalizations? l]) {
  final room = BuiltPlan.maxName - suffix.length;
  final head = _fit(name, room);
  final result = '${head.trimRight()}$suffix';
  return BuiltPlan.validName(result)
      ? result
      : '${(l ?? L10n.strings).builderFallbackName}$suffix';
}

/// The line the share key copies, in [l]'s language: a sentence a friend
/// can read with the level's own name (never translated), ending with the
/// share code ([BuiltCode.message] is its English twin).
String shareMessage(
  BuiltPlan plan, {
  required bool cleared,
  AppLocalizations? l,
}) {
  final words = l ?? L10n.strings;
  return words.builderShareMessage(
    words.playerText(plan.name),
    words.playModeName(plan.mode),
    words.playerText(BuiltCode.encode(plan, cleared: cleared)),
  );
}

/// Copies [plan]'s share code to the clipboard, in [l]'s language
/// ([L10n.strings] by default).
Future<void> copyShareCode(
  BuiltPlan plan, {
  required bool cleared,
  AppLocalizations? l,
}) => Clipboard.setData(
  ClipboardData(
    text: shareMessage(plan, cleared: cleared, l: l),
  ),
);

// ---------------------------------------------------------------------------
// Keys.

/// A sticker key of the builder's toolbars and cards: the flight HUD's
/// ink-outlined plate with an [icon] or [art] and an optional [label].
/// Pressing sinks the face into its lip (with Reduced Motion the face shades
/// instead).
///
/// A [muted] key looks greyed but still answers a press with [onMuted]
/// (and the "not yet" cue), so it can say why it is not ready.
class BuilderKey extends StatefulWidget {
  const BuilderKey({
    super.key,
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.art,
    this.label,
    this.color = SkyColors.cream,
    this.selected = false,
    this.muted = false,
    this.onMuted,
    this.width,
    this.height = MapKey.size,
    this.sound = 'ui_tap',
    this.labelSize = 15,
    this.vertical = false,
    this.gap = 7,
  });

  /// What a screen reader says, and the tooltip of a key without a label.
  final String tooltip;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? art;
  final String? label;
  final Color color;
  final bool selected, muted, vertical;
  final VoidCallback? onMuted;
  final double? width;
  final double height, labelSize;

  /// Room between the picture and the label.
  final double gap;
  final String sound;

  @override
  State<BuilderKey> createState() => _BuilderKeyState();
}

class _BuilderKeyState extends State<BuilderKey> {
  bool pressed = false, focused = false;

  bool get enabled =>
      widget.onPressed != null && (!widget.muted || widget.onMuted != null);

  void _press() {
    if (widget.muted) {
      UiSounds.effect(context, ShopCues.denied);
      widget.onMuted?.call();
      return;
    }
    UiSounds.effect(context, widget.sound);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final ring =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final face = widget.selected ? SkyColors.yellow : widget.color;
    final label = widget.label;
    final inset = label == null
        ? 0.0
        : widget.vertical || widget.width != null && widget.width! < 90
        ? 4.0
        : 12.0;
    final glyph =
        widget.art ??
        (widget.icon == null
            ? null
            : Icon(widget.icon, size: 22, color: SkyColors.ink));
    final text = label == null
        ? null
        : Text(
            label,
            maxLines: 1,
            style: bodyText(
              widget.labelSize,
              weight: FontWeight.w900,
            ).copyWith(height: 1.05),
          );
    final content = widget.vertical
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ?glyph,
              if (text != null) ...[const SizedBox(height: 2), text],
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ?glyph,
              if (glyph != null && text != null) SizedBox(width: widget.gap),
              ?text,
            ],
          );
    Widget key = Semantics(
      button: true,
      enabled: enabled && !widget.muted,
      selected: widget.selected,
      label: widget.tooltip,
      excludeSemantics: true,
      onTap: enabled ? _press : null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTap: enabled ? _press : null,
          onFocusChange: (value) => setState(() => focused = value),
          onHighlightChanged: (value) => setState(() => pressed = value),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.height),
              boxShadow: [
                if (ring)
                  const BoxShadow(color: SkyColors.gold, spreadRadius: 6),
              ],
            ),
            child: Opacity(
              opacity: widget.muted || widget.onPressed == null ? .5 : 1,
              child: Transform.translate(
                offset: Offset(0, pressed && !still ? 3 : 0),
                child: MatchPlate(
                  color: pressed && still
                      ? Color.lerp(face, SkyColors.ink, .12)!
                      : face,
                  radius: math.min(widget.height / 2, 18),
                  padding: EdgeInsets.symmetric(horizontal: inset),
                  child: SizedBox(
                    width: widget.width == null
                        ? (label == null ? widget.height : null)
                        : widget.width! - inset * 2,
                    height: widget.height,
                    child: Center(
                      child: FittedBox(fit: BoxFit.scaleDown, child: content),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (label == null) key = Tooltip(message: widget.tooltip, child: key);
    return key;
  }
}

/// A row of small keys that pick one of [values], such as a level's pace.
class BuilderChoice<T> extends StatelessWidget {
  const BuilderChoice({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.enabled,
    this.onDisabled,
    this.height = MapKey.size,
    this.spacing = 6,
    this.labelSize = 14,
  });
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  /// Values that cannot be picked now; pressing one calls [onDisabled].
  final bool Function(T)? enabled;
  final ValueChanged<T>? onDisabled;
  final double height, spacing, labelSize;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (i, value) in values.indexed) ...[
        if (i > 0) SizedBox(width: spacing),
        Expanded(
          child: BuilderKey(
            key: ValueKey('choice-$value'),
            tooltip: label(value),
            label: label(value),
            labelSize: labelSize,
            height: height,
            selected: value == selected,
            muted: !(enabled?.call(value) ?? true),
            onMuted: onDisabled == null ? null : () => onDisabled!(value),
            sound: 'ui_toggle',
            onPressed: () => onSelected(value),
          ),
        ),
      ],
    ],
  );
}

/// A value between a − and a + key.
class BuilderStepper extends StatelessWidget {
  const BuilderStepper({
    super.key,
    required this.name,
    required this.value,
    required this.onLess,
    required this.onMore,
    this.lessIcon = Icons.remove_rounded,
    this.moreIcon = Icons.add_rounded,
    this.lead,
    this.label,
  });

  /// What is stepped, for the keys' names: "two-star mark" makes
  /// `two-star mark-less`.
  final String name;

  /// What is stepped, as a screen reader says it ([name] when null).
  final String? label;
  final String value;
  final VoidCallback? onLess, onMore;
  final IconData lessIcon, moreIcon;

  /// A picture before the value, such as the stars of a star mark.
  final Widget? lead;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final spoken = label ?? name;
    return Row(
      children: [
        BuilderKey(
          key: ValueKey('$name-less'),
          tooltip: l.builderLessSemantics(spoken),
          icon: lessIcon,
          sound: 'ui_toggle',
          onPressed: onLess,
        ),
        Expanded(
          child: Semantics(
            label: l.builderValueSemantics(spoken, value),
            excludeSemantics: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (lead != null) ...[lead!, const SizedBox(width: 4)],
                  Text(value, style: heading(18, weight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
        BuilderKey(
          key: ValueKey('$name-more'),
          tooltip: l.builderMoreSemantics(spoken),
          icon: moreIcon,
          sound: 'ui_toggle',
          onPressed: onMore,
        ),
      ],
    );
  }
}

/// A small caption over a group of controls: "OPENING".
class BuilderCaption extends StatelessWidget {
  const BuilderCaption(this.text, {super.key, this.trailing});
  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 2, bottom: 4),
    child: Row(
      children: [
        Text(
          L10n.upper(text),
          style: bodyText(
            11,
            color: SkyColors.muted,
            weight: FontWeight.w900,
          ).copyWith(letterSpacing: 1.1, height: 1),
        ),
        const SizedBox(width: 8),
        // A long note shrinks to the room left rather than past it.
        if (trailing != null)
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FitText(
                trailing!,
                style: bodyText(
                  11,
                  color: SkyColors.muted,
                  weight: FontWeight.w800,
                ).copyWith(height: 1),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Level stars as the shelf shows them: [earned] of [of], gold on ink.
class BuilderStars extends StatelessWidget {
  const BuilderStars({
    super.key,
    required this.earned,
    this.of = 3,
    this.size = 16,
  });
  final int earned, of;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.builderStarsSemantics(earned, of),
    excludeSemantics: true,
    child: CustomPaint(
      size: Size(size * (of + .2), size),
      painter: _StarsPainter(earned, of),
    ),
  );
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter(this.earned, this.of);
  final int earned, of;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    for (var i = 0; i < of; i++) {
      final c = Offset(r + i * size.height * 1.1, r);
      if (i < earned) {
        StarArt.mini(canvas, c, r, outline: r * .16);
      } else {
        StarArt.mini(canvas, c, r * .92, opacity: .28, outline: r * .12);
      }
    }
  }

  @override
  bool shouldRepaint(_StarsPainter oldDelegate) =>
      oldDelegate.earned != earned || oldDelegate.of != of;
}

/// A sticker tag on a card: "Cleared", "Needs work".
class BuilderBadge extends StatelessWidget {
  const BuilderBadge(
    this.label, {
    super.key,
    required this.icon,
    required this.color,
    this.foreground = SkyColors.ink,
  });
  final String label;
  final IconData icon;
  final Color color, foreground;

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    padding: const EdgeInsets.fromLTRB(5, 0, 8, 0),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: SkyColors.ink, width: 2),
      boxShadow: [
        BoxShadow(
          color: SkyColors.ink.withValues(alpha: .25),
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: foreground),
        const SizedBox(width: 3),
        Text(
          label,
          style: bodyText(
            11,
            color: foreground,
            weight: FontWeight.w900,
          ).copyWith(height: 1),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Pictures.

/// A region's flight scenery in a rounded, ink-outlined frame.
class RegionThumb extends StatelessWidget {
  const RegionThumb({
    super.key,
    required this.region,
    this.radius = 14,
    this.outline = 2.5,
  });
  final WorldRegion region;
  final double radius, outline;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: SkyColors.ink, width: outline),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius - outline),
      child: CampaignRegionView(region: region),
    ),
  );
}

/// A boss as it stands in a story scene, fitted to its box, facing left.
class BossPortrait extends StatelessWidget {
  const BossPortrait(this.kind, {super.key, this.size = const Size(64, 64)});
  final BossKind kind;
  final Size size;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: size,
    child: CustomPaint(painter: BossPortraitPainter(kind)),
  );
}

/// Paints [kind]'s story figure fitted to the canvas size.
class BossPortraitPainter extends CustomPainter {
  const BossPortraitPainter(this.kind);
  final BossKind kind;

  static final _pictures = <BossKind, ui.Picture>{};

  /// Paints [kind] fitted inside [box].
  static void paintIn(Canvas canvas, Rect box, BossKind kind) {
    final reach = StoryBossArt.portrait(kind).reach;
    final scale = math.min(box.width / reach.width, box.height / reach.height);
    final picture = _pictures.putIfAbsent(kind, () {
      final recorder = ui.PictureRecorder();
      StoryBossArt.paint(Canvas(recorder), kind, StoryMood.plain);
      return recorder.endRecording();
    });
    canvas.save();
    canvas.translate(box.center.dx, box.center.dy);
    canvas.scale(scale);
    canvas.translate(-reach.center.dx, -reach.center.dy);
    canvas.drawPicture(picture);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) =>
      paintIn(canvas, Offset.zero & size, kind);

  @override
  bool shouldRepaint(BossPortraitPainter oldDelegate) =>
      oldDelegate.kind != kind;
}

// ---------------------------------------------------------------------------
// Toasts.

/// Holds the builder screens' toasts: a short sticker line over the bottom
/// of the canvas that fades after a moment. Place it inside the
/// [SceneLayout]; [BuilderToast.show] finds it.
class BuilderToastHost extends StatefulWidget {
  const BuilderToastHost({super.key, required this.child, this.bottom = 26});
  final Widget child;

  /// How far above the canvas's bottom edge a toast sits.
  final double bottom;

  @override
  State<BuilderToastHost> createState() => BuilderToastHostState();
}

class BuilderToastHostState extends State<BuilderToastHost> {
  String? _text;
  IconData _icon = Icons.check_circle_rounded;
  Color _color = SkyColors.mint;
  Timer? _timer;
  bool _shown = false;

  void show(String text, {IconData? icon, Color? color}) {
    _timer?.cancel();
    setState(() {
      _text = text;
      _icon = icon ?? Icons.check_circle_rounded;
      _color = color ?? SkyColors.mint;
      _shown = true;
    });
    SemanticsService.sendAnnouncement(
      View.of(context),
      text,
      Directionality.of(context),
    );
    _timer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _shown = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final text = _text;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (text != null)
          Positioned(
            left: 120,
            right: 120,
            bottom: widget.bottom,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _shown ? 1 : 0,
                duration: still
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                // With Reduced Motion the fade ends inside the build that
                // hid it, so the toast is put away after that frame.
                onEnd: () => WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_shown && mounted) setState(() => _text = null);
                }),
                child: Center(
                  child: MatchPlate(
                    key: const ValueKey('builder-toast'),
                    color: SkyColors.cream,
                    padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _color,
                            shape: BoxShape.circle,
                            border: Border.all(color: SkyColors.ink, width: 2),
                          ),
                          child: Icon(_icon, size: 17, color: SkyColors.ink),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            text,
                            style: bodyText(15, weight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

abstract final class BuilderToast {
  /// Shows [text] on the nearest [BuilderToastHost].
  static void show(
    BuildContext context,
    String text, {
    IconData? icon,
    Color? color,
  }) => context.findAncestorStateOfType<BuilderToastHostState>()?.show(
    text,
    icon: icon,
    color: color,
  );

  /// A line about something that is not ready yet.
  static void warn(BuildContext context, String text) => show(
    context,
    text,
    icon: Icons.priority_high_rounded,
    color: SkyColors.yellow,
  );
}

// ---------------------------------------------------------------------------
// Sheets.

/// Opens [builder] over the screen on the [SceneLayout] canvas, on a dimmed
/// and softened sky, as the Mini games picker opens.
Future<T?> showBuilderSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? label,
}) {
  final still = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: label ?? context.l10n.commonClose,
    barrierColor: const Color(0xff12333d).withValues(alpha: .78),
    transitionDuration: still
        ? Duration.zero
        : const Duration(milliseconds: 200),
    pageBuilder: (context, _, _) => BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Material(
        type: MaterialType.transparency,
        child: _SceneSheet(child: Builder(builder: builder)),
      ),
    ),
    transitionBuilder: (context, animation, _, child) => still
        ? child
        : FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween(begin: .97, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          ),
  );
}

/// A sheet's canvas: the screen's 1000 × 450 [SceneLayout] with its own
/// toasts. A tap on its empty sky closes it, as a tap on the dimmed bars
/// does.
class _SceneSheet extends StatelessWidget {
  const _SceneSheet({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => builderTextScale(
    SafeArea(
      child: LayoutBuilder(
        builder: (context, c) => Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 1000,
              height: 450,
              child: BuilderToastHost(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ExcludeSemantics(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The builder's screens are drawn on a fixed canvas, so very large system
/// text is held to a size their plates and keys were drawn for.
Widget builderTextScale(Widget child) => Builder(
  builder: (context) =>
      MediaQuery.withClampedTextScaling(maxScaleFactor: 1.2, child: child),
);

/// The title row of a builder sheet: a cream heading with an ink drop and a
/// round close key.
class BuilderSheetTitle extends StatelessWidget {
  const BuilderSheetTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.closeLabel,
    this.trailing,
  });
  final String title;
  final String? subtitle;

  /// A back key before the title, for a sheet's second step.
  final VoidCallback? onBack;

  /// The close key's spoken name ("Close" when null).
  final String? closeLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      children: [
        if (onBack != null)
          MapKey(
            glyph: MapGlyph.back,
            label: l.builderBackSemantics,
            onPressed: onBack!,
          )
        else
          const SizedBox(width: MapKey.size),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              Semantics(
                header: true,
                child: FitText(
                  title,
                  textAlign: TextAlign.center,
                  style: heading(
                    30,
                    color: SkyColors.cream,
                    weight: FontWeight.w700,
                  ).copyWith(shadows: matchInkEdge(1.4)),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                FitText(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: bodyText(14, color: const Color(0xffd3ecea)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        ?trailing,
        if (trailing != null) const SizedBox(width: 10),
        MapKey(
          glyph: MapGlyph.close,
          label: closeLabel ?? l.commonClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// A question with two answers on a sheet: "Delete this level?".
Future<bool> confirmBuilder(
  BuildContext context, {
  required String title,
  required String message,
  required String yes,
  String? no,
  IconData icon = Icons.delete_rounded,
  Color color = SkyColors.coral,
}) async {
  final keep = no ?? context.l10n.builderKeepIt;
  final answer = await showBuilderSheet<bool>(
    context,
    builder: (context) => Center(
      child: SizedBox(
        width: 520,
        child: MatchPlate(
          radius: 26,
          padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: SkyColors.ink, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: SkyColors.ink, offset: Offset(0, 3)),
                  ],
                ),
                child: Icon(icon, size: 30, color: SkyColors.ink),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: heading(24, weight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: bodyText(15, color: SkyColors.muted),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: BuilderKey(
                      key: const ValueKey('confirm-no'),
                      tooltip: keep,
                      label: keep,
                      height: 52,
                      sound: 'ui_back',
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: BuilderKey(
                      key: const ValueKey('confirm-yes'),
                      tooltip: yes,
                      label: yes,
                      icon: icon,
                      color: color,
                      height: 52,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return answer ?? false;
}
