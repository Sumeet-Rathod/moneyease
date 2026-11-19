from datetime import datetime, timezone
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import User, Goal, RiskProfile, Setting
from app.schemas.schemas import (
    GoalCalculateIn, GoalCalculateOut, GoalCreateIn, GoalUpdateIn, GoalOut, TrajectoryPoint
)
from app.core.deps import get_current_user
from app.services.calculator import calculate_goal_projection, format_inr_words
from app.config import settings

router = APIRouter(prefix="/goals", tags=["Goal Planner & Visualizer"])

def _get_default_return(db: Session, user_id: int, goal_type: str) -> float:
    if goal_type.strip().lower() == "emergency fund":
        setting = db.query(Setting).filter(Setting.key == "return_emergency").first()
        return float(setting.value) if setting else 6.0

    risk = db.query(RiskProfile).filter(RiskProfile.user_id == user_id).first()
    category = (risk.category if risk else "Moderate").lower()

    key = f"return_{category}"
    setting = db.query(Setting).filter(Setting.key == key).first()
    if setting:
        return float(setting.value)

    if category == "conservative":
        return 8.0
    elif category == "aggressive":
        return 12.0
    return 10.0

@router.post("/calculate", response_model=GoalCalculateOut)
def calculate_goal(data: GoalCalculateIn):
    """
    Stateless goal calculator endpoint.
    Computes inflation-adjusted future cost, required monthly SIP, lumpsum,
    step-up SIP, and year-by-year trajectory.
    """
    calc = calculate_goal_projection(
        current_cost=data.current_cost,
        years=data.years,
        saved_amount=data.saved_amount,
        annual_return=data.assumed_return,
        inflation_rate=data.inflation_rate,
        step_up_pct=data.step_up_pct
    )

    trajectory = [TrajectoryPoint(**p) for p in calc["trajectory"]]

    return GoalCalculateOut(
        current_cost=calc["current_cost"],
        years=calc["years"],
        saved_amount=calc["saved_amount"],
        inflation_rate=calc["inflation_rate"],
        assumed_return=calc["assumed_return"],
        future_cost=calc["future_cost"],
        future_cost_words=format_inr_words(calc["future_cost"]),
        fv_saved=calc["fv_saved"],
        gap=calc["gap"],
        gap_words=format_inr_words(calc["gap"]),
        required_sip=calc["required_sip"],
        required_lumpsum=calc["required_lumpsum"],
        required_lumpsum_words=format_inr_words(calc["required_lumpsum"]),
        step_up_pct=calc["step_up_pct"],
        starting_step_up_sip=calc["starting_step_up_sip"],
        trajectory=trajectory,
        compliance_disclaimer=settings.COMPLIANCE_DISCLAIMER
    )

@router.get("", response_model=List[GoalOut])
def list_my_goals(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    goals = db.query(Goal).filter(Goal.user_id == current_user.id).all()
    results = []
    for g in goals:
        out = GoalOut.model_validate(g)
        out.future_cost_words = format_inr_words(g.future_cost)
        out.required_lumpsum_words = format_inr_words(g.required_lumpsum)
        results.append(out)
    return results

@router.post("", response_model=GoalOut)
def create_goal(
    data: GoalCreateIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    annual_return = data.assumed_return
    if annual_return is None:
        annual_return = _get_default_return(db, current_user.id, data.type)

    calc = calculate_goal_projection(
        current_cost=data.current_cost,
        years=data.years,
        saved_amount=data.saved_amount,
        annual_return=annual_return,
        inflation_rate=data.inflation,
        step_up_pct=data.step_up_pct
    )

    goal = Goal(
        user_id=current_user.id,
        type=data.type,
        name=data.name.strip(),
        current_cost=data.current_cost,
        years=data.years,
        saved_amount=data.saved_amount,
        inflation=data.inflation,
        assumed_return=annual_return,
        future_cost=calc["future_cost"],
        required_sip=calc["required_sip"],
        required_lumpsum=calc["required_lumpsum"],
        step_up_pct=data.step_up_pct,
        created_at=datetime.now(timezone.utc)
    )
    db.add(goal)
    db.commit()
    db.refresh(goal)

    out = GoalOut.model_validate(goal)
    out.future_cost_words = format_inr_words(goal.future_cost)
    out.required_lumpsum_words = format_inr_words(goal.required_lumpsum)
    return out

@router.put("/{goal_id}", response_model=GoalOut)
def update_goal(
    goal_id: int,
    data: GoalUpdateIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    goal = db.query(Goal).filter(Goal.id == goal_id, Goal.user_id == current_user.id).first()
    if not goal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Goal not found or does not belong to you."
        )

    if data.name is not None:
        goal.name = data.name.strip()
    if data.current_cost is not None:
        goal.current_cost = max(data.current_cost, 1.0)
    if data.years is not None:
        goal.years = max(data.years, 0.5)
    if data.saved_amount is not None:
        goal.saved_amount = max(data.saved_amount, 0.0)
    if data.inflation is not None:
        goal.inflation = data.inflation
    if data.assumed_return is not None:
        goal.assumed_return = data.assumed_return
    if data.step_up_pct is not None:
        goal.step_up_pct = max(data.step_up_pct, 0.0)

    # Recalculate
    calc = calculate_goal_projection(
        current_cost=goal.current_cost,
        years=goal.years,
        saved_amount=goal.saved_amount,
        annual_return=goal.assumed_return,
        inflation_rate=goal.inflation,
        step_up_pct=goal.step_up_pct
    )
    goal.future_cost = calc["future_cost"]
    goal.required_sip = calc["required_sip"]
    goal.required_lumpsum = calc["required_lumpsum"]

    db.commit()
    db.refresh(goal)

    out = GoalOut.model_validate(goal)
    out.future_cost_words = format_inr_words(goal.future_cost)
    out.required_lumpsum_words = format_inr_words(goal.required_lumpsum)
    return out

@router.delete("/{goal_id}")
def delete_goal(
    goal_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    goal = db.query(Goal).filter(Goal.id == goal_id, Goal.user_id == current_user.id).first()
    if not goal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Goal not found or does not belong to you."
        )
    db.delete(goal)
    db.commit()
    return {"message": "Goal deleted successfully."}
