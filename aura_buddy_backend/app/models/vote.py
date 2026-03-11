import enum
from sqlalchemy import Column, Integer, DateTime, ForeignKey, Enum, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base


class VoteType(str, enum.Enum):
    AURA = "AURA"
    HATE = "HATE"


class Vote(Base):
    __tablename__ = "votes"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    post_id = Column(UUID(as_uuid=True), ForeignKey("posts.id"), nullable=False, index=True)
    vote_type = Column(Enum(VoteType, native_enum=False), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Enforce one vote per user per post at DB level
    __table_args__ = (
        UniqueConstraint("user_id", "post_id", name="uq_user_post_vote"),
    )

    # Relationships
    user = relationship("User", back_populates="votes")
    post = relationship("Post", backref="votes")

    def __repr__(self):
        return f"<Vote user={self.user_id} post={self.post_id} type={self.vote_type.value}>"
