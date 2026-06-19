import 'package:flutter/material.dart';
import '../core/models/audio_model.dart';
import '../core/theme/app_theme.dart';
import 'equalizer_bars.dart';

class AudioListTile extends StatelessWidget {
  final AudioModel audio;
  final bool isCurrentlyPlaying;
  final bool isFavorited;
  final VoidCallback onTap;
  final VoidCallback? onFavoriTap;

  const AudioListTile({
    super.key,
    required this.audio,
    required this.isCurrentlyPlaying,
    required this.isFavorited,
    required this.onTap,
    this.onFavoriTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
      child: Material(
        color: isCurrentlyPlaying
            ? AppTheme.primary.withValues(alpha: 0.08)
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: isCurrentlyPlaying
                  ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3))
                  : Border.all(color: scheme.outline),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.sm + 2),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: _buildThumbnail(),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audio.titre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isCurrentlyPlaying ? AppTheme.primary : scheme.onSurface,
                            ),
                      ),
                      if (audio.dureeFormatee.isNotEmpty || isCurrentlyPlaying) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            if (isCurrentlyPlaying) ...[
                              const EqualizerBars(
                                playing: true,
                                color: AppTheme.primary,
                                barCount: 3,
                                height: 12,
                                barWidth: 2.5,
                                spacing: 2,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              audio.dureeFormatee.isNotEmpty ? audio.dureeFormatee : 'Audio',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (onFavoriTap != null)
                  IconButton(
                    icon: Icon(
                      isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFavorited ? const Color(0xFFE53935) : scheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: onFavoriTap,
                  ),
                Icon(Icons.play_circle_fill_rounded,
                    color: isCurrentlyPlaying ? AppTheme.primary : AppTheme.gold, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (audio.imageMiniature != null && audio.imageMiniature!.isNotEmpty) {
      return Image.network(
        audio.imageMiniature!,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 54,
      height: 54,
      color: AppTheme.primary.withValues(alpha: 0.08),
      child: const Icon(Icons.headphones_rounded, color: AppTheme.primary, size: 24),
    );
  }
}
