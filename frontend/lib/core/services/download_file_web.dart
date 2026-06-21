Future<String> downloadFile(
  String url,
  String savePath,
  void Function(double) onProgress,
) async {
  throw UnsupportedError('Téléchargement non disponible sur le web.');
}

Future<void> deleteFile(String path) async {}

bool fileExists(String path) => false;
