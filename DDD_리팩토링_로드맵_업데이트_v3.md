# DDD 리팩토링 로드맵 v3 (업데이트: 2026-03-03, Phase 1 완료)

## 0. 臾몄꽌 紐⑹쟻怨??ъ슜踰???臾몄꽌???꾩옱 `safety_inspection_app` 肄붾뱶踰좎씠?ㅻ? 湲곗??쇰줈, 湲곕뒫 ?뚭? ?놁씠 DDD 援ъ“濡??④퀎?곸쑝濡??닿??섍린 ?꾪븳 ?ㅽ뻾 臾몄꽌??

?ъ슜 ?먯튃:
1. ?붿빟???꾨땲???묒뾽 吏?쒖꽌濡??ъ슜?쒕떎.
2. 媛?Step 醫낅즺 ???먮룞 寃利?+ ?섎룞 寃利앹쓣 諛섎뱶???섑뻾?쒕떎.
3. ?ㅽ뙣 ??諛붾줈 ?ㅼ쓬 Step?쇰줈 ?섏뼱媛吏 ?딄퀬, ?대떦 Step?먯꽌 濡ㅻ갚 ?먮뒗 ?섏젙 ???ш?利앺븳??
4. Phase 醫낅즺 寃利앸퓧 ?꾨땲??Step 醫낅즺 寃利앹쓣 媛뺤젣?쒕떎.

---

## 0-1. 진행 현황 (v3)
- 완료 Phase
  - Phase 0 (Step 0-1, Step 0-2, Step 0-3)
  - Phase 1 (Step 1-1, Step 1-2, Step 1-3)
- 최근 자동 검증 결과 (Phase 1 마감 기준)
  - flutter analyze lib/screens/home/home_storage.dart lib/screens/home/home_screen.dart lib/screens/home/trash_screen.dart test/smoke/scenario_id_smoke_test.dart: 통과
  - flutter test test/smoke/scenario_id_smoke_test.dart: 통과
- 최근 수동 검증 결과
  - H-01, H-02, H-03: all pass
  - H-01, D-08, P-01: all pass
- 다음 시작점
  - Phase 2 - Step 2-1: Site UseCase 도입

## 0-2. Phase 1 완료 상세 (Step별 수정)
### Step 1-1. 도메인 Repository 인터페이스 정의
- 수정 파일
  - lib/domain/site/repositories/site_repository.dart
  - lib/domain/drawing/repositories/drawing_repository.dart
  - lib/domain/inspection/repositories/photo_repository.dart
- 핵심 변경
  - 도메인 경계 인터페이스를 도입해 저장소 의존 방향을 domain <- infrastructure로 고정.
- 검증
  - 정적 분석/컴파일 기준 정상.

### Step 1-2. 인프라 어댑터 구현
- 수정 파일
  - lib/infrastructure/persistence/shared_prefs/site_prefs_repository.dart
  - lib/infrastructure/persistence/file_store/drawing_file_repository.dart
  - lib/infrastructure/photo/defect_photo_repository.dart
- 핵심 변경
  - 기존 저장소 구현을 인터페이스 어댑터로 감싸 동작 변경 없이 인프라 계층으로 분리.
- 검증
  - 자동: flutter test test/smoke/scenario_id_smoke_test.dart 통과
  - 수동: H-01, D-08, P-01 all pass

### Step 1-3. Home/Trash 정적 저장 호출 경계화
- 수정 파일
  - lib/screens/home/home_storage.dart
  - lib/screens/home/home_screen.dart
  - lib/screens/home/trash_screen.dart
  - test/smoke/scenario_id_smoke_test.dart
- 핵심 변경
  - HomeStorage를 정적 유틸에서 SiteRepository 기반 인스턴스 파사드로 전환.
  - HomeScreen/TrashScreen이 동일 HomeStorage 인스턴스를 주입받아 사용하도록 변경.
  - 스모크 테스트를 인스턴스 호출 기준으로 전환.
- 검증
  - 자동: flutter analyze (대상 4개 파일) 통과, flutter test test/smoke/scenario_id_smoke_test.dart 통과
  - 수동: H-01, H-02, H-03 all pass

---
## 1. ?꾩옱 肄붾뱶 ?ㅻ깄??(?ㅼ륫 湲곗?: 2026-03-03)

### 1-1. 肄붾뱶 蹂쇰ⅷ
- `lib/` 珥?112媛??뚯씪, 24,974以?- `lib/screens/` 95媛??뚯씪, 22,745以?- `lib/screens/drawing/` 84媛??뚯씪, 21,371以?- ?쒕줈???듭떖 4?뚯씪 ?⑷퀎 8,826以?  - `drawing_screen.dart`: 1,858
  - `drawing_screen_logic.part.dart`: 4,658
  - `drawing_screen_ui.part.dart`: 2,201
  - `drawing_screen_scale_prefs.part.dart`: 109

### 1-2. 怨좊났?〓룄 ?뚯씪 Top 15 (以???湲곗?)
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

### 1-3. 寃고빀??寃쎄퀎 ?꾨컲
- Import 寃고빀??  - `screens -> screens`: 135
  - `screens -> models`: 100
  - `models -> screens`: 1
- 紐낆떆??寃쎄퀎 ?꾨컲
  - `lib/models/drawing/drawing_stroke.dart`媛 `screens/drawing/drawing_types.dart`???섏〈
  - `lib/models/drawing_enums.dart`媛 `constants/strings_ko.dart`???섏〈
