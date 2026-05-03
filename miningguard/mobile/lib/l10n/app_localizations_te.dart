// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get checklist_title => 'Today\'\'s Checklist';

  @override
  String get checklist_submit_button => 'Submit Checklist';

  @override
  String get checklist_submit_confirm_title => 'Submit your checklist?';

  @override
  String get checklist_submit_confirm_body =>
      'You cannot change your answers after submitting.';

  @override
  String get checklist_submit_confirm_yes => 'Submit';

  @override
  String get checklist_submit_confirm_no => 'Keep editing';

  @override
  String get checklist_mandatory_badge => 'Required';

  @override
  String checklist_progress_chip(int completed, int total) {
    return '$completed / $total';
  }

  @override
  String get checklist_mandatory_incomplete_hint =>
      'Complete all required items to submit';

  @override
  String get checklist_category_ppe => 'Personal Protective Equipment';

  @override
  String get checklist_category_machinery => 'Machinery';

  @override
  String get checklist_category_environment => 'Environment';

  @override
  String get checklist_category_emergency => 'Emergency';

  @override
  String get checklist_category_supervisor => 'Supervisor Duties';

  @override
  String get checklist_ppe_helmet => 'Hard hat fitted and in good condition';

  @override
  String get checklist_ppe_boots => 'Safety boots worn';

  @override
  String get checklist_ppe_vest => 'High-visibility vest worn';

  @override
  String get checklist_ppe_gloves => 'Safety gloves available';

  @override
  String get checklist_ppe_lamp_charged => 'Cap lamp charged and functional';

  @override
  String get checklist_ppe_scsr_present => 'Self-rescuer on person';

  @override
  String get checklist_mach_preshift_done =>
      'Pre-shift machinery inspection completed';

  @override
  String get checklist_mach_guards_in_place => 'All guards and covers in place';

  @override
  String get checklist_mach_no_leaks => 'No visible oil or hydraulic leaks';

  @override
  String get checklist_env_gas_detector_ok =>
      'Gas detector reading within safe limits (CH₄ < 1%)';

  @override
  String get checklist_env_roof_inspected =>
      'Roof and side walls inspected — no loose material';

  @override
  String get checklist_env_ventilation_ok => 'Ventilation is adequate';

  @override
  String get checklist_env_walkways_clear => 'Walkways and exits are clear';

  @override
  String get checklist_emg_exit_known =>
      'Nearest emergency exit location confirmed';

  @override
  String get checklist_emg_comms_working => 'Communication device working';

  @override
  String get checklist_emg_first_aid_located =>
      'Nearest first aid kit location known';

  @override
  String get checklist_sup_attendance_confirmed =>
      'All workers signed in for shift';

  @override
  String get checklist_sup_toolbox_talk_done =>
      'Toolbox safety briefing conducted';

  @override
  String get checklist_sup_dgms_permits_reviewed =>
      'DGMS permit-to-work documents reviewed';

  @override
  String get checklist_sup_high_risk_permits_checked =>
      'High-risk work authorisations verified';

  @override
  String get checklist_sup_muster_point_communicated =>
      'Muster point communicated to crew';

  @override
  String get checklist_success_title => 'Checklist Submitted';

  @override
  String get checklist_success_excellent =>
      'Excellent — full compliance today!';

  @override
  String get checklist_success_good => 'Good — all critical items checked.';

  @override
  String get checklist_success_fair => 'Some items were missed. Stay safe.';

  @override
  String get checklist_success_poor =>
      'Multiple items missed. Please speak with your supervisor.';

  @override
  String get checklist_success_back_home => 'Back to Home';

  @override
  String get checklist_status_submitted => 'Submitted';

  @override
  String get checklist_status_in_progress => 'In Progress';

  @override
  String get checklist_status_missed => 'Missed';

  @override
  String get checklist_history_title => 'Checklist History';

  @override
  String get checklist_history_load_more => 'Load more';

  @override
  String get checklist_already_submitted => 'Checklist submitted for today';

  @override
  String get checklist_error_template_not_found =>
      'Checklist template not found. Contact your supervisor.';

  @override
  String get checklist_reminder_notification_title =>
      'Don\'\'t forget your safety checklist';

  @override
  String get checklist_reminder_notification_body =>
      'Your shift checklist is waiting — stay safe today.';

  @override
  String checklist_optional_remaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return '$count optional $_temp0 remaining';
  }

  @override
  String get education_tab_title => 'Safety Education';

  @override
  String get video_of_day_label => 'Video of the Day';

  @override
  String get continue_watching_label => 'Continue Watching';

  @override
  String get browse_by_category_label => 'Browse by Category';

  @override
  String get watch_now_button => 'Watch Now';

  @override
  String get category_all => 'All';

  @override
  String get category_ppe => 'PPE';

  @override
  String get category_gas_ventilation => 'Gas & Ventilation';

  @override
  String get category_roof_support => 'Roof Support';

  @override
  String get category_emergency => 'Emergency';

  @override
  String get category_machinery => 'Machinery';

  @override
  String get quiz_heading => 'Quick Check';

  @override
  String quiz_question_of_total(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get quiz_submit_button => 'Submit';

  @override
  String get quiz_well_done_heading => 'Well done!';

  @override
  String quiz_points_awarded(int points) {
    return '+$points compliance points';
  }

  @override
  String get quiz_try_again_heading => 'Try again next time';

  @override
  String get quiz_continue_button => 'Continue';

  @override
  String get source_dgms => 'DGMS';

  @override
  String get source_msha => 'MSHA';

  @override
  String get source_hse => 'HSE';

  @override
  String get source_worksafe => 'WorkSafe';

  @override
  String get source_custom => 'Custom';

  @override
  String get education_empty_library => 'No videos available yet.';
}
