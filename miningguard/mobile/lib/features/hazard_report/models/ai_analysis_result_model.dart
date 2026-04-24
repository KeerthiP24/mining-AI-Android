import 'hazard_report_model.dart';

class AiAnalysisResult {
  const AiAnalysisResult({
    required this.hazardDetected,
    required this.confidence,
    required this.suggestedSeverity,
    required this.recommendedAction,
  });

  final String hazardDetected;
  final double confidence;
  final HazardSeverity suggestedSeverity;
  final String recommendedAction;

  int get confidencePercent => (confidence * 100).round();
  bool get isHighConfidence => confidence >= 0.75;

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) {
    // Backend uses correction_recommendation; spec says recommended_action — handle both
    final action = (json['recommended_action'] ?? json['correction_recommendation'] ?? '') as String;
    return AiAnalysisResult(
      hazardDetected: json['hazard_detected'] as String? ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      suggestedSeverity: HazardSeverity.fromString(
        json['suggested_severity'] as String? ?? 'low',
      ),
      recommendedAction: action,
    );
  }

  static AiAnalysisResult safe() => const AiAnalysisResult(
        hazardDetected: 'safe',
        confidence: 0.0,
        suggestedSeverity: HazardSeverity.low,
        recommendedAction: '',
      );
}
