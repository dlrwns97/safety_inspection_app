# New Feature Onboarding Guide

## 1. 목표
신규 기능을 추가할 때 구조를 깨지 않고 빠르게 배포하기 위한 실무 가이드다.

## 2. 기본 절차

1. 요구사항을 시나리오 ID 기준으로 쪼갠다.
2. 도메인 규칙/유스케이스/UI를 분리 설계한다.
3. 최소 단위 구현 후 자동 테스트를 먼저 통과시킨다.
4. 수동 시나리오를 실행하고 결과를 기록한다.
5. 로드맵 문서에 수정 파일/핵심 변경/검증 결과를 남긴다.

## 3. 구현 순서 템플릿

### 3.1 Domain

- 규칙이 필요하면 `lib/domain/**/services`에 먼저 추가
- 저장 계약이 필요하면 `lib/domain/**/repositories` 인터페이스 추가

### 3.2 Application

- `lib/application/**/use_cases`에 유스케이스 추가
- 외부 I/O는 인터페이스 의존만 사용

### 3.3 Infrastructure

- 저장소 구현/매퍼/파일 접근을 `lib/infrastructure/**`에 추가
- 직렬화 변경 시 기존 데이터 호환성 확인

### 3.4 Presentation + Screens

- 상태/컨트롤러/ViewModel은 `lib/presentation/**`
- 실제 위젯 렌더/입력 라우팅은 `lib/screens/**`

## 4. Drawing 기능 추가 예시

예시: "새 장비 카테고리 + 마커 상세 입력" 추가

1. `domain`
   - 라벨 정책 반영: `marker_label_domain_service.dart`
2. `application`
   - 생성 유스케이스 분기 추가: `create_equipment_updated_site_use_case.dart`
3. `presentation`
   - 사이드패널 필터/표기 갱신: `marker_side_panel_view_model.dart`
4. `screens`
   - 다이얼로그/탭 UI 추가: `dialogs/*`, `drawing_screen_*`
5. `test`
   - 규칙 테스트 + smoke 시나리오 추가

## 5. 테스트 가이드

필수:

- `flutter test`

권장(변경 범위별):

- domain 규칙: `test/domain/**`
- use case: `test/application/**`
- drawing 안정성: `test/drawing_history_stress_test.dart`
- 회귀 시나리오: `test/smoke/scenario_id_smoke_test.dart`

## 6. 수동 검증 가이드

변경 유형에 따라 아래 시나리오를 선택한다.

- 제스처/입력: `D-01`, `D-03`, `D-06`, `D-07`
- 마커: `D-04`, `D-05`
- 저장/복원: `D-08`, `D-09`
- 사진: `P-01`, `P-02`, `P-03`
- 홈/휴지통: `H-01`, `H-02`, `H-03`

## 7. PR 전 최종 체크리스트

- 레이어 규칙 위반 없는지 점검
- 자동 생성 파일 5종 정리(`git restore`) 여부 확인
- 자동 테스트 통과 확인
- 수동 테스트 결과 확보
- 로드맵 문서 업데이트 완료
