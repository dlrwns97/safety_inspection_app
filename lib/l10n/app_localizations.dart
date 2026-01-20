import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'strings_en.dart';
import 'strings_ko.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': stringsEn,
    'ko': stringsKo,
  };

  String? _string(String key) => _localizedValues[locale.languageCode]?[key];

  String get appTitle => _string('appTitle') ?? 'Safety Inspection';
}
