# Safety Inspection App Architecture Overview

## 1. 목적
이 문서는 현재 코드베이스의 DDD 기반 구조를 빠르게 파악하기 위한 개요 문서다.
핵심 목표는 다음 3가지다.

- 계층별 책임을 명확히 이해한다.
- 데이터/이벤트 흐름을 한 번에 따라간다.
- 신규 기능 추가 시 어디를 수정해야 하는지 빠르게 찾는다.

## 2. 레이어 구조
프로젝트는 아래 흐름으로 의존한다.

`domain <- application <- presentation/screens <- infrastructure`

- `domain`
  - 비즈니스 규칙(인터페이스/도메인 서비스)
  - 예: `lib/domain/site/repositories/site_repository.dart`
  - 예: `lib/domain/inspection/services/marker_label_domain_service.dart`
- `application`
  - 유스케이스 오케스트레이션
  - 예: `lib/application/site/use_cases/create_site_use_case.dart`
  - 예: `lib/application/inspection/use_cases/marker_tap_use_case.dart`
- `presentation`
  - 화면 상태/컨트롤러/ViewModel
  - 예: `lib/presentation/drawing/states/tool_state.dart`
  - 예: `lib/presentation/drawing/view_models/marker_side_panel_view_model.dart`
- `screens`
  - 실제 Flutter 위젯, 입력 처리, 화면 조립
  - 예: `lib/screens/drawing/drawing_screen.dart`
- `infrastructure`
  - 저장소 구현, 매퍼, 파일/SharedPreferences I/O
  - 예: `lib/infrastructure/persistence/shared_prefs/site_prefs_repository.dart`
  - 예: `lib/infrastructure/mappers/site_mapper.dart`

## 3. Drawing 모듈 핵심 컴포넌트

- 진입점: `lib/screens/drawing/drawing_screen.dart`
- 상태:
  - `DrawingSessionState`, `ToolState`, `GestureState`, `HistoryState`, `PersistState`
  - `DrawingStateFacade`를 통해 묶어서 사용
- 캔버스 렌더:
  - `DrawingCanvasWidget`
  - `StrokeCacheManager` (페이지별 캐시)
  - `temp_polyline_painter.dart` (프리뷰/설정 팝업 렌더)
- 히스토리:
  - `history_manager.dart`
  - `history_commands.dart`
- PDF/뷰포트:
  - `PdfViewportController`
  - `drawing_screen_move_actions.part.dart`
- 마커:
  - `marker_tap_use_case.dart`, `create_defect_marker_use_case.dart`
  - `marker_side_panel_view_model.dart`

## 4. 대표 데이터 흐름

### 4.1 현장 생성(Home)
1. `HomeScreen` 입력 수집
2. `CreateSiteUseCase` 호출
3. `SiteRepository` 인터페이스 사용
4. `SitePrefsRepository`가 실제 저장
5. 결과 `Site` 반환 및 UI 반영

### 4.2 결함/장비 마커 입력(Drawing)
1. 화면 탭 이벤트 -> `drawing_screen_*` 파트에서 좌표/모드 해석
2. `MarkerTapUseCase`에서 분기 결정
3. 필요 시 `CreateDefectMarkerUseCase` 또는 장비 생성 흐름 호출
4. `Site` 불변 업데이트 반영
5. 사이드패널/마커 레이어 재렌더

### 4.3 드로잉 저장/복원
1. 화면 변경 -> persist debounce 트리거
2. `PersistSiteDrawingUseCase` 호출
3. `DrawingRepository`를 통해 JSON 저장
4. 재진입 시 `LoadSiteDrawingUseCase`로 복원

## 5. 테스트 구성

- Domain: `test/domain/*`
- Application: `test/application/*`
- Presentation state/viewmodel: `test/presentation/*`
- 안정성/좌표/직렬화: `test/drawing_*`
- 스모크 시나리오: `test/smoke/scenario_id_smoke_test.dart`

## 6. 유지보수 포인트

- DrawingScreen은 part 파일로 분리된 구조이므로, 기능별 파트에만 수정 범위를 최소화한다.
- 저장 포맷 변경 시 반드시 mapper + compat test를 같이 수정한다.
- 성능 이슈는 `StrokeCacheManager`/포인터 핫패스부터 먼저 점검한다.
