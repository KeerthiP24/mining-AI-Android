"""
Image Hazard Detection Engine — MobileNetV2 with ImageNet weights.
Uses top-1 ImageNet class to heuristically map to mining hazard categories.
Full fine-tuned classifier deferred to Phase 6.
"""
import time
from io import BytesIO
from typing import Optional

from app.core.logger import logger
from app.schemas.image_schema import ImageDetectionResponse

try:
    import numpy as np
    from PIL import Image
    import tensorflow as tf

    _MNV2_AVAILABLE = True
except ImportError:  # pragma: no cover
    _MNV2_AVAILABLE = False
    logger.warning("[ImageModel] TensorFlow/Pillow not installed — falling back to stub")

# ImageNet class index ranges that heuristically map to mining hazards.
# These are rough cluster approximations; Phase 6 uses a fine-tuned head.
_HAZARD_MAP: list[tuple[set[int], str, str, str]] = [
    # (class_index_set, hazard_detected, suggested_severity, recommendation)
    (set(range(895, 900)),  "fire",      "high",   "Evacuate area and activate fire suppression."),
    (set(range(725, 730)),  "gas_leak",  "high",   "Ventilate area and check gas detectors."),
    (set(range(570, 580)),  "machinery", "medium", "Stop machinery and inspect before resuming."),
    (set(range(950, 960)),  "roof_fall", "critical","Evacuate section and notify supervisor immediately."),
    (set(range(763, 770)),  "electrical","high",   "Isolate power supply and call qualified personnel."),
]


class ImageDetectionModel:
    def __init__(self) -> None:
        self._model: Optional[object] = None
        self._decode_fn: Optional[object] = None

    def _load(self) -> None:
        if self._model is not None or not _MNV2_AVAILABLE:
            return
        logger.info("[ImageModel] Loading MobileNetV2 (ImageNet weights)…")
        self._model = tf.keras.applications.MobileNetV2(weights="imagenet")
        self._decode_fn = tf.keras.applications.mobilenet_v2.decode_predictions
        logger.info("[ImageModel] MobileNetV2 loaded")

    def predict(self, image_bytes: bytes) -> ImageDetectionResponse:
        start = time.perf_counter()

        if not _MNV2_AVAILABLE:
            return self._stub_response(image_bytes, start)

        try:
            self._load()
            img = Image.open(BytesIO(image_bytes)).convert("RGB").resize((224, 224))
            arr = np.array(img, dtype=np.float32)[np.newaxis, ...]
            arr = tf.keras.applications.mobilenet_v2.preprocess_input(arr)

            preds = self._model.predict(arr, verbose=0)
            top_preds = self._decode_fn(preds, top=5)[0]

            # top_preds: list of (class_id_str, class_name, probability)
            # Use the top-1 class index to determine hazard category
            top_class_name: str = top_preds[0][1].lower()
            top_confidence: float = float(top_preds[0][2])

            hazard, severity, recommendation = self._classify(top_class_name, top_confidence)

            elapsed_ms = int((time.perf_counter() - start) * 1000)
            logger.info(
                f"[ImageModel] hazard={hazard} confidence={top_confidence:.2f} "
                f"class={top_class_name} elapsed={elapsed_ms}ms"
            )
            return ImageDetectionResponse(
                hazard_detected=hazard,
                confidence=top_confidence,
                suggested_severity=severity,
                correction_recommendation=recommendation,
                processing_time_ms=elapsed_ms,
            )
        except Exception as exc:  # noqa: BLE001
            logger.error(f"[ImageModel] Prediction error: {exc}")
            return self._stub_response(image_bytes, start)

    @staticmethod
    def _classify(class_name: str, confidence: float) -> tuple[str, str, str]:
        fire_keywords = {"fire", "flame", "smoke", "conflagration"}
        gas_keywords = {"gas", "fume", "pipe", "valve"}
        machinery_keywords = {"crane", "excavator", "bulldozer", "chainsaw", "machine"}
        roof_keywords = {"cliff", "rock", "rubble", "cave", "mine"}
        electrical_keywords = {"switch", "circuit", "electric", "wire", "cable", "pylon"}

        name = class_name.lower()

        if any(k in name for k in fire_keywords):
            return ("fire", "high", "Evacuate area and activate fire suppression.")
        if any(k in name for k in gas_keywords):
            return ("gas_leak", "high", "Ventilate area and check gas detectors.")
        if any(k in name for k in machinery_keywords):
            return ("machinery", "medium", "Stop machinery and inspect before resuming.")
        if any(k in name for k in roof_keywords):
            return ("roof_fall", "critical", "Evacuate section and notify supervisor immediately.")
        if any(k in name for k in electrical_keywords):
            return ("electrical", "high", "Isolate power supply and call qualified personnel.")

        # Default: safe / other
        severity = "low" if confidence < 0.4 else "medium"
        return ("other", severity, "Monitor situation and report to supervisor if worsening.")

    @staticmethod
    def _stub_response(image_bytes: bytes, start: float) -> ImageDetectionResponse:
        elapsed_ms = int((time.perf_counter() - start) * 1000)
        logger.info(f"[ImageModel STUB] Analyzing image ({len(image_bytes)} bytes)")
        return ImageDetectionResponse(
            hazard_detected="safe",
            confidence=0.50,
            suggested_severity="low",
            correction_recommendation="No immediate action required. (TensorFlow not available.)",
            processing_time_ms=elapsed_ms,
        )


image_model = ImageDetectionModel()
