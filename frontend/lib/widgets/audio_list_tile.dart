import 'package:flutter/material.dart';
import '../core/models/audio_model.dart';
import '../core/theme/app_theme.dart';

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
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isCurrentlyPlaying
              ? AppTheme.primary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isCurrentlyPlaying
              ? Border.all(color: AppTheme.primary.withValues(alpha: 0.25))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildThumbnail(),
              ),
              const SizedBox(width: 14),
              // Info
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
                            color: isCurrentlyPlaying
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                          ),
                    ),
                    if (audio.dureeFormatee.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isCurrentlyPlaying) ...[
                            const Icon(Icons.equalizer_rounded,
                                color: AppTheme.primary, size: 14),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            audio.dureeFormatee,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Favoris button
              if (onFavoriTap != null)
                IconButton(
                  icon: Icon(
                    isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorited ? const Color(0xFFE53935) : AppTheme.textSecondary,
                    size: 20,
                  ),
                  onPressed: onFavoriTap,
                  tooltip: isFavorited ? 'Retirer des favoris' : 'Ajouter aux favoris',
                ),
              // Play icon
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (audio.imageMiniature != null && audio.imageMiniature!.isNotEmpty) {
      return Image.network(
        audio.imageMiniature!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: AppTheme.primary.withValues(alpha: 0.08),
      child: const Icon(Icons.headphones_rounded,
          color: AppTheme.primary, size: 26),
    );
  }
}
