# DDD 리팩토링 로드맵 v4.8 (업데이트: 2026-03-05, Phase 3-6 진행중)

## 0. 문서 목적과 사용법
이 문서는 현재 `safety_inspection_app` 코드베이스를 기준으로, 기능 회귀 없이 DDD 구조로 단계적으로 이관하기 위한 실행 문서다.

사용 원칙:
1. 요약이 아니라 작업 지시서로 사용한다.
2. 각 Step 종료 시 자동 검증 + 수동 검증을 반드시 수행한다.
3. 실패 시 바로 다음 Step으로 넘어가지 않고, 해당 Step에서 롤백 또는 수정 후 재검증한다.
4. Phase 종료 검증뿐 아니라 Step 종료 검증을 강제한다.

---

## 0-1. 진행 현황 (v4.8)
- 완료 Phase
  - `Phase 0` (`Step 0-1`, `Step 0-2`, `Step 0-3`)
  - `Phase 1` (`Step 1-1`, `Step 1-2`, `Step 1-3`)
  - `Phase 2` (`Step 2-1`, `Step 2-2`, `Step 2-3`, `Step 2-4`)
- Phase 3 진행 상태
  - `완료`: `Step 3-1`, `Step 3-2`, `Step 3-3`, `Step 3-4`, `Step 3-5`
  - `진행중`: `Step 3-6` (`3-6A`~`3-6D` 완료, `3-6E` 진행중)
- 최근 자동 검증 결과 (Phase 3 작업 기준)
  - `flutter test test/application/site/use_cases/site_use_cases_test.dart`: 통과
  - `flutter test test/application/inspection/use_cases/marker_interaction_use_cases_test.dart`: 통과
  - `flutter test test/application/drawing/use_cases/pdf_use_cases_test.dart`: 통과
  - `flutter test test/application/drawing/use_cases/drawing_persistence_use_cases_test.dart`: 통과
  - `flutter test test/drawing_history_stress_test.dart`: 통과
  - `flutter test test/smoke/scenario_id_smoke_test.dart`: 통과
- 최근 수동 검증 결과
  - `Step 2-1`: `H-01`, `D-08`, `P-01` all pass
  - `Step 2-2`: `D-04`, `D-05` all pass
  - `Step 2-3`: `D-02`, `D-03`, `D-08` all pass
  - `Step 2-4`: `D-08`, `D-09` all pass
  - `Step 3-1` ~ `Step 3-5`: all pass
  - `Step 3-6` 진행 중 반영분(툴 전환/스타일러스 입력/미니 설정 아이콘): all pass
  - `Step 3-6A` 반영분(포인터 라우팅 분리/로그 정리/소형 도형 이동 보정): all pass
- 다음 시작점
  - `Phase 3 - Step 3-6E`: 상태 접근 단일화(accessor 포워딩 축소 + facade 정리) 마무리
  - 이후 `Step 3-6F`: DrawingScreen 최종 정리(라인수 절감/part 책임 최소화)

## 0-2. Phase 1 완료 상세 (Step별 수정)
### Step 1-1. 도메인 Repository 인터페이스 정의
- 수정 파일
  - `lib/domain/site/repositories/site_repository.dart`
  - `lib/domain/drawing/repositories/drawing_repository.dart`
  - `lib/domain/inspection/repositories/photo_repository.dart`
- 핵심 변경
  - 도메인 경계 인터페이스를 도입해 저장소 의존 방향을 `domain <- infrastructure`로 고정.
- 검증
  - 정적 분석/컴파일 기준 정상.

### Step 1-2. 인프라 어댑터 구현
- 수정 파일
  - `lib/infrastructure/persistence/shared_prefs/site_prefs_repository.dart`
  - `lib/infrastructure/persistence/file_store/drawing_file_repository.dart`
  - `lib/infrastructure/photo/defect_photo_repository.dart`
- 핵심 변경
  - 기존 저장소 구현을 인터페이스 어댑터로 감싸 동작 변경 없이 인프라 계층으로 분리.
- 검증
  - 자동: `flutter test test/smoke/scenario_id_smoke_test.dart` 통과
  - 수동: `H-01`, `D-08`, `P-01` all pass

