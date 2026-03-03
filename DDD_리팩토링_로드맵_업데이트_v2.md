# DDD 리팩토링 로드맵 v2 (업데이트: 2026-03-03, Phase 0 완료)

## 0. 문서 목적과 사용법
이 문서는 현재 `safety_inspection_app` 코드베이스를 기준으로, 기능 회귀 없이 DDD 구조로 단계적으로 이관하기 위한 실행 문서다.

사용 원칙:
1. 요약이 아니라 작업 지시서로 사용한다.
2. 각 Step 종료 시 자동 검증 + 수동 검증을 반드시 수행한다.
3. 실패 시 바로 다음 Step으로 넘어가지 않고, 해당 Step에서 롤백 또는 수정 후 재검증한다.
4. Phase 종료 검증뿐 아니라 Step 종료 검증을 강제한다.

---

## 0-1. 진행 현황 (v2)
- 완료 Phase: `Phase 0` (`Step 0-1`, `Step 0-2`, `Step 0-3`)
- 자동 검증 결과
  - `flutter test test/photo_path_ordering_test.dart`: 통과
  - `flutter test test/smoke/scenario_id_smoke_test.dart`: 통과
  - `flutter test`: 전체 통과 (26/26)
  - `flutter analyze`: warning 0, info 86
- 이번 버전 산출물
  - 경로 정규화 보강 (`photoReferenceKey`) + legacy path 회귀 테스트 추가
  - drawing 경고(미사용 멤버) 제거로 warning 11 -> 0 달성
  - 시나리오 ID 기반 smoke 스위트 추가 (`H-01`, `H-02`, `H-03`, `D-05`, `P-02`)
  - Phase 테스트 카탈로그 문서 추가 (`PHASE_TEST_CATALOG.md`)
- 다음 시작점
  - `Phase 1 - Step 1-1`: Domain Repository 인터페이스 정의

---

## 1. 현재 코드 스냅샷 (실측 기준: 2026-03-03)

### 1-1. 코드 볼륨
- `lib/` 총 112개 파일, 24,974줄
- `lib/screens/` 95개 파일, 22,745줄
- `lib/screens/drawing/` 84개 파일, 21,371줄
- 드로잉 핵심 4파일 합계 8,826줄
  - `drawing_screen.dart`: 1,858
  - `drawing_screen_logic.part.dart`: 4,658
  - `drawing_screen_ui.part.dart`: 2,201
  - `drawing_screen_scale_prefs.part.dart`: 109

### 1-2. 고복잡도 파일 Top 15 (줄 수 기준)
1. `lib/screens/drawing/drawing_screen_logic.part.dart` (4,658)
2. `lib/screens/drawing/drawing_screen_ui.part.dart` (2,201)
3. `lib/screens/drawing/drawing_screen.dart` (1,858)
4. `lib/screens/drawing/dialogs/defect_details_dialog.dart` (766)
5. `lib/screens/home/home_screen.dart` (737)
6. `lib/screens/drawing/widgets/color_picker_dialog.dart` (725)
7. `lib/screens/drawing/widgets/side_panel/marker_side_panel.dart` (712)
8. `lib/screens/drawing/flows/marker_tap_flow.dart` (479)
9. `lib/widgets/drawing/temp_polyline_painter.dart` (460)
10. `lib/screens/drawing/dialogs/equipment_details_dialog.dart` (433)
11. `lib/screens/drawing/dialogs/rebar_spacing_dialog.dart` (380)
12. `lib/screens/drawing/widgets/highlighter_settings_popup.dart` (368)
13. `lib/screens/drawing/widgets/pen_settings_popup.dart` (358)
14. `lib/models/drawing/drawing_stroke.dart` (343)
15. `lib/screens/drawing/history/history_commands.dart` (333)

### 1-3. 결합도/경계 위반
- Import 결합도
  - `screens -> screens`: 135
  - `screens -> models`: 100
  - `models -> screens`: 1
- 명시적 경계 위반
  - `lib/models/drawing/drawing_stroke.dart`가 `screens/drawing/drawing_types.dart`에 의존
  - `lib/models/drawing_enums.dart`가 `constants/strings_ko.dart`에 의존
- UI 외부 계층의 UI/표현 혼합
  - 라벨/표시 규칙이 `flows/marker_presenters.dart`와 `drawing_enums.dart`에 혼재

