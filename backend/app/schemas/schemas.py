from datetime import datetime, date
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, EmailStr, Field, ConfigDict

# ----------------- Auth Schemas -----------------
class RequestOtpIn(BaseModel):
    mobile: str = Field(..., description="10-digit Indian mobile number with or without +91")

class VerifyOtpIn(BaseModel):
    mobile: str
    otp: str

class RegisterIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: Optional[EmailStr] = None
    mobile: Optional[str] = None
    password: Optional[str] = Field(None, min_length=6)
    consent_accepted: bool = Field(..., description="DPDP Act 2023 explicit consent")

class LoginIn(BaseModel):
    email_or_mobile: str
    password: str

class RefreshTokenIn(BaseModel):
    refresh_token: str

class UserOut(BaseModel):
    id: int
    role: str
    name: str
    email: Optional[str] = None
    mobile: Optional[str] = None
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class TokenOut(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserOut

# ----------------- Consent Schemas -----------------
class ConsentIn(BaseModel):
    consent_text_version: str = "DPDP_ACT_2023_V1"

# ----------------- Onboarding & Profile Schemas -----------------
class InvestmentItem(BaseModel):
    type: str  # FD, MF, stocks, PPF, EPF, insurance, gold, none
    amount: float = 0.0

class ProfileStepUpdateIn(BaseModel):
    # Step 1: Basic
    name: Optional[str] = None
    dob: Optional[date] = None
    gender: Optional[str] = None
    city: Optional[str] = None
    occupation: Optional[str] = None
    # Step 2: Income & Expenses
    income_range: Optional[str] = None
    monthly_expenses: Optional[float] = None
    savings: Optional[float] = None
    loans_emi: Optional[float] = None
    dependents: Optional[int] = None
    # Step 3: Existing Investments
    existing_investments: Optional[List[InvestmentItem]] = None
    # Step 4: KYC Readiness
    has_pan: Optional[bool] = None
    pan_number: Optional[str] = None
    has_aadhaar_linked_mobile: Optional[bool] = None
    has_bank: Optional[bool] = None
    onboarding_step: Optional[int] = None

class CustomerProfileOut(BaseModel):
    id: int
    user_id: int
    name: str
    email: Optional[str] = None
    mobile: Optional[str] = None
    dob: Optional[date] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    city: Optional[str] = None
    occupation: Optional[str] = None
    income_range: Optional[str] = None
    monthly_expenses: Optional[float] = None
    savings: Optional[float] = None
    loans_emi: Optional[float] = None
    dependents: Optional[int] = None
    existing_investments: Optional[List[Dict[str, Any]]] = None
    has_pan: bool = False
    pan_masked: Optional[str] = None
    has_bank: bool = False
    has_aadhaar_linked_mobile: bool = False
    onboarding_step: int = 1
    completed: bool = False
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

# ----------------- Risk Profile Schemas -----------------
class RiskOption(BaseModel):
    text: str
    score: int

class RiskQuestionOut(BaseModel):
    id: str
    question: str
    category: str
    options: List[RiskOption]

class RiskSubmitIn(BaseModel):
    answers: Dict[str, int]  # question_id -> score

class RiskProfileOut(BaseModel):
    id: int
    user_id: int
    answers: Dict[str, Any]
    score: int
    category: str  # Conservative, Moderate, Aggressive
    explanation: str
    suggested_return: float
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

# ----------------- Goal Schemas -----------------
class GoalCalculateIn(BaseModel):
    current_cost: float = Field(..., gt=0)
    years: float = Field(..., gt=0)
    saved_amount: float = Field(default=0.0, ge=0)
    assumed_return: float = Field(default=10.0, ge=0)
    inflation_rate: float = Field(default=6.0, ge=0)
    step_up_pct: float = Field(default=0.0, ge=0)

class TrajectoryPoint(BaseModel):
    year: int
    invested: float
    projected_value: float

class GoalCalculateOut(BaseModel):
    current_cost: float
    years: float
    saved_amount: float
    inflation_rate: float
    assumed_return: float
    future_cost: float
    future_cost_words: str
    fv_saved: float
    gap: float
    gap_words: str
    required_sip: float
    required_lumpsum: float
    required_lumpsum_words: str
    step_up_pct: float
    starting_step_up_sip: float
    trajectory: List[TrajectoryPoint]
    compliance_disclaimer: str

class GoalCreateIn(BaseModel):
    type: str  # Emergency Fund, Higher Education, etc.
    name: str = Field(..., min_length=2, max_length=100)
    current_cost: float = Field(..., gt=0)
    years: float = Field(..., gt=0)
    saved_amount: float = Field(default=0.0, ge=0)
    inflation: float = Field(default=6.0, ge=0)
    assumed_return: Optional[float] = None
    step_up_pct: float = Field(default=0.0, ge=0)

class GoalUpdateIn(BaseModel):
    name: Optional[str] = None
    current_cost: Optional[float] = None
    years: Optional[float] = None
    saved_amount: Optional[float] = None
    inflation: Optional[float] = None
    assumed_return: Optional[float] = None
    step_up_pct: Optional[float] = None

class GoalOut(BaseModel):
    id: int
    user_id: int
    type: str
    name: str
    current_cost: float
    years: float
    saved_amount: float
    inflation: float
    assumed_return: float
    future_cost: float
    future_cost_words: Optional[str] = None
    required_sip: float
    required_lumpsum: float
    required_lumpsum_words: Optional[str] = None
    step_up_pct: float
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

# ----------------- Doubts Schemas -----------------
class DoubtAskIn(BaseModel):
    question: str = Field(..., min_length=2)

class DoubtAskOut(BaseModel):
    id: int
    question: str
    answer: str
    source: str  # ai, faq
    topic: Optional[str] = None
    compliance_disclaimer: str
    created_at: datetime

class DoubtHistoryOut(BaseModel):
    id: int
    question: str
    answer: str
    source: str
    topic: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class CallbackRequestIn(BaseModel):
    note: Optional[str] = None

# ----------------- Leads & Executive Schemas -----------------
class LeadSubmitIn(BaseModel):
    note: Optional[str] = None

class LeadStatusOut(BaseModel):
    lead_id: int
    status: str
    assigned_executive_name: Optional[str] = None
    assigned_executive_email: Optional[str] = None
    assigned_executive_phone: Optional[str] = None
    submitted_at: datetime
    updated_at: datetime
    tracker_steps: List[Dict[str, Any]]

class LeadNoteIn(BaseModel):
    note: str = Field(..., min_length=1)

class LeadNoteOut(BaseModel):
    id: int
    executive_name: str
    note: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class MeetingIn(BaseModel):
    scheduled_at: datetime
    mode: str = "video"  # call, video, office

class MeetingOut(BaseModel):
    id: int
    scheduled_at: datetime
    mode: str
    status: str

    model_config = ConfigDict(from_attributes=True)

class DecisionIn(BaseModel):
    decision: str  # Approved, Not suitable, Follow-up later
    reason: str

class LeadMessageIn(BaseModel):
    title: str = "Update from Wealth Advisor"
    message: str

class LeadListItemOut(BaseModel):
    lead_id: int
    user_id: int
    name: str
    age: Optional[int] = None
    city: Optional[str] = None
    risk_category: Optional[str] = None
    total_goals_count: int
    total_goal_amount: float
    total_required_sip: float
    status: str
    assigned_executive_id: Optional[int] = None
    assigned_executive_name: Optional[str] = None
    submitted_at: datetime
    updated_at: datetime

class LeadDetailOut(BaseModel):
    lead_id: int
    user_id: int
    status: str
    final_decision: Optional[str] = None
    decision_reason: Optional[str] = None
    submitted_at: datetime
    updated_at: datetime
    assigned_executive_id: Optional[int] = None
    assigned_executive_name: Optional[str] = None
    consent_accepted_at: Optional[datetime] = None
    profile: Optional[CustomerProfileOut] = None
    risk_profile: Optional[RiskProfileOut] = None
    goals: List[GoalOut] = []
    doubts_asked: List[DoubtHistoryOut] = []
    notes: List[LeadNoteOut] = []
    meetings: List[MeetingOut] = []

# ----------------- Admin Schemas -----------------
class ExecutiveCreateIn(BaseModel):
    name: str = Field(..., min_length=2)
    email: EmailStr
    mobile: str
    password: str = Field(..., min_length=6)

class ExecutiveUpdateIn(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    mobile: Optional[str] = None
    is_active: Optional[bool] = None
    password: Optional[str] = None

class FAQCreateIn(BaseModel):
    question: str
    answer: str
    keywords: Optional[str] = None
    category: str = "Mutual Funds"
    is_active: bool = True

class FAQUpdateIn(BaseModel):
    question: Optional[str] = None
    answer: Optional[str] = None
    keywords: Optional[str] = None
    category: Optional[str] = None
    is_active: Optional[bool] = None

class SettingItem(BaseModel):
    key: str
    value: str

class SettingsUpdateIn(BaseModel):
    settings: List[SettingItem]

class AdminStatsOut(BaseModel):
    total_signups: int
    onboarding_completed_count: int
    onboarding_completion_pct: float
    total_leads: int
    leads_by_status: Dict[str, int]
    leads_per_executive: List[Dict[str, Any]]
    top_doubt_topics: List[Dict[str, Any]]
    conversion_rate_pct: float

# ----------------- Notification Schemas -----------------
class NotificationOut(BaseModel):
    id: int
    user_id: int
    title: str
    body: str
    is_read: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
