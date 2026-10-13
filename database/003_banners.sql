-- MoodEats: Banner Iklan dengan Geo-Targeting & Time-Parting
CREATE TABLE IF NOT EXISTS banners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(150) NOT NULL,
    image_url TEXT NOT NULL,
    target_url TEXT,
    targeting_type VARCHAR(20) DEFAULT 'global' CHECK (targeting_type IN ('global', 'city', 'radius')),
    target_city VARCHAR(100),
    target_lat DOUBLE PRECISION,
    target_lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION DEFAULT 5.0,
    active_days INT[] DEFAULT '{1,2,3,4,5,6,7}',
    start_hour TIME NULL,
    end_hour TIME NULL,
    priority INT DEFAULT 1,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_banners_active ON banners(is_active, start_date, end_date);
