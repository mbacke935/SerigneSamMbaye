import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Image réseau adaptée à la plateforme.
///
/// - **Web** : `Image.network` (décodage natif via l'élément `<img>`, hors du
///   thread principal). On évite ainsi le gel de l'UI provoqué par
///   `cached_network_image` / `flutter_cache_manager` sur le web, qui traite les
///   octets de l'image sur l'isolate principal et fige l'app quand plusieurs
///   images apparaissent d'un coup (ex. la grille de vidéos).
/// - **Mobile** : `CachedNetworkImage` (cache disque, stable et précieux).
class NetworkThumb extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget placeholder;

  const NetworkThumb({
    super.key,
    required this.url,
    required this.placeholder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => placeholder,
    );
  }
}
