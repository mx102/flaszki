import 'package:material_ui/material_ui.dart';

import '../l10n/gen/app_localizations.dart';

export '../l10n/gen/app_localizations.dart' show AppLocalizations;

/// App strings + `material_ui`'s own (PRD §4.7). Not
/// `AppLocalizations.localizationsDelegates`: that one carries
/// `flutter_localizations`' Material delegate, which `material_ui` widgets
/// don't read.
const List<LocalizationsDelegate<Object?>> appLocalizationsDelegates = [
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

extension L10nContext on BuildContext {
  /// Strings for the system locale (fallback English). Add a string: key in
  /// lib/l10n/app_en.arb (+ `@key` description) and app_pl.arb.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
