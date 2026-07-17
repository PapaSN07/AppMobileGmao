-- Create database if not exists
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'coswin_mock')
BEGIN
    CREATE DATABASE coswin_mock;
END
GO

USE coswin_mock;
GO

-- Drop tables if exist in reverse dependency order
IF OBJECT_ID('dbo.workorder', 'U') IS NOT NULL DROP TABLE dbo.workorder;
IF OBJECT_ID('dbo.equipment', 'U') IS NOT NULL DROP TABLE dbo.equipment;
IF OBJECT_ID('dbo.coswin_user', 'U') IS NOT NULL DROP TABLE dbo.coswin_user;
IF OBJECT_ID('dbo.costcentre', 'U') IS NOT NULL DROP TABLE dbo.costcentre;
IF OBJECT_ID('dbo.entity', 'U') IS NOT NULL DROP TABLE dbo.entity;
IF OBJECT_ID('dbo.zone', 'U') IS NOT NULL DROP TABLE dbo.zone;
IF OBJECT_ID('dbo.category', 'U') IS NOT NULL DROP TABLE dbo.category;
IF OBJECT_ID('dbo.workorder_validation_status', 'U') IS NOT NULL DROP TABLE dbo.workorder_validation_status;

-- Create Reference tables
CREATE TABLE dbo.category (
    pk_category INT IDENTITY(1,1) NOT NULL,
    mdct_code VARCHAR(50) NOT NULL,
    mdct_description VARCHAR(255) NOT NULL,
    mdct_parent_category VARCHAR(50) NULL,
    mdct_system_category VARCHAR(50) NULL,
    mdct_level INT NULL,
    mdct_entity VARCHAR(50) NULL,
    CONSTRAINT PK_category PRIMARY KEY (pk_category),
    CONSTRAINT UQ_category_mdct_code UNIQUE (mdct_code)
);

CREATE TABLE dbo.zone (
    pk_zone INT IDENTITY(1,1) NOT NULL,
    mdzo_code VARCHAR(50) NOT NULL,
    mdzo_description VARCHAR(255) NOT NULL,
    mdzo_entity VARCHAR(50) NULL,
    CONSTRAINT PK_zone PRIMARY KEY (pk_zone),
    CONSTRAINT UQ_zone_mdzo_code UNIQUE (mdzo_code)
);

CREATE TABLE dbo.entity (
    pk_entity INT IDENTITY(1,1) NOT NULL,
    chen_code VARCHAR(50) NOT NULL,
    chen_description VARCHAR(255) NOT NULL,
    chen_entity_type VARCHAR(50) NOT NULL,
    chen_level INT NOT NULL,
    chen_parent_entity VARCHAR(50) NULL,
    chen_system_entity VARCHAR(50) NULL,
    CONSTRAINT PK_entity PRIMARY KEY (pk_entity),
    CONSTRAINT UQ_entity_chen_code UNIQUE (chen_code)
);

CREATE TABLE dbo.costcentre (
    pk_costcentre INT IDENTITY(1,1) NOT NULL,
    mdcc_code VARCHAR(50) NOT NULL,
    mdcc_description VARCHAR(255) NOT NULL,
    mdcc_entity VARCHAR(50) NULL,
    CONSTRAINT PK_costcentre PRIMARY KEY (pk_costcentre),
    CONSTRAINT UQ_costcentre_mdcc_code UNIQUE (mdcc_code)
);

CREATE TABLE dbo.coswin_user (
    pk_coswin_user INT IDENTITY(1,1) NOT NULL,
    cwcu_code VARCHAR(50) NOT NULL,
    cwcu_signature VARCHAR(255) NOT NULL,
    cwcu_password VARCHAR(255) NULL,
    cwcu_email VARCHAR(255) NULL,
    cwcu_entity VARCHAR(50) NULL,
    cwcu_preferred_group VARCHAR(50) NULL,
    cwcu_url_image VARCHAR(255) NULL,
    cwcu_is_absent INT NULL,
    CONSTRAINT PK_coswin_user PRIMARY KEY (pk_coswin_user),
    CONSTRAINT UQ_coswin_user_cwcu_code UNIQUE (cwcu_code)
);

