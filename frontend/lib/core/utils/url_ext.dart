/// Normalise une URL média avant de la passer au lecteur.
///
/// Les noms de fichiers Internet Archive contiennent souvent des espaces ou des
/// caractères accentués (ex. `s.sam 56.mp3`, `Léçon n°2.mp3`). S'ils sont stockés
/// bruts dans `lien_externe`, le lecteur natif (just_audio / video_player) ne sait
/// pas charger l'URL et reste bloqué en « chargement » indéfiniment, sur toutes
/// les plateformes.
///
/// `Uri.parse(...).toString()` encode ces caractères (espace → `%20`, accents →
/// `%XX`) **sans double-encoder** ceux qui sont déjà au format `%XX`.
String normalizeMediaUrl(String url) {
  try {
    return Uri.parse(url.trim()).toString();
  } catch (_) {
    return url;
  }
}
