-- =============================================================
--  create_local_schema.sql
--  Crée le schéma local pour les données extraites de Coswin
--  Exécuter dans la DB locale Docker : gmao_backend
-- =============================================================

USE master;
GO

-- Créer la base si elle n'existe pas
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'gmao_backend')
BEGIN
    CREATE DATABASE gmao_backend;
END
GO

USE gmao_backend;
GO

-- Créer le schéma dbo (existe déjà par défaut, au cas où)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dbo')
    EXEC('CREATE SCHEMA dbo');
GO

-- =============================================================
--  1. SPECIFICATION (doit exister avant attribute et equipment_specs)
-- =============================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.t_specification') AND type = 'U')
CREATE TABLE dbo.t_specification (
    pk_specification     INT           NOT NULL IDENTITY(1,1),
    cwsp_code            VARCHAR(50)   NOT NULL UNIQUE,
    cwsp_description     NVARCHAR(MAX) NULL,
    CONSTRAINT PK_specification PRIMARY KEY (pk_specification)
);
GO

-- =============================================================
--  2. ATTRIBUTE
-- =============================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.attribute') AND type = 'U')
CREATE TABLE dbo.attribute (
    pk_attribute         INT          NOT NULL IDENTITY(1,1),
    cwat_index           VARCHAR(10)  NOT NULL,
    cwat_specification   INT          NULL,
    cwat_name            NVARCHAR(255) NOT NULL,
    cwat_type            VARCHAR(50)  NULL DEFAULT 'string',
    CONSTRAINT PK_attribute PRIMARY KEY (pk_attribute)
);
GO

-- =============================================================
--  3. ATTRIBUTE_VALUES
-- =============================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.attribute_values') AND type = 'U')
CREATE TABLE dbo.attribute_values (
    pk_attribute_values  INT          NOT NULL IDENTITY(1,1),
    cwav_specification   VARCHAR(50)  NOT NULL,
    cwav_attribute_index VARCHAR(10)  NOT NULL,
    cwav_value           NVARCHAR(MAX) NOT NULL,
    CONSTRAINT PK_attribute_values PRIMARY KEY (pk_attribute_values)
);
GO

-- =============================================================
--  4. EQUIPMENT
-- =============================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.equipment') AND type = 'U')
CREATE TABLE dbo.equipment (
    timestamp              BIGINT        NOT NULL,   -- pk Coswin
    ereq_parent_equipment  VARCHAR(50)   NULL,
    ereq_code              VARCHAR(50)   NOT NULL,
    ereq_category          VARCHAR(50)   NOT NULL,
    ereq_zone              VARCHAR(50)   NOT NULL,
    ereq_entity            VARCHAR(50)   NOT NULL,
    ereq_function          VARCHAR(50)   NOT NULL,
    ereq_costcentre        VARCHAR(50)   NOT NULL,
    ereq_description       NVARCHAR(MAX) NOT NULL,
    ereq_longitude         FLOAT         NULL,
    ereq_latitude          FLOAT         NULL,
    ereq_string2           VARCHAR(255)  NULL,       -- feeder
    ereq_bar_code          VARCHAR(50)   NULL,
    ereq_creation_date     DATE          NULL,
    costcentre_description NVARCHAR(255) NULL,
    CONSTRAINT PK_equipment PRIMARY KEY (timestamp)
);
GO

CREATE INDEX IX_equipment_code   ON dbo.equipment (ereq_code);
CREATE INDEX IX_equipment_entity ON dbo.equipment (ereq_entity);
GO

-- =============================================================
--  5. EQUIPMENT_SPECS
-- =============================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.equipment_specs') AND type = 'U')
CREATE TABLE dbo.equipment_specs (
    timestamp_specs      BIGINT      NOT NULL,
    etes_specification   VARCHAR(50) NOT NULL,
    etes_equipment       VARCHAR(50) NOT NULL,
    etes_release_date    DATE        NULL,
    etes_release_number  INT         NULL DEFAULT 1,
    CONSTRAINT PK_equipment_specs PRIMARY KEY (timestamp_specs)
);
GO

-- =============================================================
--  6. EQUIPMENT_ATTRIBUTE
-- =============================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.equipment_attribute') AND type = 'U')
CREATE TABLE dbo.equipment_attribute (
    commonkey     BIGINT        NOT NULL,
    indx          VARCHAR(10)   NOT NULL,
    etat_value    NVARCHAR(MAX) NULL,
    CONSTRAINT PK_equipment_attribute PRIMARY KEY (commonkey, indx)
);
GO

-- =============================================================
--  7. CATEGORY_SPECIFICATION
-- =============================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.category_specification') AND type = 'U')
CREATE TABLE dbo.category_specification (
    mdcs_category      VARCHAR(50) NOT NULL,
    mdcs_specification VARCHAR(50) NOT NULL,
    CONSTRAINT PK_category_specification PRIMARY KEY (mdcs_category, mdcs_specification)
);
GO

