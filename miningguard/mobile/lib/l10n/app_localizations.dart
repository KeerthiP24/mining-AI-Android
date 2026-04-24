import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_or.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('bn'),
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
    Locale('or'),
    Locale('te')
  ];

  /// No description provided for @checklist_title.
  ///
  /// In en, this message translates to:
  /// **'Today\'\'s Checklist'**
  String get checklist_title;

  /// No description provided for @checklist_submit_button.
  ///
  /// In en, this message translates to:
  /// **'Submit Checklist'**
  String get checklist_submit_button;

  /// No description provided for @checklist_submit_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Submit your checklist?'**
  String get checklist_submit_confirm_title;

  /// No description provided for @checklist_submit_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'You cannot change your answers after submitting.'**
  String get checklist_submit_confirm_body;

  /// No description provided for @checklist_submit_confirm_yes.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get checklist_submit_confirm_yes;

  /// No description provided for @checklist_submit_confirm_no.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get checklist_submit_confirm_no;

  /// No description provided for @checklist_mandatory_badge.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get checklist_mandatory_badge;

  /// No description provided for @checklist_progress_chip.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total}'**
  String checklist_progress_chip(int completed, int total);

  /// No description provided for @checklist_mandatory_incomplete_hint.
  ///
  /// In en, this message translates to:
  /// **'Complete all required items to submit'**
  String get checklist_mandatory_incomplete_hint;

  /// No description provided for @checklist_category_ppe.
  ///
  /// In en, this message translates to:
  /// **'Personal Protective Equipment'**
  String get checklist_category_ppe;

  /// No description provided for @checklist_category_machinery.
  ///
  /// In en, this message translates to:
  /// **'Machinery'**
  String get checklist_category_machinery;

  /// No description provided for @checklist_category_environment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get checklist_category_environment;

  /// No description provided for @checklist_category_emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get checklist_category_emergency;

  /// No description provided for @checklist_category_supervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor Duties'**
  String get checklist_category_supervisor;

  /// No description provided for @checklist_ppe_helmet.
  ///
  /// In en, this message translates to:
  /// **'Hard hat fitted and in good condition'**
  String get checklist_ppe_helmet;

  /// No description provided for @checklist_ppe_boots.
  ///
  /// In en, this message translates to:
  /// **'Safety boots worn'**
  String get checklist_ppe_boots;

  /// No description provided for @checklist_ppe_vest.
  ///
  /// In en, this message translates to:
  /// **'High-visibility vest worn'**
  String get checklist_ppe_vest;

  /// No description provided for @checklist_ppe_gloves.
  ///
  /// In en, this message translates to:
  /// **'Safety gloves available'**
  String get checklist_ppe_gloves;

  /// No description provided for @checklist_ppe_lamp_charged.
  ///
  /// In en, this message translates to:
  /// **'Cap lamp charged and functional'**
  String get checklist_ppe_lamp_charged;

  /// No description provided for @checklist_ppe_scsr_present.
  ///
  /// In en, this message translates to:
  /// **'Self-rescuer on person'**
  String get checklist_ppe_scsr_present;

  /// No description provided for @checklist_mach_preshift_done.
  ///
  /// In en, this message translates to:
  /// **'Pre-shift machinery inspection completed'**
  String get checklist_mach_preshift_done;

  /// No description provided for @checklist_mach_guards_in_place.
  ///
  /// In en, this message translates to:
  /// **'All guards and covers in place'**
  String get checklist_mach_guards_in_place;

  /// No description provided for @checklist_mach_no_leaks.
  ///
  /// In en, this message translates to:
  /// **'No visible oil or hydraulic leaks'**
  String get checklist_mach_no_leaks;

  /// No description provided for @checklist_env_gas_detector_ok.
  ///
  /// In en, this message translates to:
  /// **'Gas detector reading within safe limits (CH₄ < 1%)'**
  String get checklist_env_gas_detector_ok;

  /// No description provided for @checklist_env_roof_inspected.
  ///
  /// In en, this message translates to:
  /// **'Roof and side walls inspected — no loose material'**
  String get checklist_env_roof_inspected;

  /// No description provided for @checklist_env_ventilation_ok.
  ///
  /// In en, this message translates to:
  /// **'Ventilation is adequate'**
  String get checklist_env_ventilation_ok;

  /// No description provided for @checklist_env_walkways_clear.
  ///
  /// In en, this message translates to:
  /// **'Walkways and exits are clear'**
  String get checklist_env_walkways_clear;

  /// No description provided for @checklist_emg_exit_known.
  ///
  /// In en, this message translates to:
  /// **'Nearest emergency exit location confirmed'**
  String get checklist_emg_exit_known;

  /// No description provided for @checklist_emg_comms_working.
  ///
  /// In en, this message translates to:
  /// **'Communication device working'**
  String get checklist_emg_comms_working;

  /// No description provided for @checklist_emg_first_aid_located.
  ///
  /// In en, this message translates to:
  /// **'Nearest first aid kit location known'**
  String get checklist_emg_first_aid_located;

  /// No description provided for @checklist_sup_attendance_confirmed.
  ///
  /// In en, this message translates to:
  /// **'All workers signed in for shift'**
  String get checklist_sup_attendance_confirmed;

  /// No description provided for @checklist_sup_toolbox_talk_done.
  ///
  /// In en, this message translates to:
  /// **'Toolbox safety briefing conducted'**
  String get checklist_sup_toolbox_talk_done;

  /// No description provided for @checklist_sup_dgms_permits_reviewed.
  ///
  /// In en, this message translates to:
  /// **'DGMS permit-to-work documents reviewed'**
  String get checklist_sup_dgms_permits_reviewed;

  /// No description provided for @checklist_sup_high_risk_permits_checked.
  ///
  /// In en, this message translates to:
  /// **'High-risk work authorisations verified'**
  String get checklist_sup_high_risk_permits_checked;

  /// No description provided for @checklist_sup_muster_point_communicated.
  ///
  /// In en, this message translates to:
  /// **'Muster point communicated to crew'**
  String get checklist_sup_muster_point_communicated;

  /// No description provided for @checklist_success_title.
  ///
  /// In en, this message translates to:
  /// **'Checklist Submitted'**
  String get checklist_success_title;

  /// No description provided for @checklist_success_excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent — full compliance today!'**
  String get checklist_success_excellent;

  /// No description provided for @checklist_success_good.
  ///
  /// In en, this message translates to:
  /// **'Good — all critical items checked.'**
  String get checklist_success_good;

  /// No description provided for @checklist_success_fair.
  ///
  /// In en, this message translates to:
  /// **'Some items were missed. Stay safe.'**
  String get checklist_success_fair;

  /// No description provided for @checklist_success_poor.
  ///
  /// In en, this message translates to:
  /// **'Multiple items missed. Please speak with your supervisor.'**
  String get checklist_success_poor;

  /// No description provided for @checklist_success_back_home.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get checklist_success_back_home;

  /// No description provided for @checklist_status_submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get checklist_status_submitted;

  /// No description provided for @checklist_status_in_progress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get checklist_status_in_progress;

  /// No description provided for @checklist_status_missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get checklist_status_missed;

  /// No description provided for @checklist_history_title.
  ///
  /// In en, this message translates to:
  /// **'Checklist History'**
  String get checklist_history_title;

  /// No description provided for @checklist_history_load_more.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get checklist_history_load_more;

  /// No description provided for @checklist_already_submitted.
  ///
  /// In en, this message translates to:
  /// **'Checklist submitted for today'**
  String get checklist_already_submitted;

  /// No description provided for @checklist_error_template_not_found.
  ///
  /// In en, this message translates to:
  /// **'Checklist template not found. Contact your supervisor.'**
  String get checklist_error_template_not_found;

  /// No description provided for @checklist_reminder_notification_title.
  ///
  /// In en, this message translates to:
  /// **'Don\'\'t forget your safety checklist'**
  String get checklist_reminder_notification_title;

  /// No description provided for @checklist_reminder_notification_body.
  ///
  /// In en, this message translates to:
  /// **'Your shift checklist is waiting — stay safe today.'**
  String get checklist_reminder_notification_body;

  /// No description provided for @checklist_optional_remaining.
  ///
  /// In en, this message translates to:
  /// **'{count} optional {count, plural, one{item} other{items}} remaining'**
  String checklist_optional_remaining(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'bn',
        'en',
        'hi',
        'mr',
        'or',
        'te'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
    case 'or':
      return AppLocalizationsOr();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