### 1-4. I/O 책임 분산 상태
- 사이트 메타 저장: `lib/models/site_storage.dart` (`SharedPreferences`)
- Home wrapper: `lib/screens/home/home_storage.dart`
- 드로잉 저장: `lib/screens/drawing/persistence/drawing_persistence_store.dart` (JSON file)
- 결함 사진 저장: `lib/screens/drawing/attachments/defect_photo_store.dart`
- 홈 화면에서 파일/디렉토리 직접 접근:
  - `lib/screens/home/home_screen.dart`
  - `lib/screens/home/site_photo_orphan_scanner.dart`
- 드로잉 화면에서 `SharedPreferences` 직접 접근:
  - `drawing_screen.dart`
  - `drawing_screen_logic.part.dart`
  - `drawing_screen_scale_prefs.part.dart`

### 1-5. 품질 베이스라인
- `flutter test`: 18개 중 1개 실패
  - 실패: `test/photo_path_ordering_test.dart` case D
  - 현상: `C:\a\2.jpg`와 `/a/2.jpg`가 동등 경로로 취급되지 않아 중복 삽입
- `flutter analyze`: 111 이슈
  - warning 11
  - info 100
  - 주요: `deprecated_member_use`, `unused_field`, `unused_element`, `constant_identifier_names`

---

## 2. 목표 아키텍처 (DDD + Clean 경계)

### 2-1. 레이어 정의
- Domain
  - 엔티티, 값객체, 도메인 서비스, 도메인 리포지토리 인터페이스
  - Flutter/UI/파일I/O 의존 금지
- Application
  - UseCase, 트랜잭션 경계, 정책 조합
  - Domain 인터페이스 사용
- Infrastructure
  - 파일/SharedPreferences/PDF/Photo 저장 구현체
  - Domain/Application 인터페이스 구현
- Presentation
  - Flutter 위젯, ViewState, Input Adapter
  - UseCase 호출과 결과 반영만 담당

### 2-2. 의존 규칙
1. `presentation -> application -> domain`
2. `infrastructure -> domain` (필요 시 `application` DTO 참조 허용)
3. `domain -> (none)` (Flutter, screens, constants 문자열 금지)
4. 화면 파일에서 `dart:io`, `SharedPreferences`, `path_provider` 직접 호출 금지

### 2-3. 권장 폴더 청사진
```text
lib/
  domain/
    site/
      entities/
      repositories/
      services/
    drawing/
      entities/
      repositories/
      services/
    inspection/
      entities/
      repositories/
      services/
  application/
    site/
      use_cases/
    drawing/
      use_cases/
    inspection/
      use_cases/
  infrastructure/
    persistence/
      shared_prefs/
      file_store/
    photo/
    pdf/
    mappers/
  presentation/
    home/
    drawing/
      states/
      view_models/
      widgets/
```

### 2-4. 현재 파일 -> 타깃 위치 매핑
- Core Model
  - `lib/models/site.dart` -> `lib/domain/site/entities/site.dart`
  - `lib/models/defect.dart` -> `lib/domain/inspection/entities/defect.dart`
  - `lib/models/equipment_marker.dart` -> `lib/domain/inspection/entities/equipment_marker.dart`
  - `lib/models/drawing/drawing_stroke.dart` -> `lib/domain/drawing/entities/drawing_stroke.dart`
  - JSON mapper는 `lib/infrastructure/mappers/*`로 분리
- Storage/Persistence
  - `lib/models/site_storage.dart` -> `lib/infrastructure/persistence/shared_prefs/site_prefs_repository.dart`
  - `lib/screens/drawing/persistence/drawing_persistence_store.dart` -> `lib/infrastructure/persistence/file_store/drawing_file_repository.dart`
  - `lib/screens/drawing/attachments/defect_photo_store.dart` -> `lib/infrastructure/photo/defect_photo_repository.dart`
- Flow/UseCase
  - `lib/screens/drawing/flows/*.dart` -> `lib/application/inspection/use_cases/*`, `lib/application/drawing/use_cases/*`
  - `lib/screens/home/home_storage.dart` -> 삭제 후 `application/site/use_cases/*`로 대체
- Presentation
  - `lib/screens/home/*` -> `lib/presentation/home/*`
  - `lib/screens/drawing/*` -> `lib/presentation/drawing/*` (단, 인프라/유스케이스로 분리될 파일 제외)

---

## 3. 실행 원칙 (운영 규칙)

### 3-1. 변경 단위
1. Step당 최대 핵심 책임 1개만 이동
2. Step 내에서 파일 이동 + 로직 변경 동시 대량 수행 금지
3. 경계 생성(인터페이스) 후 구현 이관 순서 고정

