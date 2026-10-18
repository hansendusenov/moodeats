"""
MoodEats ADK Agent - Hybrid Hyperlocal Places Resolver
Implements Section 6.3 & 7.1: Google Places API (New) + Overpass OSM Fallback + Action Links.
"""

import math
import hashlib
import json
import httpx
import urllib.parse
from datetime import datetime
from typing import List, Dict, Any, Optional
from adk_agent.config import get_settings
from adk_agent.agent.tools.cache_manager import PlacesCacheManager


def calculate_distance_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Haversine distance between two coordinates in kilometers."""
    R = 6371.0  # Earth radius in kilometers
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlng / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(R * c, 1)


def get_culinary_photo_url(name: str, category: str = "") -> str:
    lower = f"{name} {category}".lower()
    if any(k in lower for k in ["bakso", "meatball"]):
        return "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600"
    if any(k in lower for k in ["soto", "soup", "kuah", "sop", "rawon"]):
        return "https://images.unsplash.com/photo-1547592180-85f173990554?w=600"
    if any(k in lower for k in ["sate", "satay", "panggang", "bakar"]):
        return "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=600"
    if any(k in lower for k in ["kopi", "coffee", "cafe", "kafe", "kopitiam"]):
        return "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600"
    if any(k in lower for k in ["ayam", "chicken", "geprek", "bebek"]):
        return "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600"
    if any(k in lower for k in ["nasi", "rice", "padang", "warteg"]):
        return "https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600"
    if any(k in lower for k in ["burger", "western", "pizza", "pasta"]):
        return "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600"
    if any(k in lower for k in ["mie", "noodle", "ramen", "kwetiau"]):
        return "https://images.unsplash.com/photo-1552611052-33e04de081de?w=600"
    if any(k in lower for k in ["manis", "dessert", "cake", "boba", "es ", "gelato", "ice cream"]):
        return "https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=600"
    if any(k in lower for k in ["seafood", "ikan", "udang", "cumi"]):
        return "https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=600"
    return "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600"


class PlacesResolver:
    PLACES_SEARCH_URL = "https://places.googleapis.com/v1/places:searchText"
    OVERPASS_URL = "https://overpass-api.de/api/interpreter"

    def __init__(self):
        self.settings = get_settings()
        self.cache_manager = PlacesCacheManager()

    async def resolve_places_hybrid(
        self,
        keyword: str,
        user_lat: Optional[float] = None,
        user_lng: Optional[float] = None,
        city: Optional[str] = "Jakarta",
        mood_badge: str = "Warm Comfort",
        max_results: int = 3,
        max_distance_km: float = 10.0,
        open_now: bool = False,
    ) -> List[Dict[str, Any]]:
        """
        Resolves places with:
        1. Cache inspection in Supabase places_cache (PRD 6.3.1)
        2. Google Places API (New v1) (PRD 6.3.2)
        3. Zero-cost Overpass OSM fallback if Google fails or limit reached (PRD 6.3.3)
        Strictly enforces max_distance_km <= 10.0 km and optional open_now filter.
        """
        # 1. Cache Inspection
        cache_seed = f"{keyword.lower().strip()}_{city or 'default'}_{round(user_lat or -6.2, 2)}_{round(user_lng or 106.8, 2)}_{'open' if open_now else 'all'}"
        cache_key = hashlib.sha256(cache_seed.encode("utf-8")).hexdigest()

        cached_results = self.cache_manager.get_cached_places(cache_key)
        if cached_results:
            if user_lat is not None and user_lng is not None:
                cached_results = [p for p in cached_results if p.get("distance_km", 0) <= max_distance_km]
            if open_now:
                cached_results = [p for p in cached_results if p.get("is_open", True)]
            if cached_results:
                return cached_results[:max_results]

        # 2. Try Google Places API (New v1)
        results = await self._search_google_places(
            keyword=keyword,
            user_lat=user_lat,
            user_lng=user_lng,
            city=city,
            mood_badge=mood_badge,
            max_results=max_results,
            max_distance_km=max_distance_km,
            open_now=open_now,
        )

        # 3. Fallback to Overpass OSM if Google failed
        if not results and user_lat is not None and user_lng is not None:
            results = await self._search_overpass_osm(
                keyword=keyword,
                user_lat=user_lat,
                user_lng=user_lng,
                mood_badge=mood_badge,
                max_results=max_results,
                max_distance_km=max_distance_km,
            )

        # Filter strictly by open_now if requested
        if open_now and results:
            results = [p for p in results if p.get("is_open", True)]

        # Save to Cache if results found
        if results:
            self.cache_manager.set_cached_places(
                cache_key=cache_key,
                keyword=keyword,
                places=results,
                provider="google_places_v1" if results and results[0].get("source") != "osm" else "osm_overpass",
                ttl_days=7,
            )

        return results

    async def _search_google_places(
        self,
        keyword: str,
        user_lat: Optional[float],
        user_lng: Optional[float],
        city: Optional[str],
        mood_badge: str,
        max_results: int,
        max_distance_km: float = 10.0,
        open_now: bool = False,
    ) -> List[Dict[str, Any]]:
        api_key = self.settings.google_places_api_key
        if not api_key:
            return []

        headers = {
            "Content-Type": "application/json",
            "X-Goog-Api-Key": api_key,
            "X-Goog-FieldMask": (
                "places.id,places.displayName,places.formattedAddress,"
                "places.location,places.rating,places.userRatingCount,"
                "places.priceLevel,places.primaryType,places.googleMapsUri,"
                "places.regularOpeningHours,places.currentOpeningHours"
            ),
        }

        query_text = f"{keyword} {city or ''}".strip()
        payload: Dict[str, Any] = {
            "textQuery": query_text,
            "maxResultCount": 10,
            "languageCode": "id",
        }

        if open_now:
            payload["openNow"] = True

        if user_lat is not None and user_lng is not None:
            payload["locationBias"] = {
                "circle": {
                    "center": {"latitude": user_lat, "longitude": user_lng},
                    "radius": 10000.0,
                }
            }

        try:
            async with httpx.AsyncClient(timeout=4.0) as client:
                res = await client.post(self.PLACES_SEARCH_URL, json=payload, headers=headers)
                if res.status_code == 200:
                    data = res.json()
                    places = []
                    for item in data.get("places", []):
                        lat = item.get("location", {}).get("latitude")
                        lng = item.get("location", {}).get("longitude")
                        dist = calculate_distance_km(user_lat, user_lng, lat, lng) if (user_lat and user_lng and lat and lng) else 1.2

                        # Strictly filter out places further than max_distance_km (10km limit)
                        if user_lat is not None and user_lng is not None and dist > max_distance_km:
                            continue

                        current_hours = item.get("currentOpeningHours", {})
                        is_open = current_hours.get("openNow", True) if current_hours else True
                        if open_now and not is_open:
                            continue

                        opening_hours_text = "Buka Sekarang" if is_open else "Tutup"
                        weekday_descs = current_hours.get("weekdayDescriptions", [])
                        if weekday_descs:
                            today_idx = datetime.now().weekday()
                            if today_idx < len(weekday_descs):
                                desc = weekday_descs[today_idx]
                                parts = desc.split(":", 1)
                                if len(parts) > 1 and parts[1].strip():
                                    hours_str = parts[1].strip()
                                    opening_hours_text = f"Buka • {hours_str}" if is_open else f"Tutup • Buka {hours_str}"

                        place_name = item.get("displayName", {}).get("text", "Unknown")
                        import urllib.parse
                        encoded_name = urllib.parse.quote(f"{place_name} {item.get('formattedAddress', '')}")
                        
                        # Official Google Maps Place Page or Verified Search URI with Place ID
                        maps_url = item.get("googleMapsUri")
                        if not maps_url:
                            if item.get("id"):
                                maps_url = f"https://www.google.com/maps/search/?api=1&query={encoded_name}&query_place_id={item.get('id')}"
                            elif lat and lng:
                                maps_url = f"https://www.google.com/maps/search/?api=1&query={lat},{lng}"
                            else:
                                maps_url = f"https://www.google.com/maps/search/?api=1&query={encoded_name}"

                        delivery_url = f"https://gofood.co.id/jakarta/search?q={urllib.parse.quote(place_name)}"

                        places.append({
                            "id": str(item.get("id", "top-1")),
                            "name": place_name,
                            "category": (item.get("primaryType") or "Kuliner Nusantara").replace("_", " ").title(),
                            "address": item.get("formattedAddress", f"Sekitar {city or 'Jakarta'}"),
                            "distance_km": round(dist, 1),
                            "rating": item.get("rating", 4.5),
                            "photo_url": get_culinary_photo_url(place_name, item.get("primaryType") or "Kuliner"),
                            "mood_badge": mood_badge,
                            "price_range": "Rp 20.000 - Rp 45.000",
                            "is_sponsored": False,
                            "is_open": is_open,
                            "opening_hours": opening_hours_text,
                            "voucher": {"has_voucher": False},
                            "action_links": {
                                "google_maps": maps_url,
                                "delivery_app": delivery_url,
                                "whatsapp_booking": None,
                            },
                            "source": "google_places_v1",
                        })

                    # Sort by proximity
                    places.sort(key=lambda x: x["distance_km"])
                    return places[:max_results]
        except Exception:
            pass

        return []

    async def _search_overpass_osm(
        self,
        keyword: str,
        user_lat: float,
        user_lng: float,
        mood_badge: str,
        max_results: int,
        max_distance_km: float = 10.0,
    ) -> List[Dict[str, Any]]:
        """Overpass OSM Zero-Cost Safety Net with 10km radius limitation"""
        overpass_query = f"""
        [out:json][timeout:5];
        (
          node["amenity"~"restaurant|cafe|fast_food"](around:10000,{user_lat},{user_lng});
        );
        out body 15;
        """
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                res = await client.post(self.OVERPASS_URL, data={"data": overpass_query})
                if res.status_code == 200:
                    data = res.json()
                    places = []
                    for el in data.get("elements", []):
                        name = el.get("tags", {}).get("name") or f"Warung {keyword.title()}"
                        cuisine = el.get("tags", {}).get("cuisine") or "Indonesian"
                        street = el.get("tags", {}).get("addr:street") or "Jl. Raya Terdekat"
                        lat = el.get("lat")
                        lng = el.get("lon")
                        dist = calculate_distance_km(user_lat, user_lng, lat, lng) if (lat and lng) else 1.5

                        # Enforce max 10km radius limit
                        if dist > max_distance_km:
                            continue

                        places.append({
                            "id": f"osm-{el.get('id')}",
                            "name": name,
                            "category": cuisine.title(),
                            "address": street,
                            "distance_km": round(dist, 1),
                            "rating": 4.4,
                            "photo_url": get_culinary_photo_url(name, cuisine),
                            "mood_badge": mood_badge,
                            "price_range": "Rp 15.000 - Rp 35.000",
                            "is_sponsored": False,
                            "is_open": True,
                            "opening_hours": "Buka Sekarang",
                            "voucher": {"has_voucher": False},
                            "action_links": {
                                "google_maps": f"https://www.google.com/maps/search/?api=1&query={urllib.parse.quote(name)}+{lat},{lng}" if (lat and lng) else f"https://www.google.com/maps/search/?api=1&query={urllib.parse.quote(name)}",
                                "delivery_app": f"https://gofood.co.id/jakarta/search?q={urllib.parse.quote(name)}",
                                "whatsapp_booking": None,
                            },
                            "source": "osm",
                        })

                    places.sort(key=lambda x: x["distance_km"])
                    return places[:max_results]
        except Exception:
            pass
        return []
