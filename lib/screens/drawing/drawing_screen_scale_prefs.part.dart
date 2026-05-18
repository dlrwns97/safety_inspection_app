part of 'drawing_screen.dart';

const String _kMarkerScaleKey = 'drawing_marker_scale_percent';
const String _kLabelScaleKey = 'drawing_label_scale_percent';
const String _kScaleLockKey = 'drawing_scale_locked';
const String _kPdfLastPageKey = 'inspection_pdf_last_page';
const String _kLegacyPdfLastPageKey = 'drawing_pdf_last_page';

extension _DrawingScreenScalePrefs on _DrawingScreenState {
  String _drawingIdentityKey(Site site) {
    final path = site.pdfPath;
    final name = site.pdfName;
    String identitySource;
    if (path != null && path.isNotEmpty) {
      identitySource = path;
    } else if (name != null && name.isNotEmpty) {
      identitySource = name;
    } else {
      identitySource = site.id;
    }
    return '${site.drawingType.name}:$identitySource';
  }

  String _markerKeyFor(Site site) =>
      '$_kMarkerScaleKey:${_drawingIdentityKey(site)}';

  String _labelKeyFor(Site site) =>
      '$_kLabelScaleKey:${_drawingIdentityKey(site)}';

  String _lockKeyFor(Site site) =>
      '$_kScaleLockKey:${_drawingIdentityKey(site)}';

  String _pdfLastPageKeyFor(Site site) => '$_kPdfLastPageKey:${site.id}';

  String _pdfLastPageLegacyKeyFor(Site site) =>
      '$_kLegacyPdfLastPageKey:${_drawingIdentityKey(site)}';

  void resetScaleState() {
    _markerScale = 1.0;
    _labelScale = 1.0;
    _isScaleLocked = false;
    _didLoadScalePrefs = false;
  }

  void _resetScalePreferences({bool notify = true}) {
    if (notify) {
      _safeSetState(resetScaleState);
    } else {
      resetScaleState();
    }
  }

  int _scaleToPercent(double scale) => (scale * 100).round().clamp(20, 200);

  double _percentToScale(int percent) => (percent / 100.0).clamp(0.2, 2.0);

  Future<void> _loadScalePreferences() async {
    if (_didLoadScalePrefs) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final markerPercent = prefs.getInt(_markerKeyFor(_site));
    final labelPercent = prefs.getInt(_labelKeyFor(_site));
    final lockValue = prefs.getBool(_lockKeyFor(_site));
    if (markerPercent == null && labelPercent == null && lockValue == null) {
      _didLoadScalePrefs = true;
      return;
    }
    if (!mounted) {
      return;
    }
    _safeSetState(() {
      if (markerPercent != null) {
        _markerScale = _percentToScale(markerPercent);
      }
      if (labelPercent != null) {
        _labelScale = _percentToScale(labelPercent);
      }
      if (lockValue != null) {
        _isScaleLocked = lockValue;
      }
      _didLoadScalePrefs = true;
    });
  }

  Future<void> _persistScalePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_markerKeyFor(_site), _scaleToPercent(_markerScale));
    await prefs.setInt(_labelKeyFor(_site), _scaleToPercent(_labelScale));
    await prefs.setBool(_lockKeyFor(_site), _isScaleLocked);
  }

  void _handleMarkerScaleChanged(double value) {
    if (_isScaleLocked) {
      return;
    }
    _safeSetState(() => _markerScale = value.clamp(0.2, 2.0));
    _persistScalePreferences();
  }

  void _handleLabelScaleChanged(double value) {
    if (_isScaleLocked) {
      return;
    }
    _safeSetState(() => _labelScale = value.clamp(0.2, 2.0));
    _persistScalePreferences();
  }

  void _toggleScaleLock() {
    _safeSetState(() => _isScaleLocked = !_isScaleLocked);
    _persistScalePreferences();
  }

  Future<int> _loadPersistedPdfPage({required Site site}) async {
    if (site.drawingType != DrawingType.pdf) {
      return 1;
    }
    final prefs = await SharedPreferences.getInstance();
    final restored = prefs.getInt(_pdfLastPageKeyFor(site));
    if (restored != null && restored > 0) {
      return restored;
    }
    final fallback = site.lastViewedPdfPage;
    if (fallback != null && fallback > 0) {
      return fallback;
    }
    final legacyRestored = prefs.getInt(_pdfLastPageLegacyKeyFor(site));
    if (legacyRestored != null && legacyRestored > 0) {
      return legacyRestored;
    }
    return 1;
  }

  Future<void> _persistCurrentPdfPage({required int page}) async {
    if (_site.drawingType != DrawingType.pdf) {
      return;
    }
    final safePage = page <= 0 ? 1 : page;
    final targetSiteId = _site.id;
    final siteSnapshot = _site;
    final sequence = ++_pdfPagePersistSequence;
    if (_site.lastViewedPdfPage != safePage) {
      _site = _site.copyWith(lastViewedPdfPage: safePage);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pdfLastPageKeyFor(_site), safePage);
    await prefs.setInt(_pdfLastPageLegacyKeyFor(_site), safePage);
    final updatedSite = await _persistPdfPagePositionUseCase.execute(
      site: siteSnapshot,
      page: safePage,
    );
    if (!mounted ||
        _site.id != targetSiteId ||
        sequence != _pdfPagePersistSequence) {
      return;
    }
    _site = updatedSite;
  }
}
