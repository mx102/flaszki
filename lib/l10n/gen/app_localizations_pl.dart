// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get undo => 'Cofnij';

  @override
  String get restart => 'Od nowa';

  @override
  String get restartConfirm => 'Stuknij ponownie, aby zacząć od nowa';

  @override
  String get settings => 'Ustawienia';

  @override
  String levelLabel(int number) {
    return 'Poziom $number';
  }

  @override
  String get solved => 'Rozwiązane';

  @override
  String get goalQueueNext => 'NASTĘPNY';

  @override
  String get deadEnd => 'Stąd nie da się już ukończyć poziomu';

  @override
  String get colorblindPatterns => 'Wzory dla daltonistów';

  @override
  String get sound => 'Dźwięk';

  @override
  String get creditsAndLicenses => 'Autorzy i licencje';

  @override
  String get privacy => 'Prywatność';

  @override
  String get version => 'Wersja';

  @override
  String get openSourceLicenses => 'Licencje open source';
}