- UI ?몃? 怨꾩링??UI/?쒗쁽 ?쇳빀
  - ?쇰꺼/?쒖떆 洹쒖튃??`flows/marker_presenters.dart`? `drawing_enums.dart`???쇱옱

### 1-4. I/O 梨낆엫 遺꾩궛 ?곹깭
- ?ъ씠??硫뷀? ??? `lib/models/site_storage.dart` (`SharedPreferences`)
- Home wrapper: `lib/screens/home/home_storage.dart`
- ?쒕줈????? `lib/screens/drawing/persistence/drawing_persistence_store.dart` (JSON file)
- 寃고븿 ?ъ쭊 ??? `lib/screens/drawing/attachments/defect_photo_store.dart`
- ???붾㈃?먯꽌 ?뚯씪/?붾젆?좊━ 吏곸젒 ?묎렐:
  - `lib/screens/home/home_screen.dart`
  - `lib/screens/home/site_photo_orphan_scanner.dart`
- ?쒕줈???붾㈃?먯꽌 `SharedPreferences` 吏곸젒 ?묎렐:
  - `drawing_screen.dart`
  - `drawing_screen_logic.part.dart`
  - `drawing_screen_scale_prefs.part.dart`

### 1-5. ?덉쭏 踰좎씠?ㅻ씪??- `flutter test`: 18媛?以?1媛??ㅽ뙣
  - ?ㅽ뙣: `test/photo_path_ordering_test.dart` case D
  - ?꾩긽: `C:\a\2.jpg`? `/a/2.jpg`媛 ?숇벑 寃쎈줈濡?痍④툒?섏? ?딆븘 以묐났 ?쎌엯
- `flutter analyze`: 111 ?댁뒋
  - warning 11
  - info 100
  - 二쇱슂: `deprecated_member_use`, `unused_field`, `unused_element`, `constant_identifier_names`

---

## 2. 紐⑺몴 ?꾪궎?띿쿂 (DDD + Clean 寃쎄퀎)

### 2-1. ?덉씠???뺤쓽
- Domain
  - ?뷀떚?? 媛믨컼泥? ?꾨찓???쒕퉬?? ?꾨찓??由ы룷吏?좊━ ?명꽣?섏씠??  - Flutter/UI/?뚯씪I/O ?섏〈 湲덉?
- Application
  - UseCase, ?몃옖??뀡 寃쎄퀎, ?뺤콉 議고빀
  - Domain ?명꽣?섏씠???ъ슜
- Infrastructure
  - ?뚯씪/SharedPreferences/PDF/Photo ???援ы쁽泥?  - Domain/Application ?명꽣?섏씠??援ы쁽
- Presentation
  - Flutter ?꾩젽, ViewState, Input Adapter
  - UseCase ?몄텧怨?寃곌낵 諛섏쁺留??대떦

### 2-2. ?섏〈 洹쒖튃
1. `presentation -> application -> domain`
2. `infrastructure -> domain` (?꾩슂 ??`application` DTO 李몄“ ?덉슜)
3. `domain -> (none)` (Flutter, screens, constants 臾몄옄??湲덉?)
4. ?붾㈃ ?뚯씪?먯꽌 `dart:io`, `SharedPreferences`, `path_provider` 吏곸젒 ?몄텧 湲덉?

### 2-3. 沅뚯옣 ?대뜑 泥?궗吏?```text
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

### 2-4. ?꾩옱 ?뚯씪 -> ?源??꾩튂 留ㅽ븨
- Core Model
  - `lib/models/site.dart` -> `lib/domain/site/entities/site.dart`
  - `lib/models/defect.dart` -> `lib/domain/inspection/entities/defect.dart`
  - `lib/models/equipment_marker.dart` -> `lib/domain/inspection/entities/equipment_marker.dart`
  - `lib/models/drawing/drawing_stroke.dart` -> `lib/domain/drawing/entities/drawing_stroke.dart`
  - JSON mapper??`lib/infrastructure/mappers/*`濡?遺꾨━
- Storage/Persistence
  - `lib/models/site_storage.dart` -> `lib/infrastructure/persistence/shared_prefs/site_prefs_repository.dart`
  - `lib/screens/drawing/persistence/drawing_persistence_store.dart` -> `lib/infrastructure/persistence/file_store/drawing_file_repository.dart`
  - `lib/screens/drawing/attachments/defect_photo_store.dart` -> `lib/infrastructure/photo/defect_photo_repository.dart`
- Flow/UseCase
  - `lib/screens/drawing/flows/*.dart` -> `lib/application/inspection/use_cases/*`, `lib/application/drawing/use_cases/*`
  - `lib/screens/home/home_storage.dart` -> ??젣 ??`application/site/use_cases/*`濡??泥?- Presentation
  - `lib/screens/home/*` -> `lib/presentation/home/*`
  - `lib/screens/drawing/*` -> `lib/presentation/drawing/*` (?? ?명봽???좎뒪耳?댁뒪濡?遺꾨━???뚯씪 ?쒖쇅)

---

## 3. ?ㅽ뻾 ?먯튃 (?댁쁺 洹쒖튃)

