from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from uuid import UUID


# --- User Schemas ---
class UserUpdate(BaseModel):
    username: Optional[str] = Field(None, min_length=3, max_length=30, pattern=r"^[a-zA-Z0-9_]+$")
    avatar_url: Optional[str] = None
    bio: Optional[str] = Field(None, max_length=200)


class UserResponse(BaseModel):
    id: UUID
    username: Optional[str] = None
    email: str
    avatar_url: Optional[str] = None
    aura_points: int
    level: int
    current_streak: int
    is_premium: bool
    created_at: datetime
    posts_count: int = 0
    followers_count: int = 0
    following_count: int = 0
    bio: Optional[str] = None

    class Config:
        from_attributes = True


# --- Post Schemas ---
class PostCreate(BaseModel):
    caption: str = Field(..., min_length=1, max_length=1000)
    image_url: Optional[str] = None
    hashtags: Optional[List[str]] = []


class PostResponse(BaseModel):
    id: UUID
    user_id: UUID
    caption: str
    image_url: Optional[str] = None
    aura_score: int
    created_at: datetime
    expires_at: Optional[datetime] = None
    author_username: Optional[str] = None
    hashtags: List[str] = []

    class Config:
        from_attributes = True


# --- Aura Schemas ---
class AuraTransfer(BaseModel):
    post_id: UUID
    amount: int = Field(..., gt=0, le=1000)


class HaterTax(BaseModel):
    post_id: UUID
    amount: int = Field(..., gt=0, le=500)


class AuraTransactionResponse(BaseModel):
    id: int
    from_user_id: Optional[UUID] = None
    to_user_id: Optional[UUID] = None
    post_id: Optional[UUID] = None
    amount: int
    type: str
    created_at: datetime

    class Config:
        from_attributes = True


# --- Mission Schemas ---
class MissionResponse(BaseModel):
    id: int
    title: str
    description: str
    type: str # daily / weekly / milestone
    aura_reward: int

    class Config:
        from_attributes = True


class UserMissionResponse(BaseModel):
    id: int
    user_id: UUID
    mission_id: int
    status: str
    completed_at: Optional[datetime] = None
    mission: MissionResponse

    class Config:
        from_attributes = True


# --- Vote Schemas ---
class VoteCreate(BaseModel):
    post_id: UUID
    vote_type: str = Field(..., pattern=r"^(AURA|HATE)$")


class VoteResponse(BaseModel):
    id: int
    user_id: UUID
    post_id: UUID
    vote_type: str
    created_at: datetime

    class Config:
        from_attributes = True


# --- Follower Schemas ---
class FollowerResponse(BaseModel):
    id: UUID
    follower_id: UUID
    following_id: UUID
    created_at: datetime

    class Config:
        from_attributes = True


# --- Achievement Schemas ---
class AchievementResponse(BaseModel):
    id: int
    title: str
    description: str
    aura_reward: int

    class Config:
        from_attributes = True


class UserAchievementResponse(BaseModel):
    id: int
    user_id: UUID
    achievement_id: int
    unlocked_at: datetime
    achievement: AchievementResponse

    class Config:
        from_attributes = True


# --- Feedback & Ads ---
class FeedbackCreate(BaseModel):
    message: str = Field(..., min_length=1)


class AdsRewardCreate(BaseModel):
    reward_type: str = "AURA"
    aura_reward: int = 100


# --- Generic ---
class PublicUserResponse(BaseModel):
    id: UUID
    username: Optional[str] = None
    avatar_url: Optional[str] = None
    aura_points: int
    level: int
    current_streak: int
    is_premium: bool
    created_at: datetime
    posts_count: int = 0
    followers_count: int = 0
    following_count: int = 0
    bio: Optional[str] = None

    class Config:
        from_attributes = True


class MessageResponse(BaseModel):
    message: str
    detail: Optional[str] = None
