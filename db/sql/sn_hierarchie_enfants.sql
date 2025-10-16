-- Version corrigée pour correspondre exactement à la fonction Oracle
-- Retourne uniquement la colonne chen_code (entity_code)

CREATE OR ALTER FUNCTION dbo.sn_hierarchie_enfants(
    @my_entity NVARCHAR(255)
)
RETURNS TABLE
AS
RETURN
(
    WITH cte AS (
        -- Ancre : noeud racine
        SELECT
            t.chen_code,
            t.chen_parent_entity,
            1 AS hierarchy_level
        FROM dbo.entity AS t
        WHERE t.chen_code = @my_entity

        UNION ALL

        -- Récursion : descendants
        SELECT
            e.chen_code,
            e.chen_parent_entity,
            cte.hierarchy_level + 1
        FROM dbo.entity AS e
        INNER JOIN cte ON e.chen_parent_entity = cte.chen_code
    )
    -- Retourner uniquement chen_code pour correspondre à Oracle
    SELECT 
        chen_code AS entity_code
    FROM cte
    -- Note : ORDER BY ne peut pas être dans une TVF inline
    -- Le tri doit être fait côté appelant si nécessaire
);