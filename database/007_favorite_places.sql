-- MoodEats: Comfort Food Vault (Daftar Resto/Menu Favorit Pengguna)
CREATE TABLE IF NOT EXISTS favorite_places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    place_name VARCHAR(150) NOT NULL,
    category VARCHAR(100),
    address TEXT,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    saved_reason VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
