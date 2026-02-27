# DDD 리팩토링 로드맵 - Safety Inspection App

## 목차
1. [현재 아키텍처 분석](#1-현재-아키텍처-분석)
2. [핵심 문제점 진단](#2-핵심-문제점-진단)
3. [목표 DDD 아키텍처](#3-목표-ddd-아키텍처)
4. [도메인 식별 및 바운디드 컨텍스트](#4-도메인-식별-및-바운디드-컨텍스트)
5. [단계별 리팩토링 로드맵](#5-단계별-리팩토링-로드맵)
6. [파일별 이동/변환 매핑](#6-파일별-이동변환-매핑)
7. [의존성 방향 규칙](#7-의존성-방향-규칙)
8. [테스트 전략](#8-테스트-전략)

---

## 1. 현재 아키텍처 분석

### 1.1 현재 디렉토리 구조
```
lib/
├── main.dart
├── constants/
│   └── strings_ko.dart
├── models/                          # 데이터 모델 + 영속성 로직 혼재
│   ├── defect.dart
│   ├── defect_details.dart
│   ├── drawing_enums.dart
│   ├── equipment_marker.dart
│   ├── rebar_spacing_group_details.dart
│   ├── site.dart
│   ├── site_storage.dart            # ⚠️ 영속성 로직이 모델에 존재
│   └── drawing/
│       ├── drawing_history_action_persisted.dart
│       ├── drawing_stroke.dart
│       ├── eraser_preview.dart
│       ├── temp_stroke.dart
│       └── text_box_data.dart
├── screens/                         # UI + 비즈니스 로직 + 플로우 전부 혼재
│   ├── home/
│   │   ├── home_screen.dart         # ⚠️ 파일 I/O, 네비게이션, 비즈니스 로직 혼재
│   │   ├── home_storage.dart
│   │   ├── site_photo_orphan_scanner.dart
│   │   ├── trash_screen.dart
│   │   ├── dialogs/
│   │   └── widgets/
│   └── drawing/
│       ├── drawing_screen.dart      # ⚠️ GOD CLASS: 90+개 상태변수, 2000+줄
│       ├── drawing_screen_ui.part.dart
│       ├── drawing_screen_logic.part.dart
│       ├── drawing_screen_scale_prefs.part.dart
│       ├── drawing_controller.dart
│       ├── drawing_coordinate_utils.dart
│       ├── drawing_types.dart
│       ├── drawing_constants.dart
│       ├── canvas/                  # 캔버스 렌더링 (10개 파일)
│       ├── engines/                 # 드로잉 엔진 (6개 파일)
│       ├── history/                 # Undo/Redo (3개 파일)
│       ├── persistence/             # 파일 영속성 (1개 파일)
│       ├── attachments/             # 사진 저장 (1개 파일)
│       ├── models/                  # 프리셋 (1개 파일)
│       ├── flows/                   # ⚠️ 유스케이스인데 screens 안에 존재 (10개 파일)
│       ├── dialogs/                 # 다이얼로그 (15개 파일)
│       └── widgets/                 # 위젯 (13+11개 파일)
├── utils/
│   └── photo_path_ordering.dart
└── widgets/
    ├── mode_button.dart
    └── drawing/
        ├── shape_handles_overlay.dart
        └── temp_polyline_painter.dart
```

### 1.2 현재 파일 통계
| 구분 | 파일 수 | 비고 |
|------|---------|------|
| Models | 12 | 데이터 클래스 + 영속성 혼재 |
| Screens (Home) | 8 | 비교적 단순 |
| Screens (Drawing) | 77 | 심각한 결합도 |
| Utils/Widgets | 4 | 공통 유틸리티 |
| Constants | 1 | 한국어 문자열 |
| Tests | 5 | 커버리지 매우 낮음 |
| **합계** | **~102** | |

---

## 2. 핵심 문제점 진단

### 2.1 God Class 문제 (심각도: 🔴 Critical)
**`DrawingScreen` + part 파일들**
- 인스턴스 변수 **90개 이상**
- 3개 part 파일로 분리했지만 여전히 **하나의 State 클래스**
- 드로잉, 마커관리, PDF뷰어, 히스토리, 영속성, 도구설정이 **전부 한 클래스에** 존재
- 단일 책임 원칙(SRP) 완전 위반

### 2.2 비즈니스 로직이 UI에 혼재 (심각도: 🔴 Critical)
| 위치 | 혼재된 비즈니스 로직 |
|------|---------------------|
| `home_screen.dart` | PDF 파일 복사, 현장 생성 플로우, 고아 사진 스캔 |
| `drawing_screen.dart` | 스트로크 생성/조작, 지우개 연산, 도형 변환, 히스토리 관리, 영속성 |
| `defect_details_dialog.dart` | 사진 선택/저장/삭제, 파일 I/O |
| `marker_side_panel.dart` | 결함/장비 필터링, 상세정보 빌드 |

### 2.3 영속성 레이어 분산 (심각도: 🟠 High)
- `SiteStorage` → SharedPreferences에 사이트 메타데이터 저장
- `HomeStorage` → SiteStorage를 래핑 (불필요한 중간 계층)
- `DrawingPersistenceStore` → 파일시스템에 드로잉 데이터 저장
- `DefectPhotoStore` → 사진 파일 I/O
- **통합된 Repository 패턴 부재**

### 2.4 상태관리 부재 (심각도: 🟠 High)
- Provider, BLoC, Riverpod 등 **상태관리 프레임워크 없음**
- 순수 `setState()` + `ValueNotifier` + `ChangeNotifier` 조합
- 콜백 함수가 위젯 트리를 따라 **5~6단계** 전달
- 테스트 불가능한 구조

### 2.5 도메인 모델 빈약 (심각도: 🟡 Medium)
- `Site`가 사실상 **Aggregate Root**이지만, 비즈니스 로직은 외부 flow 파일에 분산
- `Defect`, `EquipmentMarker`는 순수 데이터 홀더 (Anemic Domain Model)
- 도메인 규칙(라벨 생성, 카테고리 검증 등)이 presenter/flow에 흩어져 있음

### 2.6 의존성 방향 위반 (심각도: 🟡 Medium)
```
models/ ← (OK)
  ↓
screens/ → models/  (OK)
screens/ → screens/ (⚠️ 순환 의존 위험)
models/drawing_stroke.dart → screens/drawing/drawing_types.dart (🔴 역방향!)
```

---

## 3. 목표 DDD 아키텍처

### 3.1 4-Layer 아키텍처
```
┌──────────────────────────────────────────────────┐
│                 Presentation Layer                │
│         (Screens, Widgets, State Holders)         │
│  • UI 렌더링만 담당                                 │
│  • 상태관리를 통해 Application Layer와 통신           │
└──────────────┬───────────────────────────────────┘
               │ depends on ↓
┌──────────────▼───────────────────────────────────┐
│                Application Layer                  │
│            (Use Cases, State Notifiers)           │
│  • 유스케이스(비즈니스 플로우) 오케스트레이션           │
│  • Domain 엔티티 조합                               │
│  • Repository 인터페이스 사용                        │
└──────────────┬───────────────────────────────────┘
               │ depends on ↓
┌──────────────▼───────────────────────────────────┐
│                  Domain Layer                     │
│    (Entities, Value Objects, Repository Interfaces)│
│  • 핵심 비즈니스 규칙                                │
│  • 외부 의존성 ZERO                                 │
│  • 순수 Dart (Flutter 의존 없음)                     │
└──────────────────────────────────────────────────┘
               ↑ implements
┌──────────────────────────────────────────────────┐
│              Infrastructure Layer                 │
│     (Repository Impl, Storage, File I/O)         │
│  • Domain의 Repository 인터페이스 구현               │
│  • SharedPreferences, 파일시스템 접근                │
│  • 외부 패키지 의존                                  │
└──────────────────────────────────────────────────┘
```

### 3.2 목표 디렉토리 구조
```
lib/
├── main.dart
├── app.dart                                    # MaterialApp 설정
├── di/                                         # 의존성 주입
│   └── service_locator.dart
│
├── domain/                                     # 🟢 Domain Layer (순수 Dart)
│   ├── site/
│   │   ├── entities/
│   │   │   └── site.dart                       # Site Aggregate Root
│   │   ├── value_objects/
│   │   │   ├── site_metadata.dart              # 현장명, 구조물종류, 점검유형 등
│   │   │   └── site_id.dart
│   │   ├── repositories/
│   │   │   └── site_repository.dart            # 인터페이스
│   │   └── services/
│   │       └── site_domain_service.dart         # 현장 도메인 규칙
│   │
│   ├── inspection/
│   │   ├── entities/
│   │   │   ├── defect.dart                     # 결함 Entity
│   │   │   └── equipment_marker.dart           # 장비마커 Entity
│   │   ├── value_objects/
│   │   │   ├── defect_details.dart
│   │   │   ├── defect_category.dart
│   │   │   ├── equipment_category.dart
│   │   │   ├── rebar_spacing_group.dart
│   │   │   ├── marker_position.dart            # normalizedX/Y 캡슐화
│   │   │   └── measurement_values.dart         # 각종 측정값 VO
│   │   ├── repositories/
│   │   │   └── inspection_repository.dart      # 인터페이스
│   │   └── services/
│   │       ├── defect_label_service.dart        # 라벨 생성 규칙
│   │       └── equipment_label_service.dart     # 장비 라벨 규칙
│   │
│   └── drawing/
│       ├── entities/
│       │   └── drawing_stroke.dart             # 스트로크 Entity
│       ├── value_objects/
│       │   ├── stroke_style.dart               # 스트로크 스타일 VO
│       │   ├── text_box_data.dart
│       │   ├── stroke_tool_kind.dart
│       │   ├── pen_variant.dart
│       │   └── shape_type.dart
│       ├── repositories/
│       │   └── drawing_repository.dart         # 인터페이스
│       └── services/
│           ├── stroke_factory.dart             # 스트로크 생성 규칙
│           ├── eraser_service.dart             # 지우개 도메인 로직
│           └── shape_geometry_service.dart     # 도형 기하학 계산
│
├── application/                                # 🔵 Application Layer
│   ├── site/
│   │   ├── site_list_use_case.dart             # 현장 목록 조회/생성/삭제
│   │   ├── site_trash_use_case.dart            # 휴지통 관리
│   │   └── site_state.dart                     # 현장 상태 관리
│   │
│   ├── inspection/
│   │   ├── defect_marker_use_case.dart         # 결함 마커 생성/수정/삭제
│   │   ├── equipment_marker_use_case.dart      # 장비 마커 CRUD
│   │   ├── equipment_pack_a_use_case.dart      # 팩A 플로우
│   │   ├── equipment_pack_b_use_case.dart      # 팩B 플로우
│   │   ├── equipment_pack_c_use_case.dart      # 팩C 플로우
│   │   ├── equipment_pack_d_use_case.dart      # 팩D 플로우
│   │   └── photo_management_use_case.dart      # 사진 관리
│   │
│   └── drawing/
│       ├── drawing_session_use_case.dart        # 드로잉 세션 관리
│       ├── history_use_case.dart                # Undo/Redo 오케스트레이션
│       ├── tool_selection_use_case.dart         # 도구 선택/설정
│       └── drawing_persistence_use_case.dart    # 저장/로드 오케스트레이션
│
├── infrastructure/                             # 🟠 Infrastructure Layer
│   ├── persistence/
│   │   ├── shared_prefs_site_repository.dart   # SiteRepository 구현
│   │   ├── file_drawing_repository.dart        # DrawingRepository 구현
│   │   └── file_photo_repository.dart          # 사진 파일 I/O 구현
│   ├── mappers/
│   │   ├── site_mapper.dart                    # Site ↔ JSON 변환
│   │   ├── defect_mapper.dart                  # Defect ↔ JSON 변환
│   │   ├── equipment_marker_mapper.dart
│   │   ├── drawing_stroke_mapper.dart
│   │   └── history_action_mapper.dart
│   └── services/
│       ├── pdf_file_service.dart               # PDF 파일 복사/관리
│       └── photo_picker_service.dart           # 카메라/갤러리 접근
│
├── presentation/                               # 🟣 Presentation Layer
│   ├── home/
│   │   ├── home_screen.dart                    # 순수 UI
│   │   ├── home_state_notifier.dart            # 상태 관리
│   │   ├── trash_screen.dart
│   │   ├── widgets/
│   │   │   ├── site_list_tile.dart
│   │   │   └── home_overflow_menu.dart
│   │   └── dialogs/
│   │       ├── new_site_dialog.dart
│   │       └── site_trash_dialogs.dart
│   │
│   ├── drawing/
│   │   ├── drawing_screen.dart                 # 순수 UI (경량화)
│   │   ├── drawing_state_notifier.dart         # 드로잉 상태 관리
│   │   ├── tool_state_notifier.dart            # 도구 상태 관리
│   │   ├── marker_state_notifier.dart          # 마커 상태 관리
│   │   │
│   │   ├── canvas/                             # 캔버스 렌더링 (유지)
│   │   │   ├── drawing_canvas_controller.dart
│   │   │   ├── drawing_canvas_widget.dart
│   │   │   ├── cached_image_painter.dart
│   │   │   ├── centerline_style_utils.dart
│   │   │   ├── eraser_cursor_painter.dart
│   │   │   ├── eraser_preview_painter.dart
│   │   │   ├── live_stroke_painter.dart
│   │   │   ├── preview_strokes_painter.dart
│   │   │   ├── spatial_index.dart
│   │   │   └── stroke_cache_manager.dart
│   │   │
│   │   ├── engines/                            # 렌더링 엔진 (Presentation)
│   │   │   ├── pen_engine.dart
│   │   │   ├── highlighter_engine.dart
│   │   │   ├── eraser_engine_v2.dart
│   │   │   ├── shape_engine.dart
│   │   │   ├── shape_manipulator.dart
│   │   │   └── text_engine.dart
│   │   │
│   │   ├── widgets/
│   │   │   ├── drawing_scaffold_body.dart
│   │   │   ├── drawing_top_bar.dart
│   │   │   ├── tool_selection_row.dart
│   │   │   ├── tool_detail_row.dart
│   │   │   ├── tool_header_row.dart
│   │   │   ├── pen_settings_popup.dart
│   │   │   ├── highlighter_settings_popup.dart
│   │   │   ├── eraser_settings_popup.dart
│   │   │   ├── color_picker_dialog.dart
│   │   │   ├── settings_popover.dart
│   │   │   ├── canvas_marker_layer.dart
│   │   │   ├── pdf_drawing_view.dart
│   │   │   ├── pdf_view_layer.dart
│   │   │   ├── marker_filter_chips.dart
│   │   │   ├── marker_details_content.dart
│   │   │   ├── narrow_dialog_frame.dart
│   │   │   ├── numbered_tabs.dart
│   │   │   └── drawing_local_parts.dart
│   │   │
│   │   ├── side_panel/                         # 사이드 패널
│   │   │   ├── marker_side_panel.dart
│   │   │   ├── marker_side_panel_header.dart
│   │   │   ├── marker_side_panel_body.dart
│   │   │   ├── marker_side_panel_list_section.dart
│   │   │   ├── marker_side_panel_list_item_tile.dart
│   │   │   ├── marker_side_panel_details_section.dart
│   │   │   ├── marker_side_panel_action_bar.dart
│   │   │   ├── marker_header_controls.dart
│   │   │   ├── marker_info_banner.dart
│   │   │   ├── marker_list.dart
│   │   │   ├── marker_detail_section.dart
│   │   │   └── marker_view_tab.dart
│   │   │
│   │   └── dialogs/
│   │       ├── defect_details_dialog.dart
│   │       ├── defect_category_picker_sheet.dart
│   │       ├── defect_photo_thumbnails_section.dart
│   │       ├── equipment_details_dialog.dart
│   │       ├── equipment_category_picker_sheet.dart
│   │       ├── carbonation_dialog.dart
│   │       ├── core_sampling_dialog.dart
│   │       ├── deflection_dialog.dart
│   │       ├── rebar_spacing_dialog.dart
│   │       ├── schmidt_hammer_dialog.dart
│   │       ├── settlement_dialog.dart
│   │       ├── structural_tilt_dialog.dart
│   │       ├── delete_defect_tab_dialog.dart
│   │       ├── delete_equipment_tab_dialog.dart
│   │       ├── dialog_field_builders.dart
│   │       ├── photo_manager_dialog.dart
│   │       └── photo_source_bottom_sheet.dart
│   │
│   └── shared/
│       ├── widgets/
│       │   ├── mode_button.dart
│       │   ├── shape_handles_overlay.dart
│       │   └── temp_polyline_painter.dart
│       └── constants/
│           └── strings_ko.dart
│
└── core/                                       # 🔘 공통 유틸리티
    ├── utils/
    │   ├── photo_path_ordering.dart
    │   └── coordinate_utils.dart
    └── extensions/
        └── list_extensions.dart
```

---

## 4. 도메인 식별 및 바운디드 컨텍스트

### 4.1 Bounded Contexts 식별

```
┌─────────────────────────────────────────────────────────────┐
│                    Safety Inspection App                     │
│                                                             │
│  ┌──────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │   Site Mgmt  │  │   Inspection     │  │   Drawing    │  │
│  │   Context    │  │   Context        │  │   Context    │  │
│  │              │  │                  │  │              │  │
│  │ • Site       │  │ • Defect         │  │ • Stroke     │  │
│  │ • SiteList   │  │ • EquipmentMarker│  │ • StrokeStyle│  │
│  │ • Trash      │  │ • DefectDetails  │  │ • TextBox    │  │
│  │              │  │ • Measurements   │  │ • History    │  │
│  │              │  │ • Photos         │  │ • Canvas     │  │
│  └──────┬───────┘  └────────┬─────────┘  └──────┬───────┘  │
│         │                   │                    │          │
│         └───────────────────┼────────────────────┘          │
│                             │                               │
│                    Site = Aggregate Root                     │
│              (Defects + Markers + Strokes 소유)              │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Aggregate Root: Site

```dart
// domain/site/entities/site.dart
class Site {
  final SiteId id;
  final SiteMetadata metadata;
  final List<Defect> defects;
  final List<EquipmentMarker> equipmentMarkers;
  final DrawingData drawingData;  // strokes + history
  final TrashInfo? trashInfo;

  // 비즈니스 메서드 (현재 flow 파일들에 흩어진 로직 흡수)
  Defect addDefect({...});
  void removeDefect(String defectId);
  EquipmentMarker addEquipmentMarker({...});
  void moveToTrash();
  void restore();
  String nextDefectLabel(DefectCategory category, int pageIndex);
  String nextEquipmentLabel(EquipmentCategory category);
}
```

### 4.3 Entities

| Entity | 현재 위치 | 역할 | 식별자 |
|--------|----------|------|--------|
| `Site` | `models/site.dart` | Aggregate Root - 점검 현장 | `id: String` |
| `Defect` | `models/defect.dart` | 결함 마커 | `id: String` |
| `EquipmentMarker` | `models/equipment_marker.dart` | 장비 마커 | `id: String` |
| `DrawingStroke` | `models/drawing/drawing_stroke.dart` | 드로잉 스트로크 | `id: String` |

### 4.4 Value Objects (새로 추출)

| Value Object | 추출 원천 | 불변 데이터 |
|-------------|----------|------------|
| `SiteId` | `Site.id` | UUID 문자열 |
| `SiteMetadata` | `Site`의 name, structureType 등 | 현장 메타 정보 |
| `MarkerPosition` | Defect/Equipment의 normalizedX/Y | 정규화 좌표 |
| `DefectCategory` | `drawing_enums.dart` | 결함 분류 |
| `EquipmentCategory` | `drawing_enums.dart` | 장비 분류 |
| `DefectDetails` | `defect_details.dart` | 결함 상세 정보 |
| `StrokeStyle` | `DrawingStroke.style` | 스트로크 스타일 |
| `TextBoxData` | `text_box_data.dart` | 텍스트 박스 데이터 |
| `MeasurementValues` | `EquipmentMarker`의 측정값들 | 각종 측정값 |
| `RebarSpacingGroup` | `rebar_spacing_group_details.dart` | 철근 간격 그룹 |

### 4.5 Domain Services

| Service | 현재 위치 | 흡수할 로직 |
|---------|----------|------------|
| `DefectLabelService` | `marker_presenters.dart` | `defectDisplayLabel()`, `defectLabelPrefix()` |
| `EquipmentLabelService` | `marker_presenters.dart` | `equipmentDisplayLabel()`, 라벨 순서 규칙 |
| `StrokeFactory` | `drawing_screen.dart` (흩어진 코드) | 스트로크 생성, ID 생성 |
| `EraserService` | `eraser_engine_v2.dart` (일부) | 지우개 마스크 계산 도메인 로직 |
| `ShapeGeometryService` | `shape_engine.dart` (일부) | 도형 좌표 계산 (순수 기하학) |

---

## 5. 단계별 리팩토링 로드맵

### Phase 0: 사전 준비 (1~2일)
> 리팩토링을 안전하게 진행하기 위한 기반 작업

#### 0-1. 상태관리 프레임워크 도입 결정
```yaml
# pubspec.yaml에 추가 (권장: flutter_riverpod)
dependencies:
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0
```

**선택지:**
| 옵션 | 장점 | 단점 |
|------|-----|------|
| **Riverpod (권장)** | 컴파일 타임 안전성, 테스트 용이, DDD 궁합 | 학습 곡선 |
| BLoC | 이벤트 기반, 큰 팀에 적합 | 보일러플레이트 많음 |
| Provider | 간단, 이미 Flutter 생태계 표준 | Riverpod보다 기능 부족 |

#### 0-2. 기존 테스트 보강
현재 **5개 테스트**로는 리팩토링 안전망이 부족함.
```
우선 추가할 테스트:
├── test/models/site_serialization_test.dart        # Site JSON 왕복 테스트
├── test/models/defect_serialization_test.dart       # Defect JSON 왕복 테스트
├── test/models/equipment_marker_test.dart           # EquipmentMarker JSON 왕복 테스트
├── test/screens/drawing/flows/defect_marker_flow_test.dart  # 결함 생성 플로우
└── test/screens/home/home_storage_test.dart          # 저장/로드 통합 테스트
```

#### 0-3. 의존성 주입 컨테이너 설정
```dart
// lib/di/service_locator.dart
// Riverpod Provider 기반 DI 설정
```

---

### Phase 1: Domain Layer 추출 (3~5일)
> 가장 핵심적인 단계. 순수 비즈니스 로직을 외부 의존성 없이 분리.

#### 1-1. Value Objects 추출
```
작업 순서:
1. DefectCategory, EquipmentCategory enum → domain/inspection/value_objects/
2. StrokeToolKind, PenVariant enum → domain/drawing/value_objects/
3. MarkerPosition (normalizedX/Y 캡슐화) → domain/inspection/value_objects/
4. SiteMetadata (name, structureType 등) → domain/site/value_objects/
5. DefectDetails → domain/inspection/value_objects/
6. TextBoxData → domain/drawing/value_objects/
7. StrokeStyle → domain/drawing/value_objects/
```

**핵심 규칙:** Value Object는 `dart:core`만 의존. Flutter import 없음.

#### 1-2. Entity 리팩토링
```
작업 순서:
1. Defect → domain/inspection/entities/defect.dart
   - toJson/fromJson 제거 → Infrastructure Mapper로 이동
   - 비즈니스 메서드 추가 (updateDetails, addPhoto 등)

2. EquipmentMarker → domain/inspection/entities/equipment_marker.dart
   - toJson/fromJson 제거
   - copyWith은 유지 (불변 업데이트 패턴)

3. DrawingStroke → domain/drawing/entities/drawing_stroke.dart
   - toJson/fromJson 제거
   - generateId()는 Factory로 이동
   - 렌더링 관련 코드 분리 (Presentation으로)

4. Site → domain/site/entities/site.dart
   - Aggregate Root로 승격
   - 비즈니스 메서드 흡수 (flows에서 가져오기)
   - toJson/fromJson 제거
```

#### 1-3. Repository 인터페이스 정의
```dart
// domain/site/repositories/site_repository.dart
abstract class SiteRepository {
  Future<List<Site>> loadAll();
  Future<void> save(Site site);
  Future<void> saveAll(List<Site> sites);
  Future<void> delete(String siteId);
}

// domain/drawing/repositories/drawing_repository.dart
abstract class DrawingRepository {
  Future<List<DrawingStroke>> loadStrokes(String siteId);
  Future<void> saveStrokes(String siteId, List<DrawingStroke> strokes);
  Future<void> deleteDrawing(String siteId);
}

// domain/inspection/repositories/inspection_repository.dart
abstract class InspectionRepository {
  Future<void> savePhoto(String siteId, String defectId, String sourcePath);
  Future<void> deletePhoto(String siteId, String photoPath);
  Future<List<String>> getPhotoPaths(String siteId, String defectId);
}
```

#### 1-4. Domain Services 추출
```
작업 순서:
1. marker_presenters.dart의 라벨 생성 로직 →
   - DefectLabelService.generateLabel()
   - EquipmentLabelService.generateLabel()

2. drawing_screen.dart의 스트로크 생성 로직 →
   - StrokeFactory.createPenStroke()
   - StrokeFactory.createHighlighterStroke()
   - StrokeFactory.createShapeStroke()

3. shape_engine.dart의 기하학 계산 →
   - ShapeGeometryService.buildPoints()
   - ShapeGeometryService.calculateBounds()

4. eraser_engine_v2.dart의 마스크 계산 →
   - EraserService.computeMask()
```

---

### Phase 2: Infrastructure Layer 구축 (2~3일)
> Repository 구현체 + JSON 매핑 분리

#### 2-1. Mapper 클래스 생성
```
현재 각 Entity의 toJson/fromJson을 Mapper로 추출:

1. SiteMapper
   - toJson(Site) → Map<String, dynamic>
   - fromJson(Map<String, dynamic>) → Site
   - 레거시 포맷 호환 로직 포함

2. DefectMapper
3. EquipmentMarkerMapper
4. DrawingStrokeMapper (레거시 호환 로직이 가장 복잡)
5. HistoryActionMapper
```

#### 2-2. Repository 구현
```
1. SharedPrefsSiteRepository implements SiteRepository
   - 기존 SiteStorage + HomeStorage 로직 통합
   - HomeStorage 클래스 제거

2. FileDrawingRepository implements DrawingRepository
   - 기존 DrawingPersistenceStore 로직 흡수
   - compute() 사용한 백그라운드 인코딩 유지

3. FilePhotoRepository implements InspectionRepository
   - 기존 DefectPhotoStore 로직 흡수
```

#### 2-3. 외부 서비스 래퍼
```
1. PdfFileService
   - PDF 파일 복사 (home_screen.dart에서 추출)
   - 경로 관리

2. PhotoPickerService
   - ImagePicker/FilePicker 래핑
   - 기존 defect_details_dialog.dart에서 추출
```

---

### Phase 3: Application Layer 구축 (3~5일)
> Use Case 클래스 작성. 비즈니스 플로우 오케스트레이션.

#### 3-1. Site Management Use Cases
```dart
// application/site/site_list_use_case.dart
class SiteListUseCase {
  final SiteRepository _siteRepo;
  final DrawingRepository _drawingRepo;
  final PdfFileService _pdfService;

  Future<List<Site>> loadSites();
  Future<Site> createSite(String name, SiteMetadata metadata, String? pdfPath);
  Future<void> updateSite(Site site);
}

// application/site/site_trash_use_case.dart
class SiteTrashUseCase {
  Future<void> moveToTrash(String siteId);
  Future<void> restore(String siteId);
  Future<void> permanentlyDelete(String siteId);
  Future<void> emptyTrash();
}
```

#### 3-2. Inspection Use Cases (기존 flows/ 흡수)
```
현재 파일 → Use Case 매핑:

defect_marker_flow.dart → DefectMarkerUseCase
  - createDefect()
  - updateDefect()
  - deleteDefect()

equipment_pack_a_flow.dart → EquipmentPackAUseCase
equipment_pack_b_flow.dart → EquipmentPackBUseCase
equipment_pack_c_flow.dart → EquipmentPackCUseCase
equipment_pack_d_flow.dart → EquipmentPackDUseCase

marker_tap_flow.dart → MarkerInteractionUseCase
  - handleTap()
  - selectMarker()

equipment_updated_site_flow.dart → (EquipmentMarkerUseCase에 통합)

photo_manager_dialog.dart 내 로직 → PhotoManagementUseCase
  - pickAndSavePhoto()
  - deletePhoto()
```

#### 3-3. Drawing Use Cases (DrawingScreen 분해)
```
DrawingScreen의 90+ 상태변수를 분리:

1. DrawingSessionUseCase
   - 드로잉 세션 시작/종료
   - 페이지 전환
   - 캔버스/PDF 모드 관리

2. HistoryUseCase
   - undo()
   - redo()
   - clearHistory()
   (기존 HistoryManager를 래핑)

3. ToolSelectionUseCase
   - selectTool()
   - updateToolSettings()
   - 도구별 설정 관리

4. DrawingPersistenceUseCase
   - autoSave() (디바운스 포함)
   - manualSave()
   - loadDrawing()
```

---

### Phase 4: Presentation Layer 리팩토링 (5~7일)
> 가장 큰 작업. DrawingScreen God Class 분해.

#### 4-1. DrawingScreen 상태 분리 (Riverpod StateNotifier 사용)

```dart
// 현재: _DrawingScreenState에 90+개 변수
// 목표: 4~5개의 StateNotifier로 분리

// 1. DrawingStateNotifier - 드로잉 코어 상태
class DrawingState {
  final int currentPage;
  final int pageCount;
  final bool hasUnsavedChanges;
  final Map<int, List<DrawingStroke>> strokesByPage;
  // ... 드로잉 관련 상태만
}

// 2. ToolStateNotifier - 도구 선택/설정 상태
class ToolState {
  final DrawMode mode;
  final DrawingTool activeTool;
  final ToolFamily activeFamily;
  final PenUiType activePenType;
  final Map<PenVariant, double> penWidthByType;
  final Map<PenVariant, int> penColorByType;
  // ... 도구 관련 상태만
}

// 3. MarkerStateNotifier - 마커/점검 상태
class MarkerState {
  final String? selectedDefectId;
  final String? selectedEquipmentId;
  final Set<String> visibleDefectCategories;
  final Set<String> visibleEquipmentCategories;
  // ... 마커 관련 상태만
}

// 4. CanvasInteractionStateNotifier - 캔버스 인터랙션
class CanvasInteractionState {
  final double markerScale;
  final double labelScale;
  final bool isScaleLocked;
  final Offset? eraserCursorPageLocal;
  // ... 인터랙션 관련 상태만
}
```

#### 4-2. DrawingScreen 위젯 경량화
```dart
// presentation/drawing/drawing_screen.dart
// Before: 2000+ 줄, 90+ 상태변수
// After: ~200줄, UI 조합만 담당

class DrawingScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingState = ref.watch(drawingStateProvider);
    final toolState = ref.watch(toolStateProvider);
    final markerState = ref.watch(markerStateProvider);

    return Scaffold(
      appBar: DrawingTopBar(toolState: toolState, ...),
      body: Row(
        children: [
          Expanded(child: DrawingScaffoldBody(...)),
          if (markerState.isSidePanelOpen)
            MarkerSidePanel(...),
        ],
      ),
    );
  }
}
```

#### 4-3. HomeScreen 정리
```
HomeScreen은 상대적으로 단순하므로:
1. 파일 I/O 로직 → SiteListUseCase로 이동
2. PDF 선택/복사 → PdfFileService로 이동
3. 고아 사진 스캔 → PhotoManagementUseCase로 이동
4. 남은 UI 코드만 유지
```

#### 4-4. part 파일 제거
```
drawing_screen_ui.part.dart       → 별도 위젯으로 분리
drawing_screen_logic.part.dart    → UseCase/StateNotifier로 이동
drawing_screen_scale_prefs.part.dart → ToolStateNotifier로 이동
```

---

### Phase 5: 테스트 & 안정화 (3~5일)

#### 5-1. Domain Layer 테스트 (순수 유닛 테스트)
```
test/domain/
├── site/
│   ├── site_test.dart                  # Site 비즈니스 메서드
│   ├── site_metadata_test.dart
│   └── site_domain_service_test.dart
├── inspection/
│   ├── defect_test.dart
│   ├── equipment_marker_test.dart
│   ├── defect_label_service_test.dart
│   └── equipment_label_service_test.dart
└── drawing/
    ├── drawing_stroke_test.dart
    ├── stroke_factory_test.dart
    ├── eraser_service_test.dart
    └── shape_geometry_service_test.dart
```

#### 5-2. Application Layer 테스트 (Use Case 테스트)
```
test/application/
├── site/
│   ├── site_list_use_case_test.dart
│   └── site_trash_use_case_test.dart
├── inspection/
│   ├── defect_marker_use_case_test.dart
│   └── equipment_marker_use_case_test.dart
└── drawing/
    ├── drawing_session_use_case_test.dart
    └── history_use_case_test.dart
```

#### 5-3. Infrastructure Layer 테스트
```
test/infrastructure/
├── mappers/
│   ├── site_mapper_test.dart
│   ├── drawing_stroke_mapper_test.dart    # 기존 serialization_compat_test 흡수
│   └── equipment_marker_mapper_test.dart
└── persistence/
    ├── shared_prefs_site_repository_test.dart
    └── file_drawing_repository_test.dart
```

#### 5-4. 기존 테스트 마이그레이션
```
기존 테스트 → 새 위치 매핑:

drawing_coordinate_accuracy_test.dart → test/domain/drawing/shape_geometry_test.dart
                                       + test/core/coordinate_utils_test.dart
drawing_history_stress_test.dart      → test/application/drawing/history_use_case_test.dart
drawing_serialization_compat_test.dart→ test/infrastructure/mappers/drawing_stroke_mapper_test.dart
marker_presenters_label_test.dart     → test/domain/inspection/label_service_test.dart
photo_path_ordering_test.dart         → test/core/utils/photo_path_ordering_test.dart
```

---

## 6. 파일별 이동/변환 매핑

### 6.1 models/ → domain/ + infrastructure/

| 현재 파일 | 이동 대상 | 변환 내용 |
|-----------|----------|----------|
| `models/site.dart` | `domain/site/entities/site.dart` | toJson/fromJson 제거, 비즈니스 메서드 추가 |
| `models/site_storage.dart` | `infrastructure/persistence/shared_prefs_site_repository.dart` | Repository 인터페이스 구현으로 변환 |
| `models/defect.dart` | `domain/inspection/entities/defect.dart` | toJson/fromJson 제거 |
| `models/defect_details.dart` | `domain/inspection/value_objects/defect_details.dart` | VO로 변환, photoDisplayName은 Presenter로 |
| `models/drawing_enums.dart` | `domain/inspection/value_objects/` (분리) | DefectCategory, EquipmentCategory 분리 |
| `models/equipment_marker.dart` | `domain/inspection/entities/equipment_marker.dart` | toJson/fromJson 제거 |
| `models/rebar_spacing_group_details.dart` | `domain/inspection/value_objects/rebar_spacing_group.dart` | JSON 직렬화 분리 |
| `models/drawing/drawing_stroke.dart` | `domain/drawing/entities/drawing_stroke.dart` | toJson/fromJson 제거, 헬퍼 함수 분리 |
| `models/drawing/drawing_history_action_persisted.dart` | `infrastructure/mappers/history_action_mapper.dart` | 영속성 전용이므로 Infra로 |
| `models/drawing/eraser_preview.dart` | `presentation/drawing/canvas/eraser_preview.dart` | UI 상태이므로 Presentation으로 |
| `models/drawing/temp_stroke.dart` | `presentation/drawing/canvas/temp_stroke.dart` | UI 상태이므로 Presentation으로 |
| `models/drawing/text_box_data.dart` | `domain/drawing/value_objects/text_box_data.dart` | VO로 변환 |

### 6.2 screens/drawing/flows/ → application/

| 현재 파일 | 이동 대상 |
|-----------|----------|
| `flows/defect_marker_flow.dart` | `application/inspection/defect_marker_use_case.dart` |
| `flows/equipment_pack_a_flow.dart` | `application/inspection/equipment_pack_a_use_case.dart` |
| `flows/equipment_pack_b_flow.dart` | `application/inspection/equipment_pack_b_use_case.dart` |
| `flows/equipment_pack_c_flow.dart` | `application/inspection/equipment_pack_c_use_case.dart` |
| `flows/equipment_pack_d_flow.dart` | `application/inspection/equipment_pack_d_use_case.dart` |
| `flows/equipment_updated_site_flow.dart` | `application/inspection/equipment_marker_use_case.dart` (통합) |
| `flows/marker_tap_flow.dart` | `application/inspection/marker_interaction_use_case.dart` |
| `flows/marker_presenters.dart` | `domain/inspection/services/` (라벨 로직) + `presentation/` (표시 로직) |
| `flows/drawing_lookup_helpers.dart` | `domain/site/services/site_query_service.dart` |
| `flows/pdf_controller_flow.dart` | `presentation/drawing/drawing_state_notifier.dart` |

### 6.3 screens/drawing/ 기타 → 재배치

| 현재 파일 | 이동 대상 | 이유 |
|-----------|----------|------|
| `drawing_screen.dart` + parts | `presentation/drawing/drawing_screen.dart` | 경량화 후 이동 |
| `drawing_controller.dart` | `application/drawing/` (로직) + `presentation/` (UI 결정) | 분리 |
| `drawing_types.dart` | `domain/drawing/value_objects/drawing_tool.dart` | 도메인 타입 |
| `drawing_constants.dart` | `presentation/shared/constants/` + `domain/` (분리) | 도메인 상수 vs UI 상수 분리 |
| `drawing_coordinate_utils.dart` | `core/utils/coordinate_utils.dart` | 공통 유틸리티 |
| `persistence/drawing_persistence_store.dart` | `infrastructure/persistence/file_drawing_repository.dart` | Infra 구현체 |
| `attachments/defect_photo_store.dart` | `infrastructure/persistence/file_photo_repository.dart` | Infra 구현체 |
| `models/stroke_presets.dart` | `presentation/drawing/constants/stroke_presets.dart` | UI 프리셋 |
| `history/history_manager.dart` | `application/drawing/history_use_case.dart` | 유스케이스 |
| `history/history_commands.dart` | `application/drawing/commands/` | 커맨드 패턴 유지 |
| `history/history_types.dart` | `application/drawing/commands/` | 타입 정의 |

---

## 7. 의존성 방향 규칙

### 7.1 허용되는 의존성
```
Presentation → Application → Domain ← Infrastructure
     ↓              ↓           ↑          ↑
     └──────────────┴───────────┘          │
                                           │
              core/ ←──────────────────────┘
```

### 7.2 금지되는 의존성
```
❌ Domain → Infrastructure  (Domain은 구현체를 모름)
❌ Domain → Presentation    (Domain은 UI를 모름)
❌ Domain → Application     (Domain은 유스케이스를 모름)
❌ Application → Presentation (유스케이스는 UI를 모름)
❌ Infrastructure → Presentation
```

### 7.3 각 레이어별 허용 import

| Layer | 허용 import |
|-------|------------|
| **Domain** | `dart:core`, `dart:math`, `dart:collection` 만 |
| **Application** | Domain, `dart:async` |
| **Infrastructure** | Domain, `dart:convert`, `dart:io`, 외부 패키지 (shared_preferences, path_provider 등) |
| **Presentation** | Application, Domain, `package:flutter/*`, UI 패키지 (pdfx, perfect_freehand 등) |

### 7.4 현재 위반 사항 수정 필요
```
🔴 models/drawing/drawing_stroke.dart → screens/drawing/drawing_types.dart
   수정: DrawingTool enum을 domain/drawing/value_objects/로 이동

🔴 models/drawing_enums.dart → constants/strings_ko.dart
   수정: UI 라벨은 Presentation에서 처리, Domain enum은 순수하게 유지

🟡 models/defect_details.dart → package:path
   수정: photoDisplayName()은 Presentation Presenter로 이동
```

---

## 8. 테스트 전략

### 8.1 테스트 피라미드

```
         ╱╲
        ╱  ╲        Widget Tests (10%)
       ╱    ╲       - 주요 화면 렌더링 검증
      ╱──────╲
     ╱        ╲     Integration Tests (20%)
    ╱          ╲    - UseCase + Repository 통합
   ╱────────────╲
  ╱              ╲  Unit Tests (70%)
 ╱                ╲ - Domain Entity/VO/Service
╱──────────────────╲- Application UseCase (Mock Repository)
                     - Infrastructure Mapper
```

### 8.2 테스트 커버리지 목표

| Layer | 목표 커버리지 | 이유 |
|-------|-------------|------|
| Domain | **95%+** | 핵심 비즈니스 로직, 가장 중요 |
| Application | **85%+** | 유스케이스 플로우 검증 |
| Infrastructure | **80%+** | JSON 매핑 호환성 중요 |
| Presentation | **50%+** | Widget 테스트는 선택적 |

### 8.3 테스트 원칙
- Domain 테스트는 **Mock 없이** 순수 유닛 테스트
- Application 테스트는 Repository **Mock** 사용
- Infrastructure Mapper 테스트는 **레거시 JSON 호환성** 반드시 검증
- 기존 5개 테스트 **절대 삭제 금지** → 새 위치로 마이그레이션

---

## 부록: 전체 타임라인 요약

```
Week 1: Phase 0 (사전 준비) + Phase 1 전반 (Domain 추출 시작)
  ├── Day 1-2: 상태관리 도입, 기존 테스트 보강, DI 설정
  ├── Day 3-4: Value Objects 추출, Entity 리팩토링
  └── Day 5:   Repository 인터페이스 정의, Domain Services 추출

Week 2: Phase 1 후반 + Phase 2 (Infrastructure)
  ├── Day 1-2: Domain Layer 마무리, Domain 테스트 작성
  ├── Day 3-4: Mapper 생성, Repository 구현
  └── Day 5:   외부 서비스 래퍼, Infrastructure 테스트

Week 3: Phase 3 (Application Layer)
  ├── Day 1-2: Site/Inspection Use Cases
  ├── Day 3-4: Drawing Use Cases, History Use Case
  └── Day 5:   Application 테스트

Week 4-5: Phase 4 (Presentation 리팩토링)
  ├── Day 1-3: DrawingScreen 상태 분리 (StateNotifier)
  ├── Day 4-5: DrawingScreen UI 경량화
  ├── Day 6-7: HomeScreen 정리
  └── Day 8-9: part 파일 제거, 위젯 분리

Week 5-6: Phase 5 (테스트 & 안정화)
  ├── Day 1-3: 전체 테스트 커버리지 확보
  ├── Day 4-5: 기존 테스트 마이그레이션
  └── Day 6:   최종 검증, 불필요 파일 정리
```

---

## 핵심 리팩토링 원칙

1. **점진적 마이그레이션**: 한 번에 전체를 바꾸지 않음. 각 Phase는 독립 배포 가능
2. **테스트 먼저**: 기존 기능의 테스트를 작성한 후 리팩토링 시작
3. **의존성 역전**: Domain이 중심, 나머지가 Domain에 의존
4. **기존 동작 보존**: 리팩토링 중 기능 변경 절대 금지
5. **레거시 호환**: JSON 직렬화 포맷은 하위 호환 유지 (기존 사용자 데이터 보호)
