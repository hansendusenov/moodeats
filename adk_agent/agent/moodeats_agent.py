"""
MoodEats ADK Agent - Master Autonomous Culinary Intelligence Agent
Implements PRD Section 6 & 7: Gemini Flash Lite + Anti-Injection + Temporal Context + Places + Vouchers.
"""

import json
from datetime import datetime
from typing import Dict, Any, Optional, List
from google import genai
from google.genai import types

from adk_agent.config import get_settings
from adk_agent.agent.system_prompt import MOODEATS_SYSTEM_INSTRUCTION
from adk_agent.agent.output_schema import GeminiMoodAnalysisSchema
from adk_agent.agent.tools.places_resolver import PlacesResolver
from adk_agent.agent.tools.voucher_manager import VoucherManager
import re


def _is_english(text: str) -> bool:
    if not text:
        return False
    lower = f" {text.lower()} "
    en_words = [
        " i ", "i'm", "im ", "my ", "me ", "want", "craving", "need", "feel", "feeling",
        "hungry", "tired", "sad", "happy", "stress", "stressed", "cold", "warm", "hot",
        "good", "bad", "eat", "food", "late", "work", "night", "dinner", "lunch", "breakfast",
        "something", "recommend", "please", "soup", "coffee"
    ]
    return any(w in lower for w in en_words)


def _sanitize_badge_for_english(badge: str) -> str:
    b_lower = badge.lower()
    if "comfort food malam" in b_lower or "kuliner malam" in b_lower:
        return "Late-Night Comfort Food"
    if "kuah hangat" in b_lower:
        return "Warm Broth"
    if "makan malam" in b_lower:
        return "Cozy Dinner"
    if "makan siang" in b_lower:
        return "Hearty Lunch"
    if "sarapan" in b_lower:
        return "Morning Breakfast"
    badge = re.sub(r'\bmalam\b', 'Late-Night', badge, flags=re.IGNORECASE)
    badge = re.sub(r'\bsiang\b', 'Lunch', badge, flags=re.IGNORECASE)
    badge = re.sub(r'\bpagi\b', 'Morning', badge, flags=re.IGNORECASE)
    badge = re.sub(r'\bhangat\b', 'Warm', badge, flags=re.IGNORECASE)
    badge = re.sub(r'\bkuah\b', 'Broth', badge, flags=re.IGNORECASE)
    badge = re.sub(r'\bpedas\b', 'Spicy', badge, flags=re.IGNORECASE)
    badge = re.sub(r'\bmanis\b', 'Sweet', badge, flags=re.IGNORECASE)
    badge = re.sub(r'\brempah\b', 'Spiced', badge, flags=re.IGNORECASE)
    badge = re.sub(r'\bkuliner\b', 'Cuisine', badge, flags=re.IGNORECASE)
    return badge.strip()