### 3-2. 커밋 원칙
1. 커밋은 Step 단위로 쪼갠다.
2. 커밋 메시지는 `PhaseX-StepY: ...` 형식 사용
3. 리네임/이동 커밋과 동작 변경 커밋을 분리한다.

### 3-3. 필수 검증 게이트
- Step 게이트
  - 대상 테스트 + `flutter test` 최소 1회
  - 주요 수동 시나리오 2개 이상
- Phase 게이트
  - `flutter test` 전체 통과
  - `flutter analyze` warning 수 목표 달성
  - 시나리오 카탈로그의 해당 Phase 항목 전부 통과

---

## 4. 상세 로드맵 (실행 버전)

## Phase 0. 베이스라인 고정 (2~3일)
목표: 현재 깨진 상태를 먼저 정상화하여 이후 리팩토링 리스크를 줄인다.

### Step 0-1. 경로 정규화 실패 테스트 복구 ✅ 완료
대상 파일:
- `lib/utils/photo_path_ordering.dart`
- `lib/screens/home/site_photo_orphan_scanner.dart`
- `test/photo_path_ordering_test.dart`

작업:
1. `photoReferenceKey`를 Windows/Unix 동등 비교가 되도록 normalize 규칙 강화.
2. 중복 판단 키와 정렬 비교 키를 동일 함수로 통일.
3. legacy path(`\`, `/`, drive letter`) 케이스를 테스트에 추가.

자동 검증:
- `flutter test test/photo_path_ordering_test.dart`
- `flutter test`

수동 검증:
- 시나리오 `P-01`, `P-02` 수행.

롤백 포인트:
- 경로 정규화 함수 변경 전후 diff만 되돌리면 복구 가능하도록 커밋 분리.

### Step 0-2. warning 11 -> 0 ✅ 완료
대상 파일:
- `lib/screens/drawing/drawing_screen.dart`
- `lib/screens/drawing/drawing_screen_logic.part.dart`
- `lib/screens/drawing/drawing_screen_ui.part.dart`

작업:
1. `unused_field`, `unused_element` 제거.
2. 동작에 영향 없는 deprecate 교체를 우선 적용.
3. naming/info 성격 lint는 별도 Phase로 이동 가능하나 warning은 즉시 제거.

자동 검증:
- `flutter analyze`
- `flutter test`

수동 검증:
- 시나리오 `D-01`, `D-03`, `D-06`.

롤백 포인트:
- UI/gesture 변경이 포함되면 즉시 중단 후 warning 제거만 남긴 패치로 재구성.

### Step 0-3. 스모크 테스트 이름 체계 고정 ✅ 완료
대상 파일:
- `test/` 신규 smoke 스위트

작업:
1. 핵심 시나리오 ID(`H-*`, `D-*`, `P-*`)를 테스트명으로 반영.
2. Phase별 필수 테스트 목록을 문서화.

자동 검증:
- `flutter test`

수동 검증:
- 없음 (테스트 목록 정합성 확인으로 대체).

---

## Phase 1. Repository 경계 확립 (3~4일)
목표: 저장소 접근을 인터페이스 뒤로 감춰서 Presentation의 I/O 직접 호출 제거 기반을 만든다.

### Step 1-1. 도메인 Repository 인터페이스 정의
생성 파일:
- `lib/domain/site/repositories/site_repository.dart`
- `lib/domain/drawing/repositories/drawing_repository.dart`
- `lib/domain/inspection/repositories/photo_repository.dart`

작업:
1. 최소 API만 정의 (load/save/delete 위주).
2. `Site`/`Drawing`/`Photo` 저장 관심사를 분리.

자동 검증:
- 정적 분석 + 컴파일

수동 검증:
- 없음.

### Step 1-2. 인프라 어댑터 구현 (기능 동일)
대상:
- `site_storage.dart`, `drawing_persistence_store.dart`, `defect_photo_store.dart`

작업:
1. 기존 구현을 adapter class로 감싼다.
2. 내부 로직은 건드리지 않고 인터페이스만 맞춘다.

자동 검증:
- `flutter test`

수동 검증:
- 시나리오 `H-01`, `D-08`, `P-01`.

### Step 1-3. HomeScreen/TrashScreen의 정적 저장 호출 제거
대상:
- `home_storage.dart`, `home_screen.dart`, `trash_screen.dart`

