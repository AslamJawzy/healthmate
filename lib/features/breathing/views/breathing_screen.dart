import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// One step of the breathing pattern.
class _Phase {
  final String label;
  final int seconds;
  final double targetScale; // circle size at the end of this phase

  const _Phase(this.label, this.seconds, this.targetScale);
}

/// VIEW: guided "box breathing" exercise.
/// Inhale 4s -> Hold 4s -> Exhale 4s -> Hold 4s, repeated.
/// The circle grows while inhaling and shrinks while exhaling.
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> with SingleTickerProviderStateMixin {
  static const _phases = [
    _Phase('Breathe in', 4, 1.0),
    _Phase('Hold', 4, 1.0),
    _Phase('Breathe out', 4, 0.55),
    _Phase('Hold', 4, 0.55),
  ];

  late final AnimationController _controller;
  Animation<double> _scale = const AlwaysStoppedAnimation(0.55);
  Timer? _ticker;

  int _minutes = 2; // session length chosen by the user
  bool _running = false;
  int _phaseIndex = 0;
  int _secondsLeftInPhase = 0;
  int _secondsLeftTotal = 0;
  int _cycles = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose(); // always free the animation controller
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _cycles = 0;
      _secondsLeftTotal = _minutes * 60;
    });
    _startPhase(0);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stop({bool finished = false}) {
    _ticker?.cancel();
    _controller.stop();
    setState(() {
      _running = false;
      _scale = const AlwaysStoppedAnimation(0.55);
    });
    if (finished) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.self_improvement, color: AppColors.breathing, size: 40),
          title: const Text('Well done!'),
          content: Text('You completed $_cycles breathing cycles. Take a moment to notice how you feel.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
        ),
      );
    }
  }

  void _startPhase(int index) {
    final phase = _phases[index];
    final from = _scale.value;
    _phaseIndex = index;
    _secondsLeftInPhase = phase.seconds;
    _controller.duration = Duration(seconds: phase.seconds);
    _scale = Tween<double>(begin: from, end: phase.targetScale)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward(from: 0);
  }

  void _tick() {
    setState(() {
      _secondsLeftTotal--;
      _secondsLeftInPhase--;
    });
    if (_secondsLeftTotal <= 0) {
      _stop(finished: true);
      return;
    }
    if (_secondsLeftInPhase <= 0) {
      final next = (_phaseIndex + 1) % _phases.length;
      if (next == 0) _cycles++;
      setState(() => _startPhase(next));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = _phases[_phaseIndex];
    final mm = (_secondsLeftTotal ~/ 60).toString();
    final ss = (_secondsLeftTotal % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: const Text('Breathing Exercise')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                _running ? phase.label : 'Box breathing',
                style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.breathing, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _running
                    ? '$_secondsLeftInPhase'
                    : 'Breathe in, hold, breathe out, hold.\n4 seconds each. Follow the circle.',
                textAlign: TextAlign.center,
                style: _running ? theme.textTheme.displaySmall : theme.textTheme.bodyLarge,
              ),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final size = 260 * _scale.value;
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.breathing.withAlpha(220),
                              AppColors.breathing.withAlpha(60),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.breathing.withAlpha(90),
                              blurRadius: 40 * _scale.value,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.air, color: Colors.white, size: 48),
                      );
                    },
                  ),
                ),
              ),
              if (_running) ...[
                Text('$mm:$ss left  •  $_cycles cycles', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _stop(),
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ] else ...[
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('1 min')),
                    ButtonSegment(value: 2, label: Text('2 min')),
                    ButtonSegment(value: 5, label: Text('5 min')),
                  ],
                  selected: {_minutes},
                  onSelectionChanged: (s) => setState(() => _minutes = s.first),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.breathing,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
