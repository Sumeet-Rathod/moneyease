from datetime import datetime, timezone
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import User, Doubt
from app.schemas.schemas import DoubtAskIn, DoubtAskOut, DoubtHistoryOut
from app.core.deps import get_current_user
from app.services.doubts import solve_user_doubt

router = APIRouter(prefix="/doubts", tags=["Doubt Solver (AI & FAQ)"])

SUGGESTED_CHIPS = [
    "What is SIP (Systematic Investment Plan)?",
    "Is mutual fund investment safe for beginners?",
    "What is ELSS (Equity Linked Savings Scheme)?",
    "SIP vs Fixed Deposit (FD): what is the difference?",
    "What is NAV (Net Asset Value)?",
    "How much of my monthly salary should I invest?",
    "What is KYC and why is it mandatory for mutual funds?",
    "What is Term Insurance and why is it essential?",
    "How are Equity Mutual Funds taxed in India?",
    "What is the Power of Compounding?"
]

@router.get("/suggested", response_model=List[str])
def get_suggested_doubts():
    return SUGGESTED_CHIPS

@router.post("/ask", response_model=DoubtAskOut)
async def ask_doubt(
    data: DoubtAskIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    clean_q = data.question.strip()
    if not clean_q:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Question cannot be empty."
        )

    # Solve doubt via AI or local FAQ engine
    result = await solve_user_doubt(clean_q)

    # Record doubt in DB under customer's profile so executive can review
    doubt_record = Doubt(
        user_id=current_user.id,
        question=result["question"],
        answer=result["answer"],
        source=result["source"],
        topic=result.get("topic", "General"),
        created_at=datetime.now(timezone.utc)
    )
    db.add(doubt_record)
    db.commit()
    db.refresh(doubt_record)

    return DoubtAskOut(
        id=doubt_record.id,
        question=doubt_record.question,
        answer=doubt_record.answer,
        source=doubt_record.source,
        topic=doubt_record.topic,
        compliance_disclaimer=result["compliance_disclaimer"],
        created_at=doubt_record.created_at
    )

@router.get("/history", response_model=List[DoubtHistoryOut])
def get_doubt_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    doubts = (
        db.query(Doubt)
        .filter(Doubt.user_id == current_user.id)
        .order_by(Doubt.created_at.desc())
        .limit(50)
        .all()
    )
    return [DoubtHistoryOut.model_validate(d) for d in doubts]