작업:
1. `HomeStorage` 정적 메서드 의존을 UseCase 호출로 치환 준비.
2. 임시로 façade를 둘 수 있으나 화면은 인터페이스를 바라보게 변경.

자동 검증:
- `flutter test`
- `flutter analyze`

수동 검증:
- 시나리오 `H-01`, `H-02`, `H-03`.

---

## Phase 2. Application UseCase 이관 (4~6일)
목표: `flows/` 함수 집합을 명시적 유스케이스 클래스로 승격.

### Step 2-1. Site UseCase 도입
생성:
- `application/site/use_cases/load_sites_use_case.dart`
- `application/site/use_cases/create_site_use_case.dart`
- `application/site/use_cases/trash_site_use_case.dart`
- `application/site/use_cases/restore_site_use_case.dart`

검증:
- 시나리오 `H-01`, `H-02`, `H-03`.

### Step 2-2. MarkerInteraction UseCase 도입
대상:
- `flows/marker_tap_flow.dart`
- `flows/defect_marker_flow.dart`
- `flows/equipment_pack_*.dart`
- `flows/equipment_updated_site_flow.dart`

작업:
1. Tap decision, marker 생성, 상세 입력 반영을 UseCase 클래스로 분리.
2. 라벨 증가 규칙은 일단 동일 복제.

검증:
- `test/marker_presenters_label_test.dart`
- 시나리오 `D-04`, `D-05`.

### Step 2-3. PDF UseCase 도입
대상:
- `flows/pdf_controller_flow.dart`
- `drawing_screen_logic.part.dart` PDF 관련 블록

작업:
1. 로드/교체/에러 처리 유스케이스 분리.
2. 페이지 수/현재 페이지/오류 상태 반영을 단일 응답 모델로 표준화.

검증:
- 시나리오 `D-02`, `D-03`, `D-08`.

### Step 2-4. DrawingPersistence UseCase 도입
대상:
- `drawing_persistence_store.dart`
- `drawing_screen_logic.part.dart` persist loop

검증:
- 시나리오 `D-08`, `D-09`.

---

## Phase 3. DrawingScreen 상태 슬라이스 분해 (핵심, 7~10일)
목표: `_DrawingScreenState` 집중 상태를 책임별 state object로 절단.

### Step 3-1. SessionState 분리
분리 대상:
- `_currentPage`, `_pageCount`, `_pdfController`, `_pdfPageSizes`, `_pdfLoadError`

신규:
- `presentation/drawing/states/drawing_session_state.dart`

검증:
- 시나리오 `D-02`, `D-03`.

### Step 3-2. ToolState 분리
분리 대상:
- `_activeTool`, `_activeFamily`, 펜/형광펜/도형 옵션 맵, straighten 옵션

신규:
- `presentation/drawing/states/tool_state.dart`

검증:
- 시나리오 `D-06`, `D-07`.

### Step 3-3. MarkerState 분리
분리 대상:
- 선택 ID, 카테고리 탭, 가시성 set, 패널 탭 상태

신규:
- `presentation/drawing/states/marker_state.dart`

검증:
- 시나리오 `D-04`, `D-05`.

### Step 3-4. GestureState 분리
분리 대상:
- pointer tracking, nav gesture, eraser session, straighten 임시 상태

신규:
- `presentation/drawing/states/gesture_state.dart`

검증:
- 시나리오 `D-01`, `D-06`, `D-09`.

### Step 3-5. HistoryState/PersistState 분리
분리 대상:
- undo/redo 가능 상태, debounce, in-flight 플래그

신규:
- `presentation/drawing/states/history_state.dart`
- `presentation/drawing/states/persist_state.dart`

검증:
- `test/drawing_history_stress_test.dart`
- 시나리오 `D-09`.

### Step 3-6. `DrawingScreen` 경량화
목표:
- `DrawingScreen`은 상태 조합 + 위젯 구성 + 이벤트 바인딩만 담당.

정량 목표:
- `drawing_screen*` 8,826줄 -> 4,500줄 이하(1차 목표)

검증:
- 시나리오 `D-01` ~ `D-09` 전수.

---

## Phase 4. Domain 순수화 + Mapper 분리 (5~7일)
목표: 엔티티를 프레젠테이션/직렬화 의존에서 분리.

### Step 4-1. 엔티티 직렬화 제거
대상:
- `site.dart`, `defect.dart`, `equipment_marker.dart`, `drawing_stroke.dart`

작업:
1. `toJson/fromJson`를 mapper 클래스로 이동.
2. 엔티티는 순수 데이터 + 도메인 행위만 유지.

