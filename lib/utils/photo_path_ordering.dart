List<String> insertPreservingReferenceOrder({
  required List<String> photoPaths,
  required String restoreKey,
  required String Function(String) normalizeKey,
}) {
  final orderedPaths = List<String>.from(photoPaths);
  final restoreNormalized = normalizeKey(restoreKey);

  for (var i = 0; i < orderedPaths.length; i += 1) {
    final existingNormalized = normalizeKey(orderedPaths[i]);
    if (restoreNormalized == existingNormalized) {
      return orderedPaths;
    }
    if (restoreNormalized.compareTo(existingNormalized) < 0) {
      orderedPaths.insert(i, restoreKey);
      return orderedPaths;
    }
  }

  orderedPaths.add(restoreKey);
  return orderedPaths;
}
