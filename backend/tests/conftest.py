"""
Pytest configuration and shared fixtures.
This file is automatically loaded by pytest.
"""

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session
from typing import Generator

from app.main import app
from app.core.config import settings
from app.core.db import engine
from app.models import SQLModel, UserCreate
from app.crud import create_user


# ============================================================================
# Database Fixtures
# ============================================================================

@pytest.fixture(scope="session")
def db_engine():
    """Return the database engine for testing."""
    return engine


@pytest.fixture(scope="function")
def db_session(db_engine) -> Generator[Session, None, None]:
    """Create a fresh database session for each test."""
    # Optional: Create tables if they don't exist
    SQLModel.metadata.create_all(db_engine)
    
    with Session(db_engine) as session:
        yield session
        session.rollback()


# ============================================================================
# API Client Fixtures
# ============================================================================

@pytest.fixture
def client() -> TestClient:
    """Create a test client for FastAPI app."""
    return TestClient(app)


@pytest.fixture
def authenticated_client(client) -> TestClient:
    """Create an authenticated test client with a normal user."""
    # First, create a test user
    user_data = UserCreate(
        email="testuser@example.com",
        password="testpassword123",
        full_name="Test User"
    )
    
    response = client.post(
        f"{settings.API_V1_STR}/users/signup",
        json=user_data.model_dump()
    )
    
    # Login to get token
    response = client.post(
        f"{settings.API_V1_STR}/login/access-token",
        data={
            "username": "testuser@example.com",
            "password": "testpassword123"
        }
    )
    token = response.json()["access_token"]
    client.headers.update({"Authorization": f"Bearer {token}"})
    return client


@pytest.fixture
def superuser_client(client) -> TestClient:
    """Create an authenticated superuser client."""
    # Note: You need to have a superuser in the database
    # This fixture assumes FIRST_SUPERUSER exists
    response = client.post(
        f"{settings.API_V1_STR}/login/access-token",
        data={
            "username": settings.FIRST_SUPERUSER,
            "password": settings.FIRST_SUPERUSER_PASSWORD
        }
    )
    token = response.json()["access_token"]
    client.headers.update({"Authorization": f"Bearer {token}"})
    return client


# ============================================================================
# Test Data Fixtures
# ============================================================================

@pytest.fixture
def sample_item_data():
    """Sample item data for tests."""
    return {
        "title": "Test Item",
        "description": "This is a test item description",
        "price": 29.99
    }


@pytest.fixture
def sample_user_data():
    """Sample user data for tests."""
    return {
        "email": "newuser@example.com",
        "password": "newpassword123",
        "full_name": "New User"
    }


# ============================================================================
# Mock Fixtures
# ============================================================================

@pytest.fixture
def mock_email_service(monkeypatch):
    """Mock email sending for tests that don't need real email."""
    def mock_send_email(*args, **kwargs):
        return True
    
    monkeypatch.setattr("app.utils.send_email", mock_send_email)
    return mock_send_email


# ============================================================================
# Helper Functions
# ============================================================================

@pytest.fixture
def create_test_user(db_session):
    """Factory fixture to create test users on demand."""
    def _create_user(email, password="testpass123", full_name="Test User"):
        user_data = UserCreate(
            email=email,
            password=password,
            full_name=full_name
        )
        return create_user(session=db_session, user_create=user_data)
    return _create_user
