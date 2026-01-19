class StringsKo {
  static const appTitle = '현장 안전 점검';
  static const homeTitle = '점검 현장';
  static const newSite = '새 현장';
  static const siteNameLabel = '현장 이름';
  static const siteNameRequired = '현장 이름을 입력해주세요.';
  static const cancel = '취소';
  static const create = '생성';
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
  static const defectDetailsTitle = '결함 상세';
  static const structuralMemberLabel = '부재';
  static const crackTypeLabel = '균열 유형';
  static const widthLabel = '폭 (mm)';
  static const lengthLabel = '길이 (mm)';
  static const causeLabel = '원인';
  static const selectMemberError = '부재를 선택해주세요';
  static const selectCrackTypeError = '균열 유형을 선택해주세요';
  static const enterWidthError = '폭을 입력해주세요';
  static const enterLengthError = '길이를 입력해주세요';
  static const selectCauseError = '원인을 선택해주세요';
  static const confirm = '확인';
  static const modePlaceholder = '모드 설정은 1단계에서 임시로 제공됩니다.';
  static const defectModeLabel = '결함';
  static const equipmentModeLabel = '장비';
  static const freeDrawModeLabel = '자유 그리기';
  static const eraserModeLabel = '지우개';
  static const selectDefectCategoryHint = '결함 유형을 선택해주세요.';
  static const defectCategoryGeneralCrack = '일반 균열';
  static const defectCategoryWaterLeakage = '누수';
  static const defectCategoryConcreteSpalling = '콘크리트 박락';
  static const defectCategoryOther = '기타 결함';

  static const List<String> structuralMembers = [
    '기둥',
    '벽',
    '슬래브',
    '보',
    '조적벽',
  ];

  static const List<String> crackTypes = [
    '수평',
    '수직',
    '대각',
    '수직+수평',
    '거미줄',
  ];

  static const List<String> defectCauses = [
    '건조 수축',
    '철근 부식',
    '줄눈 균열',
    '마감 균열',
  ];

  static String pageTitle(int pageNumber) => '페이지 $pageNumber';
}
