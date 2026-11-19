import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_doubts_faq_fallback_and_history():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 1. Suggested chips
        sug_res = await ac.get("/api/v1/doubts/suggested")
        assert sug_res.status_code == 200
        chips = sug_res.json()
        assert len(chips) >= 8
        assert any("SIP" in c for c in chips)

        # Login as sample customer Rahul
        login_res = await ac.post("/api/v1/auth/login", json={
            "email_or_mobile": "rahul.sharma@example.com",
            "password": "Customer@123"
        })
        token = login_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 2. Ask a high-confidence FAQ question
        ask_res = await ac.post("/api/v1/doubts/ask", headers=headers, json={
            "question": "What is SIP and how does rupee cost averaging work?"
        })
        assert ask_res.status_code == 200
        data = ask_res.json()
        assert data["source"] in ["faq", "ai"]
        assert len(data["answer"]) > 20
        assert "disclaimer" in data["compliance_disclaimer"].lower() or "market risks" in data["compliance_disclaimer"].lower()

        # 3. Ask another question
        await ac.post("/api/v1/doubts/ask", headers=headers, json={
            "question": "What is ELSS tax lock in period?"
        })

        # 4. Check user history contains both asked questions
        hist_res = await ac.get("/api/v1/doubts/history", headers=headers)
        assert hist_res.status_code == 200
        history = hist_res.json()
        assert len(history) >= 2
        questions = [h["question"] for h in history]
        assert any("ELSS" in q for q in questions)
        assert any("SIP" in q for q in questions)

        # 5. Test callback request
        cb_res = await ac.post("/api/v1/leads/callback", headers=headers, json={
            "note": "Need help understanding small cap funds"
        })
        assert cb_res.status_code == 200
        assert "callback" in cb_res.json()["message"].lower() or "reach out" in cb_res.json()["message"].lower()