### Step 1-3. Home/Trash 정적 저장 호출 경계화
- 수정 파일
  - `lib/screens/home/home_storage.dart`
  - `lib/screens/home/home_screen.dart`
  - `lib/screens/home/trash_screen.dart`
  - `test/smoke/scenario_id_smoke_test.dart`
- 핵심 변경
  - `HomeStorage`를 정적 유틸에서 `SiteRepository` 기반 인스턴스 파사드로 전환.
  - `HomeScreen`/`TrashScreen`이 동일 `HomeStorage` 인스턴스를 주입받아 사용하도록 변경.
  - 스모크 테스트를 인스턴스 호출 기준으로 전환.
- 검증
  - 자동: `flutter analyze` (대상 4개 파일) 통과, `flutter test test/smoke/scenario_id_smoke_test.dart` 통과
  - 수동: `H-01`, `H-02`, `H-03` all pass

## 0-3. Phase 2 완료 상세 (Step별 수정)
### Step 2-1. Site UseCase 도입
- 수정 파일
  - `lib/application/site/use_cases/load_sites_use_case.dart`
  - `lib/application/site/use_cases/create_site_use_case.dart`
  - `lib/application/site/use_cases/trash_site_use_case.dart`
  - `lib/application/site/use_cases/restore_site_use_case.dart`
- 핵심 변경
  - 사이트 생성/조회/휴지통 이동/복원 로직을 Application UseCase로 분리.
  - 프레젠테이션 계층은 UseCase 호출 중심으로 흐름 정리.
- 검증
  - 자동: `flutter test test/application/site/use_cases/site_use_cases_test.dart` 통과
  - 수동: `H-01`, `D-08`, `P-01` all pass

### Step 2-2. MarkerInteraction UseCase 도입
- 수정 파일
  - `lib/application/inspection/use_cases/marker_tap_use_case.dart`
  - `lib/application/inspection/use_cases/create_defect_marker_use_case.dart`
  - `lib/application/inspection/use_cases/create_equipment_updated_site_use_case.dart`
  - `lib/screens/drawing/flows/marker_tap_flow.dart`
  - `test/application/inspection/use_cases/marker_interaction_use_cases_test.dart`
- 핵심 변경
  - 마커 탭 의사결정/생성/상세 입력 반영을 UseCase 계층으로 승격.
  - 기존 라벨 증가 규칙과 동작은 유지.
- 검증
  - 자동: `flutter test test/application/inspection/use_cases/marker_interaction_use_cases_test.dart` 통과
  - 수동: `D-04`, `D-05` all pass

### Step 2-3. PDF UseCase 도입
- 수정 파일
  - `lib/application/drawing/use_cases/pdf_use_case_models.dart`
  - `lib/application/drawing/use_cases/load_pdf_controller_use_case.dart`
  - `lib/application/drawing/use_cases/replace_pdf_use_case.dart`
  - `lib/screens/drawing/flows/pdf_controller_flow.dart`
  - `lib/screens/drawing/drawing_screen_logic.part.dart`
  - `test/application/drawing/use_cases/pdf_use_cases_test.dart`
- 핵심 변경
  - PDF 로드/교체/에러 처리를 UseCase로 분리하고 응답 모델을 표준화.
  - 교체 확인 다이얼로그를 추가하고 교체 직후 로딩 정체 현상을 보정.
- 검증
  - 자동: `flutter test test/application/drawing/use_cases/pdf_use_cases_test.dart` 통과
  - 수동: `D-02`, `D-03`, `D-08` all pass

### Step 2-4. DrawingPersistence UseCase 도입
- 수정 파일
  - `lib/application/drawing/use_cases/load_site_drawing_use_case.dart`
  - `lib/application/drawing/use_cases/persist_site_drawing_use_case.dart`
  - `lib/screens/drawing/drawing_screen.dart`
  - `lib/screens/drawing/drawing_screen_logic.part.dart`
  - `test/application/drawing/use_cases/drawing_persistence_use_cases_test.dart`
