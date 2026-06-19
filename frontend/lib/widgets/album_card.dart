import 'package:flutter/material.dart';
import '../core/models/album_model.dart';
import '../core/theme/app_theme.dart';

/// Pochette d'album (dossier thématique) affichée dans un rail horizontal.
class AlbumCard extends StatelessWidget {
  final AlbumModel album;
  final VoidCallback onTap;

  const AlbumCard({super.key, required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: AppTheme.softShadow(0.10),
                ),
                clipBehavior: Clip.antiAlias,
                child: _cover(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              album.titre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              _subtitle(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle() {
    final parts = <String>[];
    if (album.nbAudios > 0) parts.add('${album.nbAudios} audio${album.nbAudios > 1 ? 's' : ''}');
    if (album.nbVideos > 0) parts.add('${album.nbVideos} vidéo${album.nbVideos > 1 ? 's' : ''}');
    return parts.isEmpty ? 'Album' : parts.join(' · ');
  }

  Widget _cover() {
    if (album.image != null && album.image!.isNotEmpty) {
      return Image.network(album.image!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryLight, AppTheme.primary],
        ),
      ),
      child: const Center(
        child: Icon(Icons.album_rounded, color: AppTheme.gold, size: 44),
      ),
    );
  }
}
