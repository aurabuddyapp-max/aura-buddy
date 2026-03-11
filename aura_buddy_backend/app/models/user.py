import enum
import uuid
from sqlalchemy import Column, Integer, String, Boolean, DateTime, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    username = Column(String(30), unique=True, nullable=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    avatar_url = Column(String(500), nullable=True)
    aura_points = Column(Integer, default=0, nullable=False)
    level = Column(Integer, default=1, nullable=False)
    current_streak = Column(Integer, default=0, nullable=False)
    last_streak_claimed_at = Column(DateTime(timezone=True), nullable=True)
    is_premium = Column(Boolean, default=False, nullable=False)
    premium_expires_at = Column(DateTime(timezone=True), nullable=True)
    bio = Column(String(200), nullable=True, default="Aura enthusiast ✨")
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    posts = relationship("Post", back_populates="author", lazy="dynamic")
    assigned_missions = relationship("UserMission", back_populates="user", lazy="dynamic")
    votes = relationship("Vote", back_populates="user", lazy="dynamic")
    sent_transactions = relationship(
        "AuraTransaction",
        foreign_keys="AuraTransaction.from_user_id",
        back_populates="from_user",
        lazy="dynamic",
    )
    received_transactions = relationship(
        "AuraTransaction",
        foreign_keys="AuraTransaction.to_user_id",
        back_populates="to_user",
        lazy="dynamic",
    )

    def __repr__(self):
        return f"<User {self.username} | Aura: {self.aura_points}>"
