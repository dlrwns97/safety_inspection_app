enum DrawingHistoryOp { add, remove }

class DrawingHistoryActionPersisted {
  const DrawingHistoryActionPersisted({
    required this.op,
    required this.strokeId,
    this.strokeJson,
  });

  final DrawingHistoryOp op;
  final String strokeId;
  final Map<String, dynamic>? strokeJson;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'op': op.name, 'strokeId': strokeId};
    if (strokeJson != null) {
      json['stroke'] = strokeJson;
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
    final strokeId =
        json['strokeId']?.toString() ?? strokeJson?['id']?.toString() ?? '';
    return DrawingHistoryActionPersisted(
      op: op,
      strokeId: strokeId,
      strokeJson: strokeJson,
    );
  }
}