- 핵심 변경
  - 드로잉 복원/저장 책임을 UseCase로 이동해 persist loop의 저장소 직접 호출 제거.
  - 앱 강종 후 다중 페이지 복원 시 2페이지 획 노출 지연 문제를 캐시 재빌드 트리거로 보정.
- 검증
  - 자동: `flutter test test/application/drawing/use_cases/drawing_persistence_use_cases_test.dart` 통과
  - 수동: `D-08`, `D-09` all pass

---

## 1. 현재 코드 스냅샷 (실측 기준: 2026-03-04)

### 1-1. 코드 볼륨
- `drawing_screen*.dart` 합계 7,640줄 (실측)
  - `drawing_screen.dart`: 804
  - `drawing_screen_logic.part.dart`: 4,197
  - `drawing_screen_ui.part.dart`: 1,467
  - `drawing_screen_tooling.part.dart`: 556
  - `drawing_screen_state_accessors.part.dart`: 283
  - `drawing_screen_marker_actions.part.dart`: 237
  - `drawing_screen_scale_prefs.part.dart`: 96
- 리팩토링 관점 핵심 병목
  - `drawing_screen_logic.part.dart`가 여전히 4k+ 라인으로 단일 책임 위반 위험이 큼
  - `drawing_screen_ui.part.dart`도 1.5k+ 라인으로 UI/입력/오버레이 책임 혼합 상태

### 1-2. 고복잡도 파일 Top 15 (줄 수 기준)
1. `lib/screens/drawing/drawing_screen_logic.part.dart` (4,197)
2. `lib/screens/drawing/drawing_screen_ui.part.dart` (1,467)
3. `lib/screens/drawing/drawing_screen.dart` (804)
4. `lib/screens/home/home_screen.dart` (696)
5. `lib/screens/drawing/dialogs/defect_details_dialog.dart` (694)
6. `lib/screens/drawing/widgets/side_panel/marker_side_panel.dart` (691)
7. `lib/screens/drawing/widgets/color_picker_dialog.dart` (664)
8. `lib/screens/drawing/drawing_screen_tooling.part.dart` (556)
9. `lib/application/inspection/use_cases/marker_tap_use_case.dart` (497)
10. `lib/widgets/drawing/temp_polyline_painter.dart` (413)
11. `lib/screens/drawing/dialogs/equipment_details_dialog.dart` (402)
12. `lib/screens/drawing/flows/marker_tap_flow.dart` (387)
13. `lib/screens/drawing/widgets/highlighter_settings_popup.dart` (350)
14. `lib/screens/drawing/dialogs/rebar_spacing_dialog.dart` (348)
15. `lib/screens/drawing/widgets/pen_settings_popup.dart` (339)

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

실행 기록 (2026-03-03):
- 수정 파일
  - `lib/screens/home/site_photo_orphan_scanner.dart`
  - `test/photo_path_ordering_test.dart`
- 핵심 수정
  - `photoReferenceKey` 정규화 규칙 강화(슬래시/드라이브 레터/트레일링 슬래시 처리).
  - 중복 판정 회귀 케이스 추가(`drive letter case`, `trailing slash`).
- 자동 검증 결과
  - `flutter test test/photo_path_ordering_test.dart` 통과
  - `flutter test` 통과

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

실행 기록 (2026-03-03):
- 수정 파일
  - `lib/screens/drawing/drawing_screen.dart`
  - `lib/screens/drawing/drawing_screen_logic.part.dart`
  - `lib/screens/drawing/drawing_screen_ui.part.dart`
- 핵심 수정
  - 미사용 field/element 제거로 warning 항목 정리.
  - 사용되지 않던 레거시 UI 블록/보조 함수 제거.
- 자동 검증 결과
  - `flutter analyze` warning 0 달성
  - `flutter test` 통과

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

실행 기록 (2026-03-03):
- 수정 파일
  - `test/smoke/scenario_id_smoke_test.dart` (신규)
  - `PHASE_TEST_CATALOG.md` (신규)
- 핵심 수정
  - 시나리오 ID 기준 smoke 테스트 추가(`H-01`, `H-02`, `H-03`, `D-05`, `P-02`).
  - Phase 0 필수 테스트 카탈로그 문서화.
