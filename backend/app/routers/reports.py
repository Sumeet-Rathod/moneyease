from fastapi import APIRouter, Depends, HTTPException, status, Response
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import User, CustomerProfile, RiskProfile, Goal, Doubt, Lead
from app.core.deps import get_current_user
from app.services.pdf import generate_customer_snapshot_pdf

router = APIRouter(prefix="/reports", tags=["Reports & PDF"])

@router.get("/profile/{user_id}.pdf")
def download_profile_pdf(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Authorization check
    is_owner = (current_user.id == user_id)
    is_admin = (current_user.role == "admin")
    
    lead = db.query(Lead).filter(Lead.user_id == user_id).first()
    is_assigned_exec = (lead and lead.assigned_executive_id == current_user.id)

    if not (is_owner or is_admin or is_assigned_exec):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to download this customer's financial report."
        )

    target_user = db.query(User).filter(User.id == user_id).first()
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Customer not found."
        )

    customer_profile = db.query(CustomerProfile).filter(CustomerProfile.user_id == user_id).first()
    risk_profile = db.query(RiskProfile).filter(RiskProfile.user_id == user_id).first()
    goals = db.query(Goal).filter(Goal.user_id == user_id).all()
    doubts = db.query(Doubt).filter(Doubt.user_id == user_id).order_by(Doubt.created_at.desc()).all()

    pdf_bytes = generate_customer_snapshot_pdf(
        customer_user=target_user,
        customer_profile=customer_profile,
        risk_profile=risk_profile,
        goals=goals,
        doubts=doubts,
        lead=lead
    )

    filename = f"MoneyEase_Financial_Snapshot_{target_user.name.replace(' ', '_')}_{user_id}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f"attachment; filename=\"{filename}\""
        }
    )
