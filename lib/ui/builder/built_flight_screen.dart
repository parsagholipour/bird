import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/builder_providers.dart';
import '../../domain/built_level.dart';
import '../../domain/game_rules.dart';
import '../components.dart';
import '../play_screen.dart';

/// Flies the built level [id] (`/play/<mode>?built=<id>`), or its
/// creator's [test] flight [from] a place on the route. The level is read
/// once, as the flight begins: saving its result never swaps the plan
/// under a flight or its retries. A level that cannot be found, or cannot
/// be flown as it stands, goes back to the builder.
class BuiltFlightScreen extends ConsumerStatefulWidget {
  const BuiltFlightScreen({
    super.key,
    required this.id,
    this.test = false,
    this.from,
  });
  final String id;
  final bool test;
  final int? from;

  @override
  ConsumerState<BuiltFlightScreen> createState() => _BuiltFlightScreenState();
}

class _BuiltFlightScreenState extends ConsumerState<BuiltFlightScreen> {
  BuiltFlight? _flight;
  bool _leaving = false;

  void _away() {
    if (_leaving) return;
    _leaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/builder');
    });
  }

  @override
  Widget build(BuildContext context) {
    final flight = _flight;
    if (flight != null) {
      return PlayScreen(
        mode: flight.plan.mode,
        course: FlightCourse.starTrail,
        built: flight,
      );
    }
    final loaded = ref.watch(builtLevelProvider(widget.id));
    switch (loaded) {
      case AsyncData(:final value):
        final from = widget.test ? widget.from : null;
        final candidate = value == null
            ? null
            : BuiltFlight(value, test: widget.test, from: from);
        // A test flight may fly a level still being built; a real one only
        // a level that can be flown as it stands.
        if (candidate == null ||
            (!widget.test && candidate.plan.problem != null)) {
          _away();
        } else {
          _flight = candidate;
          return PlayScreen(
            mode: candidate.plan.mode,
            course: FlightCourse.starTrail,
            built: candidate,
          );
        }
      case AsyncError():
        _away();
      case AsyncLoading():
        break;
    }
    return const Scaffold(body: SkyBackdrop(child: SizedBox.expand()));
  }
}