CREATE TABLE dbo.equipment (
    pk_equipment INT IDENTITY(1,1) NOT NULL,
    ereq_parent_equipment VARCHAR(50) NULL,
    ereq_code VARCHAR(50) NOT NULL,
    ereq_category VARCHAR(50) NOT NULL,
    ereq_zone VARCHAR(50) NOT NULL,
    ereq_entity VARCHAR(50) NOT NULL,
    ereq_function VARCHAR(50) NOT NULL,
    ereq_costcentre VARCHAR(50) NOT NULL,
    ereq_description VARCHAR(MAX) NOT NULL,
    ereq_longitude FLOAT NULL,
    ereq_latitude FLOAT NULL,
    ereq_string2 VARCHAR(50) NULL,
    ereq_bar_code VARCHAR(50) NULL,
    ereq_creation_date DATE NULL,
    CONSTRAINT PK_equipment PRIMARY KEY (pk_equipment),
    CONSTRAINT UQ_equipment_ereq_code UNIQUE (ereq_code)
);

-- Create WorkOrder table with Foreign Keys pointing to the local reference tables inside coswin_mock
CREATE TABLE dbo.workorder (
    pk_workorder INT IDENTITY(1,1) NOT NULL,
    wowo_code BIGINT NOT NULL,
    wowo_user_status VARCHAR(50) NOT NULL,
    wowo_equipment VARCHAR(50) NULL,
    wowo_job VARCHAR(255) NOT NULL,
    wowo_job_type VARCHAR(50) NULL,
    wowo_job_class VARCHAR(50) NULL,
    wowo_priority VARCHAR(50) NULL,
    wowo_action_entity VARCHAR(50) NULL,
    wowo_request_entity VARCHAR(50) NULL,
    wowo_schedule_date DATETIME2 NULL,
    wowo_supervisor VARCHAR(50) NULL,
    wowo_costcentre VARCHAR(50) NULL,
    wowo_target_date DATETIME2 NULL,
    wowo_start_date DATETIME2 NULL,
    wowo_end_date DATETIME2 NULL,
    wowo_zone VARCHAR(50) NULL,
    wowo_function VARCHAR(50) NULL,
    wowo_feedback_note VARCHAR(MAX) NULL,
    wowo_equipment_description VARCHAR(255) NULL,
    wowo_string1 VARCHAR(50) NULL,
    wowo_string2 VARCHAR(50) NULL,
    wowo_string4 VARCHAR(50) NULL,
    mdjb_description VARCHAR(MAX) NULL,
    mdus_description VARCHAR(100) NULL,
    wowo_action_entity_description VARCHAR(255) NULL,
    wowo_costcentre_description VARCHAR(255) NULL,
    wowo_job_class_description VARCHAR(255) NULL,
    wowo_job_type_description VARCHAR(100) NULL,
    wowo_supervisor_description VARCHAR(255) NULL,

    CONSTRAINT PK_workorder PRIMARY KEY (pk_workorder),
    CONSTRAINT UQ_workorder_wowo_code UNIQUE (wowo_code),
    
    -- Foreign Keys pointing to local reference tables inside coswin_mock
    CONSTRAINT FK_workorder_equipment FOREIGN KEY (wowo_equipment) REFERENCES dbo.equipment(ereq_code),
    CONSTRAINT FK_workorder_supervisor FOREIGN KEY (wowo_supervisor) REFERENCES dbo.coswin_user(cwcu_code),
    CONSTRAINT FK_workorder_costcentre FOREIGN KEY (wowo_costcentre) REFERENCES dbo.costcentre(mdcc_code),
    CONSTRAINT FK_workorder_action_entity FOREIGN KEY (wowo_action_entity) REFERENCES dbo.entity(chen_code),
    CONSTRAINT FK_workorder_request_entity FOREIGN KEY (wowo_request_entity) REFERENCES dbo.entity(chen_code),
    CONSTRAINT FK_workorder_zone FOREIGN KEY (wowo_zone) REFERENCES dbo.zone(mdzo_code),
    CONSTRAINT FK_workorder_job_class FOREIGN KEY (wowo_job_class) REFERENCES dbo.category(mdct_code)
);

CREATE TABLE dbo.workorder_validation_status (
    pk_validation_status INT IDENTITY(1,1) NOT NULL,
    current_status VARCHAR(50) NOT NULL,
    next_status VARCHAR(50) NOT NULL,
    description VARCHAR(255) NULL,
    CONSTRAINT PK_workorder_validation_status PRIMARY KEY (pk_validation_status)
);
