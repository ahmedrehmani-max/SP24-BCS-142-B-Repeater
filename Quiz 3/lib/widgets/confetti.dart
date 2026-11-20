import 'dart:math';

import 'package:flutter/material.dart';

import 'liquid_palette.dart';

/// Celebration particles for the level-complete screen.
class Confetti extends StatefulWidget {
  final int pieces;

  const Confetti({super.key, this.pieces = 70});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  late final List<_Piece> pieces = List.generate(
    widget.pieces,
    (i) => _Piece(Random(i * 31)),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(pieces, controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Piece {
  final double x;
  final double delay;
  final double speed;
  final double size;
  final double spin;
  final int color;

  _Piece(Random random)
      : x = random.nextDouble(),
        delay = random.nextDouble(),
        speed = 0.6 + random.nextDouble() * 0.8,
        size = 5 + random.nextDouble() * 7,
        spin = (random.nextDouble() - 0.5) * 8,
        color = random.nextInt(LiquidPalette.colors.length);
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double time;

  _ConfettiPainter(this.pieces, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final progress = ((time * piece.speed) + piece.delay) % 1.0;
      final y = progress * (size.height + 60) - 30;
      // A gentle horizontal sway as the piece falls.
      final x = piece.x * size.width + sin(progress * pi * 4) * 14;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * piece.spin);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.size,
          height: piece.size * 0.55,
        ),
        Paint()
          ..color = LiquidPalette.of(piece.color)
              .withValues(alpha: (1 - progress).clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.time != time;
}
