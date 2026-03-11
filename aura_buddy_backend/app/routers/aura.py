from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas.schemas import AuraTransfer, HaterTax, AuraTransactionResponse
from app.utils.auth import get_current_user
from app.services.aura_service import AuraService
from app.services.rate_limiter import RateLimiter

router = APIRouter(prefix="/aura", tags=["Aura Economy"])


@router.post("/transfer", response_model=AuraTransactionResponse)
def transfer_aura(
    data: AuraTransfer,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Award Aura to another user's post. Deducts from giver, adds to receiver."""
    txn = AuraService.transfer_aura(db, current_user, data.post_id, data.amount)
    return AuraTransactionResponse(
        id=txn.id,
        from_user_id=txn.from_user_id,
        to_user_id=txn.to_user_id,
        post_id=txn.post_id,
        amount=txn.amount,
        transaction_type=txn.transaction_type.value,
        created_at=txn.created_at,
    )


@router.post("/hater-tax", response_model=AuraTransactionResponse)
def hater_tax(
    data: HaterTax,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Apply hater tax: post loses X, hater loses 2X from balance."""
    txn = AuraService.hater_tax(db, current_user, data.post_id, data.amount)
    return AuraTransactionResponse(
        id=txn.id,
        from_user_id=txn.from_user_id,
        to_user_id=txn.to_user_id,
        post_id=txn.post_id,
        amount=txn.amount,
        transaction_type=txn.transaction_type.value,
        created_at=txn.created_at,
    )


@router.post("/claim-ad-reward", response_model=AuraTransactionResponse)
def claim_ad_reward(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Claim ad reward (+100 Aura). Max 2 per 12-hour window."""
    txn = AuraService.claim_ad_reward(db, current_user)
    return AuraTransactionResponse(
        id=txn.id,
        from_user_id=txn.from_user_id,
        to_user_id=txn.to_user_id,
        post_id=txn.post_id,
        amount=txn.amount,
        transaction_type=txn.transaction_type.value,
        created_at=txn.created_at,
    )


@router.get("/remaining-ad-claims")
def get_remaining_ad_claims(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get remaining ad reward claims in the current 12-hour window."""
    remaining = RateLimiter.get_remaining_ad_claims(db, current_user)
    return {"remaining_ad_claims": remaining}


@router.post("/claim-mood-reward", response_model=AuraTransactionResponse)
def claim_mood_reward(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Claim daily mood reward (+10 Aura). Max 1 claim per 12-hour window."""
    txn = AuraService.grant_mood_reward(db, current_user)
    return AuraTransactionResponse(
        id=txn.id,
        from_user_id=txn.from_user_id,
        to_user_id=txn.to_user_id,
        post_id=txn.post_id,
        amount=txn.amount,
        transaction_type=txn.transaction_type.value,
        created_at=txn.created_at,
    )


@router.get("/verify-integrity")
def verify_integrity(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Check if the user's aura points match the sum of their transactions."""
    from sqlalchemy import func as sql_func
    from app.models.aura_transaction import AuraTransaction

    received = db.query(sql_func.sum(AuraTransaction.amount)).filter(
        AuraTransaction.to_user_id == current_user.id
    ).scalar() or 0

    sent = db.query(sql_func.sum(AuraTransaction.amount)).filter(
        AuraTransaction.from_user_id == current_user.id
    ).scalar() or 0

    calculated_balance = received - sent
    is_valid = calculated_balance == current_user.aura_points

    return {
        "is_valid": is_valid,
        "recorded_balance": current_user.aura_points,
        "calculated_balance": calculated_balance,
        "discrepancy": current_user.aura_points - calculated_balance
    }


@router.get("/leaderboards")
def get_leaderboards(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get top users for various Leaderboard categories.
    """
    from app.services.leaderboard_service import LeaderboardService
    
    global_users = LeaderboardService.get_weekly_leaderboard(db, 50)
    global_aura = [
        {"username": u.username or "Anonymous", "aura": u.aura_points, "premium": u.is_premium, "id": str(u.id)}
        for u in global_users
    ]

    return {
        "globalAura": global_aura,
        "weeklyAura": global_aura[:10], # For now, same as global but top 10
        "topJury": [],
        "topCreators": []
    }


@router.get("/history")
def get_aura_history(
    limit: int = 50,
    offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get the transaction history for the current user."""
    from app.models.aura_transaction import AuraTransaction
    from sqlalchemy import or_

    records = db.query(AuraTransaction).filter(
        or_(
            AuraTransaction.from_user_id == current_user.id,
            AuraTransaction.to_user_id == current_user.id
        )
    ).order_by(AuraTransaction.created_at.desc()).limit(limit).offset(offset).all()

    history = []
    for txn in records:
        is_receiver = txn.to_user_id == current_user.id
        # Calculate relative impact on the user
        amount = txn.amount if is_receiver else -txn.amount
        
        title = "Aura Transfer"
        emoji = "💸"
        desc = "Aura transaction"

        ttype = txn.type.value if txn.type else ""

        if ttype == "POST_REWARD" or ttype == "TRANSFER":
            title = "Post Loved" if is_receiver else "Spread the Love"
            emoji = "✨"
            desc = "Someone sent aura to your post" if is_receiver else "You tipped a post"
        elif ttype == "MISSION_REWARD":
            title = "Mission Reward"
            emoji = "🎯"
            desc = "Reward for completion"
        elif ttype == "JURY_REWARD":
            title = "Jury Duty"
            emoji = "⚖️"
            desc = "Earned for voting"
        elif ttype == "MOOD_REWARD":
            title = "Daily Mood Logging"
            emoji = "😊"
            desc = "Daily check-in"
        elif ttype == "HATER_TAX":
            title = "Hater Tax"
            emoji = "💀"
            desc = "Penalty applied"
        elif ttype == "STREAK_REWARD":
            title = "Daily Streak"
            emoji = "🔥"
            desc = f"Day {current_user.current_streak} reward"

        history.append({
            "id": str(txn.id),
            "title": title,
            "description": desc,
            "amount": amount,
            "emoji": emoji,
            "date": txn.created_at.isoformat()
        })

    return history


@router.post("/claim-daily-streak", response_model=AuraTransactionResponse)
def claim_daily_streak(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Claim daily login streak reward."""
    txn = AuraService.claim_daily_streak_reward(db, current_user)
    return AuraTransactionResponse(
        id=txn.id,
        from_user_id=txn.from_user_id,
        to_user_id=txn.to_user_id,
        post_id=txn.post_id,
        amount=txn.amount,
        transaction_type=txn.transaction_type.value,
        created_at=txn.created_at,
    )
