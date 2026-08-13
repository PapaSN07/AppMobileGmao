USE coswin_mock;
GO

-- Drop tables in reverse order of dependency if they exist
IF OBJECT_ID('dbo.workorder_attribute', 'U') IS NOT NULL DROP TABLE dbo.workorder_attribute;
IF OBJECT_ID('dbo.workorder_part', 'U') IS NOT NULL DROP TABLE dbo.workorder_part;
IF OBJECT_ID('dbo.workorder_workforce', 'U') IS NOT NULL DROP TABLE dbo.workorder_workforce;
IF OBJECT_ID('dbo.workorder_comment', 'U') IS NOT NULL DROP TABLE dbo.workorder_comment;
IF OBJECT_ID('dbo.workorder_operation', 'U') IS NOT NULL DROP TABLE dbo.workorder_operation;
GO

-- 1. Table for Operations (Mode Opératoire)
CREATE TABLE dbo.workorder_operation (
    pk_operation INT IDENTITY(1,1) NOT NULL,
    wowo_code BIGINT NOT NULL,
    operation_code VARCHAR(50) NOT NULL,
    description VARCHAR(255) NOT NULL,
    duration FLOAT NULL,
    CONSTRAINT PK_workorder_operation PRIMARY KEY (pk_operation),
    CONSTRAINT FK_workorder_operation_workorder FOREIGN KEY (wowo_code) REFERENCES dbo.workorder(wowo_code) ON DELETE CASCADE
);
GO

-- 2. Table for Comments (Commentaires / Feedbacks)
CREATE TABLE dbo.workorder_comment (
    pk_comment INT IDENTITY(1,1) NOT NULL,
    wowo_code BIGINT NOT NULL,
    comment_code VARCHAR(50) NOT NULL,
    content VARCHAR(MAX) NOT NULL,
    author VARCHAR(50) NULL,
    creation_date DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT PK_workorder_comment PRIMARY KEY (pk_comment),
    CONSTRAINT FK_workorder_comment_workorder FOREIGN KEY (wowo_code) REFERENCES dbo.workorder(wowo_code) ON DELETE CASCADE
);
GO

-- 3. Table for Workforce (Mains d'œuvre / Allocated Employees)
CREATE TABLE dbo.workorder_workforce (
    pk_workforce INT IDENTITY(1,1) NOT NULL,
    wowo_code BIGINT NOT NULL,
    employee_code VARCHAR(50) NOT NULL,
    employee_name VARCHAR(255) NULL,
    hours_planned FLOAT NULL,
    hours_spent FLOAT NULL,
    CONSTRAINT PK_workorder_workforce PRIMARY KEY (pk_workforce),
    CONSTRAINT FK_workorder_workforce_workorder FOREIGN KEY (wowo_code) REFERENCES dbo.workorder(wowo_code) ON DELETE CASCADE
);
GO

-- 4. Table for Parts (Matériel / Pieces / Stock Used)
CREATE TABLE dbo.workorder_part (
    pk_part INT IDENTITY(1,1) NOT NULL,
    wowo_code BIGINT NOT NULL,
    part_code VARCHAR(50) NOT NULL,
    description VARCHAR(255) NOT NULL,
    quantity FLOAT NOT NULL,
    unit VARCHAR(50) NULL,
    CONSTRAINT PK_workorder_part PRIMARY KEY (pk_part),
    CONSTRAINT FK_workorder_part_workorder FOREIGN KEY (wowo_code) REFERENCES dbo.workorder(wowo_code) ON DELETE CASCADE
);
GO

-- 5. Table for Attributes (Sous-attributs / Custom attributes)
CREATE TABLE dbo.workorder_attribute (
    pk_attribute INT IDENTITY(1,1) NOT NULL,
    wowo_code BIGINT NOT NULL,
    attribute_code VARCHAR(50) NOT NULL,
    value VARCHAR(255) NOT NULL,
    description VARCHAR(255) NULL,
    CONSTRAINT PK_workorder_attribute PRIMARY KEY (pk_attribute),
    CONSTRAINT FK_workorder_attribute_workorder FOREIGN KEY (wowo_code) REFERENCES dbo.workorder(wowo_code) ON DELETE CASCADE
);
GO
