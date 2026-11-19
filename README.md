# MoneyEase — AMFI-Registered Wealth Management & Goal Planning Application

[![FastAPI](https://img.shields.io/badge/Backend-FastAPI%200.115+-009688.svg?style=flat&logo=fastapi)](https://fastapi.tiangolo.com)
[![Flutter](https://img.shields.io/badge/Frontend-Flutter%203.22+-02569B.svg?style=flat&logo=flutter)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.11%2B%20%7C%203.13-3776AB.svg?style=flat&logo=python)](https://python.org)
[![License](https://img.shields.io/badge/License-Proprietary-blue.svg)](#)

**MoneyEase** is a production-quality, mobile-first financial onboarding and wealth planning application built for Indian Mutual Fund Distributors (AMFI-registered MFDs). Specifically tailored for young professionals and first-time investors (ages 18–35), MoneyEase simplifies complex financial concepts, guides users through a compliant 7-step onboarding process, simulates inflation-adjusted future goals with interactive charts, and connects customers with certified human wealth advisors.

---

## ⚖️ AMFI / SEBI Compliance & Regulatory Rule

> **Mandatory Regulatory Disclaimer:**  
> *"Mutual fund investments are subject to market risks, read all scheme related documents carefully. Projections are illustrative and based on assumed returns; they are not guaranteed."*

- **Single Firm Configuration:** Firm details (`FIRM_NAME`, `ARN_NUMBER`, `SUPPORT_PHONE`, `SUPPORT_EMAIL`) are managed in a single configuration file (`backend/app/config.py` and `frontend/lib/config.dart`).
- **No Stock/Fund Recommendations:** The platform provides educational projections and financial simulations using configurable assumed rates, routing all final investment execution to a human wealth advisor.
- **Data Protection:** India Digital Personal Data Protection (DPDP) Act 2023 compliance with explicit consent logging (timestamp, IP address, version). Permanent Account Numbers (PAN) are encrypted at rest with AES-256 (Fernet) and displayed masked (`XXXXX1234X`). Aadhaar numbers are never stored.

---

## 🏗️ Architecture & Tech Stack

### Frontend (Mobile & Web)
- **Framework:** Flutter 3.22+ (Dart 3.4+ with null-safety). Targets: **Android** & **Web** (Desktop/Web executive console).
- **State Management:** Riverpod 2.6+ with code-generator-free clean state notifiers.
- **Navigation:** `go_router` 14.8+ with role-based routing guards, redirects, and responsive navigation shell (`NavigationBar` on mobile, `NavigationRail` on web/desktop).
- **Networking:** Dio 5.11+ with dual interceptors (JWT bearer attach + transparent 401 token auto-refresh).
- **Interactive Visuals:** `fl_chart` 0.68+ (Line charts for invested vs compounded wealth, Bar charts for multi-goal comparison, Pie charts for administrative lead pipeline distribution).
- **Secure Storage:** `flutter_secure_storage` with encrypted SharedPreferences.
- **Theme:** Material 3 with calm teal/blue palette (`#028090`, `#0F4C81`), sage green (`#00A896`), warm amber, and full dark-mode support.

### Backend
- **Engine:** Python 3.11+ / 3.13+, FastAPI, Uvicorn (ASGI).
- **Database & ORM:** SQLAlchemy 2.0 with Alembic migrations. Automatic fallback to SQLite (`moneyease.db`) if `DATABASE_URL` is unset, or PostgreSQL via Docker Compose.
- **Validation:** Pydantic v2 schemas with `ConfigDict(from_attributes=True)`.
- **Security & Cryptography:** Passwords hashed with `bcrypt` (passlib), JWT tokens (`PyJWT`), PAN encrypted with AES-256 `Fernet`.
- **Doubt Assistant:** Google Gemini API (`gemini-1.5-flash`) via `GEMINI_API_KEY`. If key is missing, automatically falls back to an offline 42-article FAQ knowledge base using `rapidfuzz` token-ratio matching.
- **Reports:** Server-side PDF generation using `reportlab` with customer financial snapshot, asset allocation, goals table, and disclaimer watermark.
- **Rate Limiting:** `slowapi` endpoint-level rate protection.

---

## 👥 Default Seed Credentials

The database seeds an Admin, two Wealth Advisors, and five complete customer profiles on initial execution.

| Role | Name | Email | Password | Details |
|---|---|---|---|---|
| **Admin** | Super Admin | `admin@moneyease.local` | `Admin@123` | Full administrative controls, advisor management, FAQ KB, return rates |
| **Executive** | Amit Verma | `amit.verma@moneyease.local` | `Exec@123` | Senior Wealth Advisor (Assigned leads, notes, meetings) |
| **Executive** | Priya Sharma | `priya.sharma@moneyease.local` | `Exec@123` | Certified Financial Planner (CFP) |
| **Customer** | Rahul Sharma | `rahul.sharma@example.com` | `Customer@123` | Age 24, Bengaluru, Aggressive Risk, 3 Goals |
| **Customer** | Ananya Patel | `ananya.patel@example.com` | `Customer@123` | Age 28, Mumbai, Moderate Risk, 2 Goals |
| **Customer** | Vikram Singh | `vikram.singh@example.com` | `Customer@123` | Age 32, New Delhi, Conservative Risk, 2 Goals |
| **Customer** | Sneha Reddy | `sneha.reddy@example.com` | `Customer@123` | Age 22, Hyderabad, Aggressive Risk, 1 Goal |
| **Customer** | Arjun Mehta | `arjun.mehta@example.com` | `Customer@123` | Age 29, Pune, Moderate Risk, 3 Goals |

*Note: For Mobile OTP login in development mode, entering any 10-digit mobile generates a 6-digit OTP printed in the backend console (default dev OTP: `123456`).*

---

## 📐 Mathematical Formulas (Mirrored in Python & Dart)

All calculations are implemented in `backend/app/services/calculator.py` and strictly mirrored in `frontend/lib/core/utils/calculator.dart` with matching test suites:

1. **Inflation-Adjusted Future Cost:**
   $$\text{FV}_{\text{cost}} = \text{Cost} \times (1 + i)^n$$
   *(Default inflation $i = 6.0\%$, editable)*

2. **Future Value of Existing Savings:**
   $$\text{FV}_{\text{saved}} = \text{Saved} \times (1 + r)^n$$

3. **Net Funding Gap:**
   $$\text{Gap} = \max(\text{FV}_{\text{cost}} - \text{FV}_{\text{saved}}, 0)$$

4. **Required Monthly SIP (Annuity-Due Formula):**
   $$r_m = \frac{r_{\text{annual}}}{12}, \quad N = n \times 12$$
   $$\text{SIP} = \frac{\text{Gap} \times r_m}{((1 + r_m)^N - 1) \times (1 + r_m)}$$

5. **Lumpsum Needed Today:**
   $$\text{Lumpsum} = \frac{\text{Gap}}{(1 + r_{\text{annual}})^n}$$

6. **SIP Wealth Projection (What-If Simulator):**
   $$\text{FV}_{\text{sip}} = P \times \frac{(1 + r_m)^N - 1}{r_m} \times (1 + r_m)$$

7. **Yearly Step-Up SIP:** Month-by-month simulation compounding at $r_m$ with annual percentage increase.

---

## 🚀 Quickstart Guide

### 1. Prerequisites
- **Python 3.11+**
- **Flutter 3.22+**
- **Git**

### 2. Backend Setup
```bash
cd moneyease/backend

# Create virtual environment
python -m venv .venv

# Activate virtual environment
# Windows (PowerShell):
.\.venv\Scripts\Activate.ps1
# Linux/macOS:
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run migrations & seed data
alembic upgrade head
python -m app.seed

# Start backend server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
API Documentation (Swagger UI): `http://localhost:8000/docs`  
Interactive OpenAPI specification: `http://localhost:8000/api/v1/openapi.json`

### 3. Frontend Setup
```bash
cd moneyease/frontend

# Fetch dependencies
flutter pub get

# Run on Chrome (Web - Executive / Customer)
flutter run -d chrome

# Or run on Android Emulator / Device
flutter run -d android
```

### 4. Running with Docker Compose (PostgreSQL)
```bash
cd moneyease
docker-compose up --build
```

---

## 🧪 Running Automated Tests

### Backend Unit & Integration Tests (14 Pytest Suites)
```bash
cd moneyease/backend
pytest -v
```
**Coverage:** OTP login lifecycle, email authentication, role authorization guards, mathematical calculation parity, What-if SIP simulations, step-up SIP month-by-month compounding, Indian currency word formatting, RapidFuzz FAQ fallback engine, health & OpenAPI endpoints, lead workflow state transitions, and PAN encryption at rest.

### Frontend Unit & Widget Tests (Flutter)
```bash
cd moneyease/frontend
flutter test
flutter analyze
```
**Coverage:** Dart financial calculator mirroring, currency formatter tests, widget rendering, navigation shell, and AMFI compliance banner verification.

---

## 📂 Project Structure

```text
moneyease/
├── docker-compose.yml          # PostgreSQL & backend container orchestration
├── README.md                   # System documentation & seed credentials
├── backend/
│   ├── requirements.txt        # FastAPI, SQLAlchemy, Alembic, ReportLab, RapidFuzz
│   ├── Dockerfile              # Container definition
│   ├── alembic.ini             # Database migration configuration
│   ├── alembic/                # Schema migration versions
│   ├── app/
│   │   ├── main.py             # FastAPI ASGI entrypoint & OpenAPI documentation
│   │   ├── config.py           # AMFI distributor details, JWT, and Fernet settings
│   │   ├── database.py         # SQLAlchemy engine & session factory
│   │   ├── seed.py             # Automatic database seeder
│   │   ├── core/
│   │   │   ├── security.py     # Bcrypt, JWT tokens, Fernet PAN encryption & masking
│   │   │   └── deps.py         # Role-based dependency injectors (customer/exec/admin)
│   │   ├── models/
│   │   │   └── models.py       # 13 SQLAlchemy models (users, goals, leads, doubts, etc.)
│   │   ├── schemas/
│   │   │   └── schemas.py      # Pydantic v2 schemas
│   │   ├── services/
│   │   │   ├── calculator.py   # Inflation, SIP, lumpsum, step-up math engine
│   │   │   ├── doubts.py       # RapidFuzz FAQ matcher & Gemini AI assistant
│   │   │   ├── leads.py        # Round-robin advisor assignment service
│   │   │   └── pdf.py          # ReportLab financial snapshot PDF generator
│   │   ├── routers/
│   │   │   ├── auth.py         # Mobile OTP & Email authentication
│   │   │   ├── onboarding.py   # 7-step onboarding wizard persistence
│   │   │   ├── risk.py         # 8-question risk profiler & asset allocation
│   │   │   ├── goals.py        # Goal planner & future visualizer endpoints
│   │   │   ├── doubts.py       # AI & FAQ doubt solver chat
│   │   │   ├── leads.py        # Customer profile submission & tracker
│   │   │   ├── reports.py      # Customer snapshot PDF downloads
│   │   │   ├── executive.py    # Executive pipeline, notes, and meetings
│   │   │   ├── admin.py        # Administrative stats, FAQs, and settings
│   │   │   └── notifications.py# Polled in-app notification alerts
│   │   └── data/
│   │       └── faq_knowledge_base.json # 42 curated mutual fund Q&As
│   └── tests/                  # Pytest test suite
└── frontend/
    ├── pubspec.yaml            # Flutter Riverpod, GoRouter, fl_chart, Dio
    ├── lib/
    │   ├── main.dart           # App entrypoint with Riverpod ProviderScope
    │   ├── config.dart         # Firm details, ARN number, compliance disclaimer
    │   ├── theme.dart          # Material 3 calm teal & sage green theme
    │   ├── app_router.dart     # GoRouter configuration with role-based guards
    │   ├── core/
    │   │   ├── api_client.dart # Dio instance with JWT attach & 401 token refresh
    │   │   ├── storage.dart    # FlutterSecureStorage tokens wrapper
    │   │   ├── utils/
    │   │   │   ├── calculator.dart         # Mirrored Dart financial calculations
    │   │   │   └── currency_formatter.dart # ₹ Lakh & Crore formatter
    │   │   └── widgets/
    │   │       ├── app_nav_shell.dart      # Responsive NavigationBar / NavigationRail
    │   │       ├── disclaimer_banner.dart  # Mandatory AMFI compliance disclaimer
    │   │       ├── custom_button.dart      # Material 3 styled action buttons
    │   │       └── custom_text_field.dart  # Form input with validation
    │   └── features/
    │       ├── auth/           # Splash, Carousel, Login, and OTP screens
    │       ├── onboarding/     # 7-step wizard with PAN validation & progress bar
    │       ├── risk_profile/   # Questionnaire, gauge meter & asset allocation
    │       ├── goals/          # Goal planner, editor, fl_chart visualizer & slider
    │       ├── doubts/         # Live chat with chips, AI/FAQ, and callback modal
    │       ├── profile/        # Customer summary, tracker, and PDF download
    │       ├── notifications/  # 30-second polling in-app notification inbox
    │       └── executive/      # Advisor pipeline, lead detail & admin portal
    └── test/                   # Calculator parity tests & widget smoke tests
```

---

## 🔒 Security & Privacy Features

- **DPDP Act 2023 Compliance:** Customer consent timestamp, version, and IP address are captured upon registration and profile submission.
- **PAN Encryption:** Stored in database as encrypted ciphertext using AES-256 Fernet. Everywhere across API responses and frontend screens, PAN is strictly displayed masked as `XXXXX1234X`.
- **Role Isolation:** Endpoints and routes enforce strict role checks preventing customers from accessing executive/admin portals and vice-versa.
- **Fail-Safe Offline Architecture:** Automatic fallback to SQLite when Docker/PostgreSQL is unavailable, and automatic fallback to 42-question FAQ matching when `GEMINI_API_KEY` is not provided.

---

## 📄 License
Proprietary & Confidential. All rights reserved by MoneyEase Wealth Advisors.
