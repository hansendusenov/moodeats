-- MoodEats: Cache Pencarian Lokasi (Hybrid Quota Saver)
CREATE TABLE IF NOT EXISTS places_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cache_key VARCHAR(255) UNIQUE NOT NULL,
    keyword VARCHAR(100) NOT NULL,
    source_provider VARCHAR(20) NOT NULL,
    places_payload JSONB NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_places_cache_lookup ON places_cache(cache_key, expires_at);
