"""Modification d'équipement depuis le mobile : proposition enregistrée dans la base intermédiaire (ClicClac)."""
import asyncio
from contextlib import contextmanager
from datetime import date

import pytest
from sqlalchemy import ColumnDefault, Date, create_engine, event
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

import app.services.equipment_service as equipment_service
from app.models.attribute_model import AttributeClicClac
from app.models.equipment_model import EquipmentClicClac


@pytest.fixture
def temp_db(monkeypatch):
    """Base intermédiaire remplacée par SQLite en mémoire (schéma « dbo » attaché)."""
    engine = create_engine("sqlite://", poolclass=StaticPool, connect_args={"check_same_thread": False})

    @event.listens_for(engine, "connect")
    def _attach_dbo(dbapi_connection, _record):
        dbapi_connection.execute("ATTACH DATABASE ':memory:' AS dbo")

    # Les colonnes Date utilisent func.now() (format MSSQL) : SQLite ne relit pas ce format,
    # on les remplace dans ce test par la date du jour calculée en Python.
    for table in (EquipmentClicClac.__table__, AttributeClicClac.__table__):
        for column in table.columns:
            if isinstance(column.type, Date):
                monkeypatch.setattr(column, "default", ColumnDefault(date.today))
                monkeypatch.setattr(column, "onupdate", ColumnDefault(date.today))
                monkeypatch.setattr(column, "server_default", None)
        table.create(engine)

    @contextmanager
    def fake_temp_session():
        with Session(engine) as session:
            yield session

    async def no_notification(*_args, **_kwargs):
        return None

    monkeypatch.setattr(equipment_service, "get_temp_session", fake_temp_session)
    monkeypatch.setattr(equipment_service, "get_user_connect", lambda _username: None)
    monkeypatch.setattr(equipment_service, "send_notification", no_notification)
    monkeypatch.setattr(equipment_service, "invalidate_statistics_cache", lambda: None)
    monkeypatch.setattr(equipment_service, "invalidate_equipment_insertion_cache", lambda *_a: None)
    monkeypatch.setattr(asyncio, "ensure_future", lambda coro: coro.close())
    return engine


def _update(value):
    return {
        "code": "EQ-TEST-001",
        "famille": "TRANSFO",
        "description": "Transformateur de test",
        "created_by": "agent.test",
        "attributs": [
            {"specification": "20395", "index": 1, "name": "PUISSANCE EN KVA", "value": value},
            {"specification": "20395", "index": 2, "name": "Numero de serie", "value": "SN-1"},
        ],
    }


def test_repeated_updates_replace_attributes_instead_of_duplicating(temp_db):
    ok_first, _ = equipment_service.update_equipment_mobile("1", _update("400"))
    ok_second, _ = equipment_service.update_equipment_mobile("1", _update("630"))

    assert ok_first and ok_second
    with Session(temp_db) as session:
        attributes = session.query(AttributeClicClac).filter_by(code="EQ-TEST-001").all()
        assert len(attributes) == 2
        assert {a.attribute_name: a.value for a in attributes}["PUISSANCE EN KVA"] == "630"

        proposals = session.query(EquipmentClicClac).filter_by(code="EQ-TEST-001").all()
        assert len(proposals) == 1
        assert proposals[0].is_update is True
