import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../shared/models/user_model.dart';
import '../models/checklist.dart';
import '../models/checklist_item.dart';
import '../models/checklist_template.dart';
import 'checklist_repository.dart';

class ChecklistTemplateNotFoundException implements Exception {
  final String message;
  const ChecklistTemplateNotFoundException(this.message);
  @override
  String toString() => 'ChecklistTemplateNotFoundException: $message';
}

/// Responsible for getting or creating the daily checklist for a given worker.
/// Called once per screen load — returns quickly if today's checklist already exists.
class ChecklistGenerationService {
  const ChecklistGenerationService(this._repository, this._firestore);

  final ChecklistRepository _repository;
  final FirebaseFirestore _firestore;

  /// Returns the current shift-day checklist for [user].
  /// Creates it from the appropriate template if it doesn't exist yet.
  Future<Checklist> getOrCreateChecklist(UserModel user) async {
    final today = await _todayInMineTimezone(user.mineId);
    final checklistId = '${user.uid}_${user.mineId}_$today';

    // Return existing checklist (any status — resume in_progress or show submitted)
    final existing = await _repository.getChecklist(checklistId);
    if (existing != null) return existing;

    // Fetch the role-appropriate template; auto-seed defaults on first run
    final roleKey = user.role == UserRole.supervisor ? 'supervisor' : 'worker';
    ChecklistTemplate? template = await _repository.getTemplate(user.mineId, roleKey);
    if (template == null) {
      debugPrint('[ChecklistGenerationService] No template for ${user.mineId}/$roleKey — seeding defaults');
      await _seedDefaultTemplates(user.mineId);
      template = await _repository.getTemplate(user.mineId, roleKey);
    }
    if (template == null) {
      throw ChecklistTemplateNotFoundException(
        'No template found for mine ${user.mineId} role $roleKey. '
        'An admin must seed checklist_templates first.',
      );
    }

    // Build initial items map — all items incomplete
    final items = <String, ChecklistItemData>{};
    for (final item in template.items) {
      items[item.itemId] = ChecklistItemData(
        mandatory: item.mandatory,
        completed: false,
      );
    }

    final checklist = Checklist(
      checklistId: checklistId,
      uid: user.uid,
      mineId: user.mineId,
      shift: user.shift,
      date: today,
      templateVersion: template.version,
      status: 'in_progress',
      items: items,
      createdAt: DateTime.now(), // replaced by FieldValue.serverTimestamp() in repo
    );

    await _repository.createChecklist(checklist);

    // Write Phase 8 reminder stub
    try {
      await _repository.writeReminderStub(user.uid, today);
    } catch (e) {
      // Non-fatal — reminder is best-effort
      debugPrint('[ChecklistGenerationService] reminder stub failed: $e');
    }

    // Return the freshly created checklist from Firestore to get server timestamp
    final created = await _repository.getChecklist(checklistId);
    return created ?? checklist;
  }

