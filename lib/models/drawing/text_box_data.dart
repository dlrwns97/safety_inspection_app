import 'dart:ui';

double _asDouble(dynamic value, double fallback) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

int _asInt(dynamic value, int fallback) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

String _asString(dynamic value, String fallback) {
  if (value is String) {
    return value;
  }
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

class TextBoxData {
  const TextBoxData({
    required this.text,
    required this.positionNorm,
    required this.sizeNorm,
    this.fontSize = 14.0,
    this.argbColor = 0xFF000000,
    this.textAlign = TextAlign.left,
  });

  final String text;
  final Offset positionNorm;
  final Size sizeNorm;
  final double fontSize;
  final int argbColor;
  final TextAlign textAlign;

  TextBoxData copyWith({
    String? text,
    Offset? positionNorm,
    Size? sizeNorm,
    double? fontSize,
    int? argbColor,
    TextAlign? textAlign,
  }) {
    return TextBoxData(
      text: text ?? this.text,
      positionNorm: positionNorm ?? this.positionNorm,
      sizeNorm: sizeNorm ?? this.sizeNorm,
      fontSize: fontSize ?? this.fontSize,
      argbColor: argbColor ?? this.argbColor,
      textAlign: textAlign ?? this.textAlign,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'text': text,
      'positionNorm': <double>[positionNorm.dx, positionNorm.dy],
      'sizeNorm': <double>[sizeNorm.width, sizeNorm.height],
      'fontSize': fontSize,
      'argbColor': argbColor,
      'textAlign': textAlign.name,
    };
  }

  factory TextBoxData.fromJson(Map<String, dynamic> json) {
    final posRaw = json['positionNorm'];
    final sizeRaw = json['sizeNorm'];

    final posList = posRaw is List ? posRaw : const <dynamic>[];
    final sizeList = sizeRaw is List ? sizeRaw : const <dynamic>[];

    final alignmentName = _asString(json['textAlign'], TextAlign.left.name);
    final alignment = TextAlign.values.firstWhere(
      (value) => value.name == alignmentName,
      orElse: () => TextAlign.left,
    );

    return TextBoxData(
      text: _asString(json['text'], ''),
      positionNorm: Offset(
        _asDouble(posList.isNotEmpty ? posList[0] : null, 0.0),
        _asDouble(posList.length > 1 ? posList[1] : null, 0.0),
      ),
      sizeNorm: Size(
        _asDouble(sizeList.isNotEmpty ? sizeList[0] : null, 0.2),
        _asDouble(sizeList.length > 1 ? sizeList[1] : null, 0.08),
      ),
      fontSize: _asDouble(json['fontSize'], 14.0),
      argbColor: _asInt(json['argbColor'], 0xFF000000),
      textAlign: alignment,
    );
  }
}
