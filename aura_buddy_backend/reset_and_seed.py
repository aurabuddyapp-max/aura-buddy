import random
from sqlalchemy import create_engine
from app.database import Base, SessionLocal
from app.models.mission import Mission, MissionType
from app.models.achievement import Achievement
from app.config import settings

def reset_db():
    engine = create_engine(settings.DATABASE_URL)
    print("Dropping all tables...")
    Base.metadata.drop_all(engine)
    print("Creating all tables...")
    Base.metadata.create_all(engine)

def seed_missions(db):
    print("Seeding missions...")
    daily_missions = [
        ("Good Morning Aura", "Post a picture of your morning routine", 50),
        ("Healthy Fuel", "Share what you're eating for breakfast!", 40),
        ("Active Aura", "Show us 10 minutes of light exercise", 60),
        ("Fit Check", "Post your outfit for today — serve that aura!", 70),
        ("Hydration Pro", "Post a photo of your full water bottle", 30),
        ("Sunshine Moment", "Take a photo outdoors in the sunlight", 50),
        ("Study Grind", "Show us your study/work setup for today", 45),
        ("Random Act", "Do something nice and tell us about it", 100),
        ("Bookworm", "Read 5 pages of a book and share the cover", 50),
        ("Meditation", "Spend 2 minutes breathing and share a calm view", 40),
    ]
    
    # Expand to ~30 daily missions
    for i in range(20):
        daily_missions.append((f"Daily Task {i+11}", f"Description for daily task {i+11}", 50 + random.randint(-10, 20)))

    weekly_missions = [
        ("Gym Warrior", "Complete 3 workout sessions this week", 300),
        ("Social Butterfly", "Follow 5 new people this week", 150),
        ("Aura Collector", "Receive a total of 500 Aura from posts", 500),
        ("Great Judge", "Vote on 20 posts in the feed", 200),
        ("Content King", "Create 7 posts this week", 400),
    ]
    # Expand to ~20 weekly missions
    for i in range(15):
        weekly_missions.append((f"Weekly Goal {i+6}", f"Description for weekly goal {i+6}", 250 + random.randint(-50, 100)))

    milestones = [
        ("First Aura", "Complete your first ever mission", 100),
        ("Aura Newbie", "Reach 1000 total Aura points", 200),
        ("Aura Veteran", "Reach 10,000 total Aura points", 1000),
        ("Centurion", "Post 100 times", 500),
    ]

    objects = []
    for title, desc, reward in daily_missions:
        objects.append(Mission(title=title, description=desc, type=MissionType.DAILY, aura_reward=reward))
    
    for title, desc, reward in weekly_missions:
        objects.append(Mission(title=title, description=desc, type=MissionType.WEEKLY, aura_reward=reward))
        
    for title, desc, reward in milestones:
        objects.append(Mission(title=title, description=desc, type=MissionType.MILESTONE, aura_reward=reward))

    db.add_all(objects)
    db.commit()
    print(f"Seeded {len(objects)} missions.")

def seed_achievements(db):
    print("Seeding achievements...")
    achievements = [
        ("Genesis", "Be one of the first 100 users", 500),
        ("Top G", "Reach Rank 1 on the weekly leaderboard", 1000),
        ("Viral", "Have a post reach 1000 Aura score", 500),
        ("Hater Slayer", "Lose more than 100 aura to taxes but keep going", 200),
    ]
    
    objects = []
    for title, desc, reward in achievements:
        objects.append(Achievement(title=title, description=desc, aura_reward=reward))
        
    db.add_all(objects)
    db.commit()
    print(f"Seeded {len(objects)} achievements.")

if __name__ == "__main__":
    reset_db()
    db = SessionLocal()
    try:
        seed_missions(db)
        seed_achievements(db)
    finally:
        db.close()
    print("Done!")
