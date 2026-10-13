-- MoodEats: Seed Data - Admin User Default
-- Password: MoodEats@2026 (bcrypt hash)

INSERT INTO admin_users (username, email, password_hash, role, is_active) VALUES
('superadmin', 'admin@moodeats.id', '$2y$10$q4ie6MRcWyAsxK3bMOFNTut0N1jTmRDTNuLhBfz/7VLfe5STrdXbO', 'superadmin', TRUE)
ON CONFLICT (username) DO NOTHING;
