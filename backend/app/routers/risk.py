from datetime import datetime, timezone
from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import User, RiskProfile, Setting
from app.schemas.schemas import RiskQuestionOut, RiskOption, RiskSubmitIn, RiskProfileOut
from app.core.deps import get_current_user

router = APIRouter(prefix="/risk", tags=["Risk Profiler"])

RISK_QUESTIONS: List[Dict[str, Any]] = [
    {
        "id": "q1",
        "category": "Demographics",
        "question": "What is your current age bracket?",
        "options": [
            {"text": "Under 25 years old", "score": 4},
            {"text": "25 – 35 years old", "score": 3},
            {"text": "36 – 45 years old", "score": 2},
            {"text": "Above 45 years old", "score": 1}
        ]
    },
    {
        "id": "q2",
        "category": "Income Stability",
        "question": "How would you describe the stability of your monthly income?",
        "options": [
            {"text": "Very stable (permanent job, reliable government or MNC)", "score": 4},
            {"text": "Moderately stable (private corporate / steady profession)", "score": 3},
            {"text": "Variable (freelance / sales commissions / seasonal business)", "score": 2},
            {"text": "Unpredictable / currently between jobs or studying", "score": 1}
        ]
    },
    {
        "id": "q3",
        "category": "Time Horizon",
        "question": "What is your primary investment time horizon?",
        "options": [
            {"text": "More than 7 – 10+ years (long-term wealth building)", "score": 4},
            {"text": "4 – 7 years (medium-term goals like home down payment)", "score": 3},
            {"text": "2 – 4 years (short-term milestones like buying a vehicle)", "score": 2},
            {"text": "Less than 2 years (immediate capital preservation)", "score": 1}
        ]
    },
    {
        "id": "q4",
        "category": "Market Volatility",
        "question": "If your mutual fund portfolio dropped 20% in a market correction, what would you do?",
        "options": [
            {"text": "View it as a buying discount and invest MORE via SIP or lumpsum", "score": 4},
            {"text": "Stay calm, do nothing, and continue regular monthly SIPs", "score": 3},
            {"text": "Feel anxious, wait for recovery, but pause further investments", "score": 2},
            {"text": "Panic and redeem everything immediately into bank fixed deposit", "score": 1}
        ]
    },
    {
        "id": "q5",
        "category": "Experience",
        "question": "What is your previous experience with equity and mutual fund investing?",
        "options": [
            {"text": "Experienced: Active investor in equity funds & stocks for 3+ years", "score": 4},
            {"text": "Moderate: Invested in mutual funds or SIPs for 1 – 3 years", "score": 3},
            {"text": "Beginner: Mostly bank FDs, savings, PPF; new to mutual funds", "score": 2},
            {"text": "Complete novice: Never invested any money anywhere before", "score": 1}
        ]
    },
    {
        "id": "q6",
        "category": "Savings Rate",
        "question": "What percentage of your monthly income can you comfortably invest?",
        "options": [
            {"text": "Over 35% of my monthly income", "score": 4},
            {"text": "20% – 35% of my monthly income", "score": 3},
            {"text": "10% – 20% of my monthly income", "score": 2},
            {"text": "Less than 10% of my monthly income", "score": 1}
        ]
    },
    {
        "id": "q7",
        "category": "Investment Objective",
        "question": "What is the primary financial goal you want to achieve?",
        "options": [
            {"text": "Aggressive wealth compounding over 10+ years to beat inflation", "score": 4},
            {"text": "Balanced wealth accumulation with moderate safety margin", "score": 3},
            {"text": "Preserving capital while earning slightly higher than bank FD", "score": 2},
            {"text": "Zero risk to principal capital above all else", "score": 1}
        ]
    },
    {
        "id": "q8",
        "category": "Dependents",
        "question": "How many individuals financially depend on your income?",
        "options": [
            {"text": "No dependents (financially independent bachelor/spinster)", "score": 4},
            {"text": "1 dependent (spouse or child)", "score": 3},
            {"text": "2 – 3 dependents (family with children & elderly parents)", "score": 2},
            {"text": "4 or more dependents (sole breadwinner with large family)", "score": 1}
        ]
    }
]

def _get_category_and_explanation(score: int) -> tuple[str, str, float]:
    """
    Score ranges:
    8 - 14: Conservative (8%)
    15 - 22: Moderate (10%)
    23 - 32: Aggressive (12%)
    """
    if score <= 14:
        cat = "Conservative"
        exp = (
            "You prefer capital preservation and steady stability over market volatility. "
            "A portfolio tilted towards quality debt, liquid, and hybrid funds matches your profile."
        )
        suggested_return = 8.0
    elif score <= 22:
        cat = "Moderate"
        exp = (
            "You seek a balanced blend of wealth growth and downside protection. "
            "A diversified mix of large-cap equity, flexi-cap, and debt mutual funds suits you well."
        )
        suggested_return = 10.0
    else:
        cat = "Aggressive"
        exp = (
            "You have a long investment horizon and high risk tolerance to withstand market swings. "
            "An equity-heavy asset allocation (large, mid, and flexi-cap) will maximize compounding."
        )
        suggested_return = 12.0

    return cat, exp, suggested_return

@router.get("/questions", response_model=List[RiskQuestionOut])
def get_risk_questions():
    return [RiskQuestionOut(**q) for q in RISK_QUESTIONS]

@router.post("/submit", response_model=RiskProfileOut)
def submit_risk_answers(
    data: RiskSubmitIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not data.answers:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Risk questionnaire answers cannot be empty."
        )

    # Calculate total score
    total_score = sum(int(v) for v in data.answers.values())
    category, explanation, suggested_return = _get_category_and_explanation(total_score)

    risk_profile = db.query(RiskProfile).filter(RiskProfile.user_id == current_user.id).first()
    if not risk_profile:
        risk_profile = RiskProfile(user_id=current_user.id)
        db.add(risk_profile)

    risk_profile.answers = data.answers
    risk_profile.score = total_score
    risk_profile.category = category
    risk_profile.created_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(risk_profile)

    return RiskProfileOut(
        id=risk_profile.id,
        user_id=risk_profile.user_id,
        answers=risk_profile.answers,
        score=risk_profile.score,
        category=risk_profile.category,
        explanation=explanation,
        suggested_return=suggested_return,
        created_at=risk_profile.created_at
    )

@router.get("/my-profile", response_model=RiskProfileOut)
def get_my_risk_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    risk_profile = db.query(RiskProfile).filter(RiskProfile.user_id == current_user.id).first()
    if not risk_profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Risk profile not submitted yet. Please complete the risk assessment."
        )

    category, explanation, suggested_return = _get_category_and_explanation(risk_profile.score)
    return RiskProfileOut(
        id=risk_profile.id,
        user_id=risk_profile.user_id,
        answers=risk_profile.answers,
        score=risk_profile.score,
        category=risk_profile.category,
        explanation=explanation,
        suggested_return=suggested_return,
        created_at=risk_profile.created_at
    )
