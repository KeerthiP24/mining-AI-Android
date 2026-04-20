"""
Tests for the Image Detection API endpoint.
Phase 1: tests the stub model logic.
Phase 6: updated to test the trained MobileNetV2 model.
"""
from app.ml.image_model import image_model


def test_image_detection_stub():
    """Stub model should return 'safe' for any input."""
    fake_image = b"\x89PNG\r\n\x1a\n" + b"\x00" * 100  # Fake PNG header
    response = image_model.predict(fake_image)
    assert response.hazard_detected == "safe"
    assert response.confidence == 0.50
    assert response.suggested_severity == "low"
    assert response.processing_time_ms >= 0


def test_image_detection_empty():
    """Stub should handle empty bytes gracefully."""
    response = image_model.predict(b"")
    assert response.hazard_detected == "safe"