검증:
- `test/drawing_serialization_compat_test.dart`
- 기존 저장 데이터 로드 호환 수동 검증.

### Step 4-2. 도메인 역의존 제거
즉시 해결 대상:
- `drawing_stroke.dart -> drawing_types.dart`
- `drawing_enums.dart -> strings_ko.dart`

작업:
1. `DrawingTool`의 도메인 enum 버전 정의.
2. UI 라벨은 presenter/provider로 이동.

정량 목표:
- `models/domain -> screens` import 0

### Step 4-3. 라벨/순번 규칙 Domain Service화
대상:
- `flows/marker_presenters.dart`

작업:
1. 순번/접두어/표시라벨 로직을 Domain Service로 이관.
2. 화면은 결과 문자열만 수신.

검증:
- `test/marker_presenters_label_test.dart`

---

## Phase 5. Dialog/SidePanel 프레젠테이션 정리 (3~5일)
목표: Dialog가 I/O를 몰라도 되도록 입력 수집 전용화.

### Step 5-1. Defect Dialog의 파일 접근 제거
대상:
- `dialogs/defect_details_dialog.dart`
- `dialogs/photo_manager_dialog.dart`

작업:
1. 파일 픽/저장/삭제를 Application 서비스로 이동.
2. Dialog는 DTO 입력/결과 반환만 수행.

검증:
- 시나리오 `P-01`, `P-02`, `P-03`.

### Step 5-2. Equipment Dialog군 정리
대상:
- `equipment_details_dialog.dart`, `rebar_spacing_dialog.dart`, 기타 장비 다이얼로그

작업:
1. 값 검증은 validator/service로 이관.
2. Dialog는 필드 렌더링 + submit만 담당.

검증:
- 시나리오 `D-05`.

### Step 5-3. SidePanel ViewModel 도입
대상:
- `widgets/side_panel/marker_side_panel.dart`

작업:
1. 표기 문자열/정렬/필터 로직을 ViewModel로 이동.
2. 위젯 트리는 렌더링 전용화.

검증:
- 시나리오 `D-04`, `D-05`.

---

## Phase 6. 테스트 체계 확장 (지속, 5~7일)
목표: 구조 리팩토링 이후 회귀 감시망 강화.

### Step 6-1. Domain 테스트 확장
추가 테스트:
- 라벨 순번/접두어 규칙
- 가시성 필터 규칙
- shape bounds/rotation 계산
- 경계값 입력 검증

### Step 6-2. Application 테스트 확장
추가 테스트:
- site create/trash/restore usecase
- marker interaction usecase
- drawing persistence usecase
- pdf replace/load usecase

### Step 6-3. 회귀 시나리오 테스트
추가 테스트:
- PDF 교체 -> 페이지 이동 -> 마커 생성 -> 저장 -> 재실행 복원
- pen/highlighter/shape/eraser 혼합 후 undo/redo 안정성
- orphan photo scan/restore/cleanup

### Step 6-4. 장기 안정성
추가 테스트:
- 100회 이상 undo/redo 반복
- 다중 페이지(10p+)에서 성능/메모리 확인

---

## Phase 7. 성능/정리 마무리 (3~4일)
목표: 코드 품질 체감 개선과 유지보수성 마감.

### Step 7-1. 죽은 코드/스텁 정리
대상:
- `engines/eraser_engine_v2.dart`
- `engines/text_engine.dart`

작업:
1. 실제 미사용이면 제거.
2. 향후 계획이 있으면 TODO가 아니라 명시 이슈 링크로 관리.

### Step 7-2. 페인터/캐시 경로 정리
대상:
- `temp_polyline_painter.dart`
- `stroke_cache_manager.dart`

작업:
1. 중복 렌더링 경로 최소화.
2. deprecated API 교체 완료.

### Step 7-3. 문서/온보딩 마감
산출물:
- 아키텍처 개요 문서
- 레이어 규칙 문서
- 신규 기능 추가 가이드

---

## 5. Step 종료 수동 검증 시나리오 카탈로그

### Home/사이트
- `H-01` 현장 생성
  - PDF/빈 캔버스 둘 다 생성 가능
  - 구조형식/점검형식/점검일 표시 정상
- `H-02` 휴지통 플로우
  - 삭제 -> 휴지통 이동 -> 복원 -> 영구삭제
- `H-03` 앱 재실행 복원
  - Home 목록/삭제 상태 동일