### 3-1. 蹂寃??⑥쐞
1. Step??理쒕? ?듭떖 梨낆엫 1媛쒕쭔 ?대룞
2. Step ?댁뿉???뚯씪 ?대룞 + 濡쒖쭅 蹂寃??숈떆 ????섑뻾 湲덉?
3. 寃쎄퀎 ?앹꽦(?명꽣?섏씠?? ??援ы쁽 ?닿? ?쒖꽌 怨좎젙

### 3-2. 而ㅻ컠 ?먯튃
1. 而ㅻ컠? Step ?⑥쐞濡?履쇨컿??
2. 而ㅻ컠 硫붿떆吏??`PhaseX-StepY: ...` ?뺤떇 ?ъ슜
3. 由щ꽕???대룞 而ㅻ컠怨??숈옉 蹂寃?而ㅻ컠??遺꾨━?쒕떎.

### 3-3. ?꾩닔 寃利?寃뚯씠??- Step 寃뚯씠??  - ????뚯뒪??+ `flutter test` 理쒖냼 1??  - 二쇱슂 ?섎룞 ?쒕굹由ъ삤 2媛??댁긽
- Phase 寃뚯씠??  - `flutter test` ?꾩껜 ?듦낵
  - `flutter analyze` warning ??紐⑺몴 ?ъ꽦
  - ?쒕굹由ъ삤 移댄깉濡쒓렇???대떦 Phase ??ぉ ?꾨? ?듦낵

---

## 4. ?곸꽭 濡쒕뱶留?(?ㅽ뻾 踰꾩쟾)

## Phase 0. 踰좎씠?ㅻ씪??怨좎젙 (2~3??
紐⑺몴: ?꾩옱 源⑥쭊 ?곹깭瑜?癒쇱? ?뺤긽?뷀븯???댄썑 由ы뙥?좊쭅 由ъ뒪?щ? 以꾩씤??

### Step 0-1. 寃쎈줈 ?뺢퇋???ㅽ뙣 ?뚯뒪??蹂듦뎄 ???꾨즺
????뚯씪:
- `lib/utils/photo_path_ordering.dart`
- `lib/screens/home/site_photo_orphan_scanner.dart`
- `test/photo_path_ordering_test.dart`

?묒뾽:
1. `photoReferenceKey`瑜?Windows/Unix ?숇벑 鍮꾧탳媛 ?섎룄濡?normalize 洹쒖튃 媛뺥솕.
2. 以묐났 ?먮떒 ?ㅼ? ?뺣젹 鍮꾧탳 ?ㅻ? ?숈씪 ?⑥닔濡??듭씪.
3. legacy path(`\`, `/`, drive letter`) 耳?댁뒪瑜??뚯뒪?몄뿉 異붽?.

?먮룞 寃利?
- `flutter test test/photo_path_ordering_test.dart`
- `flutter test`

?섎룞 寃利?
- ?쒕굹由ъ삤 `P-01`, `P-02` ?섑뻾.

濡ㅻ갚 ?ъ씤??
- 寃쎈줈 ?뺢퇋???⑥닔 蹂寃??꾪썑 diff留??섎룎由щ㈃ 蹂듦뎄 媛?ν븯?꾨줉 而ㅻ컠 遺꾨━.

?ㅽ뻾 湲곕줉 (2026-03-03):
- ?섏젙 ?뚯씪
  - `lib/screens/home/site_photo_orphan_scanner.dart`
  - `test/photo_path_ordering_test.dart`
- ?듭떖 ?섏젙
  - `photoReferenceKey` ?뺢퇋??洹쒖튃 媛뺥솕(?щ옒???쒕씪?대툕 ?덊꽣/?몃젅?쇰쭅 ?щ옒??泥섎━).
  - 以묐났 ?먯젙 ?뚭? 耳?댁뒪 異붽?(`drive letter case`, `trailing slash`).
- ?먮룞 寃利?寃곌낵
  - `flutter test test/photo_path_ordering_test.dart` ?듦낵
  - `flutter test` ?듦낵

### Step 0-2. warning 11 -> 0 ???꾨즺
????뚯씪:
- `lib/screens/drawing/drawing_screen.dart`
- `lib/screens/drawing/drawing_screen_logic.part.dart`
- `lib/screens/drawing/drawing_screen_ui.part.dart`

?묒뾽:
1. `unused_field`, `unused_element` ?쒓굅.
2. ?숈옉???곹뼢 ?녿뒗 deprecate 援먯껜瑜??곗꽑 ?곸슜.
3. naming/info ?깃꺽 lint??蹂꾨룄 Phase濡??대룞 媛?ν븯??warning? 利됱떆 ?쒓굅.

?먮룞 寃利?
- `flutter analyze`
- `flutter test`

?섎룞 寃利?
- ?쒕굹由ъ삤 `D-01`, `D-03`, `D-06`.

濡ㅻ갚 ?ъ씤??
- UI/gesture 蹂寃쎌씠 ?ы븿?섎㈃ 利됱떆 以묐떒 ??warning ?쒓굅留??④릿 ?⑥튂濡??ш뎄??

?ㅽ뻾 湲곕줉 (2026-03-03):
- ?섏젙 ?뚯씪
  - `lib/screens/drawing/drawing_screen.dart`
  - `lib/screens/drawing/drawing_screen_logic.part.dart`
  - `lib/screens/drawing/drawing_screen_ui.part.dart`
- ?듭떖 ?섏젙
  - 誘몄궗??field/element ?쒓굅濡?warning ??ぉ ?뺣━.
  - ?ъ슜?섏? ?딅뜕 ?덇굅??UI 釉붾줉/蹂댁“ ?⑥닔 ?쒓굅.
- ?먮룞 寃利?寃곌낵
  - `flutter analyze` warning 0 ?ъ꽦
  - `flutter test` ?듦낵

### Step 0-3. ?ㅻえ???뚯뒪???대쫫 泥닿퀎 怨좎젙 ???꾨즺
????뚯씪:
- `test/` ?좉퇋 smoke ?ㅼ쐞??
?묒뾽:
1. ?듭떖 ?쒕굹由ъ삤 ID(`H-*`, `D-*`, `P-*`)瑜??뚯뒪?몃챸?쇰줈 諛섏쁺.
2. Phase蹂??꾩닔 ?뚯뒪??紐⑸줉??臾몄꽌??

?먮룞 寃利?
- `flutter test`

?섎룞 寃利?
- ?놁쓬 (?뚯뒪??紐⑸줉 ?뺥빀???뺤씤?쇰줈 ?泥?.

?ㅽ뻾 湲곕줉 (2026-03-03):
- ?섏젙 ?뚯씪
  - `test/smoke/scenario_id_smoke_test.dart` (?좉퇋)
  - `PHASE_TEST_CATALOG.md` (?좉퇋)
- ?듭떖 ?섏젙
  - ?쒕굹由ъ삤 ID 湲곗? smoke ?뚯뒪??異붽?(`H-01`, `H-02`, `H-03`, `D-05`, `P-02`).
  - Phase 0 ?꾩닔 ?뚯뒪??移댄깉濡쒓렇 臾몄꽌??
- ?먮룞 寃利?寃곌낵
  - `flutter test test/smoke/scenario_id_smoke_test.dart` ?듦낵
  - `flutter test` ?듦낵

---

## Phase 1. Repository 寃쎄퀎 ?뺣┰ (3~4??
紐⑺몴: ??μ냼 ?묎렐???명꽣?섏씠???ㅻ줈 媛먯떠??Presentation??I/O 吏곸젒 ?몄텧 ?쒓굅 湲곕컲??留뚮뱺??

### Step 1-1. ?꾨찓??Repository ?명꽣?섏씠???뺤쓽
?앹꽦 ?뚯씪:
- `lib/domain/site/repositories/site_repository.dart`
- `lib/domain/drawing/repositories/drawing_repository.dart`
- `lib/domain/inspection/repositories/photo_repository.dart`

?묒뾽:
1. 理쒖냼 API留??뺤쓽 (load/save/delete ?꾩＜).
2. `Site`/`Drawing`/`Photo` ???愿?ъ궗瑜?遺꾨━.

?먮룞 寃利?
- ?뺤쟻 遺꾩꽍 + 而댄뙆??
?섎룞 寃利?
- ?놁쓬.

### Step 1-2. ?명봽???대뙌??援ы쁽 (湲곕뒫 ?숈씪)
???
- `site_storage.dart`, `drawing_persistence_store.dart`, `defect_photo_store.dart`

?묒뾽:
1. 湲곗〈 援ы쁽??adapter class濡?媛먯떬??
2. ?대? 濡쒖쭅? 嫄대뱶由ъ? ?딄퀬 ?명꽣?섏씠?ㅻ쭔 留욎텣??

?먮룞 寃利?
- `flutter test`

?섎룞 寃利?
- ?쒕굹由ъ삤 `H-01`, `D-08`, `P-01`.

### Step 1-3. HomeScreen/TrashScreen???뺤쟻 ????몄텧 ?쒓굅
???
- `home_storage.dart`, `home_screen.dart`, `trash_screen.dart`

?묒뾽:
1. `HomeStorage` ?뺤쟻 硫붿꽌???섏〈??UseCase ?몄텧濡?移섑솚 以鍮?
2. ?꾩떆濡?fa챌ade瑜??????덉쑝???붾㈃? ?명꽣?섏씠?ㅻ? 諛붾씪蹂닿쾶 蹂寃?

?먮룞 寃利?
- `flutter test`
- `flutter analyze`

?섎룞 寃利?
- ?쒕굹由ъ삤 `H-01`, `H-02`, `H-03`.

---

## Phase 2. Application UseCase ?닿? (4~6??
紐⑺몴: `flows/` ?⑥닔 吏묓빀??紐낆떆???좎뒪耳?댁뒪 ?대옒?ㅻ줈 ?밴꺽.

### Step 2-1. Site UseCase ?꾩엯
?앹꽦:
- `application/site/use_cases/load_sites_use_case.dart`
- `application/site/use_cases/create_site_use_case.dart`
- `application/site/use_cases/trash_site_use_case.dart`
- `application/site/use_cases/restore_site_use_case.dart`

寃利?
- ?쒕굹由ъ삤 `H-01`, `H-02`, `H-03`.

### Step 2-2. MarkerInteraction UseCase ?꾩엯
???
- `flows/marker_tap_flow.dart`
- `flows/defect_marker_flow.dart`
- `flows/equipment_pack_*.dart`
- `flows/equipment_updated_site_flow.dart`

?묒뾽:
1. Tap decision, marker ?앹꽦, ?곸꽭 ?낅젰 諛섏쁺??UseCase ?대옒?ㅻ줈 遺꾨━.
2. ?쇰꺼 利앷? 洹쒖튃? ?쇰떒 ?숈씪 蹂듭젣.

寃利?
- `test/marker_presenters_label_test.dart`
- ?쒕굹由ъ삤 `D-04`, `D-05`.

### Step 2-3. PDF UseCase ?꾩엯
???
- `flows/pdf_controller_flow.dart`
- `drawing_screen_logic.part.dart` PDF 愿??釉붾줉

?묒뾽:
1. 濡쒕뱶/援먯껜/?먮윭 泥섎━ ?좎뒪耳?댁뒪 遺꾨━.
2. ?섏씠吏 ???꾩옱 ?섏씠吏/?ㅻ쪟 ?곹깭 諛섏쁺???⑥씪 ?묐떟 紐⑤뜽濡??쒖???

寃利?
- ?쒕굹由ъ삤 `D-02`, `D-03`, `D-08`.

### Step 2-4. DrawingPersistence UseCase ?꾩엯
???
- `drawing_persistence_store.dart`
- `drawing_screen_logic.part.dart` persist loop

寃利?
- ?쒕굹由ъ삤 `D-08`, `D-09`.

---

## Phase 3. DrawingScreen ?곹깭 ?щ씪?댁뒪 遺꾪빐 (?듭떖, 7~10??
紐⑺몴: `_DrawingScreenState` 吏묒쨷 ?곹깭瑜?梨낆엫蹂?state object濡??덈떒.

### Step 3-1. SessionState 遺꾨━
遺꾨━ ???
- `_currentPage`, `_pageCount`, `_pdfController`, `_pdfPageSizes`, `_pdfLoadError`

?좉퇋:
- `presentation/drawing/states/drawing_session_state.dart`

寃利?
- ?쒕굹由ъ삤 `D-02`, `D-03`.

### Step 3-2. ToolState 遺꾨━
遺꾨━ ???
- `_activeTool`, `_activeFamily`, ???뺢킅???꾪삎 ?듭뀡 留? straighten ?듭뀡

?좉퇋:
- `presentation/drawing/states/tool_state.dart`

寃利?
- ?쒕굹由ъ삤 `D-06`, `D-07`.

### Step 3-3. MarkerState 遺꾨━
遺꾨━ ???
- ?좏깮 ID, 移댄뀒怨좊━ ?? 媛?쒖꽦 set, ?⑤꼸 ???곹깭

?좉퇋:
- `presentation/drawing/states/marker_state.dart`

寃利?
- ?쒕굹由ъ삤 `D-04`, `D-05`.

### Step 3-4. GestureState 遺꾨━
遺꾨━ ???
- pointer tracking, nav gesture, eraser session, straighten ?꾩떆 ?곹깭

?좉퇋:
- `presentation/drawing/states/gesture_state.dart`

寃利?
- ?쒕굹由ъ삤 `D-01`, `D-06`, `D-09`.

### Step 3-5. HistoryState/PersistState 遺꾨━
遺꾨━ ???
- undo/redo 媛???곹깭, debounce, in-flight ?뚮옒洹?
?좉퇋:
- `presentation/drawing/states/history_state.dart`
- `presentation/drawing/states/persist_state.dart`

寃利?
- `test/drawing_history_stress_test.dart`
- ?쒕굹由ъ삤 `D-09`.

### Step 3-6. `DrawingScreen` 寃쎈웾??紐⑺몴:
- `DrawingScreen`? ?곹깭 議고빀 + ?꾩젽 援ъ꽦 + ?대깽??諛붿씤?⑸쭔 ?대떦.

?뺣웾 紐⑺몴:
- `drawing_screen*` 8,826以?-> 4,500以??댄븯(1李?紐⑺몴)

寃利?
- ?쒕굹由ъ삤 `D-01` ~ `D-09` ?꾩닔.

---

## Phase 4. Domain ?쒖닔??+ Mapper 遺꾨━ (5~7??
紐⑺몴: ?뷀떚?곕? ?꾨젅?좏뀒?댁뀡/吏곷젹???섏〈?먯꽌 遺꾨━.

### Step 4-1. ?뷀떚??吏곷젹???쒓굅
???
- `site.dart`, `defect.dart`, `equipment_marker.dart`, `drawing_stroke.dart`

?묒뾽:
1. `toJson/fromJson`瑜?mapper ?대옒?ㅻ줈 ?대룞.
2. ?뷀떚?곕뒗 ?쒖닔 ?곗씠??+ ?꾨찓???됱쐞留??좎?.

寃利?
- `test/drawing_serialization_compat_test.dart`
- 湲곗〈 ????곗씠??濡쒕뱶 ?명솚 ?섎룞 寃利?

### Step 4-2. ?꾨찓????쓽議??쒓굅
利됱떆 ?닿껐 ???
- `drawing_stroke.dart -> drawing_types.dart`
- `drawing_enums.dart -> strings_ko.dart`

?묒뾽:
1. `DrawingTool`???꾨찓??enum 踰꾩쟾 ?뺤쓽.
2. UI ?쇰꺼? presenter/provider濡??대룞.

?뺣웾 紐⑺몴:
- `models/domain -> screens` import 0

### Step 4-3. ?쇰꺼/?쒕쾲 洹쒖튃 Domain Service?????
- `flows/marker_presenters.dart`

?묒뾽:
1. ?쒕쾲/?묐몢???쒖떆?쇰꺼 濡쒖쭅??Domain Service濡??닿?.
2. ?붾㈃? 寃곌낵 臾몄옄?대쭔 ?섏떊.

寃利?
- `test/marker_presenters_label_test.dart`

---

## Phase 5. Dialog/SidePanel ?꾨젅?좏뀒?댁뀡 ?뺣━ (3~5??
紐⑺몴: Dialog媛 I/O瑜?紐곕씪???섎룄濡??낅젰 ?섏쭛 ?꾩슜??

### Step 5-1. Defect Dialog???뚯씪 ?묎렐 ?쒓굅
???
- `dialogs/defect_details_dialog.dart`
- `dialogs/photo_manager_dialog.dart`

?묒뾽:
1. ?뚯씪 ???????젣瑜?Application ?쒕퉬?ㅻ줈 ?대룞.
2. Dialog??DTO ?낅젰/寃곌낵 諛섑솚留??섑뻾.

寃利?
- ?쒕굹由ъ삤 `P-01`, `P-02`, `P-03`.

### Step 5-2. Equipment Dialog援??뺣━
???
- `equipment_details_dialog.dart`, `rebar_spacing_dialog.dart`, 湲고? ?λ퉬 ?ㅼ씠?쇰줈洹?
?묒뾽:
1. 媛?寃利앹? validator/service濡??닿?.
2. Dialog???꾨뱶 ?뚮뜑留?+ submit留??대떦.

寃利?
- ?쒕굹由ъ삤 `D-05`.

### Step 5-3. SidePanel ViewModel ?꾩엯
???
- `widgets/side_panel/marker_side_panel.dart`

?묒뾽:
1. ?쒓린 臾몄옄???뺣젹/?꾪꽣 濡쒖쭅??ViewModel濡??대룞.
2. ?꾩젽 ?몃━???뚮뜑留??꾩슜??

寃利?
- ?쒕굹由ъ삤 `D-04`, `D-05`.

---

## Phase 6. ?뚯뒪??泥닿퀎 ?뺤옣 (吏?? 5~7??
紐⑺몴: 援ъ“ 由ы뙥?좊쭅 ?댄썑 ?뚭? 媛먯떆留?媛뺥솕.

### Step 6-1. Domain ?뚯뒪???뺤옣
異붽? ?뚯뒪??
- ?쇰꺼 ?쒕쾲/?묐몢??洹쒖튃
- 媛?쒖꽦 ?꾪꽣 洹쒖튃
- shape bounds/rotation 怨꾩궛
- 寃쎄퀎媛??낅젰 寃利?
### Step 6-2. Application ?뚯뒪???뺤옣
異붽? ?뚯뒪??
- site create/trash/restore usecase
- marker interaction usecase
- drawing persistence usecase
- pdf replace/load usecase

### Step 6-3. ?뚭? ?쒕굹由ъ삤 ?뚯뒪??異붽? ?뚯뒪??
- PDF 援먯껜 -> ?섏씠吏 ?대룞 -> 留덉빱 ?앹꽦 -> ???-> ?ъ떎??蹂듭썝
- pen/highlighter/shape/eraser ?쇳빀 ??undo/redo ?덉젙??- orphan photo scan/restore/cleanup

### Step 6-4. ?κ린 ?덉젙??異붽? ?뚯뒪??
- 100???댁긽 undo/redo 諛섎났
- ?ㅼ쨷 ?섏씠吏(10p+)?먯꽌 ?깅뒫/硫붾え由??뺤씤

---

## Phase 7. ?깅뒫/?뺣━ 留덈Т由?(3~4??
紐⑺몴: 肄붾뱶 ?덉쭏 泥닿컧 媛쒖꽑怨??좎?蹂댁닔??留덇컧.

### Step 7-1. 二쎌? 肄붾뱶/?ㅽ뀅 ?뺣━
???
- `engines/eraser_engine_v2.dart`
- `engines/text_engine.dart`

?묒뾽:
1. ?ㅼ젣 誘몄궗?⑹씠硫??쒓굅.
2. ?ν썑 怨꾪쉷???덉쑝硫?TODO媛 ?꾨땲??紐낆떆 ?댁뒋 留곹겕濡?愿由?

### Step 7-2. ?섏씤??罹먯떆 寃쎈줈 ?뺣━
???
- `temp_polyline_painter.dart`
- `stroke_cache_manager.dart`

?묒뾽:
1. 以묐났 ?뚮뜑留?寃쎈줈 理쒖냼??
2. deprecated API 援먯껜 ?꾨즺.

### Step 7-3. 臾몄꽌/?⑤낫??留덇컧
?곗텧臾?
- ?꾪궎?띿쿂 媛쒖슂 臾몄꽌
- ?덉씠??洹쒖튃 臾몄꽌
- ?좉퇋 湲곕뒫 異붽? 媛?대뱶

---

## 5. Step 醫낅즺 ?섎룞 寃利??쒕굹由ъ삤 移댄깉濡쒓렇

### Home/?ъ씠??- `H-01` ?꾩옣 ?앹꽦
  - PDF/鍮?罹붾쾭???????앹꽦 媛??  - 援ъ“?뺤떇/?먭??뺤떇/?먭????쒖떆 ?뺤긽
- `H-02` ?댁????뚮줈??  - ??젣 -> ?댁????대룞 -> 蹂듭썝 -> ?곴뎄??젣
- `H-03` ???ъ떎??蹂듭썝
  - Home 紐⑸줉/??젣 ?곹깭 ?숈씪

### Drawing/PDF/Marker
- `D-01` 罹붾쾭???쒖뒪泥?  - ?ㅽ??쇰윭???쒕줈?? 2?먭????ㅻ퉬寃뚯씠??異⑸룎 ?놁쓬
- `D-02` PDF 濡쒕뱶/?먮윭
  - ?뚯씪 ?놁쓬/?먯긽 ?뚯씪 ?먮윭 硫붿떆吏 ?뺤긽
- `D-03` ?섏씠吏 ?대룞
  - ?댁쟾/?ㅼ쓬, ?섏씠吏 ?몃뵒耳?댄꽣, ?섏씠吏蹂??ㅻ쾭?덉씠 ?뺥빀
- `D-04` 寃고븿 留덉빱 ?뚮줈??  - ??異붽?/??젣, ?좏깮/?댁젣, ?곸꽭 ?섏젙 諛섏쁺
- `D-05` ?λ퉬 留덉빱 ?뚮줈??  - 移댄뀒怨좊━蹂??쇰꺼 洹쒖튃, ?곸꽭媛????諛섏쁺
- `D-06` ?꾧뎄 ?꾪솚
  - ???뺢킅???꾪삎/吏?곌컻 ?꾪솚 諛??듭뀡 ?좎?
- `D-07` ??援듦린/?щ챸??  - ?꾧뎄蹂?留덉?留??ъ슜媛?蹂댁〈
- `D-08` ???蹂듭썝
  - 洹몃━湲???媛뺤쥌/?ъ떎??蹂듭썝
  - PDF 援먯껜 ?꾨룄 ?뺤긽 蹂듭썝
- `D-09` ?덉뒪?좊━
  - undo/redo 100??諛섎났 ?덉젙??  - clear pen/highlighter/all ?숈옉 ?쇨???
### Photo/泥⑤?
- `P-01` 寃고븿 ?ъ쭊 異붽?/援먯껜/??젣
  - ?먮낯紐?sidecar) 蹂댁〈
- `P-02` 怨좎븘 ?ъ쭊 ?ㅼ틪/蹂듭썝
  - ?숈씪 寃쎈줈 以묐났 ?쎌엯 ?놁쓬
- `P-03` 怨좎븘 ?ъ쭊 ?뺣━
  - ?ㅼ젣 ?뚯씪/sidecar ?숈떆 ?뺣━

---

## 6. ?먮룞 ?꾪궎?띿쿂 媛?쒕젅??(?뺢린 ?먭? 紐낅졊)

1. ?꾨찓?몄뿉???붾㈃ ?섏〈 湲덉?
```powershell
rg -n "package:safety_inspection_app/screens/" lib/domain lib/models
```

2. ?꾨젅?좏뀒?댁뀡??吏곸젒 I/O 湲덉? (理쒖쥌 紐⑺몴)
```powershell
rg -n "dart:io|SharedPreferences|getApplicationDocumentsDirectory|FilePicker|ImagePicker" lib/presentation
```

3. 怨꾩링 寃쎄퀎 ?꾨컲 媛먯떆
```powershell
rg -n "package:safety_inspection_app/presentation/" lib/domain lib/application lib/infrastructure
```

4. ?듭떖 ?덉쭏 寃뚯씠??```powershell
flutter test
flutter analyze
```

---

## 7. ?뺣웾 ?꾨즺 湲곗? (Definition of Done)

### ?꾪궎?띿쿂
- `domain/models -> screens/presentation` import 0
- `presentation/screens`?먯꽌 吏곸젒 ?뚯씪 I/O ?몄텧 0
- `drawing_screen*` 珥앺빀 8,826 -> 2,500 ?댄븯 (理쒖쥌 紐⑺몴)
- `drawing_screen*` 珥앺빀 8,826 -> 4,500 ?댄븯 (以묎컙 紐⑺몴, Phase 3 醫낅즺)

### ?덉쭏
- `flutter test` 100% ?듦낵
- `flutter analyze` warning 0
- deprecate 二쇱슂 ??ぉ ?뺣━ ?꾨즺 (`Color.value`, `withOpacity`, 援щ쾭??callback)

### ?좎?蹂댁닔??- ?좉퇋 ?λ퉬 移댄뀒怨좊━ 異붽? ???섏젙 ?뚯씪 3媛??댄븯
- 留덉빱 ?쇰꺼 ?뺤콉 蹂寃???Domain/Application留??섏젙 媛??- ??μ냼 援먯껜 ??Infrastructure 怨꾩링 蹂寃쎈쭔?쇰줈 ???媛??
---

## 8. 2二??μ삤???ㅽ뻾??(沅뚯옣)

### Week 1
1. Day 1: Step 0-1 寃쎈줈 ?뺢퇋??蹂듦뎄 + ?뚯뒪??green
2. Day 2: Step 0-2 warning 0 ?ъ꽦
3. Day 3: Step 1-1 Repository ?명꽣?섏씠???뺤쓽
4. Day 4: Step 1-2 ?명봽???대뙌???곸슜
5. Day 5: Step 1-3 Home ????몄텧 寃쎄퀎??
### Week 2
1. Day 6: Step 2-1 Site UseCase
2. Day 7: Step 2-2 MarkerInteraction UseCase
3. Day 8: Step 2-3 PDF UseCase
4. Day 9: Step 3-1 SessionState, Step 3-2 ToolState ?쒖옉
5. Day 10: Step 3-3 MarkerState + ?뚭? 寃利?
---

## 9. 지금 바로 시작할 실행 순서 (실무용)

1. 완료 Phase 1-1 Repository 인터페이스 정의
2. 완료 Phase 1-2 인프라 어댑터 적용 (동작 변경 금지)
3. 완료 Phase 1-3 Home/Trash 정적 저장 호출 경계화
4. 다음 Phase 2-1 Site UseCase 도입
5. 다음 Phase 2-2 MarkerInteraction UseCase 도입
6. 다음 각 Step 종료 후 시나리오 ID 기준 수동 검증 로그 기록
---
## 10. 硫붾え
- ??臾몄꽌???붿빟蹂몄씠 ?꾨땲???ㅽ뻾蹂몄씠誘濡? ?ㅼ젣 ?묒뾽 以??レ옄/?쇱씤 ???댁뒋 ?섍? 諛붾뚮㈃ Step ?꾨즺 ??利됱떆 媛깆떊?쒕떎.
- 蹂寃?以묎컙???숈옉 由ъ뒪?ш? 而ㅼ?硫? Phase瑜?硫덉텛怨?Step ?⑥쐞濡????섍쾶 履쇨컻???ъ쭊?됲븳??

---

## 11. 濡쒕뱶留???湲곕뒫 ?섏젙 濡쒓렇

### 2026-03-03 / 寃고븿 ?ъ쭊 移대찓???먮낯紐??쒖떆 蹂댁젙
- ?곹솴
  - 媛ㅻ윭由??뚯씪 ?좏깮 寃쎈줈???먮낯 ?뚯씪紐낆씠 ?쒖떆?섎뒗?? 移대찓??珥ъ쁺 寃쎈줈???꾩떆 ?대쫫(`image_picker...`)???쒖떆?섎뒗 臾몄젣媛 ?덉뿀??
- ?섏젙 ?댁슜
  - 移대찓??寃쎈줈?먯꽌 ?섎? ?녿뒗 ?꾩떆 ?대쫫???쒖쇅?섍퀬 ?뚯씪紐?蹂댁젙 濡쒖쭅 異붽?.
  - ?????sidecar 硫뷀??곗씠??`originalName`)??蹂댁젙???먮낯紐낆쓣 ?곗꽑 ??ν븯?꾨줉 `DefectPhotoStore` ???API ?뺤옣.
  - 愿???뚯씪
    - `lib/screens/drawing/dialogs/defect_details_dialog.dart`
    - `lib/screens/drawing/attachments/defect_photo_store.dart`
