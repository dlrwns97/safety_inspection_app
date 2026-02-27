import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/models/drawing/text_box_data.dart';
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

      final stroke = DrawingStroke.fromJson(legacyJson);

      expect(stroke.toolType, DrawingTool.highlighter);
      expect(stroke.style.kind, StrokeToolKind.highlighter);
      expect(stroke.pageNumber, 2);
      expect(stroke.textBoxData, isNull);
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

      final stroke = DrawingStroke.fromJson(json);

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

      final stroke = DrawingStroke.fromJson(json);

      expect(stroke.erasedMask, const [1, 0, 0, 0]);
      expect(stroke.erasedMaskAsBool(), const [true, false, false, false]);
    });

    test('textBoxData with partial fields restores fallback values', () {
      final json = <String, dynamic>{
        'id': 'textbox-1',
        'pageNumber': 1,
        'toolType': 'textBox',
        'style': <String, dynamic>{
          'kind': 'textBox',
          'variant': 'pen',
          'widthPx': 1,
          'argbColor': 0xFF000000,
          'opacity': 1.0,
        },
        'pointsNorm': const [
          [0.2, 0.2],
          [0.5, 0.4],
        ],
        'textBoxData': <String, dynamic>{
          'text': 'hello',
        },
      };

      final stroke = DrawingStroke.fromJson(json);
      final data = stroke.textBoxData;

      expect(stroke.toolType, DrawingTool.textBox);
      expect(data, isNotNull);
      expect(data!.text, 'hello');
      expect(data.positionNorm, const Offset(0.0, 0.0));
      expect(data.sizeNorm, const Size(0.2, 0.08));
      expect(data.fontSize, 14.0);
      expect(data.argbColor, 0xFF000000);
      expect(data.textAlign, TextAlign.left);
    });
  });

  group('TextBoxData JSON compatibility', () {
    test('string numerics and unknown align fallback', () {
      final json = <String, dynamic>{
        'text': 123,
        'positionNorm': const ['0.25', '0.75'],
        'sizeNorm': const ['0.4', '0.1'],
        'fontSize': '18',
        'argbColor': '4278190080',
        'textAlign': 'not-valid-align',
      };

      final data = TextBoxData.fromJson(json);

      expect(data.text, '123');
      expect(data.positionNorm, const Offset(0.25, 0.75));
      expect(data.sizeNorm, const Size(0.4, 0.1));
      expect(data.fontSize, 18.0);
      expect(data.argbColor, 4278190080);
      expect(data.textAlign, TextAlign.left);
    });
  });
}
