import 'dart:io';
import 'package:dio/dio.dart';

Future<String> downloadFile(
  String url,
  String savePath,
  void Function(double) onProgress,
) async {
  final dio = Dio();
  await dio.download(
    url,
    savePath,
    onReceiveProgress: (received, total) {
      if (total > 0) onProgress(received / total);
    },
  );
  return savePath;
}

Future<void> deleteFile(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}

bool fileExists(String path) => File(path).existsSync();
