import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/regions/world_backdrop.dart';
import '../game/regions/world_region.dart';

/// One region's flight scenery as a calm still frame, for a campaign map
/// stop or a postcard.
///
/// This is the only place the menus paint region scenery, so a change to the
/// backdrop's entry points only touches [paint]. The frame is the region's
/// opening composition from the flight: its sky, light, parallax bands and
/// weather, with the bands at rest and the weather frozen, exactly as a
/// Reduced Motion flight shows it.
abstract final class CampaignRegionStill {
  /// Paints [region] filling [size]: the still a campaign level in it opens
  /// on. Sizes scale with the height, like the flight, so a wider box shows
  /// more of the skyline rather than a zoom.
  static void paint(Canvas canvas, Size size, WorldRegion region) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    WorldBackdrop.still(canvas, size, region);
    canvas.restore();
  }

  /// The newest stills, kept apart by use: the map's stops in one budget,
  /// the level card's and postcard's pictures in another, so opening a card
  /// never evicts the stops around it.
  static final _mapImages = <(WorldRegion, Size, double, double), ui.Image>{};
  static final _pictures = <(WorldRegion, Size, double, double), ui.Image>{};
  static const _keepForMap = 6, _keepPictures = 3;

  /// [region] rasterised at [frame] (logical pixels) and [pixelRatio]. The
  /// backdrop is thousands of paths, so a menu draws this image instead of
  /// repainting the scenery every frame; the few newest are kept, [forMap]
  /// choosing the map's own budget. [fadeIn] feathers the left edge to
  /// transparent over that many logical pixels, so a still can melt into the
  /// one beside it.
  static ui.Image image(
    WorldRegion region,
    Size frame,
    double pixelRatio, {
    double fadeIn = 0,
    bool forMap = false,
  }) {
    // Scenery is soft; past twice the logical size nobody sees a gain.
    final ratio = pixelRatio.clamp(1.0, 2.0);
    final key = (region, frame, ratio, fadeIn);
    final images = forMap ? _mapImages : _pictures;
    final cached = images.remove(key);
    if (cached != null) return images[key] = cached;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(ratio);
    if (fadeIn > 0) canvas.saveLayer(Offset.zero & frame, Paint());
    paint(canvas, frame, region);
    if (fadeIn > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, fadeIn, frame.height),
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.linear(Offset.zero, Offset(fadeIn, 0), const [
            Color(0x00000000),
            Color(0xff000000),
          ]),
      );
      canvas.restore();
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(
      (frame.width * ratio).ceil(),
      (frame.height * ratio).ceil(),
    );
    picture.dispose();
    images[key] = image;
    final keep = forMap ? _keepForMap : _keepPictures;
    while (images.length > keep) {
      images.remove(images.keys.first)!.dispose();
    }
    return image;
  }

  /// Greys and softens a locked region toward the menu's sky, so it reads
  /// as itself but clearly out of reach, and never as night. [t] is 0 to 1.
  static ColorFilter dim(double t) {
    const r = .2126, g = .7152, b = .0722;
    final s = 1 - .72 * t, k = 1 - .34 * t;
    double m(double luma, bool diagonal) =>
        (luma * (1 - s) + (diagonal ? s : 0)) * k;
    final lift = [
      for (final v in const [.78, .88, .94]) v * 255 * .36 * t,
    ];
    return ColorFilter.matrix([
      m(r, true), m(g, false), m(b, false), 0, lift[0], //
      m(r, false), m(g, true), m(b, false), 0, lift[1], //
      m(r, false), m(g, false), m(b, true), 0, lift[2], //
      0, 0, 0, 1, 0,
    ]);
  }
}

/// A region still that fills its box. [dim] (0 to 1) greys and darkens the
/// scene for a locked stop; [crop] shifts the frame sideways by a fraction of
/// the width (for a postcard that wants a landmark in view).
class CampaignRegionView extends StatelessWidget {
  const CampaignRegionView({
    super.key,
    required this.region,
    this.dim = 0,
    this.frameSize,
    this.crop = 0,
  });
  final WorldRegion region;
  final double dim, crop;

  /// The viewport the scene is composed for; defaults to the box itself. A
  /// postcard composes at phone size and shows a window of it.
  final Size? frameSize;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _StillPainter(
        region,
        dim,
        frameSize,
        crop,
        MediaQuery.devicePixelRatioOf(context),
      ),
    ),
  );
}

class _StillPainter extends CustomPainter {
  const _StillPainter(
    this.region,
    this.dim,
    this.frameSize,
    this.crop,
    this.pixelRatio,
  );
  final WorldRegion region;
  final double dim, crop, pixelRatio;
  final Size? frameSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final frame = frameSize ?? size;
    // Whole logical pixels keep the cache small while a box resizes.
    final key = Size(frame.width.roundToDouble(), frame.height.roundToDouble());
    final scale = size.height / key.height;
    // The frame is drawn at the size it shows, so it is rasterised for that.
    final image = CampaignRegionStill.image(region, key, pixelRatio * scale);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(
        (size.width - key.width * scale) / 2 - crop * key.width * scale,
        0,
        key.width * scale,
        size.height,
      ),
      Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = dim > 0 ? CampaignRegionStill.dim(dim) : null,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StillPainter old) =>
      old.region != region ||
      old.dim != dim ||
      old.frameSize != frameSize ||
      old.crop != crop ||
      old.pixelRatio != pixelRatio;
}
