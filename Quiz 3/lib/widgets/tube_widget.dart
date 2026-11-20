import 'package:flutter/material.dart';

import '../models/tube.dart';
import 'liquid_palette.dart';

/// A transparent glass tube with its liquid layers.
///
/// [fillOverride] lets an animation draw a different number of layers than the
/// model currently holds, which is how liquid appears to drain and fill while
/// a pour is playing.
class TubeWidget extends StatelessWidget {
  final Tube tube;
  final bool selected;
  final bool highlighted;
  final List<int>? fillOverride;
  final double width;
  final double height;

  const TubeWidget({
    super.key,
    required this.tube,
    this.selected = false,
    this.highlighted = false,
    this.fillOverride,
    this.width = 56,
    this.height = 164,
  });

  @override
  Widget build(BuildContext context) {
    final layers = fillOverride ?? tube.layers;

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _TubePainter(
          layers: layers,
          capacity: tube.capacity,
          selected: selected,
          highlighted: highlighted,
          complete: tube.isSolvedStack && fillOverride == null,
        ),
      ),
    );
  }
}

class _TubePainter extends CustomPainter {
  final List<int> layers;
  final int capacity;
  final bool selected;
  final bool highlighted;
  final bool complete;

  _TubePainter({
    required this.layers,
    required this.capacity,
    required this.selected,
    required this.highlighted,
    required this.complete,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width * 0.42;
    // Rounded at the bottom, open at the top — the classic test-tube shape.
    final glass = RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );

    canvas.save();
    canvas.clipRRect(glass);

    // Glass body: a faint vertical sheen so it reads as transparent.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.05),
          ],
        ).createShader(Offset.zero & size),
    );

    _paintLiquid(canvas, size);
    canvas.restore();

    _paintGlassDetails(canvas, size, glass);
  }

  void _paintLiquid(Canvas canvas, Size size) {
    if (layers.isEmpty) return;

    // Leave a little headroom at the top so full tubes do not touch the rim.
    const topInset = 8.0;
    final usable = size.height - topInset;
    final layerHeight = usable / capacity;

    for (var i = 0; i < layers.length; i++) {
      final color = layers[i];
      final bottom = size.height - (i * layerHeight);
      final rect = Rect.fromLTRB(0, bottom - layerHeight, size.width, bottom);

      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              LiquidPalette.highlightOf(color),
              LiquidPalette.of(color),
              LiquidPalette.shadowOf(color),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(rect),
      );

      // A bright sliver down the left edge: the light catching the liquid.
      canvas.drawRect(
        Rect.fromLTWH(rect.left + 4, rect.top + 3, 4, rect.height - 6),
        Paint()..color = Colors.white.withValues(alpha: 0.22),
      );

      // Surface line on the topmost layer, plus a couple of bubbles.
      if (i == layers.length - 1) {
        canvas.drawLine(
          Offset(0, rect.top + 1),
          Offset(size.width, rect.top + 1),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35)
            ..strokeWidth = 2,
        );
        final bubble = Paint()..color = Colors.white.withValues(alpha: 0.30);
        canvas.drawCircle(
            Offset(size.width * 0.68, rect.top + rect.height * 0.35), 2.4, bubble);
        canvas.drawCircle(
            Offset(size.width * 0.34, rect.top + rect.height * 0.62), 1.6, bubble);
      }
    }
  }

  void _paintGlassDetails(Canvas canvas, Size size, RRect glass) {
    // Outline. Selected and hint-highlighted tubes get a brighter, thicker one.
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected || highlighted ? 3.2 : 2
      ..color = highlighted
          ? const Color(0xFFFFD54F)
          : selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.55);
    canvas.drawRRect(glass.deflate(1), outline);

    // A completed tube gets a soft glow ring.
    if (complete) {
      canvas.drawRRect(
        glass.deflate(1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = Colors.white.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Reflection running down the glass.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.16, 10, size.width * 0.1, size.height - 34),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.30),
    );
  }

  @override
  bool shouldRepaint(_TubePainter old) =>
      old.selected != selected ||
      old.highlighted != highlighted ||
      old.complete != complete ||
      old.capacity != capacity ||
      !_sameLayers(old.layers, layers);

  static bool _sameLayers(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
