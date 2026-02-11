enum DrawingHistoryOp { add, remove, replace }

class DrawingHistoryActionPersisted {
  const DrawingHistoryActionPersisted({
    required this.op,
    required this.strokeId,
    this.strokeJson,
    this.strokesJson,
    this.removedStrokesJson,
    this.addedStrokesJson,
  });

  final DrawingHistoryOp op;
  final String strokeId;
  final Map<String, dynamic>? strokeJson;
  final List<Map<String, dynamic>>? strokesJson;
  final List<Map<String, dynamic>>? removedStrokesJson;
  final List<Map<String, dynamic>>? addedStrokesJson;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'op': op.name, 'strokeId': strokeId};
    if (strokeJson != null) {
      json['stroke'] = strokeJson;
    }
    if (strokesJson != null) {
      json['strokes'] = strokesJson;
    }
    if (removedStrokesJson != null) {
      json['removed'] = removedStrokesJson;
    }
    if (addedStrokesJson != null) {
      json['added'] = addedStrokesJson;
    }
    return json;
  }

  factory DrawingHistoryActionPersisted.fromJson(Map<String, dynamic> json) {
    final opName = json['op']?.toString();
    final op = DrawingHistoryOp.values.firstWhere(
      (value) => value.name == opName,
      orElse: () => DrawingHistoryOp.add,
    );
    final strokeJson = (json['stroke'] as Map?)?.cast<String, dynamic>();
    final strokesJson = (json['strokes'] as List?)
        ?.whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
    final removedStrokesJson = (json['removed'] as List?)
        ?.whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
    final addedStrokesJson = (json['added'] as List?)
        ?.whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
    final strokeId =
        json['strokeId']?.toString() ?? strokeJson?['id']?.toString() ?? '';
    return DrawingHistoryActionPersisted(
      op: op,
      strokeId: strokeId,
      strokeJson: strokeJson,
      strokesJson: strokesJson,
      removedStrokesJson: removedStrokesJson,
      addedStrokesJson: addedStrokesJson,
    );
  }
}
