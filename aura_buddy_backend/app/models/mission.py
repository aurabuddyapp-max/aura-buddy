import enum
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base





class MissionType(str, enum.Enum):
    DAILY = "DAILY"
    WEEKLY = "WEEKLY"
    MILESTONE = "MILESTONE"


class MissionStatus(str, enum.Enum):
    PENDING = "PENDING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"


class Mission(Base):
    __tablename__ = "missions"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(100), nullable=False)
    description = Column(String(500), nullable=False)
    type = Column(Enum(MissionType, native_enum=False), nullable=False)
    aura_reward = Column(Integer, default=0, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    user_assignments = relationship("UserMission", back_populates="mission")

    def __repr__(self):
        return f"<Mission {self.title} type={self.type.value}>"


class UserMission(Base):
    __tablename__ = "user_missions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    mission_id = Column(Integer, ForeignKey("missions.id"), nullable=False, index=True)
    status = Column(Enum(MissionStatus, native_enum=False), default=MissionStatus.PENDING, nullable=False)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="assigned_missions")
    mission = relationship("Mission", back_populates="user_assignments")

    def __repr__(self):
        return f"<UserMission user={self.user_id} mission={self.mission_id} status={self.status.value}>"
