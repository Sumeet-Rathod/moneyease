import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_onboarding_lifecycle_and_pan():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Register a test customer
        reg = await ac.post("/api/v1/auth/register", json={
            "name": "Manish Tiwari",
            "email": "manish.tiwari@example.com",
            "mobile": "9877766655",
            "password": "Password@123",
            "consent_accepted": True
        })
        token = reg.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 1. GET initial profile
        prof_res = await ac.get("/api/v1/profile", headers=headers)
        assert prof_res.status_code == 200
        assert prof_res.json()["onboarding_step"] == 1
        assert prof_res.json()["completed"] is False

        # 2. Update Step 1 (Basic Details)
        step1_res = await ac.put("/api/v1/profile/step/1", headers=headers, json={
            "name": "Manish Tiwari",
            "dob": "2000-05-15",
            "gender": "Male",
            "city": "Ahmedabad",
            "occupation": "salaried"
        })
        assert step1_res.status_code == 200
        p1 = step1_res.json()
        assert p1["city"] == "Ahmedabad"
        assert p1["age"] is not None
        assert p1["age"] >= 20

        # 3. Update Step 2 (Income & Expenses)
        step2_res = await ac.put("/api/v1/profile/step/2", headers=headers, json={
            "income_range": "₹50,000 - ₹1,00,000",
            "monthly_expenses": 35000.0,
            "savings": 120000.0,
            "loans_emi": 5000.0,
            "dependents": 1
        })
        assert step2_res.status_code == 200
        assert step2_res.json()["monthly_expenses"] == 35000.0

        # 4. Update Step 3 (Investments)
        step3_res = await ac.put("/api/v1/profile/step/3", headers=headers, json={
            "existing_investments": [
                {"type": "FD", "amount": 50000.0},
                {"type": "MF", "amount": 70000.0}
            ]
        })
        assert step3_res.status_code == 200
        assert len(step3_res.json()["existing_investments"]) == 2

        # 5. Invalid PAN should fail with 400
        bad_pan_res = await ac.put("/api/v1/profile/step/4", headers=headers, json={
            "has_pan": True,
            "pan_number": "INVALID123"
        })
        assert bad_pan_res.status_code == 400

        # 6. Valid PAN should be accepted and returned MASKED (XXXXX1234X)
        good_pan_res = await ac.put("/api/v1/profile/step/4", headers=headers, json={
            "has_pan": True,
            "pan_number": "ABCDE9876Z",
            "has_bank": True,
            "has_aadhaar_linked_mobile": True
        })
        assert good_pan_res.status_code == 200
        p4 = good_pan_res.json()
        assert p4["has_pan"] is True
        assert p4["pan_masked"] == "XXXXX9876X"
        # PAN must NEVER be returned raw
        assert "ABCDE9876Z" not in str(p4)
