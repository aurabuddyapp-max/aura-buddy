import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# Load environment variables from .env
load_dotenv()

# Get connection string
db_url = os.getenv("DATABASE_URL")
if not db_url:
    print("Error: DATABASE_URL not found in .env")
    exit(1)

# Create engine
engine = create_engine(db_url)

# Execute SQL to add columns
with engine.connect() as conn:
    print("Adding bio column to users...")
    try:
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS bio VARCHAR(200) DEFAULT 'Aura enthusiast ✨'"))
        conn.commit()
    except Exception as e:
        print(f"Error adding bio: {e}")

    print("Adding hashtags column to posts...")
    try:
        conn.execute(text("ALTER TABLE posts ADD COLUMN IF NOT EXISTS hashtags TEXT"))
        conn.commit()
    except Exception as e:
        print(f"Error adding hashtags: {e}")

    print("Migration complete!")
