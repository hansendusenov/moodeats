-- ╔══════════════════════════════════════════════════════════════╗
-- ║  MoodEats - Run All Database Migrations                    ║
-- ║  Execute: psql <connection_string> -f database/run_all.sql ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Extensions
\i 001_extensions.sql

-- Core tables (in dependency order)
\i 002_user_profiles.sql
\i 003_banners.sql
\i 004_default_menus.sql
\i 005_places_cache.sql
\i 006_mood_sessions.sql
\i 007_favorite_places.sql
\i 008_sponsored_merchants.sql
\i 009_user_vouchers.sql
\i 010_ad_metrics.sql
\i 011_admin_users.sql

-- Seed data
\i seed_default_menus.sql
