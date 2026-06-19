import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Équaliseur visuel : des barres qui dansent quand [playing] est vrai, et
/// se figent doucement à l'arrêt. 100% cross-plateforme (web/iOS/Android),
/// piloté par l'état de lecture (aucune analyse audio réelle requise).
class EqualizerBars extends StatefulWidget {
  final bool playing;
  final Color color;
  final int barCount;
  final double height;
  final double barWidth;
  final double spacing;

  const EqualizerBars({
    super.key,
    required this.playing,
    required this.color,
    this.barCount = 4,
    this.height = 22,
    this.barWidth = 3.5,
    this.spacing = 3,
  });

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final List<double> _phases;
  late final List<double> _speeds;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    _phases = List.generate(widget.barCount, (_) => rnd.nextDouble() * math.pi * 2);
    _speeds = List.generate(widget.barCount, (_) => 0.7 + rnd.nextDouble() * 0.8);
    if (widget.playing) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant EqualizerBars old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.playing && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value * math.pi * 2;
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.barCount, (i) {
              final wave = widget.playing
                  ? (math.sin(t * _speeds[i] + _phases[i]) + 1) / 2
                  : 0.18;
              final h = (0.22 + 0.78 * wave) * widget.height;
              return Container(
                width: widget.barWidth,
                height: h,
                margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(widget.barWidth),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
