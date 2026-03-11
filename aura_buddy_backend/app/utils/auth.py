from jose import jwt, JWTError
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.config import settings

security = HTTPBearer()


def verify_supabase_token(token: str) -> dict:
    """Verify a Supabase JWT and return decoded claims."""
    if not settings.SUPABASE_JWT_SECRET:
        # Development mode: trust token as user_id if secret is missing
        # In a real production app, SUPABASE_JWT_SECRET MUST be set
        return {"sub": token, "email": f"{token}@mock.local"}

    try:
        # Supabase uses HS256 for its tokens
        payload = jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            audience="authenticated"
        )
        return payload
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Could not validate credentials: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
) -> User:
    """FastAPI dependency: verify token and return the current User object."""
    token = credentials.credentials
    claims = verify_supabase_token(token)
    user_id = claims.get("sub")
    
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing 'sub' claim",
        )

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        # If user doesn't exist yet, we might want to auto-create them
        # but the router /login handles that. For other endpoints, they must exist.
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found. Please log in first.",
        )
    return user
