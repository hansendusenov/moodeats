-- MoodEats: Restoran Bersponsor & Voucher Promo Dinamis
CREATE TABLE IF NOT EXISTS sponsored_merchants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_name VARCHAR(150) NOT NULL,
    category VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    image_url TEXT,
    promo_badge VARCHAR(50),
    voucher_code VARCHAR(50) NOT NULL,
    discount_description VARCHAR(150) NOT NULL,
    voucher_type VARCHAR(20) DEFAULT 'timer' CHECK (voucher_type IN ('code', 'timer')),
    countdown_minutes INT DEFAULT 15,
    max_claim_quota INT DEFAULT 100,
    claimed_count INT DEFAULT 0,
    affiliate_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    priority INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