- 寃利?  - `flutter test` ?꾩껜 ?듦낵
  - ?ㅼ젣 ???섎룞 ?뺤씤?먯꽌 移대찓??珥ъ쁺 ?ъ쭊???뚯씪紐??쒖떆 ?뺤긽??
### 2026-03-03 / 移대찓??fallback ?뚯씪紐??묐몢??議곗젙
- ?곹솴
  - ??蹂댁젙 ?댄썑 fallback ?뚯씪紐낆뿉 `IMG_` ?묐몢?ш? 遺숈뼱 ?쒖떆?섎뒗 UX ?쇰뱶諛?諛쒖깮.
- ?섏젙 ?댁슜
  - fallback ?뚯씪紐??뺤떇??`IMG_YYYYMMDD_HHMMSS.ext` -> `YYYYMMDD_HHMMSS.ext`濡?蹂寃?
  - 愿???뚯씪
    - `lib/screens/drawing/dialogs/defect_details_dialog.dart`
- 寃利?  - `flutter test` ?꾩껜 ?듦낵
  - ?ㅼ젣 ???섎룞 ?뺤씤?먯꽌 ?묐몢???놁씠 湲곕????뚯씪紐??쒖떆

---

## 12. ?묒뾽 ?묒뾽 洹쒖튃