class MoodEatsAgent:
    def __init__(self):
        self.settings = get_settings()
        api_key = self.settings.google_gemini_api_key or self.settings.gemini_api_key
        self.client = genai.Client(api_key=api_key)
        self.places_resolver = PlacesResolver()
        self.voucher_manager = VoucherManager()

    async def analyze_and_discover(
        self,
        prompt: str,
        user_lat: Optional[float] = None,
        user_lng: Optional[float] = None,
        city: Optional[str] = "Jakarta",
        local_time: Optional[str] = None,
        is_halal_only: bool = False,
        dietary_type: Optional[str] = None,
        allergies: Optional[List[str]] = None,
        only_open_now: bool = False,
    ) -> Dict[str, Any]:
        """
        Coordinates full inference flow:
        1. Contextual temporal building
        2. Gemini 2.5 Flash inference with structured schema (PRD 6.2)
        3. Anti-injection and domain relevance verification (PRD 7.1)
        4. Sponsored merchant dynamic voucher injection (PRD 6.3)
        5. Hyperlocal places resolution (Google Places + Overpass fallback + Cache)
        """
        current_time_str = local_time or datetime.now().strftime("%H:%M:%S")

        # Build context prompt
        context_lines = [
            f"Waktu Lokal Pengguna: Pukul {current_time_str}",
            f"Kota Pengguna: {city or 'Jakarta'}",
            f"Curhatan / Input Pengguna: \"{prompt}\"",
        ]
        if is_halal_only:
            context_lines.append("Batasan Diet: WAJIB HALAL (Hanya rekomendasi tempat dan menu halal, hindari babi, minyak babi, arak, atau alkohol).")
        if dietary_type and dietary_type.lower() not in ("none", "bebas", "all", ""):
            context_lines.append(f"Pola Makan & Diet: {dietary_type} (Pastikan semua menu rekomendasi dan ide masakan mematuhi batasan diet ini).")
        if allergies:
            context_lines.append(f"Alergi / Pantangan Makanan: {', '.join(allergies)} (STRICT: Hindari bahan-bahan ini sama sekali).")
        if only_open_now:
            context_lines.append("Filter Operasional: HANYA RESTORAN YANG SEDANG BUKA SEKARANG (Pastikan restoran/tempat makan beroperasi pada jam ini).")
        context_lines.append("Deteksi Bahasa Input: Perhatikan bahasa 'Curhatan / Input Pengguna'. Jika berbahasa Inggris, field detected_mood, mood_explanation, food_categories, dan zero_results_home_recipes WAJIB ditulis dalam Bahasa Inggris. Jika bahasa Indonesia, gunakan Bahasa Indonesia.")

        full_prompt = "\n".join(context_lines)

        # Gemini Flash Lite call with strict JSON Schema
        config = types.GenerateContentConfig(
            system_instruction=MOODEATS_SYSTEM_INSTRUCTION,
            temperature=0.7,
            response_mime_type="application/json",
            response_schema=GeminiMoodAnalysisSchema,
        )

        response = self.client.models.generate_content(
            model=self.settings.gemini_model,
            contents=full_prompt,
            config=config,
        )

        analysis = json.loads(response.text)

        # Sanitize language purity if prompt was in English
        if _is_english(prompt):
            if "food_categories" in analysis and isinstance(analysis["food_categories"], list):
                analysis["food_categories"] = [_sanitize_badge_for_english(c) for c in analysis["food_categories"]]
            if "detected_mood" in analysis and isinstance(analysis["detected_mood"], str):
                analysis["detected_mood"] = _sanitize_badge_for_english(analysis["detected_mood"])

        # 3. Guardrail check (PRD 7.1)
        if not analysis.get("is_relevant", True):
            return {
                "is_relevant": False,
                "detected_mood": "Neutral",
                "rationale": analysis.get(
                    "mood_explanation",
                    "MoodEats hanya melayani pencarian makanan dan minuman sesuai suasana hatimu nih. Lagi pengen makan apa hari ini?"
                ),
                "places": [],
                "home_recipes": [],
            }

        places_list: List[Dict[str, Any]] = []

        # 4. Check for Sponsored Merchant with 15-Minute Dynamic Voucher (Within 10 km)
        search_keywords = analysis.get("search_keywords", [])
        sponsored_merchant = self.voucher_manager.find_matching_sponsored_merchant(
            keywords=search_keywords,
            user_lat=user_lat,
            user_lng=user_lng,
            max_distance_km=10.0,
        )
        if sponsored_merchant:
            places_list.append(sponsored_merchant)

        # 5. Resolve Hyperlocal Places for each keyword (Strict <= 10 km)
        for idx, keyword in enumerate(search_keywords):
            if len(places_list) >= 4:
                break

            cat_label = analysis.get("food_categories", ["Comfort Food"])[min(idx, len(analysis.get("food_categories", [])) - 1)]
            resolved = await self.places_resolver.resolve_places_hybrid(
                keyword=keyword,
                user_lat=user_lat,
                user_lng=user_lng,
                city=city,
                mood_badge=cat_label,
                max_results=2,
                max_distance_km=10.0,
                open_now=only_open_now,
            )
            for p in resolved:
                if len(places_list) < 4:
                    places_list.append(p)

        # Filter strictly open places if requested
        if only_open_now:
            places_list = [p for p in places_list if p.get("is_open", True)]

        # Final safety gate: Ensure all places strictly <= 10.0 km if GPS is active
        if user_lat is not None and user_lng is not None:
            places_list = [p for p in places_list if p.get("distance_km", 0) <= 10.0]

        return {
            "is_relevant": True,
            "detected_mood": analysis.get("detected_mood", "Comfort Seeking"),
            "rationale": analysis.get("mood_explanation", "Makanan yang pas untuk menemani harimu."),
            "food_categories": analysis.get("food_categories", []),
            "places": places_list,
            "home_recipes": analysis.get("zero_results_home_recipes", []),
        }

    async def analyze_image_sentiment(
        self,
        image_bytes: bytes,
        mime_type: str = "image/jpeg",
        lang: str = "id",
    ) -> Dict[str, Any]:
        """
        Multimodal analysis of food or user facial/environmental sentiment using Gemini 2.5 Flash.
        """
        image_part = types.Part.from_bytes(
            data=image_bytes,
            mime_type=mime_type,
        )

        lang_instruction = "bahasa Indonesia" if lang == "id" else "English"
        prompt_instruction = (
            "Kamu adalah asisten kurasi kuliner AI cerdas MoodEats. "
            "Tugasmu menganalisis gambar ini. Gambar ini bisa berupa makanan, minuman, meja kerja, struk, atau selfie ekspresi wajah seseorang. "
            f"Analisis gambar tersebut dan buatkan SATU kalimat ringkas dalam {lang_instruction} yang mendeskripsikan suasana hati atau makanan yang diinginkan pengguna. "
            "Contoh jika makanan: 'Mencari kuliner lezat yang serupa dengan hidangan ini: cita rasa gurih hangat dan memuaskan.' "
            "Contoh jika wajah lelah: 'Lagi lelah dan kurang bertenaga, butuh asupan makanan lezat bernutrisi untuk pemulihan.' "
            "Contoh jika ceria/santai: 'Lagi santai dan bersemangat, ingin camilan manis atau kopi segar.' "
            "PENTING: Hanya kembalikan teks kalimat tersebut saja, tanpa tanda petik pembuka/penutup, dan tanpa penjelasan tambahan."
        )

        try:
            response = self.client.models.generate_content(
                model=self.settings.gemini_model,
                contents=[image_part, prompt_instruction],
            )
            detected_text = response.text.strip().strip('"').strip("'")
            return {
                "status": "success",
                "detected_text": detected_text,
            }
        except Exception as e:
            fallback = "Mencari kuliner lezat sesuai foto ini" if lang == "id" else "Looking for delicious dishes matching this photo"
            return {
                "status": "error",
                "message": str(e),
                "detected_text": fallback,
            }

