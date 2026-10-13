-- MoodEats: Redemptions & Klaim Voucher Pengguna
CREATE TABLE IF NOT EXISTS user_vouchers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID REFERENCES sponsored_merchants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    voucher_code VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'redeemed', 'expired')),
    claimed_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL
);
