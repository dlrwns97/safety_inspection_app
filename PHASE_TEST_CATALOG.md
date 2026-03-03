# Phase Test Catalog

## Phase 0 Required Tests

### Step 0-1
- `flutter test test/photo_path_ordering_test.dart`
- `flutter test`

### Step 0-2
- `flutter analyze` (warning 0)
- `flutter test`

### Step 0-3
- `flutter test test/smoke/scenario_id_smoke_test.dart`
- `flutter test`

## Scenario ID Mapping (Phase 0 Baseline)

- `H-01`: `test/smoke/scenario_id_smoke_test.dart` - "H-01 creates and reloads site metadata"
- `H-02`: `test/smoke/scenario_id_smoke_test.dart` - "H-02 trash -> restore -> permanent delete flow"
- `H-03`: `test/smoke/scenario_id_smoke_test.dart` - "H-03 restores persisted trash state after reload"
- `D-05`: `test/smoke/scenario_id_smoke_test.dart` - "D-05 equipment label rule keeps prefix+sequence order"
- `P-02`: `test/smoke/scenario_id_smoke_test.dart` - "P-02 deduplicates mixed legacy path formats"
