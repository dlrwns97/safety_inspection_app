# DDD 리팩토링 2막 로드맵

작성일: 2026-05-06
기준 브랜치: `integrate/rollback-temp-codex-local`
기준 커밋: `0115072 Phase7-Step7-3 docs onboarding complete and roadmap v9 update`

## 0. 이 문서의 목적

기존 `DDD_리팩토링_로드맵_업데이트_v9.md`는 Phase 0~7까지의 1차 DDD 이관 기록이다.
이 문서는 1차 이관 이후의 다음 작업을 새 판으로 정리한 실행용 로드맵이다.

목표는 단순히 파일을 더 쪼개는 것이 아니라, 다음 3가지를 안정적으로 달성하는 것이다.

1. 기존 기능 회귀 없이 품질 부채를 줄인다.
2. DrawingScreen 중심의 남은 복잡도를 더 작은 책임 단위로 나눈다.
3. 새 기능을 넣을 때 계층 규칙과 테스트 흐름을 자연스럽게 지키는 구조로 만든다.

## 1. 현재 기준선

### 1-1. 완료 상태

- `Phase 0~7` 완료
- Repository 인터페이스, UseCase, Mapper, Domain Service, ViewModel 1차 도입 완료
- DrawingScreen 1차 분해 완료
- 문서화 완료
  - `docs/architecture-overview.md`
  - `docs/layer-rules.md`
  - `docs/new-feature-guide.md`

### 1-2. 최신 자동 검증

- `flutter test`: 100개 테스트 통과
- `flutter analyze lib`: No issues found (`Step 8-3` 반영 후)

### 1-3. 코드 볼륨

- `lib`: 168개 파일
- `test`: 19개 파일

### 1-4. 고복잡도 파일 Top 20

1. `lib/screens/drawing/drawing_screen_logic.part.dart` (1,972)
2. `lib/screens/drawing/drawing_screen_ui.part.dart` (792)
3. `lib/screens/drawing/drawing_screen_move_actions.part.dart` (792)
4. `lib/screens/drawing/drawing_screen.dart` (790)
5. `lib/screens/drawing/drawing_screen_ui_tool_popovers.part.dart` (718)
6. `lib/screens/home/home_screen.dart` (696)
7. `lib/screens/drawing/drawing_screen_pointer_input.part.dart` (682)
8. `lib/screens/drawing/widgets/color_picker_dialog.dart` (664)
9. `lib/screens/drawing/drawing_screen_tooling.part.dart` (586)
10. `lib/screens/drawing/dialogs/defect_details_dialog.dart` (508)
11. `lib/application/inspection/use_cases/marker_tap_use_case.dart` (497)
12. `lib/screens/drawing/widgets/side_panel/marker_side_panel.dart` (420)
13. `lib/screens/drawing/engines/shape_manipulator.dart` (411)
14. `lib/presentation/drawing/view_models/marker_side_panel_view_model.dart` (399)
15. `lib/screens/drawing/dialogs/equipment_details_dialog.dart` (388)
16. `lib/screens/drawing/flows/marker_tap_flow.dart` (387)
17. `lib/screens/drawing/drawing_screen_persistence.part.dart` (382)
18. `lib/screens/drawing/dialogs/rebar_spacing_dialog.dart` (366)
19. `lib/screens/drawing/widgets/highlighter_settings_popup.dart` (350)
20. `lib/screens/drawing/widgets/pen_settings_popup.dart` (339)

### 1-5. 현재 품질 부채

- Analyzer info 0건
  - `constant_identifier_names`
  - `deprecated_member_use`
  - `unnecessary_this`
  - `use_super_parameters`
  - `unnecessary_underscores`
  - `curly_braces_in_flow_control_structures`
  - `prefer_function_declarations_over_variables`
  - `sort_child_properties_last`
- DrawingScreen 관련 part 파일이 아직 상위 복잡도 대부분을 차지함
- Color API, Material API 변경 대응이 남아 있음
- Dialog와 Tool Popup이 화면/상태/검증 책임을 일부 섞어 갖고 있음
- `marker_tap_use_case.dart`가 dialog callback을 다수 직접 받아 Application 계층 책임이 무거움
- `home_screen.dart`가 site list, PDF 선택, orphan photo scan UI/복구 흐름을 함께 갖고 있음
- `marker_side_panel_view_model.dart` 안의 `EquipmentDetailViewModel`이 커져 장비별 표시 모델 분리가 필요함