-- =============================================================
--  8. WORK_ORDER  (OT — importés depuis l'API)
-- =============================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.work_order') AND type = 'U')
CREATE TABLE dbo.work_order (
    pk_work_order                INT           NOT NULL IDENTITY(1,1),
    wowo_pk                      INT           NULL,          -- pkWorkOrder Coswin
    wowo_code                    BIGINT        NULL,          -- wowoCode  (numéro OT)
    wowo_user_status             VARCHAR(10)   NULL,          -- CR, EN, CL...
    wowo_equipment               VARCHAR(50)   NULL,
    wowo_equipment_description   NVARCHAR(255) NULL,
    wowo_job                     VARCHAR(50)   NULL,
    wowo_job_type                VARCHAR(50)   NULL,          -- CORR, PREV...
    wowo_job_class               VARCHAR(50)   NULL,
    wowo_priority                VARCHAR(20)   NULL,
    wowo_action_entity           VARCHAR(50)   NULL,
    wowo_request_entity          VARCHAR(50)   NULL,
    wowo_schedule_date           DATETIME2     NULL,
    wowo_target_date             DATETIME2     NULL,
    wowo_start_date              DATETIME2     NULL,
    wowo_end_date                DATETIME2     NULL,
    wowo_job_request             VARCHAR(50)   NULL,          -- Code DI liée
    wowo_supervisor              VARCHAR(50)   NULL,
    wowo_costcentre              VARCHAR(50)   NULL,
    wowo_costcentre_description  NVARCHAR(255) NULL,
    wowo_zone                    VARCHAR(50)   NULL,
    wowo_function                VARCHAR(50)   NULL,
    wowo_feedback_note           NVARCHAR(MAX) NULL,
    mdjb_description             NVARCHAR(MAX) NULL,
    wowo_string1                 VARCHAR(255)  NULL,          -- charge travaux
    wowo_string2                 VARCHAR(255)  NULL,          -- nature travaux
    wowo_string4                 VARCHAR(255)  NULL,          -- société
    mdus_description             VARCHAR(100)  NULL,
    raw_json                     NVARCHAR(MAX) NULL,          -- JSON brut complet
    imported_at                  DATETIME2     DEFAULT GETDATE(),
    CONSTRAINT PK_work_order PRIMARY KEY (pk_work_order)
);
GO

CREATE INDEX IX_wo_code        ON dbo.work_order (wowo_code);
CREATE INDEX IX_wo_equipment   ON dbo.work_order (wowo_equipment);
CREATE INDEX IX_wo_status      ON dbo.work_order (wowo_user_status);
CREATE INDEX IX_wo_job_request ON dbo.work_order (wowo_job_request);
GO

-- =============================================================
--  9. WORK_REQUEST  (DI — demandes d'intervention)
-- =============================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.work_request') AND type = 'U')
CREATE TABLE dbo.work_request (
    pk_work_request              INT           NOT NULL IDENTITY(1,1),
    dinq_pk                      INT           NULL,          -- pkWorkRequest Coswin
    dinq_code                    VARCHAR(50)   NULL,          -- code DI (ex: DI00054258)
    dinq_user_status             VARCHAR(10)   NULL,
    dinq_equipment               VARCHAR(50)   NULL,
    dinq_equipment_description   NVARCHAR(255) NULL,
    dinq_job                     VARCHAR(50)   NULL,
    dinq_job_type                VARCHAR(50)   NULL,
    dinq_job_class               VARCHAR(50)   NULL,
    dinq_priority                VARCHAR(20)   NULL,
    dinq_action_entity           VARCHAR(50)   NULL,
    dinq_request_entity          VARCHAR(50)   NULL,
    dinq_ask_date                DATETIME2     NULL,
    dinq_target_date             DATETIME2     NULL,
    dinq_supervisor              VARCHAR(50)   NULL,
    dinq_costcentre              VARCHAR(50)   NULL,
    dinq_costcentre_description  NVARCHAR(255) NULL,
    dinq_zone                    VARCHAR(50)   NULL,
    dinq_function                VARCHAR(50)   NULL,
    dinq_description             NVARCHAR(MAX) NULL,
    raw_json                     NVARCHAR(MAX) NULL,
    imported_at                  DATETIME2     DEFAULT GETDATE(),
    CONSTRAINT PK_work_request PRIMARY KEY (pk_work_request)
);
GO

CREATE INDEX IX_wr_code      ON dbo.work_request (dinq_code);
CREATE INDEX IX_wr_equipment ON dbo.work_request (dinq_equipment);
CREATE INDEX IX_wr_status    ON dbo.work_request (dinq_user_status);
GO

PRINT '✅  Schéma gmao_backend créé avec succès';
GO
