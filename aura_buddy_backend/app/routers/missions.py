from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.models.mission import Mission, MissionType, MissionStatus
from app.schemas.schemas import MissionResponse
from app.utils.auth import get_current_user

from app.services.mission_service import MissionService
from app.schemas.schemas import MessageResponse, UserMissionResponse

router = APIRouter(prefix="/missions", tags=["Missions"])


@router.get("/daily", response_model=List[UserMissionResponse])
def get_daily_missions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get the user's random daily missions. Assures 3 missions are assigned."""
    missions = MissionService.assign_daily_missions(db, current_user)
    return missions


@router.get("/weekly", response_model=List[UserMissionResponse])
def get_weekly_missions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get the user's random weekly missions. Assures 5 missions are assigned."""
    missions = MissionService.assign_weekly_missions(db, current_user)
    return missions


@router.get("/milestones", response_model=List[UserMissionResponse])
def get_milestones(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get the user's milestone missions."""
    return MissionService.get_milestones(db, current_user)


@router.post("/{user_mission_id}/complete", response_model=UserMissionResponse)
def complete_mission(
    user_mission_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mark a mission as completed and claim rewards."""
    um = MissionService.complete_mission(db, current_user, user_mission_id)
    if not um:
        raise HTTPException(status_code=400, detail="Invalid mission or already completed")
    return um