- 자동 검증 결과
  - `flutter test test/smoke/scenario_id_smoke_test.dart` 통과
  - `flutter test` 통과

---

## Phase 1. Repository 경계 확립 (3~4일) ✅ 완료 (2026-03-03)
목표: 저장소 접근을 인터페이스 뒤로 감춰서 Presentation의 I/O 직접 호출 제거 기반을 만든다.

상태:
- `Step 1-1` 완료
- `Step 1-2` 완료
- `Step 1-3` 완료

### Step 1-1. 도메인 Repository 인터페이스 정의 ✅ 완료
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

### Step 1-2. 인프라 어댑터 구현 (기능 동일) ✅ 완료
대상:
- `site_storage.dart`, `drawing_persistence_store.dart`, `defect_photo_store.dart`

작업:
1. 기존 구현을 adapter class로 감싼다.
2. 내부 로직은 건드리지 않고 인터페이스만 맞춘다.

자동 검증:
- `flutter test`

수동 검증:
- 시나리오 `H-01`, `D-08`, `P-01`.

### Step 1-3. HomeScreen/TrashScreen의 정적 저장 호출 제거 ✅ 완료
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

## Phase 2. Application UseCase 이관 (4~6일) ✅ 완료
목표: `flows/` 함수 집합을 명시적 유스케이스 클래스로 승격.

### Step 2-1. Site UseCase 도입 ✅ 완료
생성:
- `application/site/use_cases/load_sites_use_case.dart`
- `application/site/use_cases/create_site_use_case.dart`
- `application/site/use_cases/trash_site_use_case.dart`
- `application/site/use_cases/restore_site_use_case.dart`

검증:
- 시나리오 `H-01`, `H-02`, `H-03`.

### Step 2-2. MarkerInteraction UseCase 도입 ✅ 완료
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

### Step 2-3. PDF UseCase 도입 ✅ 완료
대상:
- `flows/pdf_controller_flow.dart`
- `drawing_screen_logic.part.dart` PDF 관련 블록

작업:
1. 로드/교체/에러 처리 유스케이스 분리.
2. 페이지 수/현재 페이지/오류 상태 반영을 단일 응답 모델로 표준화.

검증:
- 시나리오 `D-02`, `D-03`, `D-08`.

### Step 2-4. DrawingPersistence UseCase 도입 ✅ 완료
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
- `drawing_screen*` 7,640줄 -> 4,500줄 이하(1차 목표)

세부 분리 계획(DDD 경계 준수):
1. `3-6A` 입력/제스처 라우팅 분리
   - 신규 파일
     - `lib/presentation/drawing/controllers/pointer_intent_router.dart`
     - `lib/presentation/drawing/controllers/marker_input_guard.dart`
   - 이동 대상
     - `drawing_screen_logic.part.dart`의 pointer down/move/up 분기, stylus/touch 게이트, 확대/축소 중 입력 차단 규칙
   - 경계 원칙
     - `Screen`은 이벤트 전달만 수행하고, 입력 판정 로직은 `presentation`으로 이동
2. `3-6B` PDF 뷰포트/좌표 계산 분리
   - 신규 파일
     - `lib/presentation/drawing/controllers/pdf_viewport_controller.dart`
     - `lib/presentation/drawing/models/pdf_viewport_snapshot.dart`
   - 이동 대상
     - 화면 좌표↔PDF 정규 좌표 변환, 페이지별 viewport 상태 계산, 탭 좌표 보정
   - 경계 원칙
     - 좌표 계산은 UI 위젯 트리와 분리된 순수 로직으로 유지
3. `3-6C` 마커 액션 오케스트레이션 분리
   - 신규 파일
     - `lib/presentation/drawing/controllers/marker_action_coordinator.dart`
   - 이동 대상
     - 마커 선택/생성/수정 흐름에서 `flow + use case` 조합 호출부
   - 경계 원칙
     - `application/use_case` 호출은 coordinator에서만 수행하고 `Screen`은 결과 반영만 담당
