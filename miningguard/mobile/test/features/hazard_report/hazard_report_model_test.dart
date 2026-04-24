import 'package:flutter_test/flutter_test.dart';
import 'package:miningguard/features/hazard_report/models/hazard_report_model.dart';

void main() {
  group('HazardReportModel.toJson / fromJson round-trip', () {
    HazardReportModel makeReport() {
      return HazardReportModel(
        reportId: 'r1',
        uid: 'user1',
        mineId: 'mine1',
        supervisorId: 'sup1',
        mineSection: 'Level 3',
        inputMode: InputMode.photo,
        description: 'Loose rocks overhead',
        voiceTranscription: '',
        category: HazardCategory.roofFall,
        severity: HazardSeverity.critical,
        mediaUrls: ['https://example.com/img1.jpg'],
        aiAnalysis: const AiAnalysisData(
          hazardDetected: 'roof_fall',
          confidence: 0.88,
          suggestedSeverity: 'critical',
          recommendedAction: 'Evacuate',
        ),
        status: ReportStatus.pending,
        submittedAt: DateTime(2025, 9, 1, 8, 0),
        isOfflineCreated: false,
      );
    }

    test('toJson → fromJson preserves all fields', () {
      final original = makeReport();
      final json = original.toJson();
      final restored = HazardReportModel.fromJson(json);

      expect(restored.reportId, original.reportId);
      expect(restored.uid, original.uid);
      expect(restored.mineId, original.mineId);
      expect(restored.supervisorId, original.supervisorId);
      expect(restored.mineSection, original.mineSection);
      expect(restored.inputMode, original.inputMode);
      expect(restored.description, original.description);
      expect(restored.category, original.category);
      expect(restored.severity, original.severity);
      expect(restored.status, original.status);
      expect(restored.mediaUrls, original.mediaUrls);
      expect(restored.isOfflineCreated, original.isOfflineCreated);
      expect(restored.aiAnalysis?.hazardDetected, original.aiAnalysis?.hazardDetected);
      expect(restored.aiAnalysis?.confidence, original.aiAnalysis?.confidence);
    });
  });

  group('HazardCategory enum', () {
    test('firestoreValue round-trips through fromString', () {
      for (final cat in HazardCategory.values) {
        expect(HazardCategory.fromString(cat.firestoreValue), cat);
      }
    });
  });

  group('HazardSeverity enum', () {
    test('firestoreValue round-trips through fromString', () {
      for (final sev in HazardSeverity.values) {
        expect(HazardSeverity.fromString(sev.firestoreValue), sev);
      }
    });
  });

  group('ReportStatus enum', () {
    test('firestoreValue round-trips through fromString', () {
      for (final s in ReportStatus.values) {
        expect(ReportStatus.fromString(s.firestoreValue), s);
      }
    });
  });

  group('InputMode enum', () {
    test('firestoreValue round-trips through fromString', () {
      for (final m in InputMode.values) {
        expect(InputMode.fromString(m.firestoreValue), m);
      }
    });
  });
}
