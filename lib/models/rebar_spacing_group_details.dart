import 'dart:convert';

import 'package:safety_inspection_app/models/equipment_marker.dart';

class RebarSpacingMeasurement {
  const RebarSpacingMeasurement({
    this.remarkLeft,
    this.remarkRight,
    this.numberPrefix,
    this.numberValue,
  });

  final String? remarkLeft;
  final String? remarkRight;
  final String? numberPrefix;
  final String? numberValue;

  Map<String, dynamic> toJson() => {
    'remarkLeft': remarkLeft,
    'remarkRight': remarkRight,
    'numberPrefix': numberPrefix,
    'numberValue': numberValue,
  };

  factory RebarSpacingMeasurement.fromJson(Map<String, dynamic> json) {
    return RebarSpacingMeasurement(
      remarkLeft: json['remarkLeft'] as String?,
      remarkRight: json['remarkRight'] as String?,
      numberPrefix: json['numberPrefix'] as String?,
      numberValue: json['numberValue'] as String?,
    );
  }
}

class RebarSpacingGroupDetails {
  const RebarSpacingGroupDetails({
    required this.baseLabelIndex,
    required this.labelPrefix,
    required this.memberType,
    required this.measurements,
  });

  final int baseLabelIndex;
  final String labelPrefix;
  final String memberType;
  final List<RebarSpacingMeasurement> measurements;

  String labelForIndex(int index) {
    return '$labelPrefix${baseLabelIndex + index}';
  }

  String rangeLabel() {
    if (measurements.length <= 1) {
      return '$labelPrefix$baseLabelIndex';
    }
    return '$labelPrefix$baseLabelIndex~'
        '${baseLabelIndex + measurements.length - 1}';
  }

  Map<String, dynamic> toJson() => {
    'type': 'rebarSpacingGroup',
    'baseLabelIndex': baseLabelIndex,
    'labelPrefix': labelPrefix,
    'memberType': memberType,
    'measurements': measurements.map((item) => item.toJson()).toList(),
  };

  String toJsonString() => jsonEncode(toJson());

  static RebarSpacingGroupDetails? fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      if (decoded['type'] != 'rebarSpacingGroup') {
        return null;
      }
      final baseLabelIndex = (decoded['baseLabelIndex'] as num?)?.toInt();
      final labelPrefix = decoded['labelPrefix'] as String?;
      final memberType = decoded['memberType'] as String?;
      final measurementsRaw = decoded['measurements'];
      if (baseLabelIndex == null ||
          labelPrefix == null ||
          memberType == null ||
          measurementsRaw is! List) {
        return null;
      }
      final measurements = measurementsRaw
          .whereType<Map<String, dynamic>>()
          .map(RebarSpacingMeasurement.fromJson)
          .toList();
      if (measurements.isEmpty) {
        return null;
      }
      return RebarSpacingGroupDetails(
        baseLabelIndex: baseLabelIndex,
        labelPrefix: labelPrefix,
        memberType: memberType,
        measurements: measurements,
      );
    } catch (_) {
      return null;
    }
  }
}

RebarSpacingGroupDetails? rebarSpacingGroupFromMarker(
  EquipmentMarker marker, {
  required String defaultPrefix,
}) {
  final decoded = RebarSpacingGroupDetails.fromJsonString(marker.details);
  if (decoded != null) {
    return decoded;
  }
  final labelMatch = RegExp(r'^([A-Za-z]+)(\d+)(?:~(\d+))?$')
      .firstMatch(marker.label.trim());
  final parsedPrefix = labelMatch?.group(1);
  final parsedBase = int.tryParse(labelMatch?.group(2) ?? '');
  final baseLabelIndex = parsedBase ?? 1;
  final labelPrefix = parsedPrefix ?? defaultPrefix;
  final legacyNumberValue =
      marker.numberValue ?? marker.numberText?.trim();
  final measurement = RebarSpacingMeasurement(
    remarkLeft: marker.remarkLeft,
    remarkRight: marker.remarkRight,
    numberPrefix: marker.numberPrefix,
    numberValue: legacyNumberValue?.isNotEmpty == true ? legacyNumberValue : null,
  );
  return RebarSpacingGroupDetails(
    baseLabelIndex: baseLabelIndex,
    labelPrefix: labelPrefix,
    memberType: marker.memberType ?? '',
    measurements: [measurement],
  );
}
