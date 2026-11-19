import pytest
import math
from app.services.calculator import (
    calculate_goal_projection,
    simulate_sip_future_value,
    simulate_step_up_sip,
    format_inr_words
)

def test_calculator_known_values():
    """
    Standard test with known baseline:
    Cost: 10 Lakh (1,000,000)
    Years: 10
    Inflation: 6%
    Saved: 1 Lakh (100,000)
    Return: 12%
    """
    res = calculate_goal_projection(
        current_cost=1000000.0,
        years=10.0,
        saved_amount=100000.0,
        annual_return=12.0,
        inflation_rate=6.0,
        step_up_pct=0.0
    )

    # 1. Inflation adjusted cost = 1000000 * 1.06^10 ~ 1,790,847.70
    assert math.isclose(res["future_cost"], 1790847.70, rel_tol=1e-3)

    # 2. FV of saved amount = 100000 * 1.12^10 ~ 310,584.82
    assert math.isclose(res["fv_saved"], 310584.82, rel_tol=1e-3)

    # 3. Gap = 1,790,847.70 - 310,584.82 ~ 1,480,262.88
    assert math.isclose(res["gap"], 1480262.88, rel_tol=1e-3)

    # 4. Required monthly SIP ~ 6,371.13
    assert math.isclose(res["required_sip"], 6371.13, rel_tol=1e-2)

    # 5. Required Lumpsum today ~ 476,605.02
    assert math.isclose(res["required_lumpsum"], 476605.02, rel_tol=1e-2)

    # 6. Trajectory points count
    assert len(res["trajectory"]) == 10
    assert res["trajectory"][-1]["year"] == 10
    assert res["trajectory"][-1]["invested"] > 100000.0

def test_sip_what_if_simulation():
    """
    What-if simulation: 5,000/month for 10 years at 12% return
    Total invested = 600,000
    Future value ~ 1,161,695.38
    Wealth gain ~ 561,695.38
    """
    sim = simulate_sip_future_value(
        monthly_investment=5000.0,
        years=10.0,
        annual_return=12.0
    )
    assert sim["invested"] == 600000.0
    assert math.isclose(sim["future_value"], 1161695.38, rel_tol=1e-3)
    assert math.isclose(sim["wealth_gain"], 561695.38, rel_tol=1e-3)

def test_step_up_sip():
    """
    Step-up SIP: Starting at 5,000, 10% annual step-up, 10 years at 12%
    Accumulates more than standard flat SIP
    """
    flat = simulate_sip_future_value(5000.0, 10.0, 12.0)
    step = simulate_step_up_sip(5000.0, 10.0, 12.0, 10.0)
    assert step["invested"] > flat["invested"]
    assert step["future_value"] > flat["future_value"]

def test_currency_formatting():
    assert format_inr_words(0) == "₹0"
    assert format_inr_words(50000) == "50 Thousand"
    assert format_inr_words(100000) == "1 Lakh"
    assert format_inr_words(2500000) == "25 Lakh"
    assert format_inr_words(12500000) == "1.25 Crore"
    assert format_inr_words(50000000) == "5 Crore"
