# Layer Rules

## 1. 의존 방향 규칙

허용 방향:

- `domain` -> (없음, 순수 규칙)
- `application` -> `domain`
- `presentation` -> `application`, `domain`(읽기 모델/타입)
- `screens` -> `presentation`, `application`, `domain`(필요 최소)
- `infrastructure` -> `domain`, `application` 모델

금지 방향:

- `domain` -> `screens`, `presentation`, `infrastructure`
- `application` -> `screens`, `infrastructure` 구현체 직접 참조
- `presentation` -> `dart:io`, `SharedPreferences`, 파일 시스템 직접 접근

## 2. 계층별 책임

- `domain`
  - 규칙/정책
  - 인터페이스(Repository 계약)
- `application`
  - 유스케이스 단위 트랜잭션
  - 여러 도메인 규칙 조합
- `presentation`
  - 화면 상태(State), 컨트롤러, ViewModel
- `screens`
  - 위젯 렌더링, 사용자 입력 수집, 이벤트 연결
- `infrastructure`
  - 실제 저장/로드, 직렬화 매핑, 외부 I/O

## 3. 파일 배치 기준

- 신규 Repository 인터페이스: `lib/domain/**/repositories`
- 신규 UseCase: `lib/application/**/use_cases`
- 신규 상태/컨트롤러/ViewModel: `lib/presentation/**`
- 신규 저장소 구현/매퍼: `lib/infrastructure/**`
- 신규 UI 위젯/화면 로직: `lib/screens/**`

## 4. 금지 패턴

- 화면 파일에서 직접 `File`, `Directory`, `getApplicationDocumentsDirectory` 사용
- domain 모델에 `toJson/fromJson` 직접 구현(매퍼 우선)
- UI 라벨/문구 규칙을 엔티티 내부에서 직접 처리

## 5. 권장 패턴

- 입력 검증은 `application/services`로 분리
- 라벨/순번 정책은 `domain/services`로 분리
- 화면은 UseCase 반환값을 렌더링하는 방향으로 유지
- 회귀 가능성이 큰 기능은 smoke 시나리오 테스트 추가

## 6. 점검 명령(정기 실행)

```powershell
rg -n "package:safety_inspection_app/screens/" lib/domain lib/models
rg -n "dart:io|SharedPreferences|getApplicationDocumentsDirectory|FilePicker|ImagePicker" lib/presentation
rg -n "package:safety_inspection_app/presentation/" lib/domain lib/application lib/infrastructure
flutter test
```

## 7. 변경 전 체크리스트

- 수정 대상이 올바른 계층인지 확인
- interface 변경 시 구현체 + 테스트 동시 수정
- 직렬화 포맷 변경 시 호환 테스트 존재 여부 확인
- Step 완료 전에 자동/수동 검증 결과 기록
