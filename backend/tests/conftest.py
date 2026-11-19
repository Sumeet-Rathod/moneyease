import os
import pytest
from app.database import engine, Base
from app.seed import seed_database

@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    # Clean recreate for deterministic test suite
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    seed_database()
    yield
