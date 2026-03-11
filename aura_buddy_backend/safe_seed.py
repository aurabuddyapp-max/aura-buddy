import random
import uuid
from datetime import datetime, timedelta, timezone
from sqlalchemy import create_engine
from app.database import Base, SessionLocal
from app.models.mission import Mission, MissionType
from app.models.achievement import Achievement
from app.models.post import Post
from app.models.user import User
from app.config import settings

def seed_missions(db):
    print("Seeding missions...")
    daily_missions = [
        ("Good Morning Aura", "Post a picture of your morning routine", 50),
        ("Healthy Fuel", "Share what you're eating for breakfast!", 40),
        ("Active Aura", "Show us 10 minutes of light exercise", 60),
        ("Fit Check", "Post your outfit for today — serve that aura!", 70, ["#fitcheck", "#ootd"]),
        ("Hydration Pro", "Post a photo of your full water bottle", 30),
        ("Sunshine Moment", "Take a photo outdoors in the sunlight", 50),
        ("Study Grind", "Show us your study/work setup for today", 45, ["#study", "#productivity"]),
        ("Random Act", "Do something nice and tell us about it", 100),
        ("Bookworm", "Read 5 pages of a book and share the cover", 50, ["#reading"]),
        ("Meditation", "Spend 2 minutes breathing and share a calm view", 40),
    ]

    weekly_missions = [
        ("Gym Warrior", "Complete 3 workout sessions this week", 300, ["#gym", "#workout"]),
        ("Social Butterfly", "Follow 5 new people this week", 150),
        ("Aura Collector", "Receive a total of 500 Aura from posts", 500),
        ("Great Judge", "Vote on 20 posts in the feed", 200),
        ("Content King", "Create 7 posts this week", 400),
    ]

    milestones = [
        ("First Aura", "Complete your first ever mission", 100),
        ("Aura Newbie", "Reach 1000 total Aura points", 200),
        ("Aura Veteran", "Reach 10,000 total Aura points", 1000),
        ("Centurion", "Post 100 times", 500),
    ]

    for title, desc, reward, *extra in daily_missions:
        existing = db.query(Mission).filter(Mission.title == title).first()
        if not existing:
            db.add(Mission(title=title, description=desc, type=MissionType.DAILY, aura_reward=reward))
    
    for title, desc, reward, *extra in weekly_missions:
        existing = db.query(Mission).filter(Mission.title == title).first()
        if not existing:
            db.add(Mission(title=title, description=desc, type=MissionType.WEEKLY, aura_reward=reward))
        
    for title, desc, reward in milestones:
        existing = db.query(Mission).filter(Mission.title == title).first()
        if not existing:
            db.add(Mission(title=title, description=desc, type=MissionType.MILESTONE, aura_reward=reward))

    db.commit()

def seed_achievements(db):
    print("Seeding achievements...")
    achievements = [
        ("Genesis", "Be one of the first 100 users", 500),
        ("Top G", "Reach Rank 1 on the weekly leaderboard", 1000),
        ("Viral", "Have a post reach 1000 Aura score", 500),
        ("Hater Slayer", "Lose more than 100 aura to taxes but keep going", 200),
    ]
    
    for title, desc, reward in achievements:
        existing = db.query(Achievement).filter(Achievement.title == title).first()
        if not existing:
            db.add(Achievement(title=title, description=desc, aura_reward=reward))
        
    db.commit()

def seed_posts(db):
    print("Seeding posts...")
    # Get a user (or create a system user)
    system_user = db.query(User).filter(User.username == "aura_buddy").first()
    if not system_user:
        system_user = User(
            id=uuid.uuid4(),
            username="aura_buddy",
            email="system@aurabuddy.app",
            aura_points=1000000,
            bio="The official Aura Buddy system account. Spread the positivity! ✨"
        )
        db.add(system_user)
        db.commit()

    posts = [
        ("Welcome to Aura Buddy! 🌟", ["#welcome", "#aurabuddy", "#positivity"]),
        ("Morning meditation flow. So peaceful. 🧘‍♂️", ["#meditation", "#peace", "#aura"]),
        ("Tonight's fit check! Rate it? 🔥", ["#fitcheck", "#fashion", "#drip"]),
        ("Lunch prep for the week! Healthy vibes. 🥗", ["#healthy", "#mealprep"]),
        ("Finally reached Level 5! Thanks for the aura guys! 👑", ["#levelingup", "#success"]),
    ]

    for caption, tags in posts:
        existing = db.query(Post).filter(Post.caption == caption).first()
        if not existing:
            db.add(Post(
                user_id=system_user.id,
                caption=caption,
                hashtags=",".join(tags),
                aura_score=random.randint(50, 500),
                expires_at=datetime.now(timezone.utc) + timedelta(days=14)
            ))
    db.commit()

if __name__ == "__main__":
    db = SessionLocal()
    try:
        seed_missions(db)
        seed_achievements(db)
        seed_posts(db)
        print("Done!")
    finally:
        db.close()