### Drawing/PDF/Marker
- `D-01` 캔버스 제스처
  - 스타일러스 드로잉, 2손가락 네비게이션 충돌 없음
- `D-02` PDF 로드/에러
  - 파일 없음/손상 파일 에러 메시지 정상
- `D-03` 페이지 이동
  - 이전/다음, 페이지 인디케이터, 페이지별 오버레이 정합
- `D-04` 결함 마커 플로우
  - 탭 추가/삭제, 선택/해제, 상세 수정 반영
- `D-05` 장비 마커 플로우
  - 카테고리별 라벨 규칙, 상세값 저장 반영
- `D-06` 도구 전환
  - 펜/형광펜/도형/지우개 전환 및 옵션 유지
- `D-07` 색/굵기/투명도
  - 도구별 마지막 사용값 보존
- `D-08` 저장/복원
  - 그리기 후 강종/재실행 복원
  - PDF 교체 후도 정상 복원
- `D-09` 히스토리
  - undo/redo 100회 반복 안정성
  - clear pen/highlighter/all 동작 일관성

### Photo/첨부
- `P-01` 결함 사진 추가/교체/삭제
  - 원본명(sidecar) 보존
- `P-02` 고아 사진 스캔/복원
  - 동일 경로 중복 삽입 없음
- `P-03` 고아 사진 정리
  - 실제 파일/sidecar 동시 정리

---

## 6. 자동 아키텍처 가드레일 (정기 점검 명령)

1. 도메인에서 화면 의존 금지
```powershell
rg -n "package:safety_inspection_app/screens/" lib/domain lib/models
```

2. 프레젠테이션의 직접 I/O 금지 (최종 목표)
```powershell
rg -n "dart:io|SharedPreferences|getApplicationDocumentsDirectory|FilePicker|ImagePicker" lib/presentation
```

3. 계층 경계 위반 감시
```powershell
rg -n "package:safety_inspection_app/presentation/" lib/domain lib/application lib/infrastructure
```

4. 핵심 품질 게이트
```powershell
flutter test
flutter analyze
```

---

## 7. 정량 완료 기준 (Definition of Done)

### 아키텍처
- `domain/models -> screens/presentation` import 0
- `presentation/screens`에서 직접 파일 I/O 호출 0
- `drawing_screen*` 총합 8,826 -> 2,500 이하 (최종 목표)
- `drawing_screen*` 총합 8,826 -> 4,500 이하 (중간 목표, Phase 3 종료)

### 품질
- `flutter test` 100% 통과
- `flutter analyze` warning 0
- deprecate 주요 항목 정리 완료 (`Color.value`, `withOpacity`, 구버전 callback)

### 유지보수성
- 신규 장비 카테고리 추가 시 수정 파일 3개 이하
- 마커 라벨 정책 변경 시 Domain/Application만 수정 가능
- 저장소 교체 시 Infrastructure 계층 변경만으로 대응 가능

---

## 8. 2주 킥오프 실행안 (권장)

### Week 1
1. Day 1: Step 0-1 경로 정규화 복구 + 테스트 green
2. Day 2: Step 0-2 warning 0 달성
3. Day 3: Step 1-1 Repository 인터페이스 정의
4. Day 4: Step 1-2 인프라 어댑터 적용
5. Day 5: Step 1-3 Home 저장 호출 경계화

### Week 2
1. Day 6: Step 2-1 Site UseCase
2. Day 7: Step 2-2 MarkerInteraction UseCase
3. Day 8: Step 2-3 PDF UseCase
4. Day 9: Step 3-1 SessionState, Step 3-2 ToolState 시작
5. Day 10: Step 3-3 MarkerState + 회귀 검증

---

## 9. 지금 바로 시작할 실행 순서 (실무용)

1. `Phase 1-1` Repository 인터페이스 정의
2. `Phase 1-2` 인프라 어댑터 적용 (동작 변경 금지)
3. `Phase 1-3` Home/Trash 정적 저장 호출 경계화
4. `Phase 2`에서 flows를 UseCase로 이관
5. `Phase 3`부터 상태 슬라이스 분해 시작
6. 각 Step마다 시나리오 ID 기준 수동 검증 로그 남기기

---

## 10. 메모
- 이 문서는 요약본이 아니라 실행본이므로, 실제 작업 중 숫자/라인 수/이슈 수가 바뀌면 Step 완료 시 즉시 갱신한다.
- 변경 중간에 동작 리스크가 커지면, Phase를 멈추고 Step 단위로 더 잘게 쪼개서 재진행한다.
