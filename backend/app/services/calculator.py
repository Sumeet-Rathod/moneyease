import math
from typing import Dict, Any, List

def calculate_goal_projection(
    current_cost: float,
    years: float,
    saved_amount: float = 0.0,
    annual_return: float = 10.0,
    inflation_rate: float = 6.0,
    step_up_pct: float = 0.0
) -> Dict[str, Any]:
    """
    Computes inflation-adjusted future cost, existing savings future value,
    gap, required monthly SIP, lumpsum needed today, and year-by-year timeline.
    """
    if current_cost < 0:
        current_cost = 0.0
    if years <= 0:
        years = 1.0  # minimum 1 year
    if saved_amount < 0:
        saved_amount = 0.0

    i = inflation_rate / 100.0
    r_annual = annual_return / 100.0
    r_monthly = r_annual / 12.0
    n_months = int(round(years * 12))

    # 1. Inflation-adjusted future cost
    future_cost = current_cost * math.pow(1.0 + i, years)

    # 2. Future value of existing savings
    fv_saved = saved_amount * math.pow(1.0 + r_annual, years)

    # 3. Gap
    gap = max(future_cost - fv_saved, 0.0)

    # 4. Required monthly SIP (Annuity due: invested at beginning of month)
    if gap <= 0:
        required_sip = 0.0
    elif r_monthly > 0:
        denom = (math.pow(1.0 + r_monthly, n_months) - 1.0) * (1.0 + r_monthly)
        required_sip = (gap * r_monthly) / denom if denom > 0 else 0.0
    else:
        required_sip = gap / n_months if n_months > 0 else 0.0

    # 5. Lumpsum needed today to cover gap
    if gap <= 0:
        required_lumpsum = 0.0
    elif r_annual > 0:
        required_lumpsum = gap / math.pow(1.0 + r_annual, years)
    else:
        required_lumpsum = gap

    # 6. Step-up SIP simulation (if step_up_pct > 0, find starting SIP that yields gap)
    starting_step_up_sip = required_sip
    if step_up_pct > 0 and gap > 0:
        # Binary search / formula for starting SIP with step-up
        # Accumulation factor for base SIP of 1.0
        low = 1.0
        high = required_sip
        for _ in range(50):
            mid = (low + high) / 2.0
            fv_test = simulate_step_up_sip(mid, step_up_pct, annual_return, years)["future_value"]
            if abs(fv_test - gap) < 1.0:
                starting_step_up_sip = mid
                break
            elif fv_test < gap:
                low = mid
            else:
                high = mid
        starting_step_up_sip = round((low + high) / 2.0, 2)

    # 7. Year-by-year trajectory for charts
    trajectory = []
    accumulated_value = saved_amount
    total_invested = saved_amount
    current_sip = required_sip

    for year in range(1, int(math.ceil(years)) + 1):
        # 12 months in this year
        for m in range(12):
            total_invested += current_sip
            accumulated_value = (accumulated_value + current_sip) * (1.0 + r_monthly)

        trajectory.append({
            "year": year,
            "invested": round(total_invested, 2),
            "projected_value": round(accumulated_value, 2)
        })

    return {
        "current_cost": round(current_cost, 2),
        "years": round(years, 1),
        "saved_amount": round(saved_amount, 2),
        "inflation_rate": round(inflation_rate, 2),
        "assumed_return": round(annual_return, 2),
        "future_cost": round(future_cost, 2),
        "fv_saved": round(fv_saved, 2),
        "gap": round(gap, 2),
        "required_sip": round(required_sip, 2),
        "required_lumpsum": round(required_lumpsum, 2),
        "step_up_pct": round(step_up_pct, 2),
        "starting_step_up_sip": round(starting_step_up_sip, 2),
        "trajectory": trajectory
    }


def simulate_sip_future_value(
    monthly_investment: float,
    years: float,
    annual_return: float
) -> Dict[str, Any]:
    """
    Computes SIP future value for 'what if I invest X per month':
    FV = P * ((1 + r)^n - 1) / r * (1 + r)
    """
    if monthly_investment <= 0 or years <= 0:
        return {"invested": 0.0, "future_value": 0.0, "wealth_gain": 0.0}

    r_monthly = (annual_return / 100.0) / 12.0
    n_months = int(round(years * 12))
    total_invested = monthly_investment * n_months

    if r_monthly > 0:
        fv = monthly_investment * ((math.pow(1.0 + r_monthly, n_months) - 1.0) / r_monthly) * (1.0 + r_monthly)
    else:
        fv = total_invested

    return {
        "invested": round(total_invested, 2),
        "future_value": round(fv, 2),
        "wealth_gain": round(max(fv - total_invested, 0.0), 2)
    }


def simulate_step_up_sip(
    starting_sip: float,
    step_up_pct: float,
    annual_return: float,
    years: float
) -> Dict[str, Any]:
    """
    Simulates month-by-month investment where monthly SIP increases by step_up_pct each year.
    """
    r_monthly = (annual_return / 100.0) / 12.0
    total_months = int(round(years * 12))
    current_sip = starting_sip
    accumulated = 0.0
    total_invested = 0.0

    for m in range(total_months):
        # Increase SIP at the start of each new year (every 12 months, after month 0)
        if m > 0 and m % 12 == 0:
            current_sip *= (1.0 + step_up_pct / 100.0)
        total_invested += current_sip
        accumulated = (accumulated + current_sip) * (1.0 + r_monthly)

    return {
        "invested": round(total_invested, 2),
        "future_value": round(accumulated, 2),
        "wealth_gain": round(max(accumulated - total_invested, 0.0), 2)
    }


def format_inr_words(amount: float) -> str:
    """
    Converts Indian Rupee amounts into natural words (lakh / crore).
    e.g., 100000 -> '1 Lakh', 12500000 -> '1.25 Crore', 50000 -> '50 Thousand'
    """
    if amount is None or amount == 0:
        return "₹0"
    amt = abs(amount)
    if amt >= 10_000_000:
        cr = amt / 10_000_000.0
        return f"{cr:.2f}".rstrip('0').rstrip('.') + " Crore"
    elif amt >= 100_000:
        lakh = amt / 100_000.0
        return f"{lakh:.2f}".rstrip('0').rstrip('.') + " Lakh"
    elif amt >= 1_000:
        k = amt / 1_000.0
        return f"{k:.1f}".rstrip('0').rstrip('.') + " Thousand"
    else:
        return f"₹{amt:,.0f}"
