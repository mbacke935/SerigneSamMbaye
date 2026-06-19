import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Effet shimmer léger (fait main, sans dépendance) qui anime un dégradé
/// horizontal sur ses enfants pour signaler un chargement.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04);
    final highlight =
        isDark ? Colors.white.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.65);

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width * (_controller.value * 2 - 1);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(dx),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double dx;
  const _SlideGradient(this.dx);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

/// Rectangle gris arrondi animé, brique de base des squelettes.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Squelette du rail horizontal d'audios (accueil).
class SkeletonAudioRail extends StatelessWidget {
  const SkeletonAudioRail({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SizedBox(
        height: 188,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (_, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(width: 160, height: 104, radius: AppRadius.md),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(width: 140, height: 12),
              SizedBox(height: 6),
              SkeletonBox(width: 80, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Squelette de grille (vidéos).
class SkeletonGrid extends StatelessWidget {
  final int count;
  const SkeletonGrid({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.82,
          ),
          itemCount: count,
          itemBuilder: (_, __) => const SkeletonBox(height: 180, radius: AppRadius.md),
        ),
      ),
    );
  }
}

/// Squelette de liste verticale (audios/citations/listes).
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => Row(
          children: const [
            SkeletonBox(width: 56, height: 56, radius: AppRadius.sm),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 200, height: 13),
                  SizedBox(height: 8),
                  SkeletonBox(width: 100, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
