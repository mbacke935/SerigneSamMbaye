class AudioModel {
  final int id;
  final String titre;
  final String? description;
  final String? fichier;
  final String? imageMiniature;
  final String? duree;
  final String? datePublication;

  const AudioModel({
    required this.id,
    required this.titre,
    this.description,
    this.fichier,
    this.imageMiniature,
    this.duree,
    this.datePublication,
  });

  factory AudioModel.fromJson(Map<String, dynamic> json) {
    return AudioModel(
      id: json['id'] as int,
      titre: json['titre'] as String,
      description: json['description'] as String?,
      fichier: json['fichier'] as String?,
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
