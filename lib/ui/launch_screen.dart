import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_brand.dart';

const launchBackground = Color(0xff10282f);
const _gold = Color(0xffffd45b);
const _cream = Color(0xfffff6df);

/// Also rendered into the native launch assets, so startup has one identity.
class BeakboundLaunchScreen extends StatelessWidget {
  const BeakboundLaunchScreen({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: launchBackground,
    child: SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: FittedBox(fit: BoxFit.scaleDown, child: LaunchLockup()),
        ),
      ),
    ),
  );
}

class LaunchLockup extends StatelessWidget {
  const LaunchLockup({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${AppBrand.name}. Every letter lands.',
    image: true,
    child: const ExcludeSemantics(
      child: SizedBox(
        width: 320,
        height: 284,
        child: Column(
          children: [LaunchEmblem(), SizedBox(height: 6), LaunchWordmark()],
        ),
      ),
    ),
  );
}

/// The bird sits inside a restrained celestial flight trail, not an app tile.
class LaunchEmblem extends StatelessWidget {
  const LaunchEmblem({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 192,
    child: CustomPaint(
      painter: _FlightHalo(),
      child: Center(
        child: Container(
          width: 148,
          height: 148,
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cream, _gold, Color(0xffc77b35)],
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              AppBrand.logo,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    ),
  );
}

class LaunchWordmark extends StatelessWidget {
  const LaunchWordmark({super.key});

  @override
  Widget build(BuildContext context) => MediaQuery.withNoTextScaling(
    child: const SizedBox(
      width: 320,
      height: 80,
      child: Column(
        children: [
          Text(
            'BEAKBOUND',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 38,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              height: 1.2,
              color: _cream,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Every letter lands.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: .6,
              height: 1.2,
              color: Color(0xff9bd4cc),
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    ),
  );
}

class _FlightHalo extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xff3b7b7b).withValues(alpha: .6),
          const Color(0xff3b7b7b).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 96));
    canvas.drawCircle(center, 96, halo);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _gold.withValues(alpha: .28);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 84),
      -.5,
      math.pi * 1.35,
      false,
      ring,
    );
    for (var i = 0; i < 11; i++) {
      final a = 3.8 + i * .095;
      canvas.drawCircle(
        center + Offset(math.cos(a), math.sin(a)) * 84,
        1.1,
        Paint()..color = _gold.withValues(alpha: .25 + i * .045),
      );
    }
    for (final (position, radius) in [
      (const Offset(161, 41), 6.0),
      (const Offset(27, 144), 4.0),
      (const Offset(50, 24), 2.4),
    ]) {
      final star = Path()
        ..moveTo(position.dx, position.dy - radius)
        ..quadraticBezierTo(
          position.dx + radius * .2,
          position.dy - radius * .2,
          position.dx + radius,
          position.dy,
        )
        ..quadraticBezierTo(
          position.dx + radius * .2,
          position.dy + radius * .2,
          position.dx,
          position.dy + radius,
        )
        ..quadraticBezierTo(
          position.dx - radius * .2,
          position.dy + radius * .2,
          position.dx - radius,
          position.dy,
        )
        ..quadraticBezierTo(
          position.dx - radius * .2,
          position.dy - radius * .2,
          position.dx,
          position.dy - radius,
        );
      canvas.drawPath(star, Paint()..color = _gold);
    }
  }

  @override
  bool shouldRepaint(_FlightHalo oldDelegate) => false;
}
