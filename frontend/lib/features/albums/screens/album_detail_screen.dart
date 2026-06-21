import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/album_model.dart';
import '../../../core/models/audio_model.dart';
import '../../../core/models/video_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/album_service.dart';
import '../../../core/services/audio_player_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_states.dart';
import '../../../widgets/fade_slide_in.dart';
import '../../../widgets/skeleton.dart';

class AlbumDetailScreen extends StatefulWidget {
  final int albumId;
  final String? titre;

  const AlbumDetailScreen({super.key, required this.albumId, this.titre});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final _service = AlbumService(ApiClient());
  late Future<AlbumModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAlbum(widget.albumId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre ?? 'Album')),
      body: FutureBuilder<AlbumModel?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonList(count: 6);
          }
          final album = snapshot.data;
          if (album == null) {
            return ErrorRetry(
              message: 'Album introuvable',
              onRetry: () => setState(() => _future = _service.getAlbum(widget.albumId)),
            );
          }
          return _buildContent(album);
        },
      ),
    );
  }

  Widget _buildContent(AlbumModel album) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        FadeSlideIn(child: _header(album)),
        if (album.audios.isNotEmpty) ...[
          _sectionTitle('Audios'),
          ...album.audios.asMap().entries.map(
                (e) => FadeSlideIn(
                  delay: Duration(milliseconds: 40 * e.key),
                  child: _AudioTile(
                    audio: e.value,
                    playlist: album.audios,
                    index: e.key,
                  ),
                ),
              ),
        ],
        if (album.videos.isNotEmpty) ...[
          _sectionTitle('Vidéos'),
          ...album.videos.asMap().entries.map(
                (e) => FadeSlideIn(
                  delay: Duration(milliseconds: 40 * e.key),
                  child: _VideoTile(video: e.value),
                ),
              ),
        ],
        if (album.audios.isEmpty && album.videos.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: EmptyState(
              icon: Icons.album_outlined,
              message: 'Album vide',
              hint: 'Aucun contenu publié pour le moment.',
            ),
          ),
      ],
    );
  }

  Widget _header(AlbumModel album) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 110,
              height: 110,
              child: (album.image != null && album.image!.isNotEmpty)
                  ? Image.network(album.image!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPlaceholder())
                  : _coverPlaceholder(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(album.titre,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  '${album.nbAudios} audios · ${album.nbVideos} vidéos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                if (album.description != null && album.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(album.description!,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryLight, AppTheme.primary],
          ),
        ),
        child: const Icon(Icons.album_rounded, color: AppTheme.gold, size: 44),
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
        child: Text(t,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700)),
      );
}

class _AudioTile extends StatelessWidget {
  final AudioModel audio;
  final List<AudioModel> playlist;
  final int index;

  const _AudioTile({required this.audio, required this.playlist, required this.index});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioModel?>(
      valueListenable: AudioPlayerService().currentAudioListenable,
      builder: (context, current, _) {
        final isActive = current?.id == audio.id;
        return ListTile(
          leading: _thumb(audio.imageMiniature, Icons.headphones_rounded),
          title: Text(audio.titre,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive ? AppTheme.gold : null,
              )),
          subtitle: audio.dureeFormatee.isNotEmpty ? Text(audio.dureeFormatee) : null,
          trailing: Icon(
            isActive ? Icons.graphic_eq_rounded : Icons.play_circle_fill_rounded,
            color: AppTheme.primary,
            size: 32,
          ),
          onTap: () {
            AudioPlayerService().setPlaylist(playlist, index);
            context.push('/audios/lecteur', extra: audio);
          },
        );
      },
    );
  }
}

class _VideoTile extends StatelessWidget {
  final VideoModel video;
  const _VideoTile({required this.video});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _thumb(video.imageMiniature, Icons.play_circle_outline_rounded),
      title: Text(video.titre,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: video.dureeFormatee.isNotEmpty ? Text(video.dureeFormatee) : null,
      trailing: const Icon(Icons.play_arrow_rounded, color: AppTheme.primary, size: 28),
      onTap: () => context.push('/videos/lecteur', extra: video),
    );
  }
}

Widget _thumb(String? url, IconData fallback) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: SizedBox(
      width: 52,
      height: 52,
      child: (url != null && url.isNotEmpty)
          ? Image.network(url, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _thumbPlaceholder(fallback))
          : _thumbPlaceholder(fallback),
    ),
  );
}

Widget _thumbPlaceholder(IconData icon) => Container(
      color: AppTheme.primary.withValues(alpha: 0.08),
      child: Icon(icon, color: AppTheme.primary, size: 24),
    );
