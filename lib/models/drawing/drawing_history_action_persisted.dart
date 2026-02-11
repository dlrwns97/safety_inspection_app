enum DrawingHistoryOp { add, remove }

class DrawingHistoryActionPersisted {
  const DrawingHistoryActionPersisted({
    required this.op,
    required this.strokeId,
  });

  final DrawingHistoryOp op;
  final String strokeId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'op': op.name,
      'strokeId': strokeId,
    };
  }

  factory DrawingHistoryActionPersisted.fromJson(Map<String, dynamic> json) {
    final opName = json['op']?.toString();
    final op = DrawingHistoryOp.values.firstWhere(
      (value) => value.name == opName,
      orElse: () => DrawingHistoryOp.add,
    );
    return DrawingHistoryActionPersisted(
      op: op,
      strokeId: json['strokeId']?.toString() ?? '',
    );
  }
}
