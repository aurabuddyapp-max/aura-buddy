from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas.schemas import UserResponse, UserUpdate, PublicUserResponse
from app.utils.auth import verify_supabase_token, get_current_user, security

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/login", response_model=UserResponse)
def login(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    """
    Verify Supabase JWT. Create user if not exists.
    """
    token = credentials.credentials
    claims = verify_supabase_token(token)
    user_id = claims["sub"]
    email = claims.get("email")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        # Create user with Supabase ID and email
        user = User(id=user_id, email=email)
        db.add(user)
        db.commit()
        db.refresh(user)

    return user


@router.patch("/profile", response_model=UserResponse)
def update_profile(
    data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Set or update the user's profile info."""
    if data.username:
        existing = db.query(User).filter(User.username == data.username).first()
        if existing and existing.id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Username already taken",
            )
        current_user.username = data.username
    
    if data.avatar_url:
        current_user.avatar_url = data.avatar_url
        
    if data.bio is not None:
        current_user.bio = data.bio

    db.commit()
    db.refresh(current_user)
    return current_user


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get current authenticated user profile with stats."""
    from app.models.post import Post
    from app.models.follower import Follower

    posts_count = db.query(Post).filter(Post.user_id == current_user.id).count()
    followers_count = db.query(Follower).filter(Follower.following_id == current_user.id).count()
    following_count = db.query(Follower).filter(Follower.follower_id == current_user.id).count()

    return UserResponse(
        id=current_user.id,
        username=current_user.username,
        email=current_user.email,
        aura_points=current_user.aura_points,
        level=current_user.level,
        current_streak=current_user.current_streak,
        is_premium=current_user.is_premium,
        created_at=current_user.created_at,
        avatar_url=current_user.avatar_url,
        bio=current_user.bio,
        posts_count=posts_count,
        followers_count=followers_count,
        following_count=following_count
    )


@router.get("/profile/{username}", response_model=PublicUserResponse)
def get_public_profile(username: str, db: Session = Depends(get_db)):
    """Get any user's profile by username."""
    from app.models.post import Post
    from app.models.follower import Follower

    user = db.query(User).filter(User.username == username).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    posts_count = db.query(Post).filter(Post.user_id == user.id).count()
    followers_count = db.query(Follower).filter(Follower.following_id == user.id).count()
    following_count = db.query(Follower).filter(Follower.follower_id == user.id).count()

    # We return PublicUserResponse logic but cast to UserResponse for now if needed, 
    # but I'll change the return type to something that doesn't REQUIRE email if I use PublicUserResponse.
    # Let's fix the response_model.
    return {
        "id": user.id,
        "username": user.username,
        "avatar_url": user.avatar_url,
        "aura_points": user.aura_points,
        "level": user.level,
        "current_streak": user.current_streak,
        "is_premium": user.is_premium,
        "created_at": user.created_at,
        "bio": user.bio,
        "posts_count": posts_count,
        "followers_count": followers_count,
        "following_count": following_count
    }


@router.get("/search", response_model=list[PublicUserResponse])
def search_users(q: str, db: Session = Depends(get_db)):
    """Search for users by username."""
    from app.models.post import Post
    from app.models.follower import Follower

    users = db.query(User).filter(User.username.ilike(f"%{q}%")).limit(20).all()
    
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
            "bio": u.bio,
            "posts_count": p_count,
            "followers_count": f_count,
            "following_count": fg_count
        })
    return results
