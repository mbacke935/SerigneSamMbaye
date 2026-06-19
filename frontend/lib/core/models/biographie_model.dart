class BiographieModel {
  final int id;
  final String titre;
  final String contenu;
  final String? image;
  final String? dateCreation;

  const BiographieModel({
    required this.id,
    required this.titre,
    required this.contenu,
    this.image,
    this.dateCreation,
  });

  factory BiographieModel.fromJson(Map<String, dynamic> json) {
    return BiographieModel(
      id: json['id'] as int,
      titre: json['titre'] as String,
      contenu: json['contenu'] as String,
      image: json['image'] as String?,
      dateCreation: json['date_creation'] as String?,
    );
  }
}