4. `3-6D` UI 조립 블록 분리
   - 신규 파일
     - `lib/screens/drawing/widgets/shell/drawing_canvas_shell.dart`
     - `lib/screens/drawing/widgets/shell/drawing_overlay_shell.dart`
     - `lib/screens/drawing/widgets/shell/drawing_side_panel_shell.dart`
   - 이동 대상
     - `drawing_screen_ui.part.dart`의 캔버스/오버레이/패널 빌더 메서드
   - 경계 원칙
     - 위젯 트리 조립은 `widgets/shell`로 이동, `Screen`은 상태 바인딩만 유지
5. `3-6E` 상태 접근 단일화
   - 신규 파일
     - `lib/presentation/drawing/states/drawing_state_facade.dart`
   - 이동 대상
     - `drawing_screen_state_accessors.part.dart`의 분산 getter/setter
   - 경계 원칙
     - `State` 변경 포인트를 facade로 모아 사이드 이펙트 추적 가능하게 정리
6. `3-6F` 마무리 정리
   - `drawing_screen.dart`는 `part` 선언 + 생명주기 + 의존성 조립 + 라우팅만 남긴다.
   - `drawing_screen_logic.part.dart` 2k 미만, `drawing_screen_ui.part.dart` 1k 미만으로 1차 절감한다.

실행 순서 조정(외부 리뷰 선택 반영):
- `완료`: `3-6A`, `3-6B`, `3-6C`, `3-6D`
- `진행중`: `3-6E`
- `다음`: `3-6F`
- 이유: accessor 포워딩을 먼저 줄여야 이후 최종 정리 단계(`3-6F`)에서 수정 파급을 줄일 수 있음

분리 후 기대 효과:
- 입력/좌표/오케스트레이션이 테스트 가능한 순수 단위로 분리되어 회귀 원인 추적 시간이 단축된다.
- `DrawingScreen` 변경 시 수정 범위가 줄어 PR 리뷰/충돌 비용이 감소한다.
- Step 단위 병렬 작업이 가능해져 Phase 3-6 잔여 작업 속도가 올라간다.

최적화/경량화 우선순위 반영(실측 기준):
1. `우선순위 P0` (`Step 3-6A`에 포함, 즉시 수행)
   - 핫패스 디버그 로그 정리
     - 대상: `drawing_screen_logic.part.dart`, `drawing_screen_ui.part.dart`, `drawing_canvas_widget.dart`
     - 원칙: 포인터 move/build 루프 로그는 제거하고, 장애 분석용 로그만 `kDebugMode && verbose flag`로 제한
   - 포인터 분기 단순화
     - 대상: `_handleOverlayPointerDownWithStylusDrawing`, `_handleOverlayPointerMoveWithStylusDrawing`, `_handleOverlayPointerUpWithStylusDrawing`
     - 원칙: `pointer_intent_router`에서 intent 판정 후 handler 분기
2. `우선순위 P1` (`Step 3-6C`~`3-6F`에 포함)
   - 장비 Flow 시그니처/중복 정리
     - 대상: `flows/equipment_pack_a~d_flow.dart`
     - 내용: 미사용 파라미터 제거, 공통 `site.copyWith(equipmentMarkers: [...])` append helper 추출
   - 루프 내 미세 최적화
     - 대상: `equipment_pack_a_flow.dart`
     - 내용: loop 내부 `RegExp` 생성 제거(함수 외부/초기화 시점 캐시)
3. `우선순위 P2` (`Phase 7`에서 마감)
   - Deprecated API 일괄 교체
     - 대상: `Color.value`, `withOpacity`, 구버전 callback/API
   - 잔여 디버그 코드/스텁 제거
     - 대상: painter/cache/engine 계열의 개발용 로그/스텁

외부 코드리뷰 선택 반영 항목(채택):
1. Presentation 직접 저장소/설정 접근 제거
   - 적용 Step: `3-6B`
   - 내용: `drawing_screen_logic.part.dart`의 PDF page size cache(`SharedPreferences`)를 `PdfPageSizeCacheRepository` + UseCase 경유로 이관
2. `DrawingScreen` 내부 하드코딩 DI 제거
   - 적용 Step: `3-6B`
   - 내용: `DrawingFileRepository`/`SitePrefsRepository` 직접 생성 제거, `DrawingScreen` 생성자 주입 방식으로 전환
