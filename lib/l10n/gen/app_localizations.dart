import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// Undo the last Pour (bottom bar tooltip and Dead End banner button).
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Restart the Level from its start (bottom bar tooltip and Dead End banner button).
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// Restart tooltip while armed: a second tap within 2 s restarts.
  ///
  /// In en, this message translates to:
  /// **'Tap again to restart'**
  String get restartConfirm;

  /// Gear button tooltip opening the Settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Level label in the bottom bar.
  ///
  /// In en, this message translates to:
  /// **'Level {number}'**
  String levelLabel(int number);

  /// Shown over the board when the Level is Solved.
  ///
  /// In en, this message translates to:
  /// **'Solved'**
  String get solved;

  /// Small caps label above the Goal Queue head orb (the Color to seal next).
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get goalQueueNext;

  /// Dead End banner: the Level can no longer be Solved from this state.
  ///
  /// In en, this message translates to:
  /// **'No way to finish from here'**
  String get deadEnd;

  /// Settings toggle: draw a pattern on every Color.
  ///
  /// In en, this message translates to:
  /// **'Colorblind patterns'**
  String get colorblindPatterns;

  /// Settings toggle: sound effects on/off.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// Settings entry and page title: CREDITS.md and licenses.
  ///
  /// In en, this message translates to:
  /// **'Credits and licenses'**
  String get creditsAndLicenses;

  /// Settings entry opening the privacy policy in the browser.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// Settings row showing the app version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Button opening the list of open-source licenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicenses;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
