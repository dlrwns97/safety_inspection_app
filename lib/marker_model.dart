import 'package:flutter/material.dart';

enum DefectCategory {
  crack('균열'),
  leak('누수'),
  concrete('콘크리트 결함'),
  other('기타 결함');

  const DefectCategory(this.label);
  final String label;
}

class DefectOption {
  const DefectOption({
    required this.code,
    required this.label,
    this.isCustom = false,
  });

  final String code;
  final String label;
  final bool isCustom;
}

const List<String> structuralMembers = [
  '기둥',
  '벽체',
  '슬래브',
  '보',
  '조적벽',
];

const Map<DefectCategory, List<DefectOption>> defectTypeOptions = {
  DefectCategory.crack: [
    DefectOption(code: 'vertical', label: '수직'),
    DefectOption(code: 'horizontal', label: '수평'),
    DefectOption(code: 'diagonal', label: '사선'),
    DefectOption(code: 'vertical_horizontal', label: '수직·수평'),
    DefectOption(code: 'network', label: '망상'),
    DefectOption(code: 'other', label: '기타', isCustom: true),
  ],
  DefectCategory.leak: [
    DefectOption(code: 'leak_trace', label: '누수 흔적'),
    DefectOption(code: 'leak_crack', label: '누수 균열'),
    DefectOption(code: 'leak_active', label: '누수 진행중'),
    DefectOption(code: 'other', label: '기타', isCustom: true),
  ],
  DefectCategory.concrete: [
    DefectOption(code: 'spalling', label: '콘크리트 박락'),
    DefectOption(code: 'delamination', label: '콘크리트 박리'),
    DefectOption(code: 'rebar_exposed', label: '철근 노출'),
    DefectOption(code: 'other', label: '기타', isCustom: true),
  ],
  DefectCategory.other: [
    DefectOption(code: 'finish_bulge', label: '마감재 들뜸'),
    DefectOption(code: 'finish_fall', label: '마감재 탈락'),
    DefectOption(code: 'other', label: '기타', isCustom: true),
  ],
};

const Map<DefectCategory, List<DefectOption>> defectCauseOptions = {
  DefectCategory.crack: [
    DefectOption(code: 'drying_shrinkage', label: '건조 수축'),
    DefectOption(code: 'corner_crack', label: '우각부 균열'),
    DefectOption(code: 'joint_crack', label: '접합부 균열'),
    DefectOption(code: 'stress_concentration', label: '하중 및 응력 집중'),
    DefectOption(code: 'other', label: '기타', isCustom: true),
  ],
  DefectCategory.leak: [
    DefectOption(code: 'rain_inflow', label: '우수 유입 추정'),
    DefectOption(code: 'pipe_leak', label: '배관 누수 추정'),
    DefectOption(code: 'crack_infiltration', label: '균열부 우수 침투'),
    DefectOption(code: 'other', label: '기타', isCustom: true),
  ],
  DefectCategory.concrete: [
    DefectOption(code: 'external_damage', label: '외력 손상 추정'),
    DefectOption(code: 'construction_error', label: '시공 오차'),
    DefectOption(code: 'chemical_reaction', label: '화학적 반응'),
    DefectOption(code: 'other', label: '기타', isCustom: true),
  ],
  DefectCategory.other: [
    DefectOption(code: 'aging', label: '노후화'),
    DefectOption(code: 'external_damage', label: '외력 손상 추정'),
    DefectOption(code: 'other', label: '기타', isCustom: true),
  ],
};

class DefectDetails {
  DefectDetails({
    required this.structuralMember,
    required this.defectType,
    required this.widthMm,
    required this.lengthMm,
    required this.cause,
    this.defectTypeCustomText,
    this.causeCustomText,
  });

  final String structuralMember;
  final String defectType;
  final String? defectTypeCustomText;
  final double widthMm;
  final double lengthMm;
  final String cause;
  final String? causeCustomText;

  Map<String, dynamic> toJson() => {
    'structuralMember': structuralMember,
    'defectType': defectType,
    'defectTypeCustomText': defectTypeCustomText,
    'widthMm': widthMm,
    'lengthMm': lengthMm,
    'cause': cause,
    'causeCustomText': causeCustomText,
  };

  factory DefectDetails.fromJson(Map<String, dynamic> json) => DefectDetails(
    structuralMember: json['structuralMember'] as String? ?? '',
    defectType:
        json['defectType'] as String? ?? json['crackType'] as String? ?? '',
    defectTypeCustomText: json['defectTypeCustomText'] as String?,
    widthMm: (json['widthMm'] as num? ?? 0).toDouble(),
    lengthMm: (json['lengthMm'] as num? ?? 0).toDouble(),
    cause: json['cause'] as String? ?? '',
    causeCustomText: json['causeCustomText'] as String?,
  );
}

class Defect {
  Defect({
    required this.id,
    required this.label,
    required this.pageIndex,
    required this.category,
    required this.normalizedX,
    required this.normalizedY,
    required this.details,
  });

  final String id;
  final String label;
  final int pageIndex;
  final DefectCategory category;
  final double normalizedX;
  final double normalizedY;
  final DefectDetails details;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'pageIndex': pageIndex,
    'category': category.name,
    'normalizedX': normalizedX,
    'normalizedY': normalizedY,
    'details': details.toJson(),
  };

  factory Defect.fromJson(Map<String, dynamic> json) => Defect(
    id: json['id'] as String,
    label: json['label'] as String,
    pageIndex: json['pageIndex'] as int? ?? 0,
    category: DefectCategory.values.byName(
      json['category'] as String? ?? 'crack',
    ),
    normalizedX: (json['normalizedX'] as num? ?? 0).toDouble(),
    normalizedY: (json['normalizedY'] as num? ?? 0).toDouble(),
    details: DefectDetails.fromJson(
      json['details'] as Map<String, dynamic>? ?? {},
    ),
  );
}

class DefectMarker extends StatelessWidget {
  const DefectMarker({super.key, required this.label, required this.category});

  final String label;
  final DefectCategory category;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Tooltip(
      message: category.label,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