  /// Seeds default worker + supervisor templates for [mineId] when none exist.
  /// Called automatically on first checklist load for a new mine.
  Future<void> _seedDefaultTemplates(String mineId) async {
    final batch = _firestore.batch();
    final templates = _firestore.collection('checklist_templates');

    final workerItems = [
      // PPE
      {'itemId': 'ppe_helmet',    'category': 'ppe', 'labelKey': 'checklist_ppe_helmet',       'mandatory': true,  'order': 1},
      {'itemId': 'ppe_boots',     'category': 'ppe', 'labelKey': 'checklist_ppe_boots',        'mandatory': true,  'order': 2},
      {'itemId': 'ppe_vest',      'category': 'ppe', 'labelKey': 'checklist_ppe_vest',         'mandatory': true,  'order': 3},
      {'itemId': 'ppe_gloves',    'category': 'ppe', 'labelKey': 'checklist_ppe_gloves',       'mandatory': false, 'order': 4},
      {'itemId': 'ppe_cap_lamp',  'category': 'ppe', 'labelKey': 'checklist_ppe_lamp_charged', 'mandatory': true,  'order': 5},
      {'itemId': 'ppe_scsr',      'category': 'ppe', 'labelKey': 'checklist_ppe_scsr_present', 'mandatory': true,  'order': 6},
      // Machinery
      {'itemId': 'mach_preshift',  'category': 'machinery', 'labelKey': 'checklist_mach_preshift_done',    'mandatory': true,  'order': 10},
      {'itemId': 'mach_guards',    'category': 'machinery', 'labelKey': 'checklist_mach_guards_in_place',  'mandatory': true,  'order': 11},
      {'itemId': 'mach_no_leaks',  'category': 'machinery', 'labelKey': 'checklist_mach_no_leaks',         'mandatory': false, 'order': 12},
      // Environment
      {'itemId': 'env_gas',         'category': 'environment', 'labelKey': 'checklist_env_gas_detector_ok',  'mandatory': true,  'order': 20},
      {'itemId': 'env_roof',        'category': 'environment', 'labelKey': 'checklist_env_roof_inspected',   'mandatory': true,  'order': 21},
      {'itemId': 'env_ventilation', 'category': 'environment', 'labelKey': 'checklist_env_ventilation_ok',   'mandatory': true,  'order': 22},
      {'itemId': 'env_walkways',    'category': 'environment', 'labelKey': 'checklist_env_walkways_clear',   'mandatory': false, 'order': 23},
      // Emergency
      {'itemId': 'emg_exit',      'category': 'emergency', 'labelKey': 'checklist_emg_exit_known',       'mandatory': true,  'order': 30},
      {'itemId': 'emg_comms',     'category': 'emergency', 'labelKey': 'checklist_emg_comms_working',    'mandatory': false, 'order': 31},
      {'itemId': 'emg_first_aid', 'category': 'emergency', 'labelKey': 'checklist_emg_first_aid_located','mandatory': false, 'order': 32},
    ];

    final supervisorItems = [
      ...workerItems,
      // Supervisor-only duties
      {'itemId': 'sup_attendance',  'category': 'supervisor', 'labelKey': 'checklist_sup_attendance_confirmed',       'mandatory': true,  'order': 40},
      {'itemId': 'sup_toolbox',     'category': 'supervisor', 'labelKey': 'checklist_sup_toolbox_talk_done',          'mandatory': true,  'order': 41},
      {'itemId': 'sup_dgms',        'category': 'supervisor', 'labelKey': 'checklist_sup_dgms_permits_reviewed',      'mandatory': true,  'order': 42},
      {'itemId': 'sup_high_risk',   'category': 'supervisor', 'labelKey': 'checklist_sup_high_risk_permits_checked',  'mandatory': true,  'order': 43},
      {'itemId': 'sup_muster',      'category': 'supervisor', 'labelKey': 'checklist_sup_muster_point_communicated',  'mandatory': false, 'order': 44},
    ];

    batch.set(templates.doc('${mineId}_worker'), {
      'templateId': '${mineId}_worker',
      'mineId': mineId,
      'role': 'worker',
      'version': 1,
      'items': workerItems,
    });

    batch.set(templates.doc('${mineId}_supervisor'), {
      'templateId': '${mineId}_supervisor',
      'mineId': mineId,
      'role': 'supervisor',
      'version': 1,
      'items': supervisorItems,
    });

    // Seed mine timezone doc (default IST for Indian mines)
    batch.set(_firestore.collection('mines').doc(mineId), {
      'mineId': mineId,
      'timezone': 'Asia/Kolkata',
    }, SetOptions(merge: true));

    await batch.commit();
    debugPrint('[ChecklistGenerationService] Seeded default templates for mine $mineId');
  }

  /// Computes today's date string in the mine's configured timezone.
  /// Reads timezone from mines/{mineId}.timezone.
  /// Falls back to device timezone if mine doc is missing.
  Future<String> _todayInMineTimezone(String mineId) async {
    String timezoneId = 'Asia/Kolkata'; // default for Indian mines
    try {
      final mineDoc =
          await _firestore.collection('mines').doc(mineId).get();
      if (mineDoc.exists) {
        timezoneId = mineDoc.data()?['timezone'] as String? ?? timezoneId;
      }
    } catch (e) {
      debugPrint('[ChecklistGenerationService] failed to fetch mine timezone: $e');
    }

    try {
      final location = tz.getLocation(timezoneId);
      final now = tz.TZDateTime.now(location);
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    } catch (e) {
      // Fallback: device local time
      final now = DateTime.now();
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }
  }
}
