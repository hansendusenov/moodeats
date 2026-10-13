-- MoodEats: Riwayat Sesi Percakapan Multi-Turn & Sentimen
CREATE TABLE IF NOT EXISTS mood_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'assistant')),
    message_text TEXT NOT NULL,
    detected_mood VARCHAR(50),
    food_categories JSONB,
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    city_detected VARCHAR(100),
    ai_response_payload JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mood_sessions_history ON mood_sessions(session_id, created_at ASC);
