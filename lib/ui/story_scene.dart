import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/progress_repository.dart' show birdNames;
import '../domain/campaign_story.dart';
import '../game/campaign_voices.dart';
import 'campaign_keepsake_art.dart' show CampaignHeadwear;
import 'story_backdrop.dart';
import 'story_cast_art.dart';
import 'story_speech.dart';
import 'story_stage.dart';
import 'story_to_be_continued.dart'; // New York: the end card
import 'theme.dart';
import 'ui_sounds.dart';

/// Plays one [StoryScene] over the campaign map: the scene's place behind,
/// the cast standing along the speech panel, and the line in the panel.
///
/// The courier stands on the left and Postmaster Bill faces it; at a lair
/// the boss looms on the right and Bill backs the courier up. Whoever is
/// talking steps up onto its name tag in a pool of light, and the others
/// fall back into the shade. A caption, which is nobody's voice, is set on
/// a dark plate when it names the place and on a sheet of airmail paper
/// when it reads a letter aloud.
///
/// A tap anywhere moves on: it finishes a line that is still being written
/// out, then goes to the next one, and [onDone] follows the last. Skip
/// calls [onDone] at once. With [reducedMotion] each line appears whole and
/// nothing slides, bobs, blinks or talks.
///
/// The line is one text (key `story-line`) that always holds the whole
/// line, with the part not yet written left clear, so the words never jump
/// between rows as they arrive. A cue (key `story-cue`) shows once the line
/// is whole and a tap will move on.
class StoryScenePlayer extends StatefulWidget {
  const StoryScenePlayer({
    super.key,
    required this.scene,
    required this.bird,
    required this.onDone,
    this.reducedMotion = false,
    this.voices = false,
  });
  final StoryScene scene;

  /// The equipped bird, which plays the courier.
  final int bird;
  final bool reducedMotion;
  final VoidCallback onDone;

  /// Whether each line is spoken in its character's recorded voice
  /// ([CampaignVoices]), through the app's [UiSounds]. A spoken line writes
  /// itself out at the pace of its voice.
  final bool voices;

  /// The name shown over [line], or null for a caption.
  static String? speakerName(StoryScene scene, StoryLine line, int bird) =>
      switch (line.speaker) {
        StorySpeaker.courier => birdNames[bird],
        StorySpeaker.postmaster => CampaignStory.postmaster,
        StorySpeaker.boss => CampaignHeadwear.name(scene.boss!),
        StorySpeaker.caption => null,
      };

  /// The colour of the name tag under [line]'s speaker: each bird's own,
  /// Bill's cap blue, a boss's stamp colour.
  static Color speakerColor(StoryScene scene, StoryLine line, int bird) =>
      switch (line.speaker) {
        StorySpeaker.courier => const [
          SkyColors.yellow,
          Color(0xffffb3b0),
          Color(0xff9be0ac),
          Color(0xffc9c1ff),
        ][bird],
        StorySpeaker.boss => CampaignHeadwear.field(scene.boss!),
        _ => const Color(0xff4583c4),
      };

  /// How big the scene is drawn: composed for a 360-high phone, it grows a
  /// little on a taller screen.
  static double scaleFor(Size size) => (size.height / 360).clamp(.85, 1.25);

  @override
  State<StoryScenePlayer> createState() => _StoryScenePlayerState();
}

