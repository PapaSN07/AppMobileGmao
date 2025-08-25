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
SELECT * FROM (
    SELECT 
        pk_equipment, 
        ereq_parent_equipment, 
        ereq_code, 
        ereq_category, 
        ereq_zone, 
        ereq_entity, 
        ereq_function,
        (SELECT mdcc_description FROM coswin.t_costcentre t2 WHERE coswin.t_equipment.ereq_costcentre = t2.mdcc_code AND ROWNUM = 1) as ereq_costcentre, 
        ereq_description, 
        ereq_longitude, 
        ereq_latitude,
        (SELECT pk_equipment FROM coswin.t_equipment t2 WHERE coswin.t_equipment.ereq_string2 = t2.ereq_code AND ROWNUM = 1) as feeder,
        (SELECT ereq_description FROM coswin.t_equipment t2 WHERE coswin.t_equipment.ereq_string2 = t2.ereq_code AND ROWNUM = 1) as feeder_description
    FROM coswin.t_equipment
    WHERE 1=1
"""
EQUIPMENT_ATTRIBUTS_VALUES_QUERY = """
SELECT a.pk_attribute, a.cwat_specification, a.cwat_index, a.cwat_name, ea.etat_value
FROM coswin.equipment_specs e, coswin.EQUIPMENT_ATTRIBUTE ea, coswin.t_specification s, coswin.attribute a, coswin.t_equipment t
WHERE t.ereq_code = e.etes_equipment 
    AND e.pk_equipment_specs = ea.commonkey
    AND e.etes_specification = s.cwsp_code
    AND s.pk_specification = a.cwat_specification
    AND ea.INDX = a.CWAT_INDEX
    AND t.ereq_code = :code
"""
ATTRIBUTE_VALUES_QUERY = """
SELECT pk_attribute_values, cwav_value
FROM coswin.attribute_values
WHERE 
    cwav_specification = :specification
    AND cwav_attribute_index = :attribute_index;
"""
EQUIPMENT_BY_ID_QUERY = """
SELECT 
    pk_equipment, ereq_parent_equipment, ereq_code, ereq_category, ereq_zone, 
    ereq_entity, ereq_function, ereq_costcentre, ereq_description, 
    ereq_longitude, ereq_latitude,
    (SELECT pk_equipment FROM coswin.t_equipment t2 WHERE coswin.t_equipment.ereq_string2 = t2.ereq_code) as feeder,
    (SELECT ereq_description FROM coswin.t_equipment t2 WHERE coswin.t_equipment.ereq_string2 = t2.ereq_code) as feeder_description
FROM coswin.t_equipment 
WHERE ereq_code = :code
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