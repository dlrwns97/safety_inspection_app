class StringsKo {
  static const appTitle = '현장 안전 점검';
  static const homeTitle = '점검 현장';
  static const newSite = '새 현장';
  static const siteNameLabel = '현장명';
  static const siteNameRequired = '현장명을 입력해주세요.';
  static const structureTypeLabel = '구조형식';
  static const structureTypeRequired = '구조형식을 선택해주세요.';
  static const inspectionTypeLabel = '점검형식';
  static const inspectionTypeRequired = '점검형식을 선택해주세요.';
  static const cancel = '취소';
  static const create = '생성';
  static const delete = '삭제';
  static const deleteSiteTitle = '현장 삭제';
  static const deleteSiteToTrashMessage =
      '‘{siteName}’ 현장을 삭제할까요? (휴지통으로 이동합니다.)';
  static const trashTitle = '휴지통';
  static const trashMenuLabel = '휴지통';
  static const trashEmptyTitle = '휴지통이 비어 있습니다';
  static const trashEmptySubtitle = '삭제한 현장이 이곳에 표시됩니다.';
  static const restore = '복원';
  static const permanentDelete = '영구삭제';
  static const permanentDeleteTitle = '영구 삭제';
  static const permanentDeleteMessage =
      '‘{siteName}’ 현장을 영구 삭제할까요? (삭제하면 복구할 수 없습니다.)';
  static const emptyTrash = '휴지통 비우기';
  static const emptyTrashTitle = '휴지통 비우기';
  static const emptyTrashMessage =
      '휴지통의 현장을 모두 영구 삭제할까요? (삭제하면 복구할 수 없습니다.)';
  static const importPdfTitle = 'PDF 도면 가져오기';
  static const importPdfSubtitle = '대용량 및 다중 페이지 PDF 지원';
  static const createBlankTitle = '빈 캔버스 만들기';
  static const createBlankSubtitle = '깨끗한 도면에서 시작';
  static const noSitesTitle = '등록된 현장이 없습니다';
  static const noSitesSubtitle = '현장을 생성해 도면에 결함을 표시하세요.';
  static const pdfDrawingLabel = 'PDF 도면';
  static const blankCanvasLabel = '빈 캔버스';
  static const pageLabel = '페이지';
  static const pdfDrawingLoaded = 'PDF 도면이 로드되었습니다';
  static const pdfDrawingHint = '핀치로 확대하고 탭하여 결함을 추가하세요.';
  static const pdfDrawingLoadFailed = 'PDF 도면을 불러오지 못했습니다.';
  static const replacePdfTooltip = 'PDF 다시 선택';
  static const defectDetailsTitle = '결함 상세';
  static const defectDetailsTitleGeneralCrack = '균열 결함 상세';
  static const defectDetailsTitleWaterLeakage = '누수 결함 상세';
  static const defectDetailsTitleConcreteSpalling = '콘크리트 결함 상세';
  static const defectDetailsTitleOther = '기타 결함 상세';
  static const structuralMemberLabel = '부재';
  static const crackTypeLabel = '유형';
  static const widthLabel = '폭 (mm)';
  static const lengthLabel = '길이 (mm)';
  static const causeLabel = '원인';
  static const selectMemberError = '부재를 선택해주세요';
  static const selectCrackTypeError = '유형을 선택해주세요';
  static const enterWidthError = '폭을 입력해주세요';
  static const enterLengthError = '길이를 입력해주세요';
  static const selectCauseError = '원인을 선택해주세요';
  static const enterOtherTypeError = '기타 유형을 입력해주세요';
  static const enterOtherCauseError = '기타 원인을 입력해주세요';
  static const confirm = '확인';
  static const modePlaceholder = '모드 설정은 1단계에서 임시로 제공됩니다.';
  static const defectModeLabel = '결함';
  static const equipmentModeLabel = '장비';
  static const freeDrawModeLabel = '자유 그리기';
  static const eraserModeLabel = '지우개';
  static const selectDefectCategoryHint = '결함 유형을 선택해주세요.';
  static const selectEquipmentCategoryHint = '장비 탭을 선택해주세요.';
  static const defectCategoryGeneralCrack = '균열';
  static const defectCategoryWaterLeakage = '누수';
  static const defectCategoryConcreteSpalling = '콘크리트 결함';
  static const defectCategorySteelDefect = '철골 결함';
  static const defectCategoryOther = '기타 결함';
  static const equipmentCategory1 = '장비1';
  static const equipmentCategory2 = '철근배근간격';
  static const equipmentCategory3 = '슈미트해머';
  static const equipmentCategory4 = '코어채취';
  static const equipmentCategory5 = '콘크리트 탄산화';
  static const equipmentCategory6 = '구조물 기울기';
  static const equipmentCategory7 = '부재처짐';
  static const equipmentCategory8 = '부동침하';
  static const otherOptionLabel = '기타';
  static const otherTypeLabel = '기타 유형';
  static const otherCauseLabel = '기타 원인';
  static const unsetLabel = '미설정';
  static const noInspectionDateLabel = '날짜없음';

  static const List<String> structureTypes = [
    '철근콘크리트구조',
    '철골철근콘크리트구조',
    '철골구조',
    '조적조',
    '조적조+철골조',
  ];

  static const List<String> inspectionTypes = [
    '정기안전점검',
    '정밀안전점검',
    '정밀안전진단',
    '내진성능평가',
    '구조안전진단',
  ];

  static const List<String> structuralMembers = ['기둥', '벽체', '슬래브', '보', '조적벽'];

  static const List<String> defectTypesGeneralCrack = [
    '수직 균열',
    '수평 균열',
    '사선 균열',
    '수직·수평 균열',
    '망상 균열',
    otherOptionLabel,
  ];

  static const List<String> defectTypesWaterLeakage = [
    '누수 흔적',
    '누수 균열',
    '누수 진행중',
    otherOptionLabel,
  ];

  static const List<String> defectTypesConcreteSpalling = [
    '콘크리트 박락',
    '콘크리트 박리',
    '철근 노출',
    otherOptionLabel,
  ];

  static const List<String> defectTypesOther = [
    '마감재 들뜸',
    '마감재 탈락',
    otherOptionLabel,
  ];

  static const List<String> defectCausesGeneralCrack = [
    '건조 수축',
    '우각부 균열',
    '접합부 균열',
    '하중 및 응력 집중',
    otherOptionLabel,
  ];

  static const List<String> defectCausesWaterLeakage = [
    '우수 유입 추정',
    '배관 누수 추정',
    '균열부 우수 침투',
    otherOptionLabel,
  ];

  static const List<String> defectCausesConcreteSpalling = [
    '외력에 의한 손상 추정',
    '시공 오차',
    '화학적 반응',
    otherOptionLabel,
  ];

  static const List<String> defectCausesOther = [
    '노후화',
    '외력에 의한 손상 추정',
    otherOptionLabel,
  ];

  static String pageTitle(int pageNumber) => '페이지 $pageNumber';
  static String pageIndicator(int current, int total) => '$current/$total';
}
