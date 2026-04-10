import pytest
from pydantic import ValidationError

from app.models import ItemCreate, UserCreate


def test_user_create_validates_minimum_password_length() -> None:
    with pytest.raises(ValidationError):
        UserCreate(email="short-password@example.com", password="short")


def test_item_create_accepts_required_title() -> None:
    item = ItemCreate(title="Smoke test item", description="Unit-test payload")

    assert item.title == "Smoke test item"
