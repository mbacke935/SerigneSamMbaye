import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../core/models/audio_model.dart';
import '../core/services/audio_player_service.dart';
import '../core/theme/app_theme.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AudioPlayerService();
    return ValueListenableBuilder<AudioModel?>(
      valueListenable: service.currentAudioListenable,
      builder: (context, audio, _) {
        if (audio == null) return const SizedBox.shrink();
        return _MiniPlayerContent(audio: audio, service: service);
      },
    );
  }
}

class _MiniPlayerContent extends StatelessWidget {
  final AudioModel audio;
  final AudioPlayerService service;

  const _MiniPlayerContent({required this.audio, required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/audios/lecteur', extra: audio),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thin progress bar at top
            StreamBuilder<Duration?>(
              stream: service.durationStream,
              builder: (context, durSnap) {
                final total = durSnap.data?.inMilliseconds ?? 1;
                return StreamBuilder<Duration>(
                  stream: service.positionStream,
                  builder: (context, posSnap) {
                    final pos = posSnap.data?.inMilliseconds ?? 0;
                    final ratio = total > 0 ? (pos / total).clamp(0.0, 1.0) : 0.0;
                    return LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
                      minHeight: 2,
                    );
                  },
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _thumbnail(),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      audio.titre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                  // Play/Pause button
                  StreamBuilder<PlayerState>(
                    stream: service.playerStateStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data?.playing ?? false;
                      final isLoading = snapshot.data?.processingState ==
                              ProcessingState.loading ||
                          snapshot.data?.processingState ==
                              ProcessingState.buffering;
                      if (isLoading) {
                        return const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.gold),
                        );
                      }
                      return IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppTheme.gold,
                          size: 30,
                        ),
                        onPressed: service.togglePlayPause,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white54, size: 20),
                    onPressed: service.stop,
                    tooltip: 'Fermer',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail() {
    if (audio.imageMiniature != null && audio.imageMiniature!.isNotEmpty) {
      return Image.network(audio.imageMiniature!,
          width: 40, height: 40, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholderIcon());
    }
    return _placeholderIcon();
  }

  Widget _placeholderIcon() {
    return Container(
      width: 40,
      height: 40,
      color: Colors.white.withValues(alpha: 0.1),
      child: const Icon(Icons.headphones_rounded, color: AppTheme.gold, size: 20),
    );
  }
}
