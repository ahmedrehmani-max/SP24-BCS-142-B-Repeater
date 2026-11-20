import 'package:flutter/material.dart';

import '../models/tube.dart';
import '../widgets/game_background.dart';
import '../widgets/tube_widget.dart';

/// Instructions and the sorting rules.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const _rules = <(IconData, String, String)>[
    (
      Icons.touch_app_rounded,
      'Tap to pour',
      'Tap a tube to pick it up, then tap another tube to pour into it. '
          'Tap the same tube again to put it back down.',
    ),
    (
      Icons.layers_rounded,
      'Only the top colour moves',
      'Just the topmost block of one colour is poured — and all of it moves '
          'at once, as long as there is room.',
    ),
    (
      Icons.rule_rounded,
      'Matching colours only',
      'Liquid can only go into an empty tube, or onto liquid of the same '
          'colour. Anything else is rejected.',
    ),
    (
      Icons.straighten_rounded,
      'Tubes have a limit',
      'Every tube holds four units. If only part of a block fits, only that '
          'part is poured.',
    ),
    (
      Icons.check_circle_rounded,
      'Finish the puzzle',
      'The level is solved when every tube is either empty or filled with a '
          'single colour.',
    ),
    (
      Icons.lightbulb_outline_rounded,
      'Stuck?',
      'Undo takes back your last pour, Hint highlights a move that still '
          'wins, and Add tube gives you extra space.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'How to Play',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                  children: [
                    _example(),
                    const SizedBox(height: 18),
                    for (final (icon, title, body) in _rules)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, color: const Color(0xFFFFD54F)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    body,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Before/after of a single legal pour.
  Widget _example() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'A legal pour',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TubeWidget(
                tube: Tube(layers: const [1, 2, 0, 0]),
                width: 40,
                height: 112,
              ),
              const SizedBox(width: 10),
              TubeWidget(
                tube: Tube(layers: const [0, 1]),
                width: 40,
                height: 112,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.arrow_forward_rounded, color: Colors.white54),
              ),
              TubeWidget(
                tube: Tube(layers: const [1, 2]),
                width: 40,
                height: 112,
              ),
              const SizedBox(width: 10),
              TubeWidget(
                tube: Tube(layers: const [0, 1, 0, 0]),
                width: 40,
                height: 112,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              'Two red units sit on top of the first tube and the second tube '
              'has room, so both move together.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
