import 'package:flutter/material.dart';
import '../core/models/audio_model.dart';
import '../core/theme/app_theme.dart';

class AudioCard extends StatelessWidget {
  final AudioModel audio;
  final VoidCallback? onTap;

  const AudioCard({super.key, required this.audio, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: _buildThumbnail(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audio.titre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.play_circle_outline_rounded,
                          color: AppTheme.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        audio.dureeFormatee.isNotEmpty
                            ? audio.dureeFormatee
                            : 'Audio',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (audio.imageMiniature != null && audio.imageMiniature!.isNotEmpty) {
      return Image.network(
        audio.imageMiniature!,
        height: 100,
        width: 160,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      height: 100,
      width: 160,
      color: AppTheme.primary.withValues(alpha: 0.08),
      child: const Icon(Icons.headphones_rounded,
          color: AppTheme.primary, size: 36),
    );
  }
}
