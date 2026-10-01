// Shared by the New York UI tests: the New York stop as the map is handed it
// (guardians and all), synthetic New York levels shaped like the ones the
// level-data step ships (3-2 guarded by King Coo, 3-4 by the Searchlight
// Gargoyle), and a PNG capture helper. Everything here is data, so the tests
// that use it do not depend on the catalog's 3-2 and 3-4 having bosses yet.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/ui/campaign_map.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'ny_plans.dart';

/// 3-2 as New York ships it: a 30 s run-up, then King Coo.
final CampaignLevel nyWheels = CampaignLevel(
  name: 'Wheels in the Rain',
  delivery: const Delivery(
    'Umbrellas for the newsstand pigeons',
    from: 'The newsstand pigeons',
    thanks: 'Dry feathers at last. You’re a hero.',
  ),
  hint: 'Alley pigeons swoop in to grab stars. Shoot them first!',
  bossLine: 'Nobody flies till the bread cart is found!',
  plan: nyPlan(id: '3-2', boss: BossKind.kingCoo),
);

/// 3-4: a 30 s run-up, then the Searchlight Gargoyle.
final CampaignLevel nyStorm = CampaignLevel(
  name: 'Storm Warning',
  delivery: const Delivery(
    'A weather vane for the tallest tower',
    from: 'The tower keeper',
    thanks: 'It spins! It points! It’s perfect.',
  ),
  hint: 'Stay out of the light. Shoot the lamp when it opens!',
  bossLine: 'Hold still! Nobody ever stays in the light.',
  plan: nyPlan(
    id: '3-4',
    start: 90,
    seed: 3104,
    boss: BossKind.searchlightGargoyle,
  ),
);

/// New York's four nodes, then Paris closed, as the map gets them when the
/// build opens New York. [stars] holds each beaten level's rating; the first
/// level not beaten is the current one. With [guardians] off the two shields
/// are plain coins, as a build without the level data draws them. [region]
/// lends the stop another region's scenery (a light sky, for review).
List<CampaignMapStop> nyStops({
  Map<String, int> stars = const {},
  bool guardians = true,
  bool open = true,
  WorldRegion region = WorldRegion.newYork,
}) {
  const names = {
    '3-1': 'Moth Light',
    '3-2': 'Wheels in the Rain',
    '3-3': 'Steam Alley',
    '3-4': 'Storm Warning',
  };
  const bosses = {'3-2': BossKind.kingCoo, '3-4': BossKind.searchlightGargoyle};
  var reached = true;
  String? current;
  final nodes = <CampaignMapNode>[];
  for (final MapEntry(key: id, value: name) in names.entries) {
    final cleared = (stars[id] ?? 0) > 0;
    final unlocked = open && (cleared || reached);
    if (unlocked && !cleared) current ??= id;
    if (!cleared) reached = false;
    nodes.add(
      CampaignMapNode(
        id: id,
        name: name,
        state: cleared
            ? CampaignNodeState.cleared
            : unlocked
            ? CampaignNodeState.open
            : CampaignNodeState.locked,
        stars: stars[id] ?? 0,
        isCurrent: id == current,
        boss: guardians ? bosses[id] : null,
        guardian: guardians && bosses.containsKey(id),
      ),
    );
  }
  return [
    CampaignMapStop(
      region: region,
      chapter: 3,
      route: 'The Lamplight Line',
      nodes: nodes,
      locked: nodes.every((n) => n.locked),
      comingSoon: !open,
      soonNote: 'Coming soon',
    ),
    CampaignMapStop(
      region: WorldRegion.paris,
      chapter: 3,
      route: 'The Lamplight Line',
      nodes: [
        for (final (i, name) in const [
          'Crystal Rooftops',
          'After the Gale',
          'Midnight Express',
          'Dusk Empress',
        ].indexed)
          CampaignMapNode(
            id: '3-${5 + i}',
            name: name,
            boss: i == 3 ? BossKind.duskMoth : null,
          ),
      ],
      locked: true,
      comingSoon: true,
      soonNote: open ? 'Paris — coming soon' : 'Coming soon',
    ),
  ];
}

/// Writes [boundary]'s picture to `build/visual-review/ny-ui/[name].png`.
Future<void> savePng(WidgetTester tester, Finder boundary, String name) async {
  final render = tester.renderObject<RenderRepaintBoundary>(boundary);
  await tester.runAsync(() async {
    final image = await render.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/visual-review/ny-ui/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

/// The app-free harness the New York UI tests share: a themed Material app at
/// [size] with a capture boundary round [child].
Widget nyHarness(
  Widget child,
  Size size, {
  EdgeInsets padding = EdgeInsets.zero,
  double textScale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: skyTheme(),
  home: MediaQuery(
    data: MediaQueryData(
      size: size,
      padding: padding,
      viewPadding: padding,
      textScaler: TextScaler.linear(textScale),
    ),
    child: RepaintBoundary(
      key: const ValueKey('ny-capture'),
      child: Scaffold(body: child),
    ),
  ),
);

/// The Gargoyle's last scene as the story will end it: his change of heart,
/// Bill's welcome, then the caption that closes the New York stop. The story
/// step owns the real scene; this stands in for it, with the same closing
/// caption the design settles on.
const nyLastWord = StoryScene(
  id: 'last-3-4',
  region: WorldRegion.newYork,
  boss: BossKind.searchlightGargoyle,
  lines: [
    StoryLine.boss(
      'Ah, the curtain falls. …You chipped my beak. It was my best feature.',
      StoryMood.sad,
    ),
    StoryLine.courier(
      'Sorry! I couldn’t look away. And look: the tower’s new weather vane is '
      'spinning.',
    ),
    StoryLine.boss('You looked. That’s all I ever wanted.', StoryMood.happy),
    StoryLine.bill(
      'Welcome to the club, Stoneface. And yes, the pigeons may stay.',
      StoryMood.happy,
    ),
    StoryLine.caption('To be continued… Next stop: Paris, the City of Light.'),
  ],
);
