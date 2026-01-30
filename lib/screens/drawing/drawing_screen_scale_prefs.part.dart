part of 'drawing_screen.dart';

const String _kMarkerScaleKey = 'drawing_marker_scale_percent';
const String _kLabelScaleKey = 'drawing_label_scale_percent';
const String _kScaleLockKey = 'drawing_scale_locked';

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

  void _resetScalePreferences({bool notify = true}) {
    final reset = () {
      _markerScale = 1.0;
      _labelScale = 1.0;
      _isScaleLocked = false;
      _didLoadScalePrefs = false;
    };
    if (notify) {
      _safeSetState(reset);
    } else {
      reset();
    }
  }

  int _scaleToPercent(double scale) =>
      (scale * 100).round().clamp(20, 200);

  double _percentToScale(int percent) =>
      (percent / 100.0).clamp(0.2, 2.0);

  Future<void> _loadScalePreferences() async {
    if (_didLoadScalePrefs) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final markerPercent = prefs.getInt(_markerKeyFor(_site));
    final labelPercent = prefs.getInt(_labelKeyFor(_site));
    final lockValue = prefs.getBool(_lockKeyFor(_site));
    if (markerPercent == null &&
        labelPercent == null &&
        lockValue == null) {
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
}
