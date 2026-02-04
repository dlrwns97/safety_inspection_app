import 'package:path/path.dart' as p;

class DefectDetails {
  DefectDetails({
    required this.structuralMember,
    required this.crackType,
    required this.widthMm,
    required this.lengthMm,
    required this.cause,
    this.photoPaths = const [],
    this.photoOriginalNamesByPath = const {},
  });

  final String structuralMember;
  final String crackType;
  final double widthMm;
  final double lengthMm;
  final String cause;
  final List<String> photoPaths;
  final Map<String, String> photoOriginalNamesByPath;

  Map<String, dynamic> toJson() => {
    'structuralMember': structuralMember,
    'crackType': crackType,
    'widthMm': widthMm,
    'lengthMm': lengthMm,
    'cause': cause,
    'photoPaths': photoPaths,
    'photoOriginalNamesByPath': photoOriginalNamesByPath,
  };

  factory DefectDetails.fromJson(Map<String, dynamic> json) => DefectDetails(
    structuralMember: json['structuralMember'] as String? ?? '',
    crackType: json['crackType'] as String? ?? '',
    widthMm: (json['widthMm'] as num? ?? 0).toDouble(),
    lengthMm: (json['lengthMm'] as num? ?? 0).toDouble(),
    cause: json['cause'] as String? ?? '',
    photoPaths:
        (json['photoPaths'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        const [],
    photoOriginalNamesByPath:
        _photoOriginalNamesFromJson(json['photoOriginalNamesByPath']),
  );

  static Map<String, String> _photoOriginalNamesFromJson(dynamic rawValue) {
    if (rawValue is! Map) {
      return const {};
    }
    final names = <String, String>{};
    for (final entry in rawValue.entries) {
      if (entry.key is String && entry.value is String) {
        names[entry.key as String] = entry.value as String;
      }
    }
    return names;
  }
}

String photoDisplayName({
  required String storedPath,
  required Map<String, String> originalNamesByPath,
}) {
  final raw = originalNamesByPath[storedPath] ?? p.basename(storedPath);
  return p.basenameWithoutExtension(raw);
}
