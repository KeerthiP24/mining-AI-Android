import 'package:flutter/foundation.dart';

/// Stub for the Phase 6 FastAPI AI risk recalculation endpoint.
/// Phase 3 calls this after every checklist submission so Phase 6
/// only needs to implement the HTTP POST — not hunt for the call site.
class AiService {
  /// Called after checklist submission.
  /// Phase 6 replaces this body with a real HTTP POST to /api/v1/risk/predict.
  Future<void> triggerRiskRecalculation(String uid) async {
    debugPrint(
      '[AiService] triggerRiskRecalculation called for $uid — stub, no-op in Phase 3',
    );
    // Phase 6: POST /api/v1/risk/predict with uid and feature vector
  }
}
