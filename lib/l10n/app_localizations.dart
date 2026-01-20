import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'strings_en.dart';
import 'strings_ko.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('ko')];

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? result =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(result != null, 'No AppLocalizations found in context');
    return result!;
  }

  AppStrings get strings {
    switch (locale.languageCode) {
      case 'ko':
        return stringsKo;
      default:
        return stringsEn;
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any(
        (Locale supported) => supported.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class AppStrings {
  const AppStrings({
    required this.appTitle,
    required this.workspaceTab,
    required this.defectsTab,
    required this.workspaceSummaryTitle,
    required this.workspaceSummarySubtitle,
    required this.blueprintTitle,
    required this.blueprintPlaceholder,
    required this.defectHeader,
    required this.defectListTitle,
    required this.defectDetailsTitle,
    required this.defectLocationLabel,
    required this.defectSeverityLabel,
    required this.defectStatusLabel,
    required this.defectAssigneeLabel,
    required this.defectNotesLabel,
    required this.defectActionButton,
    required this.defectTabAll,
    required this.defectTabOpen,
    required this.defectTabClosed,
    required this.defectFilterLabel,
    required this.defectFormTitle,
    required this.defectSampleTitle1,
    required this.defectSampleTitle2,
    required this.defectSampleTitle3,
    required this.defectSampleLocation1,
    required this.defectSampleLocation2,
    required this.defectSampleLocation3,
    required this.defectSampleAssignee1,
    required this.defectSampleAssignee2,
    required this.defectSampleAssignee3,
    required this.defectSampleNotes1,
    required this.defectSampleNotes2,
    required this.defectSampleNotes3,
    required this.severityHigh,
    required this.severityMedium,
    required this.severityLow,
    required this.statusOpen,
    required this.statusClosed,
    required this.blueprintMissing,
    required this.blueprintLoadError,
    required this.previousPage,
    required this.nextPage,
    required this.pageIndicator,
  });

  final String appTitle;
  final String workspaceTab;
  final String defectsTab;
  final String workspaceSummaryTitle;
  final String workspaceSummarySubtitle;
  final String blueprintTitle;
  final String blueprintPlaceholder;
  final String defectHeader;
  final String defectListTitle;
  final String defectDetailsTitle;
  final String defectLocationLabel;
  final String defectSeverityLabel;
  final String defectStatusLabel;
  final String defectAssigneeLabel;
  final String defectNotesLabel;
  final String defectActionButton;
  final String defectTabAll;
  final String defectTabOpen;
  final String defectTabClosed;
  final String defectFilterLabel;
  final String defectFormTitle;
  final String defectSampleTitle1;
  final String defectSampleTitle2;
  final String defectSampleTitle3;
  final String defectSampleLocation1;
  final String defectSampleLocation2;
  final String defectSampleLocation3;
  final String defectSampleAssignee1;
  final String defectSampleAssignee2;
  final String defectSampleAssignee3;
  final String defectSampleNotes1;
  final String defectSampleNotes2;
  final String defectSampleNotes3;
  final String severityHigh;
  final String severityMedium;
  final String severityLow;
  final String statusOpen;
  final String statusClosed;
  final String blueprintMissing;
  final String blueprintLoadError;
  final String previousPage;
  final String nextPage;
  final String Function(int current, int total) pageIndicator;
}
