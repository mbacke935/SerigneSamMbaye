class CitationModel {
  final int id;
  final String texte;
  final String? source;
  final String? datePublication;

  const CitationModel({
    required this.id,
    required this.texte,
    this.source,
    this.datePublication,
  });

  factory CitationModel.fromJson(Map<String, dynamic> json) {
    return CitationModel(
      id: json['id'] as int,
      texte: json['texte'] as String,
      source: json['source'] as String?,
      datePublication: json['date_publication'] as String?,
    );
  }
}
