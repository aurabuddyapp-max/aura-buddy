import uuid
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base


class AdsReward(Base):
    __tablename__ = "ads_rewards"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    reward_type = Column(String(50), default="AURA", nullable=False)
    aura_reward = Column(Integer, default=100, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    user = relationship("User", backref="ads_rewards")

    def __repr__(self):
        return f"<AdsReward user={self.user_id} amount={self.aura_reward}>"