1. 吏꾪뻾 ?⑥쐞??`Step` 湲곗??쇰줈 怨좎젙?쒕떎.
2. 留?Step留덈떎
   - 援ы쁽/?섏젙
   - ?먮룞 寃利?`flutter test`, ?꾩슂 ??`flutter analyze`)
   - ?ъ슜???섎룞 ?뚯뒪???붿껌
   - ?ъ슜??寃곌낵 ?뺤씤
   ?쒖꽌濡?吏꾪뻾?쒕떎.
3. ?섎룞 ?뚯뒪?몃뒗 Codex媛 ?쒕굹由ъ삤 紐⑸줉???쒖떆?섍퀬, ?ъ슜?먭? ?ㅽ뻾 ??寃곌낵瑜?怨듭쑀?쒕떎.
4. Phase 醫낅즺 ??濡쒕뱶留?臾몄꽌瑜?諛섎뱶??媛깆떊?섎ŉ, 媛?Step蹂꾨줈 ?꾨옒瑜?湲곕줉?쒕떎.
   - ?섏젙 ?뚯씪
   - ?듭떖 ?섏젙 ?댁슜
   - ?먮룞 寃利?寃곌낵
   - ?섎룞 寃利?寃곌낵
5. Phase/Step 怨꾪쉷???녿뜕 湲곕뒫 ?섏젙? `## 11. 濡쒕뱶留???湲곕뒫 ?섏젙 濡쒓렇`??蹂꾨룄濡?湲곕줉?쒕떎.
6. 而ㅻ컠/?몄떆??Codex媛 ?먮룞 ?섑뻾?쒕떎(蹂꾨룄 ?뺤씤 吏덈Ц ?놁씠 吏꾪뻾).
7. 而ㅻ컠 ?꾩뿉???꾨옒 ?먮룞 ?앹꽦 ?뚯씪????긽 `git restore`濡??뺣━?쒕떎.
   - `linux/flutter/generated_plugin_registrant.cc`
   - `linux/flutter/generated_plugins.cmake`
   - `macos/Flutter/GeneratedPluginRegistrant.swift`
   - `windows/flutter/generated_plugin_registrant.cc`
   - `windows/flutter/generated_plugins.cmake`



