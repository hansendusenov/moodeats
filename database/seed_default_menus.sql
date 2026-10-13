-- MoodEats: Seed Data - Menu Default Kurasi
-- Menu ini tampil di halaman awal mobile sebelum AI dipanggil

INSERT INTO default_menus (food_name, category, image_url, price_est, description, is_active, display_order) VALUES
('Soto Kudus Daging Sapi', 'Kuah Hangat', 'https://tpkchcrwqjrfprdibawz.supabase.co/storage/v1/object/public/menus/soto-kudus.jpg', 'Rp 25.000', 'Kuah bening rempah gurih dengan suwiran daging sapi empuk dan taburan bawang goreng', TRUE, 1),
('Nasi Gila Menteng Spesial', 'Pedas Gurih', 'https://tpkchcrwqjrfprdibawz.supabase.co/storage/v1/object/public/menus/nasi-gila.jpg', 'Rp 28.000', 'Nasi dengan tumisan sosis, bakso, telur, dan bumbu gurih pedas manis khas Menteng', TRUE, 2),
('Bubur Ayam Sukabumi Komplit', 'Sarapan Ringan', 'https://tpkchcrwqjrfprdibawz.supabase.co/storage/v1/object/public/menus/bubur-ayam.jpg', 'Rp 18.000', 'Bubur lembut kaldu kuning dengan cakwe, kerupuk, dan ati ampela', TRUE, 3),
('Bakso Mercon Urat Kuah Rawit', 'Ekstra Pedas', 'https://tpkchcrwqjrfprdibawz.supabase.co/storage/v1/object/public/menus/bakso-mercon.jpg', 'Rp 26.000', 'Bakso urat jumbo isi cabe rawit pedas meledak dengan kuah kaldu sapi', TRUE, 4),
('Es Kopi Susu Aren & Toast Klasik', 'Snack & Kopi', 'https://tpkchcrwqjrfprdibawz.supabase.co/storage/v1/object/public/menus/kopi-toast.jpg', 'Rp 22.000', 'Kopi susu gula aren creamy dipadu roti panggang mentega renyah', TRUE, 5),
('Mie Ayam Bakso Pangsit', 'Makan Siang', 'https://tpkchcrwqjrfprdibawz.supabase.co/storage/v1/object/public/menus/mie-ayam.jpg', 'Rp 20.000', 'Mie ayam kenyal dengan bakso sapi dan pangsit goreng renyah', TRUE, 6),
('Nasi Uduk Betawi Komplit', 'Sarapan Nusantara', 'https://tpkchcrwqjrfprdibawz.supabase.co/storage/v1/object/public/menus/nasi-uduk.jpg', 'Rp 15.000', 'Nasi santan gurih dengan tempe orek, telur balado, dan sambal kacang', TRUE, 7),
('Sup Ayam Rempah Jahe', 'Comfort Food', 'https://tpkchcrwqjrfprdibawz.supabase.co/storage/v1/object/public/menus/sup-ayam.jpg', 'Rp 23.000', 'Sup ayam kampung berkuah bening dengan jahe segar dan wortel', TRUE, 8);
