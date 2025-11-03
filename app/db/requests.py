"""
Requêtes SQL corrigées pour MSSQL (SQL Server)
"""

#   ================================================================================
#   REQUÊTES DE Famille/Catégories
#   ================================================================================
CATEGORY_QUERY = """
SELECT
    pk_category,
    mdct_code,
    mdct_description,
    mdct_parent_category,
    mdct_system_category,
    mdct_level,
    mdct_entity
FROM category
"""

#   ================================================================================
#   REQUÊTES DE Feeder (Équipements de référence)
#   ================================================================================
FEEDER_QUERY = """
SELECT
    pk_equipment,
    ereq_code,
    ereq_description,
    ereq_entity
FROM equipment
"""

#   ================================================================================
#   REQUÊTES DE Zone
#   ================================================================================
ZONE_QUERY = """
SELECT 
    pk_zone,
    mdzo_code,
    mdzo_description,
    mdzo_entity 
FROM zone
"""

#   ================================================================================
#   REQUÊTES DE Entité
#   ================================================================================
ENTITY_QUERY = """
SELECT
    pk_entity,
    chen_code,
    chen_description,
    chen_entity_type,
    chen_level,
    chen_parent_entity,
    chen_system_entity
FROM entity
"""

#   ================================================================================
#   REQUÊTES DE Fonction Hiérarchie
#   ================================================================================
HIERARCHIC = """
SELECT chen_code AS entity_code
FROM sn_hierarchie_ancetres(:entity)
"""

#   ================================================================================
#   REQUÊTES DE Centre de charges
#   ================================================================================
COSTCENTRE_QUERY = """
SELECT 
    pk_costcentre,
    mdcc_code,
    mdcc_description,
    mdcc_entity 
FROM costcentre
"""

#   ================================================================================
#   REQUÊTES DE Unité (Fonction)
#   ================================================================================
FUNCTION_QUERY = """
SELECT 
    pk_function_,
    mdfn_code,
    mdfn_description,
    mdfn_entity,
    mdfn_parent_function,
    mdfn_system_function 
FROM function_
"""

#   ================================================================================
#   REQUÊTES DE Équipements
#   ================================================================================
EQUIPMENT_INFINITE_QUERY = """
SELECT 
    e.timestamp, 
    e.ereq_parent_equipment, 
    e.ereq_code, 
    e.ereq_category, 
    e.ereq_zone, 
    e.ereq_entity, 
    e.ereq_function,
    COALESCE(cc.mdcc_description, '') as ereq_costcentre, 
    e.ereq_description, 
    e.ereq_longitude, 
    e.ereq_latitude,
    f.timestamp as feeder,
    f.ereq_description as feeder_description,
    -- Attributs (peuvent être NULL si pas d'attributs)
    a.pk_attribute as attr_id,
    a.cwat_specification as attr_specification,
    a.cwat_index as attr_index,
    a.cwat_name as attr_name,
    ea.etat_value as attr_value
FROM equipment e
LEFT JOIN costcentre cc ON e.ereq_costcentre = cc.mdcc_code
LEFT JOIN equipment f ON e.ereq_string2 = f.ereq_code
LEFT JOIN equipment_specs es ON e.ereq_code = es.etes_equipment
LEFT JOIN equipment_attribute ea ON es.pk_equipment_specs = ea.commonkey
LEFT JOIN specification s ON es.etes_specification = s.cwsp_code
LEFT JOIN attribute a ON (s.pk_specification = a.cwat_specification AND ea.INDX = a.CWAT_INDEX)
WHERE 1=1
"""

ATTRIBUTE_VALUES_QUERY = """
SELECT
    pk_attribute_values, 
    cwav_value
FROM
    attribute_values
WHERE 1=1
    AND cwav_specification = :specification
    AND cwav_attribute_index = :attribute_index
"""

EQUIPMENT_BY_ID_QUERY = """
SELECT 
    e.timestamp, 
    e.ereq_parent_equipment, 
    e.ereq_code, 
    e.ereq_category, 
    e.ereq_zone, 
    e.ereq_entity, 
    e.ereq_function,
    COALESCE(cc.mdcc_description, '') as ereq_costcentre, 
    e.ereq_description, 
    e.ereq_longitude, 
    e.ereq_latitude,
    f.timestamp as feeder,
    f.ereq_description as feeder_description,
    a.pk_attribute as attr_id,
    a.cwat_specification as attr_specification,
    a.cwat_index as attr_index,
    a.cwat_name as attr_name,
    ea.etat_value as attr_value
FROM equipment e
LEFT JOIN costcentre cc ON e.ereq_costcentre = cc.mdcc_code
LEFT JOIN equipment f ON e.ereq_string2 = f.ereq_code
LEFT JOIN equipment_specs es ON e.ereq_code = es.etes_equipment
LEFT JOIN equipment_attribute ea ON es.pk_equipment_specs = ea.commonkey
LEFT JOIN specification s ON es.etes_specification = s.cwsp_code
LEFT JOIN attribute a ON (s.pk_specification = a.cwat_specification AND ea.INDX = a.CWAT_INDEX)
WHERE e.pk_equipment = :equipment_id
"""

EQUIPMENT_CLASSE_ATTRIBUTS_QUERY = """
SELECT
    a.pk_attribute as id, 
    a.cwat_specification as specification, 
    a.cwat_index as index_val, 
    a.cwat_name as name,
    NULL as value
FROM
    specification s
    JOIN category_specification cs ON cs.mdcs_specification = s.cwsp_code
    JOIN category r ON r.mdct_code = cs.mdcs_category
    JOIN attribute a ON s.timestamp = a.cwat_specification
WHERE r.mdct_code = :code
ORDER BY a.cwat_index
"""

#   ================================================================================
#   REQUÊTES DE Utilisateurs
#   ================================================================================
# ✅ CORRIGÉ : Remplacer ROWNUM <= 1 par TOP 1
GET_USER_AUTHENTICATION_QUERY = """
SELECT TOP 1
    pk_coswin_user, 
    cwcu_code, 
    cwcu_signature, 
    cwcu_email, 
    cwcu_entity, 
    cwcu_preferred_group, 
    cwcu_url_image,
    cwcu_is_absent, 
    cwcu_password
FROM coswin_user
WHERE (cwcu_signature = :username OR cwcu_email = :username)
AND cwcu_password = :password
"""

UPDATE_USER_QUERY = """
UPDATE coswin_user
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

# ✅ CORRIGÉ : Remplacer ROWNUM <= 1 par TOP 1
GET_USER_CONNECT_QUERY = """
SELECT TOP 1
    pk_coswin_user, 
    cwcu_code, 
    cwcu_signature, 
    cwcu_email, 
    cwcu_entity, 
    cwcu_preferred_group, 
    cwcu_url_image,
    cwcu_is_absent
FROM coswin_user
WHERE (cwcu_signature = :username OR cwcu_email = :username)
"""