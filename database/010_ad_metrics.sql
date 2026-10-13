-- MoodEats: Metrik Iklan & Analitik Konversi (B2B Insights)
CREATE TABLE IF NOT EXISTS ad_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    banner_id UUID REFERENCES banners(id) ON DELETE CASCADE,
    merchant_id UUID REFERENCES sponsored_merchants(id) ON DELETE CASCADE,
    user_id UUID,
    event_type VARCHAR(20) NOT NULL CHECK (event_type IN ('impression', 'click', 'voucher_claim', 'voucher_redeem')),
    city VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ad_metrics_reporting ON ad_metrics(event_type, created_at);
