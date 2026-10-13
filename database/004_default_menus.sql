-- MoodEats: Menu Default Kurasi (Tampil sebelum AI Dipanggil)
CREATE TABLE IF NOT EXISTS default_menus (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    food_name VARCHAR(150) NOT NULL,
    category VARCHAR(100) NOT NULL,
    image_url TEXT NOT NULL,
    price_est VARCHAR(50),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    display_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
