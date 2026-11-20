import 'dart:math';

import 'package:flutter/material.dart';

import 'liquid_palette.dart';

/// The arc of liquid falling from a tilted tube's spout into the destination.
///
/// [progress] runs 0 → 1 over the pour: the stream grows out of the spout,
/// holds, then retracts as the last of the liquid lands.
class PourStream extends StatelessWidget {
  final Offset spout;
  final Offset target;
  final int color;
  final double progress;

  const PourStream({
    super.key,
    required this.spout,
    required this.target,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _StreamPainter(
          spout: spout,
          target: target,
          color: color,
          progress: progress,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _StreamPainter extends CustomPainter {
  final Offset spout;
  final Offset target;
  final int color;
  final double progress;

  _StreamPainter({
    required this.spout,
    required this.target,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    // Fade the stream in at the start and out at the end so liquid never
    // appears to hang in the air.
    final opacity = progress < 0.18
        ? progress / 0.18
        : progress > 0.82
            ? (1 - progress) / 0.18
            : 1.0;
    if (opacity <= 0) return;

    final paint = Paint()
      ..color = LiquidPalette.of(color).withValues(alpha: opacity)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Liquid leaves the spout sideways and falls, so the control point sits
    // out past the spout rather than halfway along the line.
    final control = Offset(
      spout.dx + (target.dx - spout.dx) * 0.45,
      spout.dy - 10,
    );
    final path = Path()
      ..moveTo(spout.dx, spout.dy)
      ..quadraticBezierTo(control.dx, control.dy, target.dx, target.dy);
    canvas.drawPath(path, paint);

    // Lighter core down the middle of the stream.
    canvas.drawPath(
      path,
      Paint()
        ..color =
            LiquidPalette.highlightOf(color).withValues(alpha: opacity * 0.7)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Droplets splashing where the stream lands.
    final splash = Paint()
      ..color = LiquidPalette.highlightOf(color).withValues(alpha: opacity * 0.8);
    for (var i = 0; i < 3; i++) {
      final phase = (progress * 6 + i * 0.7) % 1.0;
      final angle = pi + (i - 1) * 0.6;
      canvas.drawCircle(
        target + Offset(cos(angle) * 12 * phase, -sin(angle) * 10 * phase),
        2.6 * (1 - phase),
        splash,
      );
    }
  }

  @override
  bool shouldRepaint(_StreamPainter old) =>
      old.progress != progress ||
      old.spout != spout ||
      old.target != target ||
      old.color != color;
}
