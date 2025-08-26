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
FROM coswin.t_category
"""
GET_FAMILLES_QUERY = """
SELECT DISTINCT 
    mdct_code,
    mdct_description,
    mdct_entity
FROM coswin.category 
WHERE mdct_code IS NOT NULL
ORDER BY mdct_entity, mdct_description
"""

# --- Feeder (Équipements de référence)
FEEDER_QUERY = """
SELECT
    pk_equipment,
    ereq_code AS Code_Equipment_GMAO_REFERENCE,
    ereq_description AS Nom_Equipment,
    ereq_entity
FROM coswin.t_equipment
"""

# --- Zone
ZONE_QUERY = """
SELECT 
    pk_zone,
    mdzo_code,
    mdzo_description,
    mdzo_entity 
FROM coswin.t_zone
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
FROM coswin.t_entity
"""

# --- Fonction Hiérarchie
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
FROM coswin.t_costcentre
"""

# --- Unité (Fonction)
FUNCTION_QUERY = """
SELECT 
    pk_function_,
    mdfn_code,
    mdfn_description,
    mdfn_entity,
    mdfn_parent_function,
    mdfn_system_function 
FROM coswin.t_function_
"""

# --- Équipements
EQUIPMENT_INFINITE_QUERY = """
SELECT 
    e.pk_equipment, 
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
    f.pk_equipment as feeder,
    f.ereq_description as feeder_description,
    -- Attributs (peuvent être NULL si pas d'attributs)
    a.pk_attribute as attr_id,
    a.cwat_specification as attr_specification,
    a.cwat_index as attr_index,
    a.cwat_name as attr_name,
    ea.etat_value as attr_value
FROM coswin.t_equipment e
LEFT JOIN coswin.t_costcentre cc ON e.ereq_costcentre = cc.mdcc_code
LEFT JOIN coswin.t_equipment f ON e.ereq_string2 = f.ereq_code
LEFT JOIN coswin.equipment_specs es ON e.ereq_code = es.etes_equipment
LEFT JOIN coswin.EQUIPMENT_ATTRIBUTE ea ON es.pk_equipment_specs = ea.commonkey
LEFT JOIN coswin.t_specification s ON es.etes_specification = s.cwsp_code
LEFT JOIN coswin.attribute a ON (s.pk_specification = a.cwat_specification AND ea.INDX = a.CWAT_INDEX)
WHERE 1=1
"""
ATTRIBUTE_VALUES_QUERY = """
SELECT
    pk_attribute_values, 
    cwav_value
FROM
    coswin.attribute_values
WHERE 1=1
    AND cwav_specification = :specification
    AND cwav_attribute_index = :attribute_index
"""
EQUIPMENT_ADD_QUERY = """
INSERT INTO coswin.t_equipment (
    ereq_code,
    ereq_description,
    ereq_category,
    ereq_zone,
    ereq_entity,
    ereq_function,
    ereq_costcentre,
    ereq_longitude,
    ereq_latitude,
    ereq_string2
) VALUES (
    :code,
    :description,
    :category,
    :zone,
    :entity,
    :function,
    :costcentre,
    :longitude,
    :latitude,
    :feeder
)
"""
# Récupère les spécifications de l'équipement à partir de la catégorie
EQUIPMENT_T_SPECIFICATION_QUERY = """
SELECT 
    cs.mdcs_specification
    , s.pk_specification
FROM
    coswin.t_category c,
    coswin.category_specification cs,
    coswin.t_specification s
WHERE 1=1
    AND c.mdct_code = cs.mdcs_category
    AND cs.mdcs_specification = s.cwsp_code
    AND c.mdct_code LIKE :category -- ereq_category (t_equipment)
"""
EQUIPMENT_SPEC_ADD_QUERY = """
INSERT INTO coswin.equipment_specs (
    etes_specification,
    etes_equipment,
    etes_release_date
) VALUES (
    :specification, -- cwsp_code (t_specification)
    :equipment, -- ereq_code (t_equipment)
    :release_date
)
"""
EQUIPMENT_CLASSE_ATTRIBUTS_QUERY = """
SELECT
    a.*
FROM
    coswin.t_specification s
    , coswin.category_specification cs
    , coswin.t_category r
    , coswin.attribute a
WHERE 1=1
    AND cs.mdcs_specification = s.cwsp_code
    AND r.mdct_code = cs.mdcs_category
    AND  s.pk_specification = a.cwat_specification
    AND r.mdct_code LIKE :category -- ereq_category (t_equipment)
"""
EQUIPMENT_CLASSE_ATTRIBUTS_ADD_QUERY = """
INSERT INTO coswin.equipment_attribute (
    commonkey,
    indx,
) VALUES (
    :specification, -- pk_equipment (equipment_specs)
    :index -- CWAT_INDEX (attribute)
)
"""

# --- Utilisateurs
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