import json
import os
from typing import Dict, Any, Tuple
import httpx
from rapidfuzz import process, fuzz
from app.config import settings

# Load FAQ fallback knowledge base from JSON
_faq_cache = []

def _load_faqs():
    global _faq_cache
    if not _faq_cache:
        json_path = os.path.join(os.path.dirname(__file__), "..", "data", "faq_knowledge_base.json")
        if os.path.exists(json_path):
            with open(json_path, "r", encoding="utf-8") as f:
                _faq_cache = json.load(f)
    return _faq_cache

SYSTEM_PROMPT = f"""
You are the MoneyEase Financial Doubt Assistant for an Indian AMFI-registered Mutual Fund Distributor.
Your mission is to educate young Indian investors (ages 18-35) in simple, warm, encouraging, plain English (or Hindi/Gujarati if user asks in it).

CRITICAL COMPLIANCE RULES:
1. EDUCATIONAL ONLY: Never recommend specific fund names (e.g. do NOT say 'buy XYZ Bluechip Fund').
2. NO GUARANTEES: Never claim guaranteed returns or risk-free equity.
3. ALWAYS remind users that mutual funds are subject to market risks.
4. For personal financial planning, suggest tapping the 'Talk to an Expert' button to connect with an AMFI-certified advisor.
5. Keep answers concise, clear, and easy to read with bullet points where appropriate.
"""

async def solve_user_doubt(question: str) -> Dict[str, Any]:
    """
    Answers a customer's doubt using Google Gemini if GEMINI_API_KEY is configured,
    or falls back automatically to the local 42+ FAQ knowledge base with fuzzy matching.
    """
    clean_q = question.strip()
    
    # 1. Try Gemini API if key is present
    if settings.GEMINI_API_KEY and len(settings.GEMINI_API_KEY) > 5:
        try:
            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={settings.GEMINI_API_KEY}"
            payload = {
                "contents": [
                    {
                        "role": "user",
                        "parts": [
                            {"text": f"{SYSTEM_PROMPT}\n\nUser Question: {clean_q}"}
                        ]
                    }
                ],
                "generationConfig": {
                    "temperature": 0.4,
                    "maxOutputTokens": 600,
                }
            }
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.post(url, json=payload)
                if resp.status_code == 200:
                    data = resp.json()
                    candidates = data.get("candidates", [])
                    if candidates:
                        raw_text = candidates[0]["content"]["parts"][0]["text"].strip()
                        # Format and return
                        return {
                            "question": clean_q,
                            "answer": raw_text,
                            "source": "ai",
                            "topic": "AI Financial Assistant",
                            "compliance_disclaimer": settings.COMPLIANCE_DISCLAIMER
                        }
        except Exception as e:
            print(f"[MoneyEase GEMINI WARNING] API call failed: {e}. Falling back to FAQ engine.")

    # 2. Local FAQ Engine Fallback with RapidFuzz
    faqs = _load_faqs()
    if not faqs:
        return {
            "question": clean_q,
            "answer": "Thank you for asking! For detailed personalized advice, please connect with our certified wealth advisor.",
            "source": "faq",
            "topic": "General",
            "compliance_disclaimer": settings.COMPLIANCE_DISCLAIMER
        }

    # Match against question + keywords
    corpus = [f"{item['question']} {item.get('keywords', '')}" for item in faqs]
    best_match = process.extractOne(
        clean_q,
        corpus,
        scorer=fuzz.token_set_ratio
    )

    if best_match and best_match[1] >= 48:
        matched_idx = best_match[2]
        faq_item = faqs[matched_idx]
        return {
            "question": clean_q,
            "answer": faq_item["answer"],
            "source": "faq",
            "topic": faq_item.get("category", "Mutual Funds"),
            "compliance_disclaimer": settings.COMPLIANCE_DISCLAIMER
        }
    else:
        # Low confidence fallback
        fallback_msg = (
            "I don't have an exact answer for that right now, but our AMFI-registered "
            "wealth advisors would be happy to explain it in detail! "
            "Click 'Talk to an Expert' below to request a quick callback."
        )
        return {
            "question": clean_q,
            "answer": fallback_msg,
            "source": "faq",
            "topic": "Expert Callback",
            "compliance_disclaimer": settings.COMPLIANCE_DISCLAIMER
        }
