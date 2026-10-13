-- MoodEats: Profil Pengguna & Preferensi Diet
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name VARCHAR(100) NOT NULL,
    email VARCHAR(150),
    is_halal_only BOOLEAN DEFAULT FALSE,
    dietary_type VARCHAR(50) DEFAULT 'none',
    allergies JSONB DEFAULT '[]'::jsonb,
    budget_preference INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
