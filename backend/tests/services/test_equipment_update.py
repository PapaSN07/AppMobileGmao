"""Modification d'équipement depuis le mobile : proposition enregistrée dans la base intermédiaire (ClicClac)."""
from sqlalchemy.orm import Session

import app.services.equipment_service as equipment_service
from app.models.attribute_model import AttributeClicClac
from app.models.equipment_model import EquipmentClicClac


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