3. 과도한 state accessor 포워딩 축소
   - 적용 Step: `3-6E` (선행)
   - 내용: `drawing_screen_state_accessors.part.dart` 제거/축소 후 state 직접 접근 또는 facade로 단일화
4. `dynamic` 캐스팅 제거
   - 적용 Step: `3-6D`
   - 내용: 마커 렌더링 경로에 타입 안전 모델(`PageIndexed` 성격의 공통 타입 또는 렌더 DTO) 도입

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
- `screens/drawing/*` 내 개발용 디버그 로그(`print`, 과도한 `debugPrint`)

작업:
1. 실제 미사용이면 제거.
2. 향후 계획이 있으면 TODO가 아니라 명시 이슈 링크로 관리.
3. 핫패스(pointer move/build) 로그는 기본 제거하고 필요 시 토글형 verbose 로거로 대체.

### Step 7-2. 페인터/캐시 경로 정리
대상:
- `temp_polyline_painter.dart`
- `stroke_cache_manager.dart`
- `drawing_screen_logic.part.dart`
- `drawing_screen_ui.part.dart`

작업:
1. 중복 렌더링 경로 최소화.
2. deprecated API 교체 완료.
3. `Color.value`, `withOpacity`, 구버전 callback/API를 최신 API로 일괄 교체.

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

5. Drawing 화면의 직접 저장소/설정 접근 감시
```powershell
rg -n "SharedPreferences|DrawingFileRepository|SitePrefsRepository" lib/screens/drawing
```

---

## 7. 정량 완료 기준 (Definition of Done)

### 아키텍처
- `domain/models -> screens/presentation` import 0
- `presentation/screens`에서 직접 파일 I/O 호출 0
- `drawing_screen*` 총합 7,640 (진행중 실측, 2026-03-04)
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

1. `완료` Phase 1-1 Repository 인터페이스 정의
2. `완료` Phase 1-2 인프라 어댑터 적용 (동작 변경 금지)
3. `완료` Phase 1-3 Home/Trash 정적 저장 호출 경계화
4. `완료` Phase 2-1 Site UseCase 도입
5. `완료` Phase 2-2 MarkerInteraction UseCase 도입
6. `완료` Phase 2-3 PDF UseCase 도입
7. `완료` Phase 2-4 DrawingPersistence UseCase 도입
8. `완료` Phase 3-1 SessionState 분리
9. `완료` Phase 3-2 ToolState 분리
10. `완료` Phase 3-3 MarkerState 분리
11. `완료` Phase 3-4 GestureState 분리
12. `완료` Phase 3-5 History/PersistState 분리
13. `진행중` Phase 3-6 DrawingScreen 경량화 (`3-6A`~`3-6F` 순차 수행)
14. `완료` `3-6A` 입력/제스처 라우팅 분리 + 핫패스 디버그 로그 정리(P0)
15. `진행중` `3-6E` 상태 접근 단일화(accessor 포워딩 축소 + facade 정리)
16. `완료` `3-6B` PDF viewport + page size cache 경계 분리
17. `완료` `3-6C` 마커 액션 오케스트레이션 분리
18. `완료` `3-6D` UI 조립 블록 분리 + draw/move gesture 보정
19. `다음` `3-6F` DrawingScreen 최종 정리(라인 수 1차 목표 달성)
20. `다음` 각 Step 종료 후 시나리오 ID 기준 수동 검증 로그 남기기

---

## 10. 메모
- 이 문서는 요약본이 아니라 실행본이므로, 실제 작업 중 숫자/라인 수/이슈 수가 바뀌면 Step 완료 시 즉시 갱신한다.
- 변경 중간에 동작 리스크가 커지면, Phase를 멈추고 Step 단위로 더 잘게 쪼개서 재진행한다.

---

## 11. 로드맵 외 기능 수정 로그

### 2026-03-03 / 결함 사진 카메라 원본명 표시 보정
- 상황
  - 갤러리/파일 선택 경로는 원본 파일명이 표시되는데, 카메라 촬영 경로는 임시 이름(`image_picker...`)이 표시되는 문제가 있었음.
