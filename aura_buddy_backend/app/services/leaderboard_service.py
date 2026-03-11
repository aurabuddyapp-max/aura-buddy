from sqlalchemy.orm import Session
from sqlalchemy import desc
from app.models.user import User
from app.models.aura_transaction import AuraTransaction, TransactionType


class LeaderboardService:
    @staticmethod
    def get_weekly_leaderboard(db: Session, limit: int = 100):
        """Get the top users by aura points."""
        return db.query(User).order_by(desc(User.aura_points)).limit(limit).all()

    @staticmethod
    def award_weekly_leaderboard_prizes(db: Session):
        """Award aura points to top 10 users for the week."""
        top_users = db.query(User).order_by(desc(User.aura_points)).limit(10).all()
        
        rewards = {
            0: 500,  # Rank 1
            1: 300,  # Rank 2
            2: 200,  # Rank 3
        }
        # Rank 4-10 get 100
        
        assigned_rewards = []
        for i, user in enumerate(top_users):
            amount = rewards.get(i, 100)
            user.aura_points += amount
            
            # Create transaction record
            tx = AuraTransaction(
                to_user_id=user.id,
                amount=amount,
                type=TransactionType.PREMIUM_BONUS  # Or add a specific WEEKLY_RANK_REWARD
            )
            db.add(tx)
            assigned_rewards.append({"user_id": user.id, "rank": i + 1, "reward": amount})
            
        db.commit()
        return assigned_rewards
