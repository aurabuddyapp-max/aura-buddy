import random
from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.mission import Mission, UserMission, MissionType, MissionStatus
from app.models.user import User


class MissionService:
    @staticmethod
    def assign_daily_missions(db: Session, user: User):
        """Assign 3 random daily missions if not already assigned today."""
        now = datetime.now(timezone.utc)
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        
        # Check if already assigned today
        existing = db.query(UserMission).join(Mission).filter(
            UserMission.user_id == user.id,
            Mission.type == MissionType.DAILY,
            UserMission.created_at >= today_start
        ).all()
        
        if len(existing) >= 3:
            return existing
        
        # Get available daily missions
        available_missions = db.query(Mission).filter(
            Mission.type == MissionType.DAILY
        ).all()
        
        if not available_missions:
            return []
            
        # Exclude those already assigned today (in case of partial assignment)
        assigned_ids = [m.mission_id for m in existing]
        remaining_missions = [m for m in available_missions if m.id not in assigned_ids]
        
        # Pick 3 random missions
        to_assign = random.sample(remaining_missions, min(len(remaining_missions), 3 - len(existing)))
        
        new_assignments = []
        for m in to_assign:
            um = UserMission(
                user_id=user.id,
                mission_id=m.id,
                status=MissionStatus.PENDING
            )
            db.add(um)
            new_assignments.append(um)
        
        db.commit()
        return existing + new_assignments

    @staticmethod
    def assign_weekly_missions(db: Session, user: User):
        """Assign 5 random weekly missions if not already assigned this week."""
        now = datetime.now(timezone.utc)
        # Week starts on Monday
        monday_start = (now - timedelta(days=now.weekday())).replace(hour=0, minute=0, second=0, microsecond=0)
        
        existing = db.query(UserMission).join(Mission).filter(
            UserMission.user_id == user.id,
            Mission.type == MissionType.WEEKLY,
            UserMission.created_at >= monday_start
        ).all()
        
        if len(existing) >= 5:
            return existing
            
        available_missions = db.query(Mission).filter(
            Mission.type == MissionType.WEEKLY
        ).all()
        
        if not available_missions:
            return []
            
        assigned_ids = [m.mission_id for m in existing]
        remaining_missions = [m for m in available_missions if m.id not in assigned_ids]
        
        to_assign = random.sample(remaining_missions, min(len(remaining_missions), 5 - len(existing)))
        
        new_assignments = []
        for m in to_assign:
            nm = UserMission(
                user_id=user.id,
                mission_id=m.id,
                status=MissionStatus.PENDING
            )
            db.add(nm)
            new_assignments.append(nm)
            
        db.commit()
        return existing + new_assignments

    @staticmethod
    def get_milestones(db: Session, user: User):
        """Get all milestone missions and ensure they are assigned to the user."""
        milestones = db.query(Mission).filter(Mission.type == MissionType.MILESTONE).all()
        
        # Check existing assignments
        existing = db.query(UserMission).filter(
            UserMission.user_id == user.id,
            UserMission.mission_id.in_([m.id for m in milestones])
        ).all()
        
        existing_ids = {um.mission_id for um in existing}
        
        new_assignments = []
        for m in milestones:
            if m.id not in existing_ids:
                um = UserMission(
                    user_id=user.id,
                    mission_id=m.id,
                    status=MissionStatus.PENDING
                )
                db.add(um)
                new_assignments.append(um)
        
        if new_assignments:
            db.commit()
            
        return existing + new_assignments

    @staticmethod
    def complete_mission(db: Session, user: User, user_mission_id: int):
        """Mark a mission as completed and award aura points."""
        from app.models.aura_transaction import AuraTransaction, TransactionType

        um = db.query(UserMission).filter(UserMission.id == user_mission_id, UserMission.user_id == user.id).first()
        if not um or um.status != MissionStatus.PENDING:
            return None
            
        um.status = MissionStatus.COMPLETED
        um.completed_at = datetime.now(timezone.utc)
        
        # Award Aura
        reward = um.mission.aura_reward
        user.aura_points += reward
        
        # Log AuraTransaction
        tx = AuraTransaction(
            to_user_id=user.id,
            amount=reward,
            type=TransactionType.MISSION_REWARD,
            description=f"Reward for completing: {um.mission.title}"
        )
        db.add(tx)
        
        db.commit()
        db.refresh(um)
        return um
