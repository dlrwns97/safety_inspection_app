class StringsKo {
  static const appTitle = '현장 안전 점검';
  static const inspectionSitesTitle = '점검 현장 목록';
  static const noSitesTitle = '등록된 현장이 없습니다';
  static const noSitesDescription = '현장을 생성하여 도면에 결함을 표시하세요.';
  static const newSite = '새 현장';
  static const siteNameTitle = '새 현장';
  static const siteNameLabel = '현장 이름';
  static const siteNameRequired = '현장 이름을 입력하세요.';
  static const cancel = '취소';
  static const create = '생성';
  static const importPdfTitle = 'PDF 도면 가져오기';
  static const importPdfSubtitle = '대용량 및 여러 페이지 PDF 지원';
  static const createBlankTitle = '빈 캔버스 만들기';
  static const createBlankSubtitle = '빈 도면에서 시작';
  static const pdfDrawingLabel = 'PDF 도면';
  static const blankCanvasLabel = '빈 캔버스';
  static const pdfDrawingLoaded = 'PDF 도면이 로드되었습니다';
  static const pinchToZoomHint = '확대/축소하려면 핀치하고, 결함을 추가하려면 탭하세요.';
  static const modePlaceholder = '모드 컨트롤은 1차 단계에서 준비 중입니다.';
  static const selectCategoryHint = '결함을 추가하려면 결함 종류를 선택하세요.';
  static const selectCategoryButton = '결함 종류 선택';
  static const selectCategoryTitle = '결함 종류 선택';
  static const defectDetailsTitle = '결함 상세';
  static const structuralMemberLabel = '구조 부재';
  static const crackTypeLabel = '균열 유형';
  static const widthLabel = '폭 (mm)';
  static const lengthLabel = '길이 (mm)';
  static const causeLabel = '원인';
  static const memberRequired = '구조 부재를 선택하세요.';
  static const crackTypeRequired = '균열 유형을 선택하세요.';
  static const widthRequired = '폭을 입력하세요.';
  static const lengthRequired = '길이를 입력하세요.';
  static const causeRequired = '원인을 선택하세요.';
  static const confirm = '확인';
  static const modeDefect = '결함';
  static const modeEquipment = '장비';
  static const modeFreeDraw = '자유 그리기';
  static const modeEraser = '지우개';

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
    '사선',
    '수직+수평',
    '망상',
  ];
  static const List<String> defectCauses = [
    '건조 수축',
    '철근 부식',
    '줄눈 균열',
    '마감 균열',
  ];

  static String pageLabel(int page) => '페이지 $page';
  static String pageDropdownLabel(int page) => '페이지 $page';
}
