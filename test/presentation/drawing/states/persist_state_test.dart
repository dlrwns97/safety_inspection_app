import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/presentation/drawing/states/persist_state.dart';

void main() {
  group('PersistState', () {
    test('has expected defaults', () {
      final state = PersistState();

      expect(state.hasUnsavedChanges, isFalse);
      expect(state.persistDebounce, isNull);
      expect(state.persistInFlight, isFalse);
      expect(state.persistPending, isFalse);
      expect(state.persistEpoch, 0);
      expect(state.didWarnUnsavedOnExit, isFalse);
    });

    test(
      'stores mutable persist flags and cancels debounce timer on dispose',
      () {
        final state = PersistState();
        final timer = Timer(const Duration(seconds: 5), () {});
        state.hasUnsavedChanges = true;
        state.persistDebounce = timer;
        state.persistInFlight = true;
        state.persistPending = true;
        state.persistEpoch = 3;
        state.didWarnUnsavedOnExit = true;

        expect(state.hasUnsavedChanges, isTrue);
        expect(state.persistDebounce, same(timer));
        expect(state.persistInFlight, isTrue);
        expect(state.persistPending, isTrue);
        expect(state.persistEpoch, 3);
        expect(state.didWarnUnsavedOnExit, isTrue);

        state.dispose();

        expect(timer.isActive, isFalse);
        expect(state.persistDebounce, isNull);
      },
    );
  });
}
