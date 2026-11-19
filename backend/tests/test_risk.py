import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_risk_questions_and_boundaries():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 1. Fetch risk questions
        q_res = await ac.get("/api/v1/risk/questions")
        assert q_res.status_code == 200
        questions = q_res.json()
        assert len(questions) == 8

        # Register a test user
        reg = await ac.post("/api/v1/auth/register", json={
            "name": "Risk Tester",
            "email": "risk.tester@example.com",
            "password": "Password@123",
            "consent_accepted": True
        })
        token = reg.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 2. Test Conservative Boundary: score = 8 (all 1s)
        ans_cons = {f"q{i}": 1 for i in range(1, 9)}
        sub_c = await ac.post("/api/v1/risk/submit", headers=headers, json={"answers": ans_cons})
        assert sub_c.status_code == 200
        assert sub_c.json()["score"] == 8
        assert sub_c.json()["category"] == "Conservative"
        assert sub_c.json()["suggested_return"] == 8.0

        # Boundary score 14 -> Conservative
        ans_14 = {"q1": 2, "q2": 2, "q3": 2, "q4": 2, "q5": 2, "q6": 2, "q7": 1, "q8": 1}
        sub_14 = await ac.post("/api/v1/risk/submit", headers=headers, json={"answers": ans_14})
        assert sub_14.json()["score"] == 14
        assert sub_14.json()["category"] == "Conservative"

        # Boundary score 15 -> Moderate
        ans_15 = {"q1": 2, "q2": 2, "q3": 2, "q4": 2, "q5": 2, "q6": 2, "q7": 2, "q8": 1}
        sub_15 = await ac.post("/api/v1/risk/submit", headers=headers, json={"answers": ans_15})
        assert sub_15.json()["score"] == 15
        assert sub_15.json()["category"] == "Moderate"
        assert sub_15.json()["suggested_return"] == 10.0

        # Boundary score 22 -> Moderate
        ans_22 = {"q1": 3, "q2": 3, "q3": 3, "q4": 3, "q5": 3, "q6": 3, "q7": 2, "q8": 2}
        sub_22 = await ac.post("/api/v1/risk/submit", headers=headers, json={"answers": ans_22})
        assert sub_22.json()["score"] == 22
        assert sub_22.json()["category"] == "Moderate"

        # Boundary score 23 -> Aggressive
        ans_23 = {"q1": 3, "q2": 3, "q3": 3, "q4": 3, "q5": 3, "q6": 3, "q7": 3, "q8": 2}
        sub_23 = await ac.post("/api/v1/risk/submit", headers=headers, json={"answers": ans_23})
        assert sub_23.json()["score"] == 23
        assert sub_23.json()["category"] == "Aggressive"
        assert sub_23.json()["suggested_return"] == 12.0

        # Test GET /risk/my-profile
        my_prof = await ac.get("/api/v1/risk/my-profile", headers=headers)
        assert my_prof.status_code == 200
        assert my_prof.json()["category"] == "Aggressive"
