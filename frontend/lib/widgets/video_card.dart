import 'package:flutter/material.dart';
import '../core/models/video_model.dart';
import 'video_thumbnail.dart';

/// Carte vidéo style YouTube : vignette 16:9 + titre + métadonnées.
/// La largeur est pilotée par le parent (carrousel sur l'accueil, pleine
/// largeur dans la liste de l'onglet Vidéos).
class VideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback? onTap;

  const VideoCard({super.key, required this.video, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VideoThumbnail(video: video),
          const SizedBox(height: 8),
          Text(
            video.titre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
          ),
          if (videoMetaLine(video).isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              videoMetaLine(video),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
