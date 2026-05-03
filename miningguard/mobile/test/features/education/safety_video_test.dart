import 'package:flutter_test/flutter_test.dart';
import 'package:miningguard/features/education/domain/safety_video.dart';

void main() {
  group('localizeMap', () {
    test('returns the requested language when present', () {
      final map = {'en': 'Hello', 'hi': 'Namaste'};
      expect(localizeMap(map, 'hi'), 'Namaste');
    });

    test('falls back to English when requested language is missing', () {
      final map = {'en': 'Hello'};
      expect(localizeMap(map, 'bn'), 'Hello');
    });

    test('falls back to first value when neither requested nor English exist',
        () {
      final map = {'te': 'Telugu only'};
      expect(localizeMap(map, 'hi'), 'Telugu only');
    });

    test('returns empty string for empty map', () {
      expect(localizeMap(const {}, 'en'), '');
    });
  });

  group('VideoCategory', () {
    test('rotation list has 5 entries in documented order', () {
      expect(VideoCategory.values, [
        VideoCategory.ppe,
        VideoCategory.gasVentilation,
        VideoCategory.roofSupport,
        VideoCategory.emergency,
        VideoCategory.machinery,
      ]);
    });
  });
}