class _StoryScenePlayerState extends State<StoryScenePlayer>
    with TickerProviderStateMixin {
  /// The line being said, and the one before it (-1 at the opening).
  int _index = 0, _from = -1;

  /// Writes the line out, 0 to 1.
  late final AnimationController _write = AnimationController(vsync: this);

  /// Moves the stage from the last line's staging to this one's.
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

  /// Brings the cast on.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  /// Seconds of idle life: breathing, blinks, the cue's bob.
  late final AnimationController _life = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _lifeSpan),
  );
  static const _lifeSpan = 120;
  late final Animation<double> _seconds = _life.drive(
    Tween(begin: 0, end: _lifeSpan.toDouble()),
  );

  bool _started = false;

  /// Stops the line being said; looked up ahead of time, for [dispose].
  VoidCallback? _hush;

  bool get _still =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
  StoryScene get _scene => widget.scene;
  StoryLine get _line => _scene.lines[_index];

  /// The first line somebody says: the cast comes on with it, after any
  /// caption that sets the place.
  late final int _curtain = math.max(
    0,
    _scene.lines.indexWhere((line) => line.speaker != StorySpeaker.caption),
  );

  late final List<StoryActor> _cast = [
    if (_scene.boss case final boss?)
      StoryBoss(boss, beaten: _scene.bossBeaten),
    StoryPostmaster(facingLeft: _scene.boss == null),
    StoryCourier(widget.bird),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hush = widget.voices ? UiSounds.hushOf(context) : null;
    if (!_started) {
      _started = true;
      _say();
    }
    if (_still) {
      // Nothing keeps running once animations are turned off.
      _life.stop();
      _write.value = 1;
      _turn.value = 1;
      if (_index >= _curtain) _enter.value = 1;
    } else if (!_life.isAnimating) {
      _life.repeat();
    }
  }

  @override
  void dispose() {
    // A line cut short by Skip, the back key or the last tap ends with it.
    _hush?.call();
    _write.dispose();
    _turn.dispose();
    _enter.dispose();
    _life.dispose();
    super.dispose();
  }

  /// Starts the current line: the stage turns to its speaker and the line
  /// writes itself out. A still scene shows it whole at once.
  void _say() {
    final entering = _index >= _curtain && _enter.value == 0;
    final voice = widget.voices
        ? CampaignVoices.line(_scene, _index, bird: widget.bird)
        : null;
    if (voice != null) UiSounds.say(context, voice);
    if (_still) {
      _write.value = 1;
      _turn.value = 1;
      if (entering) _enter.value = 1;
      return;
    }
    // A spoken line is written out just ahead of its voice.
    final spoken = voice == null ? null : CampaignVoices.length(voice);
    _write.duration = Duration(
      milliseconds: spoken != null
          ? (spoken.inMilliseconds * .9).round().clamp(260, 8000)
          : (_line.text.length * 26).clamp(260, 1700),
    );
    _write.forward(from: 0);
    _turn.forward(from: 0);
    if (entering) _enter.forward();
  }

  void _advance() {
    if (_write.value < 1) {
      _write.value = 1;
      return;
    }
    UiSounds.effect(context);
    if (_index + 1 >= _scene.lines.length) {
      widget.onDone();
      return;
    }
    setState(() {
      _from = _index;
      _index++;
    });
    _say();
  }

  StorySpeaker? _speakerAt(int index) =>
      index < 0 ? null : _scene.lines[index].speaker;

  static StorySpeaker _roleOf(StoryActor actor) => switch (actor) {
    StoryCourier() => StorySpeaker.courier,
    StoryPostmaster() => StorySpeaker.postmaster,
    StoryBoss() => StorySpeaker.boss,
  };

  /// The line [role] says now or said last, if any.
  StoryLine? _lastLineOf(StorySpeaker role) {
    for (var i = _index; i >= 0; i--) {
      if (_scene.lines[i].speaker == role) return _scene.lines[i];
    }
    return null;
  }

  /// The face [role] wears while it listens: it keeps a frown or a long
  /// face from its last line, and otherwise settles.
  StoryMood _restingMood(StorySpeaker role) {
    for (var i = _index; i >= 0; i--) {
      final line = _scene.lines[i];
      if (line.speaker != role) continue;
      return line.mood == StoryMood.angry || line.mood == StoryMood.sad
          ? line.mood
          : StoryMood.plain;
    }
    return StoryMood.plain;
  }

  /// The cast as it stands this frame.
  List<StoryPlacement> _placements(StoryLayout layout) {
    final still = _still;
    final line = _line;
    final turn = Curves.easeOutCubic.transform(_turn.value);
    final writing = _write.value < 1;
    final written = (line.text.length * _write.value).round();
    final seconds = still ? 0.0 : _seconds.value;
    final before = _speakerAt(_from);
    return [
      for (final (i, actor) in _cast.indexed)
        () {
          final role = _roleOf(actor);
          final talking = line.speaker == role;
          final voice = still
              ? (talking ? 1.0 : 0.0)
              : (before == role ? 1 - turn : 0.0) + (talking ? turn : 0.0);
          final blink =
              !still && (seconds + i * 1.37) % 3.9 < .13 && _enter.value == 1;
          final mouth = talking && writing && !still
              ? const [1, 2, 1, 0][(written ~/ 2) % 4]
              : 0;
          // A hop as it takes the line, a bounce with its words, and a
          // breath while it waits. Hovering bosses drift.
          final hop = talking && !still
              ? math.sin(_turn.value * math.pi) * 7
              : 0.0;
          final drift = still || actor.perched
              ? 0.0
              : math.sin(seconds * 1.7 + i) * (actor.box.height > 330 ? 1 : 3);
          final bounce = talking && writing && !still
              ? math.sin(written * .7).abs() * 2.2
              : 0.0;
          final breath = still || !actor.perched
              ? 1.0
              : 1 + math.sin(seconds * 2.3 + i * 2) * .011 + bounce * .006;
          return (
            // A boss acts its own line beyond the mood where its art has a
            // gesture for it (Neferhoo's "Return to sender!" stamp).
            actor: actor is StoryBoss
                ? actor.acting(_lastLineOf(role)?.text)
                : actor,
            x: layout.placeOf(actor),
            voice: voice.clamp(0.0, 1.0),
            presence: _index < _curtain
                ? 0.0
                : ((_enter.value * 1.3 - i * .15).clamp(0.0, 1.0)),
            face: (
              mood: talking ? line.mood : _restingMood(role),
              mouth: mouth,
              blink: blink,
            ),
            lift: hop + drift + bounce,
            squash: breath,
          );
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene, line = _line;
    final name = StoryScenePlayer.speakerName(scene, line, widget.bird);
    final last = _index + 1 >= scene.lines.length;
    final still = _still;
    final safe = MediaQuery.paddingOf(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _advance,
        const SingleActivator(LogicalKeyboardKey.space): _advance,
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, box) {
            final size = box.biggest;
            final k = StoryScenePlayer.scaleFor(size);
            final layout = StoryLayout(
              size / k,
              safe / k,
              lair: scene.boss != null,
            );
            final speaker = _cast
                .where((actor) => _roleOf(actor) == line.speaker)
                .firstOrNull;
            return Stack(
              fit: StackFit.expand,
              children: [
                StoryBackdrop(region: scene.region, floor: layout.floor * k),
                FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox.fromSize(
                    size: layout.stage,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _write,
                                  _turn,
                                  _enter,
                                  _life,
                                ]),
                                builder: (context, _) => CustomPaint(
                                  painter: StoryStagePainter(
                                    cast: _placements(layout),
                                    floor: layout.floor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Semantics(
                            button: true,
                            label: last ? 'Finish' : 'Next line',
                            onTap: _advance,
                            excludeSemantics: true,
                            child: GestureDetector(
                              key: const ValueKey('story-advance'),
                              behavior: HitTestBehavior.opaque,
                              onTap: _advance,
                            ),
                          ),
                        ),
                        Positioned.fromRect(
                          rect: layout.panel,
                          child: IgnorePointer(
                            child: _Settle(
                              key: ValueKey(_index),
                              still: still,
                              // New York: the caption that closes a chapter that
                              // is not finished ("To be continued…") wears
                              // its own end card in the panel's place.
                              child: ToBeContinued.matches(line)
                                  ? ToBeContinued(
                                      text: line.text,
                                      write: _write,
                                      step: _index + 1,
                                      of: scene.lines.length,
                                      bob: still ? null : _seconds,
                                    )
                                  : StorySpeech(
                                      text: line.text,
                                      voice: StoryVoice.of(name, line.text),
                                      label: name == null
                                          ? line.text
                                          : '$name: ${line.text}',
                                      write: _write,
                                      step: _index + 1,
                                      of: scene.lines.length,
                                      bob: still ? null : _seconds,
                                    ),
                            ),
                          ),
                        ),
                        if (name != null && speaker != null)
                          () {
                            final width = StoryNameTag.widthOf(name);
                            return Positioned(
                              left: layout.tagLeft(
                                layout.placeOf(speaker),
                                width,
                              ),
                              top: layout.floor - StoryNameTag.height / 2 - 2,
                              child: IgnorePointer(
                                child: _Settle(
                                  key: ValueKey(line.speaker),
                                  still: still,
                                  pop: true,
                                  child: StoryNameTag(
                                    name,
                                    color: StoryScenePlayer.speakerColor(
                                      scene,
                                      line,
                                      widget.bird,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }(),
                        Positioned(
                          top: layout.skipTop,
                          right: layout.skipRight,
                          child: StorySkipKey(
                            key: const ValueKey('story-skip'),
                            reducedMotion: still,
                            onPressed: widget.onDone,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Settles its child into place when it appears: the panel dips a touch
/// for each new line, and a name tag pops ([pop]) when the speaker changes.
/// With [still] it is simply there.
class _Settle extends StatelessWidget {
  const _Settle({
    super.key,
    required this.still,
    required this.child,
    this.pop = false,
  });
  final bool still, pop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (still) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: pop ? 220 : 150),
      curve: pop ? Curves.easeOutBack : Curves.easeOut,
      child: child,
      builder: (context, t, child) => pop
          ? Transform.translate(
              offset: Offset(0, (1 - t) * 9),
              child: Transform.scale(scale: .7 + .3 * t, child: child),
            )
          : Transform.translate(offset: Offset(0, (1 - t) * 4), child: child),
    );
  }
}
