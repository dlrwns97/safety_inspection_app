import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/screens/home/site_photo_orphan_scanner.dart';
import 'package:safety_inspection_app/utils/photo_path_ordering.dart';

void main() {
  group('insertPreservingReferenceOrder', () {
    test('A. middle insert keeps normalized reference order', () {
      final result = insertPreservingReferenceOrder(
        photoPaths: ['/root/1.jpg', '/root/3.jpg'],
        restoreKey: '/root/2.jpg',
        normalizeKey: photoReferenceKey,
      );

      expect(result, ['/root/1.jpg', '/root/2.jpg', '/root/3.jpg']);
    });

    test('B. append when restore key is greatest', () {
      final result = insertPreservingReferenceOrder(
        photoPaths: ['/root/1.jpg', '/root/2.jpg'],
        restoreKey: '/root/3.jpg',
        normalizeKey: photoReferenceKey,
      );

      expect(result, ['/root/1.jpg', '/root/2.jpg', '/root/3.jpg']);
    });

    test('C. prepend when restore key is smallest', () {
      final result = insertPreservingReferenceOrder(
        photoPaths: ['/root/2.jpg', '/root/3.jpg'],
        restoreKey: '/root/1.jpg',
        normalizeKey: photoReferenceKey,
      );

      expect(result, ['/root/1.jpg', '/root/2.jpg', '/root/3.jpg']);
    });

    test('D. duplicate no-op by normalized key', () {
      final result = insertPreservingReferenceOrder(
        photoPaths: ['C:\\a\\2.jpg'],
        restoreKey: '/a/2.jpg',
        normalizeKey: photoReferenceKey,
      );

      expect(result, ['C:\\a\\2.jpg']);
    });

    test('E. legacy mixed key/path items are compared by normalizeKey', () {
      final result = insertPreservingReferenceOrder(
        photoPaths: ['/root/1.jpg', 'C:\\root\\3.jpg'],
        restoreKey: '/root/2.jpg',
        normalizeKey: photoReferenceKey,
      );

      expect(result, ['/root/1.jpg', '/root/2.jpg', 'C:\\root\\3.jpg']);
    });

    test('F. does not mutate the input list', () {
      final original = ['/root/1.jpg', '/root/3.jpg'];
      final before = List<String>.from(original);

      final result = insertPreservingReferenceOrder(
        photoPaths: original,
        restoreKey: '/root/2.jpg',
        normalizeKey: photoReferenceKey,
      );

      expect(original, before);
      expect(identical(result, original), isFalse);
      expect(result, ['/root/1.jpg', '/root/2.jpg', '/root/3.jpg']);
    });
  });
}
