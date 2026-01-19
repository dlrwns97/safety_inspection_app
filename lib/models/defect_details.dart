class DefectDetails {
  DefectDetails({
    required this.structuralMember,
    required this.crackType,
    required this.widthMm,
    required this.lengthMm,
    required this.cause,
  });

  final String structuralMember;
  final String crackType;
  final double widthMm;
  final double lengthMm;
  final String cause;

  Map<String, dynamic> toJson() => {
    'structuralMember': structuralMember,
    'crackType': crackType,
    'widthMm': widthMm,
    'lengthMm': lengthMm,
    'cause': cause,
  };

  factory DefectDetails.fromJson(Map<String, dynamic> json) => DefectDetails(
    structuralMember: json['structuralMember'] as String? ?? '',
    crackType: json['crackType'] as String? ?? '',
    widthMm: (json['widthMm'] as num? ?? 0).toDouble(),
    lengthMm: (json['lengthMm'] as num? ?? 0).toDouble(),
    cause: json['cause'] as String? ?? '',
  );
}
