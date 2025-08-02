"""
Requêtes SQL corrigées pour le projet SENELEC GMAO
"""

# --- Famille/Catégories (correspond à ereq_category dans t_equipment)
CATEGORY_QUERY = """
SELECT
    pk_category,
    mdct_code,
    mdct_description,
    mdct_parent_category,
    mdct_system_category,
    mdct_level,
    mdct_entity
FROM coswin.category
"""

# --- Feeder (Équipements de référence)
FEEDER_QUERY = """
SELECT
    ereq_code AS Code_Equipment_GMAO_REFERENCE,
    ereq_description AS Nom_Equipment,
    ereq_entity
FROM coswin.t_equipment
WHERE ereq_category IN (
    'DEPART30KV',   -- Feeder 30kV
    'DEPART6,6KV'   -- Feeder 6,6kV
)
ORDER BY ereq_code
"""

# --- Zone
ZONE_QUERY = """
SELECT 
    pk_zone,
    mdzo_code,
    mdzo_description,
    mdzo_entity 
FROM coswin.zone
ORDER BY mdzo_entity, mdzo_code
"""

# --- Entité
ENTITY_QUERY = """
SELECT
    pk_entity,
    chen_code,
    chen_description,
    chen_entity_type,
    chen_level,
    chen_parent_entity,
    chen_system_entity
FROM coswin.entity
WHERE chen_code IN (:placeholders)
ORDER BY chen_level, chen_code
"""

HIERARCHIC = """
SELECT COLUMN_VALUE as entity_code 
FROM TABLE(coswin.sn_hierarchie(:entity))
"""

# --- Centre de charges
COSTCENTRE_QUERY = """
SELECT 
    pk_costcentre,
    mdcc_code,
    mdcc_description,
    mdcc_entity 
FROM coswin.costcentre
"""

# --- Unité/Fonction (requête corrigée)
FUNCTION_QUERY = """
SELECT 
    pk_function_,
    mdfn_code,
    mdfn_description,
    mdfn_entity,
    mdfn_parent_function,
    mdfn_system_function 
FROM coswin.function_
ORDER BY mdfn_entity, mdfn_code
"""

# === REQUÊTES POUR LES SERVICES BACKEND ===

# Pour equipment_service.py
EQUIPMENT_INFINITE_QUERY = """
SELECT * FROM (
    SELECT 
        pk_equipment, 
        ereq_parent_equipment, 
        ereq_code, 
        ereq_category, 
        ereq_zone, 
        ereq_entity, 
        ereq_function,
        ereq_costcentre, 
        ereq_description, 
        ereq_longitude, 
        ereq_latitude,
        (SELECT pk_equipment FROM coswin.t_equipment t2 WHERE coswin.t_equipment.ereq_string2 = t2.ereq_code) as feeder,
        (SELECT ereq_description FROM coswin.t_equipment t2 WHERE coswin.t_equipment.ereq_string2 = t2.ereq_code) as feeder_description
    FROM coswin.t_equipment
    WHERE 1=1
"""

EQUIPMENT_BY_ID_QUERY = """
SELECT 
    pk_equipment, ereq_parent_equipment, ereq_code, ereq_category, ereq_zone, 
    ereq_entity, ereq_function, ereq_costcentre, ereq_description, 
    ereq_longitude, ereq_latitude,
    (SELECT pk_equipment FROM coswin.t_equipment t2 WHERE coswin.t_equipment.ereq_string2 = t2.ereq_code) as feeder,
    (SELECT ereq_description FROM coswin.t_equipment t2 WHERE coswin.t_equipment.ereq_string2 = t2.ereq_code) as feeder_description
FROM coswin.t_equipment 
WHERE pk_equipment = :equipment_id
"""


# Pour get_zones() dans equipment_service.py
GET_ZONES_QUERY = """
SELECT DISTINCT 
    mdzo_code,
    mdzo_description,
    mdzo_entity
FROM coswin.zone 
WHERE mdzo_code IS NOT NULL
ORDER BY mdzo_entity, mdzo_description
"""

# Pour get_familles() dans equipment_service.py
GET_FAMILLES_QUERY = """
SELECT DISTINCT 
    mdct_code,
    mdct_description,
    mdct_entity
FROM coswin.category 
WHERE mdct_code IS NOT NULL
ORDER BY mdct_entity, mdct_description
"""

# Pour get_entities() dans equipment_service.py
GET_ENTITIES_QUERY = """
SELECT DISTINCT 
    chen_code,
    chen_description,
    chen_entity_type
FROM coswin.entity 
WHERE chen_code IS NOT NULL
ORDER BY chen_entity_type, chen_description
"""

# Pour user_service.py
GET_USER_AUTHENTICATION_QUERY = """
SELECT 
    pk_coswin_user, 
    cwcu_code, 
    cwcu_signature, 
    cwcu_email, 
    cwcu_entity, 
    cwcu_preferred_group, 
    cwcu_url_image,
    cwcu_is_absent, 
    cwcu_password
FROM coswin.coswin_user
WHERE (cwcu_signature = :username OR cwcu_email = :username)
AND cwcu_password = :password
AND ROWNUM <= 1
"""
UPDATE_USER_QUERY = """
UPDATE coswin.coswin_user
SET 
    cwcu_code = :code,
    cwcu_signature = :signature,
    cwcu_email = :email,
    cwcu_entity = :entity,
    cwcu_preferred_group = :preferred_group,
    cwcu_url_image = :url_image,
    cwcu_is_absent = :is_absent
WHERE pk_coswin_user = :pk
"""
GET_USER_CONNECT_QUERY = """
SELECT 
    pk_coswin_user, 
    cwcu_code, 
    cwcu_signature, 
    cwcu_email, 
    cwcu_entity, 
    cwcu_preferred_group, 
    cwcu_url_image,
    cwcu_is_absent
FROM coswin.coswin_user
WHERE (cwcu_signature = :username OR cwcu_email = :username)
AND ROWNUM <= 1
"""

# === REQUÊTES DE STATISTIQUES ===

# Statistiques par entité
STATS_BY_ENTITY_QUERY = """
SELECT 
    ereq_entity,
    COUNT(*) as total_equipments,
    COUNT(DISTINCT ereq_category) as categories_count,
    COUNT(DISTINCT ereq_zone) as zones_count
FROM coswin.t_equipment 
GROUP BY ereq_entity
ORDER BY total_equipments DESC
"""

# Statistiques par catégorie
STATS_BY_CATEGORY_QUERY = """
SELECT 
    ereq_category,
    COUNT(*) as equipment_count,
    COUNT(DISTINCT ereq_entity) as entities_count
FROM coswin.t_equipment 
GROUP BY ereq_category
ORDER BY equipment_count DESC
"""