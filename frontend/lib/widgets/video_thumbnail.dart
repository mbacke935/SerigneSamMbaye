import 'package:flutter/material.dart';
import '../core/models/video_model.dart';
import '../core/theme/app_theme.dart';
import 'network_thumb.dart';

/// Vignette vidéo au format 16:9 (standard) avec dégradé de lisibilité,
/// bouton de lecture central et badges (durée, « NOUVEAU »).
/// Réutilisée par la carte vidéo, la liste et le lecteur.
class VideoThumbnail extends StatelessWidget {
  final VideoModel video;
  final double radius;
  final double playSize;

  const VideoThumbnail({
    super.key,
    required this.video,
    this.radius = AppRadius.md,
    this.playSize = 46,
  });

  bool get _isNew {
    final d = video.datePublication;
    if (d == null) return false;
    try {
      return DateTime.now().difference(DateTime.parse(d)).inDays < 7;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _thumb(),
            // Dégradé bas pour faire ressortir les badges
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            Center(
              child: Container(
                width: playSize,
                height: playSize,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: playSize * 0.58),
              ),
            ),
            if (video.dureeFormatee.isNotEmpty)
              Positioned(
                right: 6,
                bottom: 6,
                child: _badge(video.dureeFormatee, Colors.black87, Colors.white),
              ),
            if (_isNew)
              Positioned(
                left: 6,
                top: 6,
                child: _badge('NOUVEAU', AppTheme.gold, Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _thumb() {
    if (video.imageMiniature != null && video.imageMiniature!.isNotEmpty) {
      return NetworkThumb(url: video.imageMiniature!, placeholder: _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(Icons.play_circle_rounded, color: AppTheme.primary, size: 40),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

/// Ligne de métadonnées d'une vidéo : « durée · date relative ».
String videoMetaLine(VideoModel v) {
  final parts = <String>[];
  if (v.dureeFormatee.isNotEmpty) parts.add(v.dureeFormatee);
  final rel = relativeDate(v.datePublication);
  if (rel != null) parts.add(rel);
  return parts.join('  ·  ');
}

/// Date relative en français (« Aujourd'hui », « il y a 3 jours », …).
String? relativeDate(String? iso) {
  if (iso == null) return null;
  try {
    final d = DateTime.parse(iso);
    final days = DateTime.now().difference(d).inDays;
    if (days < 0) return null;
    if (days == 0) return "Aujourd'hui";
    if (days == 1) return 'Hier';
    if (days < 7) return 'il y a $days jours';
    if (days < 30) {
      final w = (days / 7).floor();
      return 'il y a $w semaine${w > 1 ? "s" : ""}';
    }
    if (days < 365) {
      final m = (days / 30).floor();
      return 'il y a $m mois';
    }
    final y = (days / 365).floor();
    return 'il y a $y an${y > 1 ? "s" : ""}';
  } catch (_) {
    return null;
  }
}
