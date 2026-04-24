import 'package:flutter_test/flutter_test.dart';
import 'package:miningguard/features/hazard_report/models/ai_analysis_result_model.dart';
import 'package:miningguard/features/hazard_report/models/hazard_report_model.dart';

void main() {
  group('AiAnalysisResult.fromJson', () {
    test('parses recommended_action field (spec field name)', () {
      final json = {
        'hazard_detected': 'fire',
        'confidence': 0.92,
        'suggested_severity': 'high',
        'recommended_action': 'Evacuate immediately',
      };
      final result = AiAnalysisResult.fromJson(json);
      expect(result.hazardDetected, 'fire');
      expect(result.confidence, closeTo(0.92, 0.001));
      expect(result.suggestedSeverity, HazardSeverity.high);
      expect(result.recommendedAction, 'Evacuate immediately');
    });

    test('parses correction_recommendation field (backend field name)', () {
      final json = {
        'hazard_detected': 'gas_leak',
        'confidence': 0.75,
        'suggested_severity': 'high',
        'correction_recommendation': 'Ventilate the area',
      };
      final result = AiAnalysisResult.fromJson(json);
      expect(result.recommendedAction, 'Ventilate the area');
    });

    test('recommended_action takes priority over correction_recommendation', () {
      final json = {
        'hazard_detected': 'other',
        'confidence': 0.5,
        'suggested_severity': 'low',
        'recommended_action': 'primary',
        'correction_recommendation': 'fallback',
      };
      final result = AiAnalysisResult.fromJson(json);
      expect(result.recommendedAction, 'primary');
    });

    test('handles missing action fields gracefully', () {
      final json = {
        'hazard_detected': 'safe',
        'confidence': 0.5,
        'suggested_severity': 'low',
      };
      final result = AiAnalysisResult.fromJson(json);
      expect(result.recommendedAction, '');
    });
  });

  group('AiAnalysisResult getters', () {
    test('confidencePercent rounds correctly', () {
      final r = AiAnalysisResult.fromJson({
        'hazard_detected': 'safe',
        'confidence': 0.876,
        'suggested_severity': 'low',
      });
      expect(r.confidencePercent, 88);
    });

    test('isHighConfidence true at >= 0.75', () {
      final high = AiAnalysisResult.fromJson({
        'hazard_detected': 'fire',
        'confidence': 0.75,
        'suggested_severity': 'high',
      });
      expect(high.isHighConfidence, isTrue);
    });

    test('isHighConfidence false below 0.75', () {
      final low = AiAnalysisResult.fromJson({
        'hazard_detected': 'safe',
        'confidence': 0.74,
        'suggested_severity': 'low',
      });
      expect(low.isHighConfidence, isFalse);
    });
  });

  group('AiAnalysisResult.safe', () {
    test('returns safe defaults', () {
      final safe = AiAnalysisResult.safe();
      expect(safe.hazardDetected, 'safe');
      expect(safe.confidence, 0.0);
      expect(safe.suggestedSeverity, HazardSeverity.low);
      expect(safe.recommendedAction, '');
      expect(safe.isHighConfidence, isFalse);
    });
  });
}
