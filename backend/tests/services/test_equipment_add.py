"""Ajout d'équipement depuis le mobile : proposition enregistrée dans la base intermédiaire (ClicClac)."""
import asyncio

import pytest
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.attribute_model import AttributeClicClac
from app.models.equipment_model import EquipmentClicClac
from app.routers.mobile.equipment_router import add_equipment_mobile
from app.schemas.requests.equipment_request import AddEquipmentRequest

# Le test remplace asyncio.ensure_future : on garde la vraie boucle pour appeler la route.
_run = asyncio.new_event_loop().run_until_complete


def _request(code="EQ-NEW-001", **extra):
    return AddEquipmentRequest(
        code=code,
        famille="TRANSFO",
        zone="DAKAR",
        entity="SDDV",
        description="Nouveau transformateur",
        created_by="agent.test",
        attributs=[
            {"specification": "20395", "index": "1", "name": "PUISSANCE EN KVA", "value": "400"},
            # Rang absent : l'attribut doit être gardé quand même
            {"specification": "20395", "index": "", "name": "Numero de serie", "value": "SN-1"},
        ],
        **extra,
    )


def test_new_equipment_is_saved_as_a_proposal_with_all_its_attributes(temp_db):
    response = _run(add_equipment_mobile(_request()))

    assert response["status"] == "success"
    with Session(temp_db) as session:
        proposal = session.query(EquipmentClicClac).filter_by(code="EQ-NEW-001").one()
        assert proposal.is_new is True
        assert proposal.is_approved is False
        assert proposal.created_by == "agent.test"
        # Pas de coordonnées saisies : NULL, pas le texte « None »
        assert proposal.longitude is None and proposal.latitude is None

        attributes = session.query(AttributeClicClac).filter_by(code="EQ-NEW-001").all()
        assert {a.attribute_name: a.value for a in attributes} == {
            "PUISSANCE EN KVA": "400",
            "Numero de serie": "SN-1",
        }


def test_same_code_twice_gives_a_clear_conflict_error(temp_db):
    _run(add_equipment_mobile(_request()))

    with pytest.raises(HTTPException) as error:
        _run(add_equipment_mobile(_request()))

    assert error.value.status_code == 409
    assert "EQ-NEW-001" in error.value.detail
