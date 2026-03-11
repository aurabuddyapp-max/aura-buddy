from typing import List
from uuid import UUID
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.models.post import Post
from app.schemas.schemas import PostCreate, PostResponse
from app.utils.auth import get_current_user
from app.services.rate_limiter import RateLimiter

router = APIRouter(prefix="/posts", tags=["Posts"])


@router.post("/", response_model=PostResponse, status_code=201)
def create_post(
    data: PostCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new post. Enforces daily post limit server-side."""
    if not current_user.username:
        raise HTTPException(status_code=400, detail="Set a username before posting")

    # Enforce rate limit
    RateLimiter.check_daily_post_limit(db, current_user)

    post = Post(
        user_id=current_user.id,
        caption=data.caption,
        image_url=data.image_url,
        hashtags=",".join(data.hashtags) if data.hashtags else "",
        expires_at=datetime.now(timezone.utc) + timedelta(days=14)
    )
    db.add(post)
    db.commit()
    db.refresh(post)

    return PostResponse(
        id=post.id,
        user_id=post.user_id,
        caption=post.caption,
        image_url=post.image_url,
        aura_score=post.aura_score,
        created_at=post.created_at,
        expires_at=post.expires_at,
        author_username=current_user.username,
        hashtags=post.hashtags.split(",") if post.hashtags else [],
    )


@router.get("/feed", response_model=List[PostResponse])
def get_feed(
    limit: int = 20,
    offset: int = 0,
    db: Session = Depends(get_db),
):
    """Get the global post feed, ordered by newest first."""
    now = datetime.now(timezone.utc)
    posts = (
        db.query(Post)
        .join(User, Post.user_id == User.id)
        .filter(Post.expires_at > now)  # Only show non-expired posts
        .order_by(Post.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    return [
        PostResponse(
            id=p.id,
            user_id=p.user_id,
            caption=p.caption,
            image_url=p.image_url,
            aura_score=p.aura_score,
            created_at=p.created_at,
            expires_at=p.expires_at,
            author_username=p.author.username if p.author else None,
            hashtags=p.hashtags.split(",") if p.hashtags else [],
        )
        for p in posts
    ]


@router.get("/{post_id}", response_model=PostResponse)
def get_post(post_id: UUID, db: Session = Depends(get_db)):
    """Get a single post by ID."""
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")

    return PostResponse(
        id=post.id,
        user_id=post.user_id,
        caption=post.caption,
        image_url=post.image_url,
        aura_score=post.aura_score,
        created_at=post.created_at,
        expires_at=post.expires_at,
        author_username=post.author.username if post.author else None,
        hashtags=post.hashtags.split(",") if post.hashtags else [],
    )


@router.get("/remaining/count")
def get_remaining_posts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get the number of remaining posts for today."""
    remaining = RateLimiter.get_remaining_posts(db, current_user)
    return {"remaining_posts": remaining}


@router.get("/hashtags/search")
def search_hashtags(q: str = "", db: Session = Depends(get_db)):
    """Search for hashtags and return unique tags with post counts."""
    from sqlalchemy import func as sql_func
    
    # This is a bit expensive for a real production app without a dedicated Hashtag table,
    # but for this prototype it works.
    query = db.query(Post.hashtags).filter(Post.hashtags.isnot(None))
    if q:
        query = query.filter(Post.hashtags.ilike(f"%{q}%"))
    
    all_hashtags_raw = query.all()
    
    tag_counts = {}
    for (tags_str,) in all_hashtags_raw:
        if not tags_str:
            continue
        tags = tags_str.split(",")
        for t in tags:
            t = t.strip()
            if not t:
                continue
            if q.lower() in t.lower() or not q:
                tag_counts[t] = tag_counts.get(t, 0) + 1
    
    # Convert to list of dicts and sort by count desc
    results = [
        {"hashtag": tag, "post_count": count}
        for tag, count in tag_counts.items()
    ]
    results.sort(key=lambda x: x["post_count"], reverse=True)
    
    return results[:20]


@router.get("/hashtags/{hashtag}", response_model=List[PostResponse])
def get_posts_by_hashtag(
    hashtag: str,
    limit: int = 20,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    """Get posts filtered by hashtag."""
    posts = (
        db.query(Post)
        .filter(Post.hashtags.ilike(f"%{hashtag}%"))
        .order_by(Post.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    
    return [
        PostResponse(
            id=p.id,
            user_id=p.user_id,
            caption=p.caption,
            image_url=p.image_url,
            aura_score=p.aura_score,
            created_at=p.created_at,
            expires_at=p.expires_at,
            author_username=p.author.username if p.author else None,
            hashtags=p.hashtags.split(",") if p.hashtags else [],
        )
        for p in posts
    ]
