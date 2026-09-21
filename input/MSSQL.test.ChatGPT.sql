-- Présence dans ce script de :
-- PK simple		NULL     déclarée au niveau colonne > impossible (une PK ne peut être NULL)
-- PK simple	    NOT NULL déclarée au niveau colonne > oui
-- PK composite	NULL	 déclarée au niveau colonne > impossible (une PK/FK composite ne peut être déclarée au niveau colonne)
-- PK composite	NOT NULL déclarée au niveau colonne > impossible (une PK/FK composite ne peut être déclarée au niveau colonne)
-- PK simple		NULL     déclarée au niveau table   > impossible (une PK ne peut être NULL)
-- PK simple	    NOT NULL déclarée au niveau table   > oui
-- PK composite	NULL	 déclarée au niveau table   > impossible (une PK ne peut être NULL)
-- PK composite	NOT NULL déclarée au niveau table   > oui
-- PK simple		NULL     déclarée au niveau ALTER   > impossible (une PK ne peut être NULL)
-- PK simple	    NOT NULL déclarée au niveau ALTER   > oui
-- PK composite	NULL	 déclarée au niveau ALTER   > impossible (une PK ne peut être NULL)
-- PK composite	NOT NULL déclarée au niveau ALTER   > oui
-- FK simple		NULL     déclarée au niveau colonne > oui
-- FK simple	    NOT NULL déclarée au niveau colonne > ************NON
-- FK composite	NULL	 déclarée au niveau colonne > impossible (une PK/FK composite ne peut être déclarée au niveau colonne)
-- FK composite	NOT NULL déclarée au niveau colonne > impossible (une PK/FK composite ne peut être déclarée au niveau colonne)
-- FK simple		NULL     déclarée au niveau table   > oui
-- FK simple	    NOT NULL déclarée au niveau table   > oui
-- FK composite	NULL	 déclarée au niveau table   > oui
-- FK composite	NOT NULL déclarée au niveau table   > oui
-- FK simple		NULL     déclarée au niveau ALTER   > oui
-- FK simple	    NOT NULL déclarée au niveau ALTER   > oui
-- FK composite	NULL	 déclarée au niveau ALTER   > oui
-- FK composite	NOT NULL déclarée au niveau ALTER   > oui

CREATE DATABASE BaseTestCles;
GO
USE BaseTestCles;
GO

-- ============================================================
-- 1. CLES PRIMAIRES : définition au niveau colonne
-- ============================================================
CREATE TABLE Client_Colonne (
    IdClient INT PRIMARY KEY, -- PK simple	    NOT NULL déclarée au niveau colonne
    Nom NVARCHAR(100)
);
GO

-- 2. CLE PRIMAIRE : définition au niveau table
CREATE TABLE Client_Table (
    IdClient INT NOT NULL,
    Nom NVARCHAR(100),
    CONSTRAINT PK_Client_Table PRIMARY KEY (IdClient) -- PK simple
);
GO

-- 3. CLE PRIMAIRE COMPOSITE : niveau table
CREATE TABLE Produit (
    IdProduit INT NOT NULL,
    VersionProduit INT NOT NULL,
    Nom NVARCHAR(100),
    CONSTRAINT PK_Produit PRIMARY KEY (IdProduit, VersionProduit) -- PK composite
);
GO

-- 4. FK simple inline au niveau colonne
CREATE TABLE Commande_Colonne (
    IdCommande INT PRIMARY KEY, -- PK simple	    NOT NULL déclarée au niveau colonne
    IdClient INT REFERENCES Client_Colonne(IdClient), -- FK simple
    DateCommande DATE
);
GO

-- 5. FK simple au niveau table
CREATE TABLE Commande_Table (
    IdCommande INT PRIMARY KEY, -- PK simple	    NOT NULL déclarée au niveau colonne
    IdClient INT,
    DateCommande DATE,
    CONSTRAINT FK_Commande_Table_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Table(IdClient)
);
GO

-- 6. FK composite au niveau table
CREATE TABLE LigneProduit (
    IdLigne INT PRIMARY KEY, -- PK simple	    NOT NULL déclarée au niveau colonne
    IdProduit INT NOT NULL,
    VersionProduit INT NOT NULL,
    Quantite INT,
    CONSTRAINT FK_LigneProduit_Produit
        FOREIGN KEY (IdProduit, VersionProduit)
        REFERENCES Produit(IdProduit, VersionProduit)
);
GO

-- ============================================================
-- 7. FK déclarée après création avec ALTER TABLE
-- ============================================================
CREATE TABLE Facture (
    IdFacture INT PRIMARY KEY, -- PK simple	    NOT NULL déclarée au niveau colonne
    IdClient INT NULL,
    Montant DECIMAL(10,2)
);
GO

