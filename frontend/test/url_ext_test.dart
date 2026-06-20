import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/url_ext.dart';

void main() {
  group('normalizeMediaUrl', () {
    test('encode un espace littéral en %20', () {
      expect(
        normalizeMediaUrl(
            'https://archive.org/download/10_ser_sam_mbaye07/s.sam 56.mp3'),
        'https://archive.org/download/10_ser_sam_mbaye07/s.sam%2056.mp3',
      );
    });

    test('ne double-encode pas une URL déjà encodée (%20 reste %20)', () {
      const already =
          'https://archive.org/download/10_ser_sam_mbaye07/s.sam%2056.mp3';
      expect(normalizeMediaUrl(already), already);
    });

    test('encode les caractères accentués', () {
      expect(
        normalizeMediaUrl('https://archive.org/download/x/Léçon n°2.mp3'),
        'https://archive.org/download/x/L%C3%A9%C3%A7on%20n%C2%B02.mp3',
      );
    });

    test('supprime les espaces de début/fin', () {
      expect(
        normalizeMediaUrl('  https://example.com/a.mp3  '),
        'https://example.com/a.mp3',
      );
    });

    test('laisse une URL propre inchangée', () {
      const clean = 'https://example.com/audios/clean-file.mp3';
      expect(normalizeMediaUrl(clean), clean);
    });
  });
}
