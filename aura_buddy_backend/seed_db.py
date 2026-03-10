import os
from sqlalchemy.orm import Session
from app.database import SessionLocal, engine
from app.models import User, Post, AuraTransaction, Mission, Vote

def seed_test_accounts():
    db = SessionLocal()
    try:
        # 1. Clean up ALL existing data
        print("Wiping existing data...")
        db.query(Vote).delete()
        db.query(Mission).delete()
        db.query(AuraTransaction).delete()
        db.query(Post).delete()
        db.query(User).delete()
        db.commit()

        # 2. Create 5 persistent test accounts
        test_accounts = [
            {"uid": "dev_cred_test1_aurabuddy_app", "username": "max_tester", "aura": 5000},
            {"uid": "dev_cred_test2_aurabuddy_app", "username": "sarah_j", "aura": 250},
            {"uid": "dev_cred_test3_aurabuddy_app", "username": "alex_dev", "aura": 1100},
            {"uid": "dev_cred_test4_aurabuddy_app", "username": "jordan_x", "aura": 50},
            {"uid": "dev_cred_test5_aurabuddy_app", "username": "taylor_swift", "aura": 9000},
        ]

        print("Creating 5 stable test accounts...")
        for acc in test_accounts:
            user = User(
                firebase_uid=acc['uid'],
                username=acc['username'],
                aura_balance=acc['aura']
            )
            db.add(user)
        
        db.commit()
        print("SUCCESS! Database seeded with 5 test accounts.")
        print("\n--- TEST LOGIN CREDENTIALS ---")
        print("You can log in to the app with any of the following emails (password: anything >6 chars):")
        print("1. test1@aurabuddy.app")
        print("2. test2@aurabuddy.app")
        print("3. test3@aurabuddy.app")
        print("4. test4@aurabuddy.app")
        print("5. test5@aurabuddy.app")

    except Exception as e:
        print(f"Error seeding DB: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_test_accounts()
