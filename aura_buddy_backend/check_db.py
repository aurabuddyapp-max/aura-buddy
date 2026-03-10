from sqlalchemy import create_engine, inspect
from app.config import settings

def check_tables():
    engine = create_engine(settings.DATABASE_URL)
    inspector = inspect(engine)
    
    tables = inspector.get_table_names(schema="public")
    print(f"Tables in public: {tables}")

    if 'alembic_version' in tables:
        with engine.connect() as conn:
            from sqlalchemy import text
            res = conn.execute(text("SELECT version_num FROM alembic_version")).fetchone()
            print(f"Current Alembic Version in DB: {res[0] if res else 'Empty'}")

if __name__ == "__main__":
    check_tables()
