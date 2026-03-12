
import uuid
from app.database import SessionLocal, engine
from app.models.user import User
from app.models.post import Post
from datetime import datetime, timedelta

def create_test_data():
    db = SessionLocal()
    try:
        # 1. Create 5 Bot Users
        bots = [
            {"username": "aura_king", "email": "king@aura.bot", "avatar": "https://api.dicebear.com/7.x/avataaars/svg?seed=king"},
            {"username": "sky_high", "email": "sky@aura.bot", "avatar": "https://api.dicebear.com/7.x/avataaars/svg?seed=sky"},
            {"username": "vibe_checker", "email": "vibe@aura.bot", "avatar": "https://api.dicebear.com/7.x/avataaars/svg?seed=vibe"},
            {"username": "glow_up", "email": "glow@aura.bot", "avatar": "https://api.dicebear.com/7.x/avataaars/svg?seed=glow"},
            {"username": "positive_paul", "email": "paul@aura.bot", "avatar": "https://api.dicebear.com/7.x/avataaars/svg?seed=paul"},
        ]

        bot_models = []
        for bot_data in bots:
            # Check if bot exists
            bot = db.query(User).filter(User.username == bot_data["username"]).first()
            if not bot:
                bot = User(
                    id=uuid.uuid4(),
                    username=bot_data["username"],
                    email=bot_data["email"],
                    avatar_url=bot_data["avatar"],
                    aura_points=2500,
                    bio=f"Official Aura Buddy test bot: {bot_data['username']} 🚀"
                )
                db.add(bot)
                db.commit()
                db.refresh(bot)
                print(f"Created bot: {bot.username}")
            bot_models.append(bot)

        # 2. Add some posts for bots
        captions = [
            "Just reached Level 5! Thanks for the aura guys! 👑",
            "Starting my morning meditation flow. So peaceful. 🧘‍♂️",
            "Lunch prep for the week! Keeping the vibes healthy. 🥗",
            "Finally hit a 7-day streak! Consistency is key. 🔥",
            "Sending positive energy to everyone today! ✨"
        ]

        for bot in bot_models:
            post_count = db.query(Post).filter(Post.user_id == bot.id).count()
            if post_count == 0:
                for i in range(3):
                    post = Post(
                        id=uuid.uuid4(),
                        user_id=bot.id,
                        caption=captions[(bot_models.index(bot) + i) % len(captions)],
                        aura_score=100 + (i * 50),
                        created_at=datetime.utcnow() - timedelta(days=i)
                    )
                    db.add(post)
                db.commit()
                print(f"Added posts for {bot.username}")

        # 3. Give the current user 5000 Aura
        # We'll look for the most recent NON-BOT user
        user = db.query(User).filter(~User.email.contains("@aura.bot")).order_by(User.created_at.desc()).first()
        if user:
            user.aura_points += 5000
            db.commit()
            print(f"Gave 5000 Aura to user: {user.username or user.email}")
        else:
            print("No real user found to give Aura to.")

    finally:
        db.close()

if __name__ == "__main__":
    create_test_data()