ALTER TABLE Facture
ADD CONSTRAINT FK_Facture_Client
    FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient);
GO

-- ============================================================
-- 8. Cardinalité 1..n : FK NOT NULL non UNIQUE
-- ============================================================
CREATE TABLE Commande_1N (
    IdCommande INT PRIMARY KEY, -- PK simple	    NOT NULL déclarée au niveau colonne
    IdClient INT NOT NULL,
    CONSTRAINT FK_Commande_1N_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);
GO

-- ============================================================
-- 9. Cardinalité 0..n : FK NULL non UNIQUE
-- ============================================================
CREATE TABLE Facture_0N (
    IdFacture INT PRIMARY KEY, -- PK simple	    NOT NULL déclarée au niveau colonne
    IdClient INT NULL,
    CONSTRAINT FK_Facture_0N_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);
GO

-- ============================================================
-- 10. Cardinalité 1..1 / 1..0..1 : FK UNIQUE NOT NULL
-- ============================================================
CREATE TABLE CompteClient_11 (
    IdCompte INT PRIMARY KEY, -- PK simple	    NOT NULL déclarée au niveau colonne
    IdClient INT NOT NULL UNIQUE,
    CONSTRAINT FK_CompteClient_11_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);
GO

-- Variante : UNIQUE déclaré au niveau table
CREATE TABLE CarteClient (
    IdCarte INT PRIMARY KEY, -- PK simple	    NOT NULL déclarée au niveau colonne
    IdClient INT NOT NULL,
    CONSTRAINT UQ_CarteClient_Client UNIQUE (IdClient),
    CONSTRAINT FK_CarteClient_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);
GO

-- ============================================================
-- 11. Cardinalité 0..1 : FK UNIQUE nullable
-- ============================================================
CREATE TABLE ProfilClient (
    IdProfil INT PRIMARY KEY, -- PK simple	    NOT NULL déclarée au niveau colonne
    IdClient INT NULL,
    CONSTRAINT UQ_ProfilClient_Client UNIQUE (IdClient),
    CONSTRAINT FK_ProfilClient_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);
GO

-- ============================================================
-- 12. n..n : table d'association avec PK composite
-- ============================================================
CREATE TABLE Client_Produit (
    IdClient INT NOT NULL,
    IdProduit INT NOT NULL,
    VersionProduit INT NOT NULL,
    CONSTRAINT PK_Client_Produit PRIMARY KEY (IdClient, IdProduit, VersionProduit), -- PK composite
    CONSTRAINT FK_Client_Produit_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient),
    CONSTRAINT FK_Client_Produit_Produit
        FOREIGN KEY (IdProduit, VersionProduit)
        REFERENCES Produit(IdProduit, VersionProduit)
);
GO

-- ============================================================
-- 13. FK composite déclarée par ALTER TABLE
-- ============================================================
CREATE TABLE HistoriqueProduit (
    IdHistorique INT PRIMARY KEY, -- PK simple	    NOT NULL déclarée au niveau colonne
    IdProduit INT NOT NULL,
    VersionProduit INT NOT NULL
);
GO

ALTER TABLE HistoriqueProduit
ADD CONSTRAINT FK_HistoriqueProduit_Produit
    FOREIGN KEY (IdProduit, VersionProduit)
    REFERENCES Produit(IdProduit, VersionProduit);
GO

-- ============================================================
-- 14. FK SIMPLE NULLABLE INLINE (niveau colonne)
-- ============================================================
CREATE TABLE Adresse_Colonne_Nullable (
    IdAdresse INT PRIMARY KEY, -- PK simple	    NOT NULL déclarée au niveau colonne
    IdClient INT NULL REFERENCES Client_Colonne(IdClient), -- FK simple
    Libelle NVARCHAR(100)
);
GO

-- ============================================================
-- 15. FK SIMPLE NULLABLE (niveau table)
-- ============================================================
CREATE TABLE Adresse_Table_Nullable (
    IdAdresse INT PRIMARY KEY, -- PK simple	    NOT NULL déclarée au niveau colonne
    IdClient INT NULL,
    Libelle NVARCHAR(100),
    CONSTRAINT FK_Adresse_Table_Nullable_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);
GO

-- ============================================================
-- 16. FK COMPOSITE NULLABLE déclarée par ALTER TABLE
-- ============================================================
CREATE TABLE HistoriqueProduit_Nullable (
    IdHistorique INT PRIMARY KEY, -- PK simple	    NOT NULL déclarée au niveau colonne
    IdProduit INT NULL,
    VersionProduit INT NULL
);
GO

ALTER TABLE HistoriqueProduit_Nullable
ADD CONSTRAINT FK_HistoriqueProduit_Nullable_Produit
    FOREIGN KEY (IdProduit, VersionProduit)
    REFERENCES Produit(IdProduit, VersionProduit);
GO