- 수정 내용
  - 카메라 경로에서 의미 없는 임시 이름을 제외하고 파일명 보정 로직 추가.
  - 저장 시 sidecar 메타데이터(`originalName`)에 보정된 원본명을 우선 저장하도록 `DefectPhotoStore` 저장 API 확장.
  - 관련 파일
    - `lib/screens/drawing/dialogs/defect_details_dialog.dart`
    - `lib/screens/drawing/attachments/defect_photo_store.dart`
- 검증
  - `flutter test` 전체 통과
  - 실제 앱 수동 확인에서 카메라 촬영 사진의 파일명 표시 정상화

### 2026-03-03 / 카메라 fallback 파일명 접두사 조정
- 상황
  - 위 보정 이후 fallback 파일명에 `IMG_` 접두사가 붙어 표시되는 UX 피드백 발생.
- 수정 내용
  - fallback 파일명 형식을 `IMG_YYYYMMDD_HHMMSS.ext` -> `YYYYMMDD_HHMMSS.ext`로 변경.
  - 관련 파일
    - `lib/screens/drawing/dialogs/defect_details_dialog.dart`
- 검증
  - `flutter test` 전체 통과
  - 실제 앱 수동 확인에서 접두사 없이 기대한 파일명 표시

### 2026-03-03 / PDF 교체 확인 다이얼로그 및 교체 직후 로딩 정체 보정
- 상황
  - PDF 교체 시 파일 선택 직후 바로 교체되어 확인 단계가 없었고, 일부 기기에서 교체 후 무한 로딩처럼 보이는 현상이 발생함.
- 수정 내용
  - PDF 교체 플로우에 `교체하시겠습니까?` 확인 다이얼로그를 추가.
  - PDF 로드/교체 시 뷰 버전 갱신과 예외 처리 경로를 보강해 로딩 정체를 줄임.
  - 관련 파일
    - `lib/application/drawing/use_cases/replace_pdf_use_case.dart`
    - `lib/application/drawing/use_cases/load_pdf_controller_use_case.dart`
    - `lib/screens/drawing/flows/pdf_controller_flow.dart`
    - `lib/screens/drawing/drawing_screen_logic.part.dart`
- 검증
  - `flutter test test/application/drawing/use_cases/pdf_use_cases_test.dart` 통과
  - 수동 확인에서 교체 확인 팝업/교체 동작 정상

### 2026-03-03 / 강종 후 PDF 2페이지 획 지연 노출 보정
- 상황
  - 앱 강종 후 재진입 시 1페이지는 정상 복원되지만, 2페이지는 빈 화면으로 보이다가 추가 그리기를 해야 기존 획이 보이는 현상 발생.
- 수정 내용
  - PDF 페이지 크기 확정 시 해당 페이지 캐시 invalidate를 재트리거.
  - 페이지 전환 시 cache miss 또는 dirty 상태면 즉시 캐시 재빌드하도록 보강.
  - 관련 파일
    - `lib/screens/drawing/drawing_screen_logic.part.dart`
- 검증
  - `flutter test test/smoke/scenario_id_smoke_test.dart` 통과
  - 수동 확인에서 강종 후 2페이지 진입 즉시 획 표시 정상

### 2026-03-04 / 새 현장 다이얼로그 키보드 오버플로우 및 위치 보정
- 상황
  - 홈 화면 `새 현장` 다이얼로그가 중앙보다 위로 뜨고, 키보드 노출 시 `BOTTOM OVERFLOWED`가 발생.
  - 오버플로우 상태에서 바깥 영역 터치 시 `'_dependents.isEmpty'` assert가 발생.
- 수정 내용
  - 다이얼로그 레이아웃을 키보드 inset 대응 구조로 변경해 오버플로우를 방지.
  - 다이얼로그 기준 위치를 화면 중앙 정렬로 조정하고 dismiss 동선을 안정화.
  - 관련 파일
    - `lib/screens/home/dialogs/new_site_dialog.dart`
- 검증
  - 수동 확인에서 키보드 열림/닫힘 포함 오버플로우 없이 정상 표시
  - 바깥 터치 dismiss 시 assert 재현 없음

