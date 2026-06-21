import 'package:flutter/material.dart';
import '../core/models/audio_model.dart';
import '../core/theme/app_theme.dart';
import 'network_thumb.dart';

class AudioCard extends StatelessWidget {
  final AudioModel audio;
  final VoidCallback? onTap;

  const AudioCard({super.key, required this.audio, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNew = _isNew(audio.datePublication);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppTheme.softShadow(0.07),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildThumbnail(),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                  ),
                ),
                if (isNew)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NOUVEAU',
                        style: TextStyle(
                            color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audio.titre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    audio.dureeFormatee.isNotEmpty ? audio.dureeFormatee : 'Audio',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isNew(String? dateStr) {
    if (dateStr == null) return false;
    try {
      final date = DateTime.parse(dateStr);
      return DateTime.now().difference(date).inDays < 7;
    } catch (_) {
      return false;
    }
  }

  Widget _buildThumbnail() {
    if (audio.imageMiniature != null && audio.imageMiniature!.isNotEmpty) {
      return NetworkThumb(
        url: audio.imageMiniature!,
        height: 100,
        width: 160,
        placeholder: _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      height: 100,
      width: 160,
      color: AppTheme.primary.withValues(alpha: 0.08),
      child: const Icon(Icons.headphones_rounded, color: AppTheme.primary, size: 34),
    );
  }
}
