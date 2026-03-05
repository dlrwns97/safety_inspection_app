
import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/infrastructure/mappers/drawing_stroke_mapper.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';

void main() {
  group('DrawingStroke JSON compatibility', () {
    test('legacy payload without toolType falls back from style.kind', () {
      final legacyJson = <String, dynamic>{
        'id': 'legacy-1',
        'pageNumber': 2,
        'style': <String, dynamic>{
          'kind': 'highlighter',
          'variant': 'highlighter',
          'widthPx': 9,
          'argbColor': 0xFF00FF00,
          'opacity': 0.4,
        },
        'pointsNorm': const [
          [0.1, 0.2],
          [0.2, 0.3],
        ],
      };

      final stroke = DrawingStrokeMapper.fromJson(legacyJson);

      expect(stroke.toolType, DrawingTool.highlighter);
      expect(stroke.style.kind, StrokeToolKind.highlighter);
      expect(stroke.pageNumber, 2);
    });

    test('unknown toolType string falls back to style.kind mapping', () {
      final json = <String, dynamic>{
        'id': 'legacy-2',
        'pageNumber': 1,
        'toolType': 'unknown-legacy-value',
        'style': <String, dynamic>{
          'kind': 'shape',
          'variant': 'pen',
          'widthPx': 3,
          'argbColor': 0xFF000000,
          'opacity': 1.0,
        },
        'pointsNorm': const [
          [0.0, 0.0],
          [1.0, 1.0],
        ],
      };

      final stroke = DrawingStrokeMapper.fromJson(json);

      expect(stroke.toolType, DrawingTool.shape);
    });

    test('legacy erasedMask gets normalized to points length', () {
      final json = <String, dynamic>{
        'id': 'legacy-3',
        'pageNumber': 1,
        'style': <String, dynamic>{
          'kind': 'pen',
          'variant': 'pen',
          'widthPx': 3,
          'argbColor': 0xFF000000,
          'opacity': 1.0,
        },
        'pointsNorm': const [
          [0.0, 0.0],
          [0.1, 0.1],
          [0.2, 0.2],
          [0.3, 0.3],
        ],
        'erasedMask': const [1, 0],
      };

      final stroke = DrawingStrokeMapper.fromJson(json);

      expect(stroke.erasedMask, const [1, 0, 0, 0]);
      expect(stroke.erasedMaskAsBool(), const [true, false, false, false]);
    });

  });
}
