import 'dart:async';

class PersistState {
  PersistState({
    this.hasUnsavedChanges = false,
    this.persistInFlight = false,
    this.persistPending = false,
    this.persistEpoch = 0,
    this.didWarnUnsavedOnExit = false,
  });

  bool hasUnsavedChanges;
  Timer? persistDebounce;
  bool persistInFlight;
  bool persistPending;
  int persistEpoch;
  bool didWarnUnsavedOnExit;

  void dispose() {
    persistDebounce?.cancel();
    persistDebounce = null;
  }
}
