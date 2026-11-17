// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get undo => 'Undo';

  @override
  String get restart => 'Restart';

  @override
  String get restartConfirm => 'Tap again to restart';

  @override
  String get settings => 'Settings';

  @override
  String levelLabel(int number) {
    return 'Level $number';
  }

  @override
  String get solved => 'Solved';

  @override
  String get goalQueueNext => 'NEXT';

  @override
  String get deadEnd => 'No way to finish from here';

  @override
  String get colorblindPatterns => 'Colorblind patterns';

  @override
  String get sound => 'Sound';

  @override
  String get creditsAndLicenses => 'Credits and licenses';

  @override
  String get privacy => 'Privacy';

  @override
  String get version => 'Version';

  @override
  String get openSourceLicenses => 'Open-source licenses';
}
