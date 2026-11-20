import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/level.dart';
import '../models/tube.dart';
import '../services/audio_service.dart';
import '../state/game_controller.dart';
import '../widgets/game_background.dart';
import '../widgets/pour_stream.dart';
import '../widgets/tube_widget.dart';
import 'win_screen.dart';

/// The board: tubes, controls, and the pouring animation.
class GameScreen extends StatefulWidget {
  final int levelNumber;

  const GameScreen({super.key, required this.levelNumber});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  final controller = GameController();
  final _boardKey = GlobalKey();
  final _tubeKeys = <int, GlobalKey>{};

  /// Drives the lift → tilt → pour → return sequence.
  late final AnimationController pourAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );

  PendingPour? animating;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
    controller.loadLevel(widget.levelNumber);
    AudioService.instance.startMusic();
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    pourAnimation.dispose();
    controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final pending = controller.pendingPour;
    if (pending != null && animating == null) {
      setState(() => animating = pending);
      pourAnimation.forward(from: 0).then((_) async {
        await controller.finishPour();
        if (!mounted) return;
        setState(() => animating = null);
        if (controller.won) _showWinScreen();
      });
    }
  }

  Future<void> _showWinScreen() async {
    // Let the last drop land before the celebration covers the board.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    final action = await Navigator.push<WinAction>(
      context,
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: WinScreen(
            level: controller.level.number,
            moves: controller.moves,
            stars: controller.starsEarned,
            bestMoves: controller.bestMoves,
            hasNextLevel: controller.level.number < LevelRecipe.totalLevels,
          ),
        ),
      ),
    );

    if (!mounted) return;
    switch (action) {
      case WinAction.next:
        controller.loadLevel(controller.level.number + 1);
      case WinAction.replay:
        controller.restart();
      case WinAction.home:
      case null:
        if (mounted) Navigator.pop(context);
    }
  }

  GlobalKey _keyFor(int index) =>
      _tubeKeys.putIfAbsent(index, () => GlobalKey());

  /// Centre of tube [index] in board coordinates, or null before layout.
  Rect? _tubeRect(int index) {
    final boardBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    final tubeBox =
        _tubeKeys[index]?.currentContext?.findRenderObject() as RenderBox?;
    if (boardBox == null || tubeBox == null) return null;
    final topLeft = boardBox.globalToLocal(tubeBox.localToGlobal(Offset.zero));
    return topLeft & tubeBox.size;
  }

  // ------------------------------------------------------- pour animation

  /// 0 → 1 for the "liquid is flowing" part of the sequence.
  double get _flowProgress {
    const start = 0.34;
    const end = 0.80;
    final t = pourAnimation.value;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return (t - start) / (end - start);
  }

  /// How many units have visibly left the source so far.
  int _unitsMoved(PendingPour pour) =>
      (_flowProgress * pour.amount).floor().clamp(0, pour.amount);

  List<int> _sourceLayers(PendingPour pour) {
    final layers = List<int>.from(controller.tubes[pour.from].layers);
    final moved = _unitsMoved(pour);
    return layers.sublist(0, layers.length - moved);
  }

  List<int> _destinationLayers(PendingPour pour) {
    final layers = List<int>.from(controller.tubes[pour.to].layers);
    layers.addAll(List.filled(_unitsMoved(pour), pour.color));
    return layers;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GameController>.value(
      value: controller,
      child: Scaffold(
        body: GameBackground(
          child: SafeArea(
            child: Consumer<GameController>(
              builder: (context, game, _) {
                if (!_isReady(game)) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                return Column(
                  children: [
                    _header(game),
                    Expanded(child: _board(game)),
                    _controls(game),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  bool _isReady(GameController game) {
    try {
      // `level` is late-initialised by loadLevel().
      game.level.number;
      return true;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------- header

  Widget _header(GameController game) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          _RoundIcon(
            icon: Icons.home_rounded,
            tooltip: 'Home',
            onTap: () {
              AudioService.instance.play(Sfx.click);
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                'Level ${game.level.number}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Moves ${game.moves}'
                '${game.bestMoves == null ? '' : '   •   Best ${game.bestMoves}'}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          _RoundIcon(
            icon: Icons.pause_rounded,
            tooltip: 'Pause',
            onTap: () => _showPauseMenu(game),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- board

  Widget _board(GameController game) {
    final pour = animating;

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = game.tubes.length;
        // Fit the tubes to the screen: narrower glasses when there are many,
        // so the board still works on a small phone.
        final perRow = count <= 5 ? count : (count / 2).ceil();
        final tubeWidth =
            ((constraints.maxWidth - 32) / perRow - 12).clamp(30.0, 60.0);
        final tubeHeight = (tubeWidth * 2.9).clamp(90.0, 180.0);

        return Stack(
          key: _boardKey,
          children: [
            Center(
              child: SingleChildScrollView(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 22,
                  children: [
                    for (var i = 0; i < count; i++)
                      _tubeSlot(game, i, tubeWidth, tubeHeight, pour),
                  ],
                ),
              ),
            ),
            if (pour != null) ..._pourOverlay(game, pour, tubeWidth, tubeHeight),
          ],
        );
      },
    );
  }

  Widget _tubeSlot(
    GameController game,
    int index,
    double width,
    double height,
    PendingPour? pour,
  ) {
    final isSource = pour != null && pour.from == index;
    final isDestination = pour != null && pour.to == index;
    final selected = game.selectedTube == index;
    final hinted = game.hintMove != null &&
        (game.hintMove!.from == index || game.hintMove!.to == index);

    final tube = game.tubes[index];
    final layers = isDestination ? _destinationLayers(pour) : null;

    return GestureDetector(
      onTap: () => game.tapTube(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        key: _keyFor(index),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        // The selected tube lifts out of the row.
        padding: EdgeInsets.only(bottom: selected ? 18 : 0, top: selected ? 0 : 18),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: selected ? 1.06 : 1.0,
          child: Opacity(
            // The source is redrawn in the overlay while it pours.
            opacity: isSource ? 0 : 1,
            child: TubeWidget(
              tube: tube,
              selected: selected,
              highlighted: hinted,
              fillOverride: layers,
              width: width,
              height: height,
            ),
          ),
        ),
      ),
    );
  }

  /// The source tube lifted above the destination, tilted, with a stream of
  /// liquid running from its spout into the target.
  List<Widget> _pourOverlay(
    GameController game,
    PendingPour pour,
    double width,
    double height,
  ) {
    final sourceRect = _tubeRect(pour.from);
    final targetRect = _tubeRect(pour.to);
    if (sourceRect == null || targetRect == null) return const [];

    return [
      AnimatedBuilder(
        animation: pourAnimation,
        builder: (context, _) {
          final t = pourAnimation.value;

          // Travel out and back: 0 → 1 → 0 across the sequence.
          final travel = t < 0.34
              ? Curves.easeOutCubic.transform(t / 0.34)
              : t > 0.80
                  ? 1 - Curves.easeInCubic.transform((t - 0.80) / 0.20)
                  : 1.0;

          // Tilt toward whichever side the destination is on.
          final toTheRight = targetRect.center.dx >= sourceRect.center.dx;
          final tilt = (toTheRight ? -1 : 1) * 1.05 * travel;

          // Park the glass just above the destination's rim.
          final restingTop = targetRect.top - height * 0.55;
          final left = sourceRect.left +
              (targetRect.center.dx -
                      sourceRect.center.dx -
                      (toTheRight ? -width * 0.55 : width * 0.55)) *
                  travel;
          final top = sourceRect.top + (restingTop - sourceRect.top) * travel;

          // Where the lip of the tilted glass ends up: the mouth sits at
          // (0, -height/2) in the tube's own space, rotated by `tilt`.
          final spout = Offset(
            left + width / 2 + sin(tilt) * height / 2,
            top + height / 2 - cos(tilt) * height / 2,
          );

          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                child: Transform.rotate(
                  angle: tilt,
                  alignment: Alignment.center,
                  child: TubeWidget(
                    tube: Tube(
                      layers: _sourceLayers(pour),
                      capacity: game.level.capacity,
                    ),
                    selected: true,
                    fillOverride: _sourceLayers(pour),
                    width: width,
                    height: height,
                  ),
                ),
              ),
              // Drawn after the glass so the liquid leaving the mouth is in
              // front of it, the way it would really fall.
              if (travel > 0.9)
                PourStream(
                  spout: spout,
                  target: Offset(targetRect.center.dx, targetRect.top + 10),
                  color: pour.color,
                  progress: _flowProgress,
                ),
            ],
          );
        },
      ),
    ];
  }

  // ------------------------------------------------------------ controls

  Widget _controls(GameController game) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 14),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _ControlButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            enabled: game.canUndo,
            onTap: game.undo,
          ),
          _ControlButton(
            icon: Icons.refresh_rounded,
            label: 'Restart',
            enabled: !game.isBusy,
            onTap: game.restart,
          ),
          _ControlButton(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Hint',
            enabled: !game.isBusy && !game.won,
            busy: game.hintSearching,
            onTap: () async {
              await game.requestHint();
              if (!mounted) return;
              if (game.hintMove == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No winning move from here — try Undo.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          _ControlButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Add tube',
            enabled: game.canAddTube,
            onTap: game.addTube,
          ),
        ],
      ),
    );
  }

  Future<void> _showPauseMenu(GameController game) async {
    AudioService.instance.play(Sfx.click);
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF2A0845),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paused',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              MenuButton(
                icon: Icons.play_arrow_rounded,
                label: 'Resume',
                onPressed: () => Navigator.pop(ctx),
              ),
              MenuButton(
                icon: Icons.refresh_rounded,
                label: 'Restart level',
                colors: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
                onPressed: () {
                  Navigator.pop(ctx);
                  game.restart();
                },
              ),
              MenuButton(
                icon: Icons.home_rounded,
                label: 'Main menu',
                colors: const [Color(0xFFEE0979), Color(0xFFFF6A00)],
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled && !busy ? onTap : null,
          child: Container(
            width: 78,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(icon, color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