### 1-6. 외부 검토 반영 메모

- 현재 실측 기준 `drawing_screen_logic.part.dart`는 1,972줄, `drawing_screen_pointer_input.part.dart`는 682줄로 이 문서의 기준선과 일치한다.
- 다만 외부 검토에서 지적한 누락 항목은 타당하므로 아래 Phase에 반영한다.
- 보강 항목:
  - `marker_tap_use_case.dart` 분해 계획 추가
  - `home_screen.dart` 분리 우선순위 상향
  - `EquipmentDetailViewModel` 분리 계획 추가
  - Home/orphan scan 자동 테스트 확장 추가

## 2. 작업 규칙

이 문서는 기존 로드맵 12번 규칙을 계속 따른다.

1. 진행 단위는 `Step` 기준으로 고정한다.
2. 매 Step마다 구현, 자동 검증, 수동 검증 요청, 사용자 결과 확인 순서로 진행한다.
3. Step 완료 전에는 다음 Step으로 넘어가지 않는다.
4. Phase 종료 시 이 문서를 갱신한다.
5. 계획 외 기능 수정은 `10. 로드맵 외 기능 수정 로그`에 따로 남긴다.
6. 커밋/푸시는 Codex가 자동 수행한다.
7. 커밋 전에는 자동생성 plugin 파일을 항상 정리한다.

커밋 전 정리 대상:

