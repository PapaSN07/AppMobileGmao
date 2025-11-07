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
GET_FAMILLES_QUERY = """
SELECT DISTINCT 
    mdct_code,
    mdct_description,
    mdct_entity
FROM category 
WHERE mdct_code IS NOT NULL
ORDER BY mdct_entity, mdct_description
"""

#   ================================================================================
#   REQUÊTES DE Feeder (Équipements de référence)
#   ================================================================================
FEEDER_QUERY = """
SELECT
    timestamp,
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
LEFT JOIN equipment_attribute ea ON es.timestamp_specs = ea.commonkey
LEFT JOIN specification s ON es.etes_specification = s.cwsp_code
LEFT JOIN attribute a ON (s.timestamp = a.cwat_specification AND ea.INDX = a.CWAT_INDEX)
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

EQUIPMENT_ADD_QUERY = """
INSERT INTO equipment (
    timestamp,
    ereq_code,
    ereq_bar_code,
    ereq_description,
    ereq_category,
    ereq_zone,
    ereq_entity,
    ereq_function,
    ereq_costcentre,
    ereq_longitude,
    ereq_latitude,
    ereq_string2,
    ereq_creation_date
) VALUES (
    :id,
    :code,
    :bar_code,
    :description,
    :category,
    :zone,
    :entity,
    :function,
    :costcentre,
    :longitude,
    :latitude,
    :feeder,
    :creation_date
)
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
LEFT JOIN equipment_attribute ea ON es.timestamp_specs = ea.commonkey
LEFT JOIN specification s ON es.etes_specification = s.cwsp_code
LEFT JOIN attribute a ON (s.timestamp = a.cwat_specification AND ea.INDX = a.CWAT_INDEX)
WHERE e.timestamp = :equipment_id
"""

EQUIPMENT_UPDATE_QUERY = """
UPDATE equipment 
SET 
    ereq_parent_equipment = :code_parent,
    ereq_code = :code,
    ereq_category = :famille,
    ereq_zone = :zone,
    ereq_entity = :entity,
    ereq_function = :unite,
    ereq_costcentre = :centre_charge,
    ereq_description = :description,
    ereq_longitude = :longitude,
    ereq_latitude = :latitude,
    ereq_string2 = :feeder
WHERE timestamp = :equipment_id
"""

UPDATE_EQUIPMENT_ATTRIBUTE_QUERY = """
UPDATE equipment_attribute 
SET etat_value = :value
WHERE commonkey = (
    SELECT es.timestamp_specs 
    FROM equipment_specs es
    JOIN specification s ON es.etes_specification = s.cwsp_code
    JOIN attribute a ON s.timestamp = a.cwat_specification
    WHERE es.etes_equipment = :equipment_code
    AND a.cwat_name = :attribute_name
)
AND indx = (
    SELECT a.cwat_index
    FROM equipment_specs es
    JOIN specification s ON es.etes_specification = s.cwsp_code
    JOIN attribute a ON s.timestamp = a.cwat_specification
    WHERE es.etes_equipment = :equipment_code
    AND a.cwat_name = :attribute_name
)
"""

EQUIPMENT_ATTRIBUTS_VALUES_QUERY = """
SELECT 
    a.pk_attribute as id, 
    a.cwat_specification as specification, 
    a.cwat_index as index_val, 
    a.cwat_name as name, 
    ea.etat_value as value
FROM 
    equipment e
    JOIN equipment_specs es ON e.ereq_code = es.etes_equipment
    JOIN equipment_attribute ea ON es.timestamp_specs = ea.commonkey
    JOIN specification s ON es.etes_specification = s.cwsp_code
    JOIN attribute a ON (s.timestamp = a.cwat_specification AND ea.INDX = a.CWAT_INDEX)
WHERE 
    e.ereq_code = :code
ORDER BY a.cwat_name
"""

EQUIPMENT_T_SPECIFICATION_QUERY = """
SELECT 
    cs.mdcs_specification,
    s.timestamp
FROM
    category c
    JOIN category_specification cs ON c.mdct_code = cs.mdcs_category
    JOIN specification s ON cs.mdcs_specification = s.cwsp_code
WHERE c.mdct_code LIKE :category
"""

EQUIPMENT_SPEC_ADD_QUERY = """
INSERT INTO equipment_specs (
    timestamp_specs,
    etes_specification,
    etes_equipment,
    etes_release_date,
    etes_release_number
) VALUES (
    :id,
    :specification,
    :equipment,
    :release_date,
    :release_number
)
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

EQUIPMENT_LENGTH_ATTRIBUTS_QUERY = """
SELECT
    a.cwat_index as len
FROM
    specification s
    JOIN category_specification cs ON cs.mdcs_specification = s.cwsp_code
    JOIN category r ON r.mdct_code = cs.mdcs_category
    JOIN attribute a ON s.timestamp = a.cwat_specification
WHERE r.mdct_code LIKE :category
ORDER BY a.cwat_index
"""

EQUIPMENT_ATTRIBUTE_ADD_QUERY = """
INSERT INTO equipment_attribute (
    commonkey,
    indx,
    etat_value
) VALUES (
    :commonkey,
    :indx,
    :etat_value
)
"""

# ✅ CORRIGÉ : Remplacer ROWNUM <= 1 par TOP 1
EQUIPMENT_T_SPECIFICATION_CODE_QUERY = """
SELECT TOP 1 s.cwsp_code
FROM equipment e
    JOIN category_specification cs ON e.ereq_category = cs.mdcs_category
    JOIN specification s ON cs.mdcs_specification = s.cwsp_code
WHERE e.ereq_category LIKE :category
"""

CHECK_ATTRIBUTE_EXISTS_QUERY = """
SELECT COUNT(*) FROM equipment_attribute 
WHERE commonkey = :commonkey AND indx = :indx
"""

EQUIPMENT_LENGTH_ATTRIBUTS_QUERY_DISTINCT = """
SELECT DISTINCT a.cwat_index
FROM specification s
JOIN category_specification cs ON s.cwsp_code = cs.mdcs_specification  
JOIN category r ON cs.mdcs_category = r.mdct_code
JOIN attribute a ON s.timestamp = a.cwat_specification
WHERE r.mdct_code LIKE :category
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

#   ================================================================================
#   REQUÊTES DE STATISTIQUES
#   ================================================================================
STATS_BY_ENTITY_QUERY = """
SELECT 
    ereq_entity,
    COUNT(*) as total_equipments,
    COUNT(DISTINCT ereq_category) as categories_count,
    COUNT(DISTINCT ereq_zone) as zones_count
FROM equipment 
GROUP BY ereq_entity
ORDER BY total_equipments DESC
"""

STATS_BY_CATEGORY_QUERY = """
SELECT 
    ereq_category,
    COUNT(*) as equipment_count,
    COUNT(DISTINCT ereq_entity) as entities_count
FROM equipment 
GROUP BY ereq_category
ORDER BY equipment_count DESC
"""