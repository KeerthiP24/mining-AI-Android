import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/checklist.dart';
import '../models/checklist_template.dart';

class ChecklistRepository {
  const ChecklistRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _checklists =>
      _firestore.collection('checklists');

  CollectionReference<Map<String, dynamic>> get _templates =>
      _firestore.collection('checklist_templates');

  /// Streams a live checklist document. Emits null when not found.
  Stream<Checklist?> watchChecklist(String checklistId) {
    return _checklists.doc(checklistId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Checklist.fromFirestore(snap);
    });
  }

  /// One-shot fetch of a checklist. Returns null when not found.
  Future<Checklist?> getChecklist(String checklistId) async {
    final snap = await _checklists.doc(checklistId).get();
    if (!snap.exists) return null;
    return Checklist.fromFirestore(snap);
  }

  /// Creates a new checklist document. Uses server timestamp for createdAt.
  Future<void> createChecklist(Checklist checklist) async {
    final data = checklist.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _checklists.doc(checklist.checklistId).set(data);
  }

  /// Marks a single item completed/uncompleted via atomic dot-notation update.
  /// Does NOT rewrite the entire items map.
  Future<void> updateItemCompleted(
    String checklistId,
    String itemId,
    bool completed,
  ) async {
    await _checklists.doc(checklistId).update({
      'items.$itemId.completed': completed,
      'items.$itemId.completedAt':
          completed ? FieldValue.serverTimestamp() : null,
    });
  }

  /// Submits the checklist: sets status, scores, submittedAt, and resets
  /// consecutiveMissedDays on the user document in a single batch.
  Future<void> submitChecklist(
    String checklistId,
    String uid,
    String today,
    double complianceScore,
    double mandatoryScore,
  ) async {
    final batch = _firestore.batch();

    batch.update(_checklists.doc(checklistId), {
      'status': 'submitted',
      'submittedAt': FieldValue.serverTimestamp(),
      'complianceScore': complianceScore,
      'mandatoryScore': mandatoryScore,
    });

    batch.update(_firestore.collection('users').doc(uid), {
      'lastChecklistDate': today,
      'consecutiveMissedDays': 0,
    });

    await batch.commit();
  }

  /// Streams checklist history for a worker, ordered newest first.
  Stream<List<Checklist>> watchHistory(String uid, {int limit = 7}) {
    return _checklists
        .where('uid', isEqualTo: uid)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Checklist.fromFirestore(d)).toList());
  }

  /// Fetches a checklist template by mineId + role.
  /// Template ID format: "{mineId}_{role}"
  Future<ChecklistTemplate?> getTemplate(String mineId, String role) async {
    final templateId = '${mineId}_$role';
    final snap = await _templates.doc(templateId).get();
    if (!snap.exists) return null;
    return ChecklistTemplate.fromFirestore(snap);
  }

  /// Streams all checklists for a mine on a given date (for supervisor overview).
  Stream<List<Checklist>> watchMineChecklists(String mineId, String date) {
    return _checklists
        .where('mineId', isEqualTo: mineId)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Checklist.fromFirestore(d)).toList());
  }

  /// Fetches all submitted checklists for a user, most recent first (for compliance rate).
  Future<List<Checklist>> getRecentSubmissions(String uid, {int limit = 30}) async {
    final snap = await _checklists
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: 'submitted')
        .orderBy('submittedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => Checklist.fromFirestore(d)).toList();
  }

  /// Writes a reminder stub document for Phase 8 push notification delivery.
  Future<void> writeReminderStub(String uid, String date) async {
    final reminderId = '${uid}_checklist_$date';
    final scheduledFor =
        DateTime.now().add(const Duration(minutes: 60));
    await _firestore.collection('reminders').doc(reminderId).set({
      'uid': uid,
      'type': 'checklist_reminder',
      'scheduledFor': Timestamp.fromDate(scheduledFor),
      'sent': false,
    });
  }
}
