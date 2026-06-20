import '../utils/url_ext.dart';

class VideoModel {
  final int id;
  final String titre;
  final String? description;
  final String? fichier;
  final String? lienExterne;
  final String? imageMiniature;
  final String? duree;
  final String? datePublication;

  const VideoModel({
    required this.id,
    required this.titre,
    this.description,
    this.fichier,
    this.lienExterne,
    this.imageMiniature,
    this.duree,
    this.datePublication,
  });

  /// Source de lecture : le lien externe (Internet Archive, etc.) est prioritaire,
  /// sinon le fichier hébergé.
  String? get sourceUrl {
    final raw = (lienExterne != null && lienExterne!.isNotEmpty)
        ? lienExterne!
        : fichier;
    if (raw == null || raw.isEmpty) return null;
    return normalizeMediaUrl(raw);
  }

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] as int,
      titre: json['titre'] as String,
      description: json['description'] as String?,
      fichier: json['fichier'] as String?,
      lienExterne: json['lien_externe'] as String?,
      imageMiniature: json['image_miniature'] as String?,
      duree: json['duree'] as String?,
      datePublication: json['date_publication'] as String?,
    );
  }

  String get dureeFormatee {
    if (duree == null || duree!.isEmpty) return '';
    final parts = duree!.split(':');
    if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts[1].padLeft(2, '0');
      final s = parts[2].split('.')[0].padLeft(2, '0');
      return h > 0 ? '$h:$m:$s' : '${int.tryParse(m) ?? 0}:$s';
    }
    return duree!;
  }
}
