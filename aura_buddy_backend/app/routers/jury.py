from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas.schemas import VoteCreate, VoteResponse
from app.utils.auth import get_current_user
from app.services.jury_service import JuryService

router = APIRouter(prefix="/jury", tags=["Jury"])


@router.post("/vote", response_model=VoteResponse, status_code=201)
def cast_vote(
    data: VoteCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Cast an AURA or HATE vote on a post."""
    # Check if already voted
    from app.models.vote import Vote, VoteType
    existing = db.query(Vote).filter(
        Vote.user_id == current_user.id,
        Vote.post_id == data.post_id
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail="You have already voted on this post")

    # TODO: Use a service for atomic vote + aura update
    vote = Vote(
        user_id=current_user.id,
        post_id=data.post_id,
        vote_type=VoteType(data.vote_type)
    )
    db.add(vote)
    
    # Simple aura score update
    from app.models.post import Post
    post = db.query(Post).filter(Post.id == data.post_id).first()
    if post:
        if vote.vote_type == VoteType.AURA:
            post.aura_score += 1
        else:
            post.aura_score -= 1
            
    db.commit()
    db.refresh(vote)
    
    return VoteResponse(
        id=vote.id,
        user_id=vote.user_id,
        post_id=vote.post_id,
        vote_type=vote.vote_type.value,
        created_at=vote.created_at,
    )
