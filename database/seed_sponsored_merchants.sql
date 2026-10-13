-- MoodEats: Seed Data - Sponsored Merchants & 15-Minute Dynamic Vouchers

INSERT INTO sponsored_merchants (
    merchant_name, category, address, lat, lng, image_url, promo_badge,
    voucher_code, discount_description, voucher_type, countdown_minutes,
    max_claim_quota, claimed_count, affiliate_url, is_active, priority
) VALUES
(
    'Soto Kudus Menara Senayan',
    'Kuah Hangat',
    'Jl. Tentara Pelajar No.1, Kebayoran Lama, Jakarta Selatan',
    -6.2210,
    106.7950,
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
    'PROMO EKSKLUSIF 25%',
    'KUDUS15',
    'Diskon 25% Min. Belanja Rp 35.000 berlaku 15 menit',
    'timer',
    15,
    50,
    0,
    'https://gofood.link/sotokudusmenara',
    TRUE,
    1
),
(
    'Kopi Kenangan & Toast Tebet',
    'Snack & Kopi',
    'Jl. Tebet Raya No. 12, Jakarta Selatan',
    -6.2280,
    106.8550,
    'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400',
    'GRATIS TOAST',
    'KENANGAN15',
    'Gratis Toast Cokelat dengan Pembelian Kopi Susu',
    'timer',
    15,
    100,
    0,
    'https://gofood.link/kopitebet',
    TRUE,
    2
)
ON CONFLICT DO NOTHING;
