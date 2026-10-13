"""
MoodEats - Database Migration Runner
Executes all SQL migration files in order against Supabase PostgreSQL.
"""

import os
from pathlib import Path
import psycopg2
from dotenv import load_dotenv

# Load .env from project root if present
root_dir = Path(__file__).resolve().parent.parent
env_file = root_dir / ".env"
if env_file.exists():
    load_dotenv(env_file)
else:
    load_dotenv()

DB_CONFIG = {
    "host": os.getenv("SUPABASE_DB_HOST", "aws-0-ap-southeast-1.pooler.supabase.com"),
    "port": int(os.getenv("SUPABASE_DB_PORT", "5432")),
    "dbname": os.getenv("SUPABASE_DB_NAME", "postgres"),
    "user": os.getenv("SUPABASE_DB_USER", "postgres"),
    "password": os.getenv("SUPABASE_DB_PASSWORD", ""),
}

SQL_FILES = [
    "001_extensions.sql",
    "002_user_profiles.sql",
    "003_banners.sql",
    "004_default_menus.sql",
    "005_places_cache.sql",
    "006_mood_sessions.sql",
    "007_favorite_places.sql",
    "008_sponsored_merchants.sql",
    "009_user_vouchers.sql",
    "010_ad_metrics.sql",
    "011_admin_users.sql",
    "seed_default_menus.sql",
    "seed_admin_users.sql",
]


def run_migrations():
    if not DB_CONFIG["password"]:
        print("[ERR] SUPABASE_DB_PASSWORD is not set! Please define it in your .env or environment.")
        return

    db_dir = Path(__file__).parent
    print(f"Connecting to PostgreSQL at {DB_CONFIG['host']} as {DB_CONFIG['user']}...")
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = True
    cursor = conn.cursor()

    print("\nStarting migrations...\n" + "=" * 50)
    for sql_file in SQL_FILES:
        file_path = db_dir / sql_file
        if not file_path.exists():
            print(f"[SKIP] {sql_file} - File not found")
            continue

        sql_content = file_path.read_text(encoding="utf-8")
        try:
            cursor.execute(sql_content)
            print(f"[OK]   {sql_file}")
        except Exception as e:
            print(f"[ERR]  {sql_file}: {e}")

    # Verify public tables
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        ORDER BY table_name;
    """)
    tables = [row[0] for row in cursor.fetchall()]
    print("=" * 50)
    print(f"Total tables created in 'public' schema: {len(tables)}")
    for t in tables:
        cursor.execute(f"SELECT COUNT(*) FROM {t};")
        count = cursor.fetchone()[0]
        print(f"  - {t:25} ({count} rows)")

    cursor.close()
    conn.close()
    print("\nMigration completed successfully!")


if __name__ == "__main__":
    run_migrations()