- `linux/flutter/generated_plugin_registrant.cc`
- `linux/flutter/generated_plugins.cmake`
- `macos/Flutter/GeneratedPluginRegistrant.swift`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugins.cmake`

## 3. 계층 규칙

기준 문서:

- `docs/architecture-overview.md`
- `docs/layer-rules.md`
- `docs/new-feature-guide.md`

핵심 원칙:

1. `domain`은 Flutter, screens, infrastructure를 모른다.
2. `application`은 UseCase와 트랜잭션 경계를 담당한다.
3. `presentation`은 화면 상태, ViewModel, 입력 정책을 담당한다.
4. `screens`는 위젯 렌더링과 이벤트 연결에 집중한다.
5. 파일 I/O, SharedPreferences, mapper는 `infrastructure`로 둔다.

## 4. Phase 8: Analyzer Info Zero 작전

목표:

- `flutter analyze lib`의 info 71건을 0건에 가깝게 줄인다.
- 동작 변경 없이 스타일/Deprecated API/언어 업데이트만 처리한다.
- 이 Phase는 감 다시 잡기용으로도 좋다. 리스크 낮고 보상 확실함.

진행 상태:

- `Step 8-1`: 완료
- `Step 8-2`: 완료
- `Step 8-3`: 완료
- `Phase 8`: 완료

### Step 8-1. 상수/스타일 Lint 정리

상태: 완료

대상:

- `lib/screens/drawing/drawing_constants.dart`
- `lib/screens/drawing/drawing_screen_logic.part.dart`
- `lib/screens/drawing/drawing_screen_pointer_input.part.dart`
- `lib/screens/drawing/drawing_screen_persistence.part.dart`
- `lib/screens/drawing/drawing_screen_scale_prefs.part.dart`

작업:

- UpperCamelCase 상수명을 lowerCamelCase로 전환
- 불필요한 `this.` 제거
- 단일 줄 `if`에 중괄호 적용
- 함수 변수 선언을 함수 선언으로 전환

수정 파일:

- `lib/screens/drawing/drawing_constants.dart`
- `lib/screens/drawing/drawing_screen_detail_dialogs.part.dart`
- `lib/screens/drawing/drawing_screen_logic.part.dart`
- `lib/screens/drawing/drawing_screen_marker_actions.part.dart`
- `lib/screens/drawing/drawing_screen_move_actions.part.dart`
- `lib/screens/drawing/drawing_screen_persistence.part.dart`
- `lib/screens/drawing/drawing_screen_pointer_input.part.dart`
- `lib/screens/drawing/drawing_screen_scale_prefs.part.dart`
- `lib/screens/drawing/drawing_screen_ui.part.dart`
- `lib/screens/drawing/flows/drawing_lookup_helpers.dart`
- `lib/screens/drawing/widgets/drawing_scaffold_body.dart`
- `lib/screens/drawing/widgets/pdf_drawing_view.dart`

검증:

- `flutter analyze lib`: info 71건 -> 44건, warning/error 없음
- `flutter test`: 100개 all pass

수동 확인:

- `D-01`: 자유선/형광펜 기본 그리기 all pass
- `D-06`: 도형 생성/수정/삭제 all pass
- `D-07`: 직교/스냅/비율 잠금 설정 all pass

### Step 8-2. Deprecated Color/Material API 정리

상태: 완료

대상:

- `lib/screens/drawing/drawing_screen_tooling.part.dart`
- `lib/screens/drawing/drawing_screen_ui_tool_popovers.part.dart`
- `lib/screens/drawing/widgets/color_picker_dialog.dart`
- `lib/screens/drawing/widgets/eraser_settings_popup.dart`
- `lib/screens/drawing/widgets/side_panel/marker_side_panel.dart`

작업:

- `Color.value`를 `toARGB32()` 또는 컴포넌트 접근 방식으로 전환
- `red/green/blue/opacity` deprecated 접근 제거
- `withOpacity`를 `withValues`로 전환
- `MaterialStateProperty`를 `WidgetStateProperty`로 전환
- `surfaceVariant`를 `surfaceContainerHighest`로 전환

수정 파일:

- `lib/screens/drawing/drawing_screen_tooling.part.dart`
- `lib/screens/drawing/drawing_screen_ui_tool_popovers.part.dart`
- `lib/screens/drawing/widgets/color_picker_dialog.dart`
- `lib/screens/drawing/widgets/eraser_settings_popup.dart`
- `lib/screens/drawing/widgets/side_panel/marker_side_panel.dart`

검증:

- `flutter analyze lib`: info 44건 -> 12건, warning/error 없음
- `flutter test`: 100개 all pass

수동 확인:

- `D-01`: 펜/형광펜 색상 변경 all pass
- `D-03`: 지우개 크기/동작 all pass
- `D-04`: 결함 마커 표시 색상/라벨 all pass
- `D-05`: 장비 마커 표시 색상/라벨 all pass

### Step 8-3. 생성자/위젯 스타일 정리

상태: 완료

대상:

- `lib/screens/drawing/history/history_commands.dart`
- `lib/screens/drawing/drawing_screen_ui.part.dart`
- `lib/screens/drawing/widgets/side_panel/marker_list.dart`
- `lib/screens/drawing/widgets/side_panel/marker_side_panel_list_section.dart`
- `lib/screens/drawing/drawing_screen_detail_dialogs.part.dart`

작업:

- `use_super_parameters` 반영
- `child` 인자 위치 정리
- 불필요한 다중 underscore 제거

수정 파일:

- `lib/screens/drawing/history/history_commands.dart`
- `lib/screens/drawing/drawing_screen_ui.part.dart`
- `lib/screens/drawing/drawing_screen_detail_dialogs.part.dart`
- `lib/screens/drawing/widgets/side_panel/marker_list.dart`
- `lib/screens/drawing/widgets/side_panel/marker_side_panel_list_section.dart`

검증:

- `flutter analyze lib`: No issues found
- `flutter test`: 100개 all pass

수동 확인:

- `D-04`: 결함 리스트/상세 진입 all pass
- `D-05`: 장비 리스트/상세 진입 all pass
- `D-08`: 저장 후 재진입 all pass

완료 기준:

- `flutter analyze lib`: No issues found
- `flutter test`: 전체 통과
- 사용자 수동 확인 all pass

## 5. Phase 9: DrawingScreen 2차 분해

목표:

- DrawingScreen 관련 part 파일의 책임을 더 작은 coordinator/service/widget로 분리한다.
- 한 번에 큰 수술하지 않고 입력, 페이지, 도구, 저장 순서로 나눈다.

### Step 9-1. Shape Interaction Coordinator 분리

대상:

- `drawing_screen_logic.part.dart`
- `drawing_screen_pointer_input.part.dart`
- `shape_manipulator.dart`

작업:

- 도형 hit test, 선택, 이동, resize, 비율 잠금 적용 흐름을 coordinator로 분리
- DrawingScreen은 이벤트를 넘기고 결과만 반영하도록 축소

검증:

- `flutter test test/drawing_coordinate_accuracy_test.dart`
- `flutter test`

수동 확인:

- `D-06`: 도형 생성/이동/리사이즈/비율 잠금
- `D-07`: 스냅/직교 조합

### Step 9-2. Page Navigation/Pdf Viewport 흐름 분리

대상:

- `drawing_screen_move_actions.part.dart`
- `drawing_screen_persistence.part.dart`
- `drawing_screen_logic.part.dart`

작업:

- 페이지 이동, 현재 페이지 복원, PDF page size cache 흐름을 별도 controller로 분리
- 강종 복원과 일반 뒤로가기 복원 정책을 명시화

검증:

- `flutter test test/application/drawing/use_cases/pdf_page_size_cache_use_cases_test.dart`
- `flutter test test/application/drawing/use_cases/drawing_persistence_use_cases_test.dart`
- `flutter test`

수동 확인:

- `D-08`: 강종 후 마지막 페이지 복원
- `D-09`: 다중 페이지 드로잉 복원
- `D-10`: PDF 교체 후 페이지 이동/저장/재진입

### Step 9-3. Tool Settings Controller 분리

대상:

- `drawing_screen_tooling.part.dart`
- `drawing_screen_ui_tool_popovers.part.dart`
- `pen_settings_popup.dart`
- `highlighter_settings_popup.dart`
- `eraser_settings_popup.dart`

작업:

- 펜/형광펜/도형/지우개 설정 상태를 controller 또는 ViewModel로 분리
- 자유선과 형광펜의 독립 설정 정책을 테스트 가능하게 고정

검증:

- 신규 unit test 추가
- `flutter test`

수동 확인:

- `D-01`: 펜/형광펜 색상/두께/투명도
- `D-03`: 지우개
- `D-07`: 직교/스냅 설정 독립성

### Step 9-4. DrawingScreen Shell 경량화

대상:

- `drawing_screen.dart`
- `drawing_screen_ui.part.dart`
- `drawing_screen_logic.part.dart`

작업:

- DrawingScreen 본체는 상태 생성, 의존성 연결, 생명주기 관리만 담당하게 축소
- UI 조립과 이벤트 라우팅을 분리한 뒤 파일 Top 20 재측정

검증:

- `flutter analyze lib`
- `flutter test`

수동 확인:

- `D-01` ~ `D-10` 중 변경 영향권 전체

완료 기준:

- `drawing_screen_logic.part.dart`: 1,500줄 이하 목표
- `drawing_screen.dart`: 650줄 이하 목표
- 전체 테스트 통과

### Step 9-5. Marker Tap UseCase 책임 재분리

대상:

- `lib/application/inspection/use_cases/marker_tap_use_case.dart`
- `lib/screens/drawing/flows/marker_tap_flow.dart`
- `lib/application/inspection/use_cases/create_defect_marker_use_case.dart`
- `lib/application/inspection/use_cases/create_equipment_updated_site_use_case.dart`

작업:

- `MarkerTapUseCase`가 직접 받는 dialog callback 묶음을 입력 포트 또는 request handler로 정리
- 결함 생성, 일반 장비 생성, 철탐/침하 등 특수 장비 생성 흐름을 더 작은 Application 서비스로 분리
- Application 계층이 UI dialog 자체를 알지 않고 "필요한 입력 요청"과 "결과 반영"만 다루도록 경계 명확화
- `marker_tap_flow.dart`는 화면 callback을 Application 입력 포트에 연결하는 adapter 역할로 축소

검증:

- `flutter test test/application/inspection/use_cases/marker_interaction_use_cases_test.dart`
- `flutter test test/domain/inspection/services/marker_label_domain_service_test.dart`
- `flutter test`

수동 확인:

- `D-04`: 결함 마커 생성/수정/삭제/번호 재정렬
- `D-05`: 장비 마커 생성/수정/삭제/번호 재정렬

완료 기준:

- `marker_tap_use_case.dart`: 350줄 이하 목표
- dialog callback 파라미터 묶음이 adapter 또는 request handler로 이동
- 기존 마커 생성/라벨/취소 동작 회귀 없음

## 6. Phase 10: Dialog/Form 구조 정리

목표:

- 결함/장비 입력 Dialog의 UI, 검증, 데이터 변환 책임을 분리한다.
- 장비별 특수 입력 규칙을 Application Service 또는 Presentation ViewModel로 이동한다.
- Home 화면의 orphan scan/복구 UI도 이 Phase에서 먼저 분리해 화면 책임을 줄인다.

### Step 10-1. Defect Details Dialog 분리

대상:

- `defect_details_dialog.dart`
- `dialog_field_builders.dart`
- `defect_photo_store.dart`

작업:

- 사진 표시/첨부/삭제 영역을 별도 widget 또는 controller로 분리
- 입력 검증과 저장 payload 생성을 화면 밖으로 이동

검증:

- `flutter test`

수동 확인:

- `D-04`: 결함 생성/수정/삭제/번호 재정렬
- `P-01`: 사진 추가/삭제
- `P-02`: 중복 경로 처리

### Step 10-2. Equipment Details Dialog 분리

대상:

- `equipment_details_dialog.dart`
- `rebar_spacing_dialog.dart`
- 기타 장비별 dialog
- `lib/presentation/drawing/view_models/marker_side_panel_view_model.dart`

작업:

- 철탐, 반발경도, 코어, 탄산화 등 장비별 입력 모델 정리
- 철탐 다중 행 추가/삭제 정책 테스트 보강
- `EquipmentDetailViewModel`을 장비 표시 모델/라벨 모델/상세 payload 모델로 나누는 방안 검토 후 분리
- 사이드패널 표시용 ViewModel과 Dialog 입력 모델이 서로 과하게 의존하지 않도록 경계 정리

검증:

- `flutter test test/application/inspection/services/equipment_input_validation_service_test.dart`
- `flutter test test/marker_presenters_label_test.dart`
- `flutter test`

수동 확인:

- `D-05`: 장비 생성/수정/삭제/번호 재정렬

### Step 10-3. Color Picker/Dialog 공통 UI 정리

대상:

- `color_picker_dialog.dart`
- Tool popup 계열

작업:

- 컬러 선택 계산 로직을 UI 밖으로 분리
- 팝업 공통 스타일과 입력 위젯 중복 제거

검증:

- 신규 unit test 추가
- `flutter test`

수동 확인:

- `D-01`: 색상/투명도 변경
- `D-06`: 도형 색상 변경

### Step 10-4. HomeScreen Orphan Scan UI 분리

대상:

- `lib/screens/home/home_screen.dart`
- `lib/screens/home/site_photo_orphan_scanner.dart`
- 신규 Home 하위 widget/controller 파일

작업:

- `_OrphanScanResultList`와 `_OrphanScanResultListState`를 별도 widget 파일로 분리
- orphan photo restore/cleanup 흐름을 화면 본체 밖 controller 또는 flow로 이동
- `HomeScreen`은 현장 목록, 주요 버튼, dialog 호출 조립에 집중하도록 축소
- PDF 선택/저장 흐름과 orphan scan 흐름의 책임 경계를 정리

검증:

- `flutter test test/smoke/scenario_id_smoke_test.dart`
- `flutter test`

수동 확인:

- `H-01`: 현장 생성 후 목록 재로드
- `H-02`: 휴지통 이동/복원/영구삭제
- `H-03`: 앱 재진입 후 휴지통 상태 유지
- `P-03`: orphan photo scan/restore/cleanup

완료 기준:

- `home_screen.dart`: 550줄 이하 목표
- orphan scan UI와 복구/정리 흐름이 HomeScreen 본체에서 분리됨

## 7. Phase 11: 테스트/회귀 방어선 확장

목표:

- 수동 테스트 부담을 줄이기 위해 핵심 회귀를 자동화한다.
- 특히 이전에 실제로 터졌던 버그를 테스트로 고정한다.

### Step 11-1. Drawing Tool Regression Test 확장

대상:

- `test/drawing_history_stress_test.dart`
- 신규 drawing tool test

작업:

- 도형 생성 후 펜/형광펜 입력 재개
- 펜/형광펜 직교/스냅 설정 독립성
- 도형 비율 잠금 resize

수동 확인:

- `D-01`, `D-06`, `D-07`

### Step 11-2. Marker Label Regression Test 확장

대상:

- `marker_presenters_label_test.dart`
- `marker_label_domain_service_test.dart`

작업:

- 결함 전체 카테고리 번호 재정렬
- 철탐 그룹 range 삭제 후 재정렬
- 장비별 예외 라벨 정책 고정

수동 확인:

- `D-04`, `D-05`

### Step 11-3. Persistence/Cold Start Test 확장

대상:

- `drawing_persistence_use_cases_test.dart`
- `scenario_id_smoke_test.dart`

작업:

- 마지막 페이지 저장/복원 정책 테스트 강화
- 10페이지 이상 PDF 시나리오 모델 테스트 추가

수동 확인:

- `D-08`, `D-09`, `D-10`

### Step 11-4. Home/Orphan Scan Regression Test 확장

대상:

- `test/smoke/scenario_id_smoke_test.dart`
- 신규 Home/orphan scan 단위 테스트

작업:

- `H-01`, `H-02`, `H-03` 시나리오 자동 테스트 보강
- orphan photo scan 결과 정렬/복구/cleanup 정책 테스트 추가
- HomeScreen 분리 후 controller/flow 단위 테스트 가능 지점 확보

수동 확인:

- `H-01`, `H-02`, `H-03`, `P-03`

## 8. Phase 12: 성능과 유지보수성

목표:

- 큰 PDF, 다중 페이지, 장시간 undo/redo 상황에서 체감 안정성을 유지한다.
- 병목을 추측하지 않고 측정 가능한 지점부터 정리한다.

### Step 12-1. Stroke Cache 계측 포인트 정리

작업:

- cache hit/miss, dirty rebuild, page transition 시점을 verbose logger로 추적 가능하게 정리
- 기본 실행에서는 로그가 조용해야 함

수동 확인:

- `D-09`: 다중 페이지 왕복
- `P-03`: 사진/드로잉 많은 현장 진입

### Step 12-2. Undo/Redo 메모리 정책 정리

작업:

- history limit, command payload 크기, 페이지별 isolation 규칙 문서화
- stress test 보강

수동 확인:

- undo/redo 100회 이상 반복

### Step 12-3. Home/Project 목록 성능 정리

작업:

- Phase 10에서 분리된 Home/orphan scan 구조를 기준으로 site list load 병목 점검
- orphan photo scan, trash restore, site list load의 체감 지연 지점 계측
- 필요 시 목록 렌더링과 scan 실행 타이밍을 분리

수동 확인:

- `H-01`, `H-02`, `H-03`, `P-03`

## 9. 수동 테스트 시나리오 색인

- `H-01`: 현장 생성 후 목록 재로드
- `H-02`: 휴지통 이동/복원/영구삭제
- `H-03`: 앱 재진입 후 휴지통 상태 유지
- `D-01`: 자유선/형광펜 그리기
- `D-02`: PDF 등록
- `D-03`: 지우개
- `D-04`: 결함 마커 생성/수정/삭제/번호 재정렬
- `D-05`: 장비 마커 생성/수정/삭제/번호 재정렬
- `D-06`: 도형 생성/수정/삭제
- `D-07`: 직교/스냅/비율 잠금
- `D-08`: 저장 후 재진입, 강종 후 마지막 페이지 복원
- `D-09`: 10페이지 이상 PDF 페이지 왕복
- `D-10`: PDF 교체 후 페이지 이동/마커/저장/재진입
- `P-01`: 사진 추가/삭제
- `P-02`: 사진 경로 중복 처리
- `P-03`: orphan photo scan/restore/cleanup

## 10. 로드맵 외 기능 수정 로그

계획 외 버그 수정이나 사용자 요청 기능은 여기에 날짜별로 기록한다.

### 템플릿

- 날짜:
- 상황:
- 수정 내용:
- 관련 파일:
- 자동 검증:
- 수동 검증:

## 11. 바로 다음 액션

추천 시작점:

1. `Phase 9 / Step 9-1`부터 시작한다.
2. Shape Interaction Coordinator를 분리해 DrawingScreen 2차 분해를 시작한다.
3. Step 단위로 테스트와 수동 확인을 반복한다.
4. DrawingScreen 관련 part 파일의 책임과 줄 수를 계속 줄인다.

이 순서가 좋은 이유:

- 현재 테스트는 안정적이다.
- analyzer info는 명확하고 작게 쪼갤 수 있다.
- 큰 리팩토링 전에 deprecated API와 스타일 잡음을 줄이면 다음 변경 diff가 훨씬 읽기 쉬워진다.