### 2026-03-04 / 자유그리기 툴 전환 UX 개선 및 미니 설정 아이콘 추가
- 상황
  - 자유선/형광펜/도형/지우개 전환 시 팝업이 닫히기만 하고 툴 전환이 직관적으로 반영되지 않는 구간이 있었음.
- 수정 내용
  - 탭 전환 시 활성 툴이 즉시 변경되도록 흐름 보정.
  - 툴 설정 팝업을 다시 열 수 있는 미니 설정 아이콘을 도면 오버레이에 추가.
  - 관련 파일
    - `lib/screens/drawing/drawing_screen_ui.part.dart`
    - `lib/screens/drawing/drawing_screen_logic.part.dart`
- 검증
  - 수동 확인에서 툴 탭 전환 즉시 반영, 미니 아이콘으로 설정 팝업 재오픈 정상

### 2026-03-04 / 마커 입력 Stylus 우선 정책 및 확대 상태 입력 보정
- 상황
  - 결함/장비 마커 입력에서 손가락과 터치펜 입력이 혼재되어 오작동이 있었고, 확대 상태에서 stylus 마커 입력이 누락되는 문제가 있었음.
- 수정 내용
  - 마커 배치 모드에서 비-스타일러스 입력 차단 규칙을 명시하고, stylus 포인터 추적 경로를 분리.
  - 확대/이동 상태에서도 stylus 탭이 마커 배치로 전달되도록 이벤트 게이트를 정리.
  - 관련 파일
    - `lib/presentation/drawing/states/gesture_state.dart`
    - `lib/screens/drawing/drawing_screen_logic.part.dart`
    - `lib/screens/drawing/drawing_screen_ui.part.dart`
    - `lib/screens/drawing/drawing_screen_state_accessors.part.dart`
- 검증
  - 수동 확인에서 손가락은 이동/확대/축소 중심으로 동작하고, stylus 마커 배치 정상
  - 확대 상태에서도 마커 입력 재현 정상

### 2026-03-04 / 미니 설정 아이콘 오버레이 위치/입력 안정화
- 상황
  - 미니 설정 아이콘이 도면 확대/이동 상황에서 위치 인지가 어렵거나 stylus 탭 반응이 불안정한 구간이 있었음.
- 수정 내용
  - 아이콘을 캔버스 상단 오버레이 기준으로 고정해 화면에서 일관된 위치로 표시.
  - stylus 탭 이벤트를 동일하게 수신하도록 입력 경로를 보정.
  - 관련 파일
    - `lib/screens/drawing/drawing_screen_ui.part.dart`
    - `lib/screens/drawing/drawing_screen_logic.part.dart`
- 검증
  - 수동 확인 all pass
  - 확대/이동/툴 전환 이후에도 아이콘 접근성 유지

---

## 12. 협업 작업 규칙

1. 진행 단위는 `Step` 기준으로 고정한다.
2. 매 Step마다
   - 구현/수정
   - 자동 검증(`flutter test`, 필요 시 `flutter analyze`)
   - 사용자 수동 테스트 요청
   - 사용자 결과 확인
   순서로 진행한다.
3. 수동 테스트는 Codex가 시나리오 목록을 제시하고, 사용자가 실행 후 결과를 공유한다.
4. Phase 종료 시 로드맵 문서를 반드시 갱신하며, 각 Step별로 아래를 기록한다.
   - 수정 파일
   - 핵심 수정 내용
   - 자동 검증 결과
   - 수동 검증 결과
5. Phase/Step 계획에 없던 기능 수정은 `## 11. 로드맵 외 기능 수정 로그`에 별도로 기록한다.
6. 커밋/푸시는 Codex가 자동 수행한다(별도 확인 질문 없이 진행).
7. 커밋 전에는 아래 자동 생성 파일을 항상 `git restore`로 정리한다.
   - `linux/flutter/generated_plugin_registrant.cc`
   - `linux/flutter/generated_plugins.cmake`
   - `macos/Flutter/GeneratedPluginRegistrant.swift`
   - `windows/flutter/generated_plugin_registrant.cc`
   - `windows/flutter/generated_plugins.cmake`
