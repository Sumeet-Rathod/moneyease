import json
import os
from datetime import datetime, date, timedelta, timezone
from sqlalchemy.orm import Session
from app.database import SessionLocal, engine, Base
from app.models.models import (
    User, Consent, CustomerProfile, RiskProfile, Goal,
    Doubt, Lead, LeadNote, Meeting, Notification, Setting, FAQ, AuditLog
)
from app.core.security import get_password_hash, encrypt_pan
from app.services.calculator import calculate_goal_projection

def seed_database():
    print("[MoneyEase] Ensuring database tables exist...")
    Base.metadata.create_all(bind=engine)
    
    db: Session = SessionLocal()
    try:
        # 1. Check if admin exists
        admin = db.query(User).filter(User.email == "admin@moneyease.local").first()
        if admin:
            print("[MoneyEase] Database already seeded. Skipping initial seed.")
            return

        print("[MoneyEase] Seeding Admin, Executives, Settings, and FAQs...")

        # 2. Settings
        default_settings = [
            ("inflation_rate", "6.0"),
            ("return_conservative", "8.0"),
            ("return_moderate", "10.0"),
            ("return_aggressive", "12.0"),
            ("return_emergency", "6.0"),
            ("firm_name", "MoneyEase Wealth Advisors"),
            ("arn_number", "ARN-189452"),
            ("support_phone", "+91 98765 43210"),
            ("support_email", "support@moneyease.in"),
        ]
        for key, val in default_settings:
            db.add(Setting(key=key, value=val))

        # 3. FAQs from JSON
        json_path = os.path.join(os.path.dirname(__file__), "data", "faq_knowledge_base.json")
        if os.path.exists(json_path):
            with open(json_path, "r", encoding="utf-8") as f:
                faqs_data = json.load(f)
                for item in faqs_data:
                    db.add(FAQ(
                        question=item["question"],
                        answer=item["answer"],
                        keywords=item.get("keywords", ""),
                        category=item.get("category", "Mutual Funds"),
                        is_active=True
                    ))

        # 4. Admin User
        admin_user = User(
            name="System Administrator",
            email="admin@moneyease.local",
            mobile="+919000000001",
            role="admin",
            password_hash=get_password_hash("Admin@123"),
            is_active=True,
            created_at=datetime.now(timezone.utc)
        )
        db.add(admin_user)
        db.flush()

        # 5. Executives
        exec1 = User(
            name="Amit Verma",
            email="amit.verma@moneyease.local",
            mobile="+919000000002",
            role="executive",
            password_hash=get_password_hash("Exec@123"),
            is_active=True,
            created_at=datetime.now(timezone.utc)
        )
        exec2 = User(
            name="Priya Sharma",
            email="priya.sharma@moneyease.local",
            mobile="+919000000003",
            role="executive",
            password_hash=get_password_hash("Exec@123"),
            is_active=True,
            created_at=datetime.now(timezone.utc)
        )
        db.add_all([exec1, exec2])
        db.flush()

        # 6. Sample Customers (5 complete real profiles)
        sample_customers = [
            {
                "name": "Rahul Sharma",
                "email": "rahul.sharma@example.com",
                "mobile": "+919811122233",
                "dob": date(2002, 4, 15),
                "gender": "Male",
                "city": "Bengaluru",
                "occupation": "salaried",
                "income_range": "₹50,000 - ₹1,00,000",
                "monthly_expenses": 32000.0,
                "savings": 150000.0,
                "loans_emi": 0.0,
                "dependents": 0,
                "investments": [{"type": "FD", "amount": 50000}, {"type": "MF", "amount": 100000}],
                "pan": "ABCDE1234F",
                "risk_score": 25,
                "risk_category": "Aggressive",
                "goals": [
                    {"type": "Wealth Creation", "name": "Financial Freedom Fund", "cost": 2500000.0, "years": 10.0, "saved": 50000.0, "ret": 12.0},
                    {"type": "Buying a Bike/Car", "name": "Electric Bike", "cost": 180000.0, "years": 2.0, "saved": 20000.0, "ret": 10.0}
                ],
                "doubts": [
                    ("What is SIP (Systematic Investment Plan)?", "A SIP allows you to invest fixed amounts regularly...", "SIP"),
                    ("SIP vs Fixed Deposit (FD): what is the difference?", "Bank FDs offer fixed interest but equity SIPs beat inflation...", "SIP vs FD")
                ],
                "lead_status": "Submitted",
                "exec": exec1
            },
            {
                "name": "Ananya Patel",
                "email": "ananya.patel@example.com",
                "mobile": "+919822233344",
                "dob": date(1999, 8, 20),
                "gender": "Female",
                "city": "Mumbai",
                "occupation": "salaried",
                "income_range": "₹1,00,000 - ₹1,50,000",
                "monthly_expenses": 55000.0,
                "savings": 320000.0,
                "loans_emi": 15000.0,
                "dependents": 1,
                "investments": [{"type": "PPF", "amount": 150000}, {"type": "MF", "amount": 170000}],
                "pan": "BKZPA5432G",
                "risk_score": 18,
                "risk_category": "Moderate",
                "goals": [
                    {"type": "Home Down Payment", "name": "2BHK Down Payment", "cost": 1800000.0, "years": 5.0, "saved": 300000.0, "ret": 10.0},
                    {"type": "Travel", "name": "Europe Trip", "cost": 400000.0, "years": 3.0, "saved": 50000.0, "ret": 10.0}
                ],
                "doubts": [
                    ("What is ELSS (Equity Linked Savings Scheme)?", "ELSS offers 80C deductions up to ₹1.5 lakh with 3y lock-in.", "ELSS"),
                    ("How are Equity Mutual Funds taxed in India?", "LTCG above ₹1.25L taxed at 12.5%, STCG at 20%.", "Taxation")
                ],
                "lead_status": "Assigned",
                "exec": exec2
            },
            {
                "name": "Vikram Singh",
                "email": "vikram.singh@example.com",
                "mobile": "+919833344455",
                "dob": date(1995, 2, 10),
                "gender": "Male",
                "city": "New Delhi",
                "occupation": "business",
                "income_range": "₹1,50,000+",
                "monthly_expenses": 85000.0,
                "savings": 650000.0,
                "loans_emi": 35000.0,
                "dependents": 2,
                "investments": [{"type": "Gold", "amount": 200000}, {"type": "MF", "amount": 450000}],
                "pan": "CPKPS9876M",
                "risk_score": 26,
                "risk_category": "Aggressive",
                "goals": [
                    {"type": "Retirement", "name": "Early Retirement Corpus", "cost": 15000000.0, "years": 20.0, "saved": 500000.0, "ret": 12.0},
                    {"type": "Higher Education", "name": "Kid's Ivy League", "cost": 5000000.0, "years": 14.0, "saved": 200000.0, "ret": 12.0}
                ],
                "doubts": [
                    ("What is NAV (Net Asset Value)?", "NAV is the price per unit calculated at market close.", "NAV"),
                    ("What is Exit Load?", "Exit load is a small fee if redeemed before 1 year.", "Exit Load")
                ],
                "lead_status": "Contacted",
                "exec": exec1
            },
            {
                "name": "Sneha Reddy",
                "email": "sneha.reddy@example.com",
                "mobile": "+919844455566",
                "dob": date(2003, 11, 5),
                "gender": "Female",
                "city": "Hyderabad",
                "occupation": "salaried",
                "income_range": "₹30,000 - ₹50,000",
                "monthly_expenses": 20000.0,
                "savings": 90000.0,
                "loans_emi": 0.0,
                "dependents": 0,
                "investments": [{"type": "FD", "amount": 40000}],
                "pan": "DHYPR6789K",
                "risk_score": 11,
                "risk_category": "Conservative",
                "goals": [
                    {"type": "Emergency Fund", "name": "6-Month Rainy Day Fund", "cost": 120000.0, "years": 1.0, "saved": 30000.0, "ret": 6.0}
                ],
                "doubts": [
                    ("Is mutual fund investment safe for beginners?", "Mutual funds carry market risks but have strict SEBI oversight.", "Safety"),
                    ("What is Term Insurance and why is it essential?", "Pure life protection with high cover at low premiums.", "Insurance")
                ],
                "lead_status": "Meeting Scheduled",
                "exec": exec2
            },
            {
                "name": "Rohan Gupta",
                "email": "rohan.gupta@example.com",
                "mobile": "+919855566677",
                "dob": date(1997, 6, 18),
                "gender": "Male",
                "city": "Pune",
                "occupation": "self-employed",
                "income_range": "₹80,000 - ₹1,20,000",
                "monthly_expenses": 42000.0,
                "savings": 450000.0,
                "loans_emi": 0.0,
                "dependents": 0,
                "investments": [{"type": "Stocks", "amount": 150000}, {"type": "MF", "amount": 300000}],
                "pan": "EMRPG4321P",
                "risk_score": 19,
                "risk_category": "Moderate",
                "goals": [
                    {"type": "Marriage", "name": "Dream Wedding", "cost": 1500000.0, "years": 3.0, "saved": 300000.0, "ret": 10.0}
                ],
                "doubts": [
                    ("What is the Power of Compounding?", "Compounding generates returns on both principal and accumulated growth.", "Compounding")
                ],
                "lead_status": "Converted",
                "exec": exec1
            }
        ]

        for cust_data in sample_customers:
            u = User(
                name=cust_data["name"],
                email=cust_data["email"],
                mobile=cust_data["mobile"],
                role="customer",
                password_hash=get_password_hash("Customer@123"),
                is_active=True,
                created_at=datetime.now(timezone.utc) - timedelta(days=10)
            )
            db.add(u)
            db.flush()

            # Consent
            db.add(Consent(
                user_id=u.id,
                consent_text_version="DPDP_ACT_2023_V1",
                accepted_at=datetime.now(timezone.utc) - timedelta(days=10),
                ip="127.0.0.1"
            ))

            # Customer Profile
            db.add(CustomerProfile(
                user_id=u.id,
                dob=cust_data["dob"],
                gender=cust_data["gender"],
                city=cust_data["city"],
                occupation=cust_data["occupation"],
                income_range=cust_data["income_range"],
                monthly_expenses=cust_data["monthly_expenses"],
                savings=cust_data["savings"],
                loans_emi=cust_data["loans_emi"],
                dependents=cust_data["dependents"],
                existing_investments=cust_data["investments"],
                has_pan=True,
                pan_encrypted=encrypt_pan(cust_data["pan"]),
                has_bank=True,
                has_aadhaar_linked_mobile=True,
                onboarding_step=7,
                completed=True,
                updated_at=datetime.now(timezone.utc)
            ))

            # Risk Profile
            db.add(RiskProfile(
                user_id=u.id,
                answers={"q1": 3, "q2": 3, "q3": 3, "q4": 3, "q5": 3, "q6": 3, "q7": 3, "q8": 3},
                score=cust_data["risk_score"],
                category=cust_data["risk_category"],
                created_at=datetime.now(timezone.utc) - timedelta(days=10)
            ))

            # Goals
            for g in cust_data["goals"]:
                calc = calculate_goal_projection(
                    current_cost=g["cost"],
                    years=g["years"],
                    saved_amount=g["saved"],
                    annual_return=g["ret"],
                    inflation_rate=6.0
                )
                db.add(Goal(
                    user_id=u.id,
                    type=g["type"],
                    name=g["name"],
                    current_cost=g["cost"],
                    years=g["years"],
                    saved_amount=g["saved"],
                    inflation=6.0,
                    assumed_return=g["ret"],
                    future_cost=calc["future_cost"],
                    required_sip=calc["required_sip"],
                    required_lumpsum=calc["required_lumpsum"],
                    step_up_pct=0.0,
                    created_at=datetime.now(timezone.utc) - timedelta(days=9)
                ))

            # Doubts
            for q_text, a_text, topic in cust_data["doubts"]:
                db.add(Doubt(
                    user_id=u.id,
                    question=q_text,
                    answer=a_text,
                    source="faq",
                    topic=topic,
                    created_at=datetime.now(timezone.utc) - timedelta(days=8)
                ))

            # Lead
            lead_obj = Lead(
                user_id=u.id,
                assigned_executive_id=cust_data["exec"].id,
                status=cust_data["lead_status"],
                final_decision="Approved" if cust_data["lead_status"] == "Converted" else None,
                decision_reason="Strong profile aligned with long-term asset allocation." if cust_data["lead_status"] == "Converted" else None,
                submitted_at=datetime.now(timezone.utc) - timedelta(days=7),
                updated_at=datetime.now(timezone.utc)
            )
            db.add(lead_obj)
            db.flush()

            # Lead Note & Meeting for specific statuses
            if cust_data["lead_status"] in ["Contacted", "Meeting Scheduled", "Converted"]:
                db.add(LeadNote(
                    lead_id=lead_obj.id,
                    executive_id=cust_data["exec"].id,
                    note=f"Initial discovery call conducted with {cust_data['name']}. Discussed asset allocation and risk profile.",
                    created_at=datetime.now(timezone.utc) - timedelta(days=5)
                ))

            if cust_data["lead_status"] == "Meeting Scheduled":
                db.add(Meeting(
                    lead_id=lead_obj.id,
                    scheduled_at=datetime.now(timezone.utc) + timedelta(days=2),
                    mode="video",
                    status="scheduled"
                ))

            # Notification for customer
            db.add(Notification(
                user_id=u.id,
                title="Profile Received!",
                body=f"Your financial snapshot has been submitted. Dedicated advisor {cust_data['exec'].name} has been assigned to your case.",
                is_read=True,
                created_at=datetime.now(timezone.utc) - timedelta(days=7)
            ))

        db.commit()
        print("[MoneyEase] Database seed completed successfully!")
        print("  - Admin: admin@moneyease.local / Admin@123")
        print("  - Exec 1: amit.verma@moneyease.local / Exec@123")
        print("  - Exec 2: priya.sharma@moneyease.local / Exec@123")
        print("  - 5 Sample Customers seeded with full profiles, goals, doubts, and leads.")
    except Exception as e:
        db.rollback()
        print(f"[MoneyEase] Seed error: {e}")
        raise e
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()
