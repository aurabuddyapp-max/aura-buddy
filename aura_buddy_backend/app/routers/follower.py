from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from uuid import UUID

from app.database import get_db
from app.models.user import User
from app.models.follower import Follower
from app.schemas.schemas import MessageResponse, PublicUserResponse
from app.utils.auth import get_current_user

router = APIRouter(prefix="/followers", tags=["Followers"])


@router.post("/follow/{username}", response_model=MessageResponse)
def follow_user(
    username: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Follow a user by username."""
    target_user = db.query(User).filter(User.username == username).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if target_user.id == current_user.id:
        raise HTTPException(status_code=400, detail="You cannot follow yourself")

    existing = db.query(Follower).filter(
        Follower.follower_id == current_user.id,
        Follower.following_id == target_user.id
    ).first()
    
    if existing:
        return {"message": f"Already following @{username}"}

    new_follow = Follower(follower_id=current_user.id, following_id=target_user.id)
    db.add(new_follow)
    db.commit()
    
    return {"message": f"Successfully followed @{username}"}


@router.delete("/unfollow/{username}", response_model=MessageResponse)
def unfollow_user(
    username: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Unfollow a user by username."""
    target_user = db.query(User).filter(User.username == username).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")

    follow = db.query(Follower).filter(
        Follower.follower_id == current_user.id,
        Follower.following_id == target_user.id
    ).first()
    
    if not follow:
        return {"message": f"Not following @{username}"}

    db.delete(follow)
    db.commit()
    
    return {"message": f"Successfully unfollowed @{username}"}


@router.get("/following", response_model=list[PublicUserResponse])
def get_following(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get list of users the current user follows."""
    from app.models.post import Post
    
    following_rels = db.query(Follower).filter(Follower.follower_id == current_user.id).all()
    following_ids = [f.following_id for f in following_rels]
    
    users = db.query(User).filter(User.id.in_(following_ids)).all()
    
    # We need to calculate counts for each user
    results = []
    for u in users:
        p_count = db.query(Post).filter(Post.user_id == u.id).count()
        f_count = db.query(Follower).filter(Follower.following_id == u.id).count()
        fg_count = db.query(Follower).filter(Follower.follower_id == u.id).count()
        
        results.append({
            "id": u.id,
            "username": u.username,
            "avatar_url": u.avatar_url,
            "aura_points": u.aura_points,
            "level": u.level,
            "current_streak": u.current_streak,
            "is_premium": u.is_premium,
            "created_at": u.created_at,
            "posts_count": p_count,
            "followers_count": f_count,
            "following_count": fg_count
        })
        
    return results


@router.get("/followers", response_model=list[PublicUserResponse])
def get_followers(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get list of users following the current user."""
    from app.models.post import Post

    follower_rels = db.query(Follower).filter(Follower.following_id == current_user.id).all()
    follower_ids = [f.follower_id for f in follower_rels]
    
    users = db.query(User).filter(User.id.in_(follower_ids)).all()
    
    results = []
    for u in users:
        p_count = db.query(Post).filter(Post.user_id == u.id).count()
        f_count = db.query(Follower).filter(Follower.following_id == u.id).count()
        fg_count = db.query(Follower).filter(Follower.follower_id == u.id).count()
        
        results.append({
            "id": u.id,
            "username": u.username,
            "avatar_url": u.avatar_url,
            "aura_points": u.aura_points,
            "level": u.level,
            "current_streak": u.current_streak,
            "is_premium": u.is_premium,
            "created_at": u.created_at,
            "posts_count": p_count,
            "followers_count": f_count,
            "following_count": fg_count
        })
        
    return results
