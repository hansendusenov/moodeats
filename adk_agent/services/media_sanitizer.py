"""
MoodEats - In-Memory Multimodal Media Sanitizer
Complies with UU PDP No. 27/2022 (Data Minimisation & Sensitive PII Protection).
Ensures raw image and audio buffers exist ONLY in RAM during inference, strips
all EXIF metadata (GPS coordinates, device tags, camera specs), and guarantees
ZERO disk writes.
"""

import io
import gc
import logging
from typing import Tuple
from PIL import Image

logger = logging.getLogger("moodeats.sanitizer")


def sanitize_image_buffer(
    raw_bytes: bytes,
    mime_type: str = "image/jpeg",
) -> Tuple[bytes, str]:
    """
    Strips EXIF, GPS location tags, device signatures, and hardware metadata
    from image bytes purely in RAM.
    
    Guarantees:
    1. Zero writes to persistent disk storage.
    2. Strips all EXIF GPS coordinates and device manufacturer info.
    3. Explicit memory release of intermediate buffers.
    """
    if not raw_bytes:
        raise ValueError("Image buffer is empty")

    input_buf = io.BytesIO(raw_bytes)
    output_buf = io.BytesIO()

    try:
        with Image.open(input_buf) as img:
            fmt = img.format or "JPEG"
            if fmt.upper() in ("JPEG", "JPG"):
                output_fmt = "JPEG"
                clean_mime = "image/jpeg"
                # Ensure RGB mode for JPEG (handles RGBA / palette / CMYK)
                if img.mode != "RGB":
                    clean_img = img.convert("RGB")
                else:
                    clean_img = img.copy()
            elif fmt.upper() == "PNG":
                output_fmt = "PNG"
                clean_mime = "image/png"
                clean_img = img.copy()
            elif fmt.upper() == "WEBP":
                output_fmt = "WEBP"
                clean_mime = "image/webp"
                clean_img = img.copy()
            else:
                # Standardize unknown format to clean JPEG
                output_fmt = "JPEG"
                clean_mime = "image/jpeg"
                clean_img = img.convert("RGB")

            # Save clean pixel stream WITHOUT passing exif parameter
            # This completely discards all EXIF / GPS / maker metadata
            clean_img.save(output_buf, format=output_fmt, quality=85)
            sanitized_bytes = output_buf.getvalue()

            logger.info(
                f"[PDP Compliance] In-memory EXIF metadata stripped. "
                f"Original: {len(raw_bytes)} bytes -> Sanitized: {len(sanitized_bytes)} bytes."
            )

            # Explicit memory cleanup
            del clean_img

        return sanitized_bytes, clean_mime

    except Exception as e:
        logger.error(f"Error sanitizing image buffer: {e}")
        raise ValueError(f"Invalid or corrupted image format: {e}")

    finally:
        input_buf.close()
        output_buf.close()
        gc.collect()
