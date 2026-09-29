import 'package:flutter/material.dart';
import '../domain/replay_highlights.dart';
import 'theme.dart';

Future<ReplayHighlight?> showReplayHighlights(
  BuildContext context,
  List<ReplayHighlight> moments,
) => showModalBottomSheet<ReplayHighlight>(
  context: context,
  backgroundColor: SkyColors.cream,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 640),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .88,
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Flight highlights', style: heading(26))),
              IconButton(
                tooltip: 'Close highlights',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: SkyColors.ink),
              ),
            ],
          ),
          Text(
            'Pick a moment. Watch from just before it happened.',
            style: bodyText(13, color: SkyColors.muted),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: moments.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: SkyColors.sky),
              itemBuilder: (context, index) {
                final moment = moments[index];
                final seconds = (moment.atMs / 1000).floor();
                final time =
                    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
                return ListTile(
                  key: ValueKey('replay-highlight-$index'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3,
                  ),
                  leading: SizedBox(
                    width: 82,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            time,
                            style: bodyText(12, weight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(switch (moment.kind) {
                          ReplayMomentKind.start =>
                            Icons.flight_takeoff_rounded,
                          ReplayMomentKind.finish => Icons.flag_rounded,
                          ReplayMomentKind.magnet => Icons.auto_awesome_rounded,
                          ReplayMomentKind.streak => Icons.star_rounded,
                          ReplayMomentKind.starTrio =>
                            Icons.auto_awesome_rounded,
                          ReplayMomentKind.shield => Icons.shield_rounded,
                          ReplayMomentKind.perfect => Icons.adjust_rounded,
                          ReplayMomentKind.milestone =>
                            Icons.emoji_events_rounded,
                          ReplayMomentKind.rush => Icons.bolt_rounded,
                          ReplayMomentKind.gale => Icons.air_rounded,
                        }, color: SkyColors.teal),
                      ],
                    ),
                  ),
                  title: Text(moment.title, style: heading(18)),
                  subtitle: Text(
                    moment.detail,
                    style: bodyText(12, color: SkyColors.muted),
                  ),
                  trailing: const Icon(
                    Icons.play_circle_fill_rounded,
                    color: SkyColors.coralDeep,
                  ),
                  onTap: () => Navigator.pop(context, moment),
                );
              },
            ),
          ),
        ],
      ),
    ),
  ),
);
