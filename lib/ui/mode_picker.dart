import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../game/tether_art.dart';
import '../domain/tracking.dart';
import 'components.dart';
import 'mode_picker_art.dart';
import 'theme.dart';
import 'ui_sounds.dart';

Future<PlayMode?> showModePicker(BuildContext context) => showDialog<PlayMode>(
  context: context,
  useSafeArea: false,
  barrierColor: const Color(0xff12333d).withValues(alpha: .82),
  builder: (context) {
    final padding = MediaQuery.paddingOf(context);
    // Reserve equal space on both edges so a landscape camera cutout does
    // not move the title and cards away from the physical screen center.
    final safeInsets = EdgeInsets.symmetric(
      horizontal: math.max(padding.left, padding.right),
      vertical: math.max(padding.top, padding.bottom),
    );
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Padding(
        padding: safeInsets,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Two players, one phone; the strip below explains it.
                      RoundButton(
                        key: const ValueKey('mode-coop-quick'),
                        icon: Icons.people_alt_rounded,
                        label: 'Fly Together: two players',
                        color: SkyColors.mint,
                        onPressed: () => _flyTogether(context),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                'Choose your mode',
                                textAlign: TextAlign.center,
                                style:
                                    heading(
                                      32,
                                      color: SkyColors.cream,
                                      weight: FontWeight.w700,
                                    ).copyWith(
                                      shadows: const [
                                        Shadow(
                                          color: SkyColors.ink,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Four ways to find your wings.',
                              textAlign: TextAlign.center,
                              style: bodyText(
                                13,
                                color: const Color(0xffc5e4e3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      RoundButton(
                        icon: Icons.close_rounded,
                        label: 'Close mode picker',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const modes = [
                          PlayMode.pushUp,
                          PlayMode.touch,
                          PlayMode.jump,
                          PlayMode.squat,
                        ];
                        final largeText =
                            MediaQuery.textScalerOf(context).scale(12) > 16;
                        final columns =
                            constraints.maxWidth >= 560 && !largeText
                            ? 4
                            : constraints.maxWidth >= 300
                            ? 2
                            : 1;
                        final artHeight =
                            (MediaQuery.sizeOf(context).height * .33).clamp(
                              108.0,
                              160.0,
                            );
                        return Column(
                          children: [
                            for (
                              var start = 0;
                              start < modes.length;
                              start += columns
                            )
                              Padding(
                                padding: EdgeInsets.only(
                                  top: start == 0 ? 0 : 16,
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      for (var i = 0; i < columns; i++) ...[
                                        if (i > 0) const SizedBox(width: 12),
                                        Expanded(
                                          child: _ModeCard(
                                            mode: modes[start + i],
                                            artHeight: artHeight,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: _CoopStrip(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  },
);

class _ModeCard extends StatefulWidget {
  const _ModeCard({required this.mode, required this.artHeight});
  final PlayMode mode;
  final double artHeight;

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  final states = WidgetStatesController();

  @override
  void dispose() {
    states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    final (color, description) = switch (mode) {
      PlayMode.pushUp => (SkyColors.yellow, 'Lower to dip.\nPush up to soar.'),
      PlayMode.touch => (SkyColors.mint, 'Tap to flap.\nAim & shoot.'),
      PlayMode.jump => (SkyColors.lavender, 'Jump for lift.\nGlide for stars.'),
      PlayMode.squat => (SkyColors.coral, 'Squat low.\nStand to soar.'),
    };
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return TextButton(
      key: ValueKey('mode-${mode.name}'),
      statesController: states,
      onPressed: () {
        UiSounds.effect(context);
        Navigator.pop(context, mode);
      },
      style: TextButton.styleFrom(
        foregroundColor: SkyColors.ink,
        overlayColor: Colors.transparent,
        padding: EdgeInsets.zero,
        minimumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: ValueListenableBuilder<Set<WidgetState>>(
        valueListenable: states,
        builder: (context, value, _) {
          final pressed = value.contains(WidgetState.pressed);
          final focused = value.contains(WidgetState.focused);
          final hovered = value.contains(WidgetState.hovered);
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(color, SkyColors.ink, .4),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .2),
                  offset: const Offset(0, 8),
                  blurRadius: 12,
                ),
                if (focused)
                  const BoxShadow(color: SkyColors.cream, spreadRadius: 4),
              ],
            ),
            child: AnimatedContainer(
              duration: reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(
                0,
                reducedMotion
                    ? 0
                    : pressed
                    ? 4
                    : hovered
                    ? -3
                    : 0,
                0,
              ),
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: SkyColors.cream,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: focused || hovered ? SkyColors.cream : SkyColors.ink,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: widget.artHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: ModePickerArt(mode: mode, color: color),
                          ),
                        ),
                        Positioned(
                          top: 9,
                          left: 9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: SkyColors.cream.withValues(alpha: .86),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  mode == PlayMode.touch
                                      ? Icons.touch_app_outlined
                                      : Icons.videocam_outlined,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  mode == PlayMode.touch
                                      ? 'No camera'
                                      : 'Camera',
                                  style: bodyText(10, weight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
                    child: Column(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                MediaQuery.textScalerOf(context).scale(20) *
                                2.16,
                          ),
                          child: Center(
                            child: Text(
                              mode.title,
                              textAlign: TextAlign.center,
                              style: heading(20, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: bodyText(12, color: SkyColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Two players, one phone: the co-op flight, under the four solo modes.
class _CoopStrip extends StatelessWidget {
  const _CoopStrip();

  @override
  Widget build(BuildContext context) => TextButton(
    key: const ValueKey('mode-coop'),
    onPressed: () {
      UiSounds.effect(context);
      _flyTogether(context);
    },
    style: TextButton.styleFrom(
      foregroundColor: SkyColors.ink,
      backgroundColor: SkyColors.cream,
      padding: const EdgeInsets.fromLTRB(16, 10, 20, 10),
      minimumSize: const Size(48, 56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: SkyColors.ink, width: 2),
      ),
    ),
    child: Row(
      children: [
        for (final color in TetherArt.players)
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const Icon(
              Icons.touch_app_rounded,
              size: 18,
              color: SkyColors.white,
            ),
          ),
        const SizedBox(width: 8),
        Text('Fly Together', style: heading(20, weight: FontWeight.w700)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Two players, one phone. Fly roped together, '
            'each on your own, or fight 1 v 1.',
            style: bodyText(13, color: SkyColors.muted),
          ),
        ),
        const Icon(Icons.arrow_forward_rounded),
      ],
    ),
  );
}

void _flyTogether(BuildContext context) {
  final router = GoRouter.of(context);
  Navigator.pop(context);
  router.go('/coop');
}
