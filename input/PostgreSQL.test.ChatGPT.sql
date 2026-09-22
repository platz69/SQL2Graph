-- Présence dans ce script de :
-- PK simple	 déclarée au niveau colonne         >
-- PK simple	 déclarée au niveau table           >
-- PK composite	 déclarée au niveau table           >
-- PK simple	 déclarée au niveau ALTER           >
-- PK composite	 déclarée au niveau ALTER           >
-- FK simple	NULL     déclarée au niveau colonne >
-- FK simple	NOT NULL déclarée au niveau colonne >
-- FK simple	NULL     déclarée au niveau table   >
-- FK simple	NOT NULL déclarée au niveau table   >
-- FK composite NULL	 déclarée au niveau table   >
-- FK composite NOT NULL déclarée au niveau table   >
-- FK simple	NULL     déclarée au niveau ALTER   >
-- FK simple	NOT NULL déclarée au niveau ALTER   >
-- FK composite	NULL	 déclarée au niveau ALTER   >
-- FK composite	NOT NULL déclarée au niveau ALTER   >

CREATE DATABASE BaseTestCles;
/*
  PostgreSQL : exécuter ensuite ce script connecté à BaseTestCles.
*/

-- ============================================================
-- 1. CLES PRIMAIRES : définition au niveau colonne
-- ============================================================
CREATE TABLE Client_Colonne (
    IdClient INT PRIMARY KEY, -- PK simple
    Nom VARCHAR(100)
);

-- 2. CLE PRIMAIRE : définition au niveau table
CREATE TABLE Client_Table (
    IdClient INT NOT NULL,
    Nom VARCHAR(100),
    CONSTRAINT PK_Client_Table PRIMARY KEY (IdClient) -- PK simple
);

-- 3. CLE PRIMAIRE COMPOSITE : niveau table
CREATE TABLE Produit (
    IdProduit INT NOT NULL,
    VersionProduit INT NOT NULL,
    Nom VARCHAR(100),
    CONSTRAINT PK_Produit PRIMARY KEY (IdProduit, VersionProduit) -- PK composite
);

-- 4. FK simple inline au niveau colonne
CREATE TABLE Commande_Colonne (
    IdCommande INT PRIMARY KEY, -- PK simple
    IdClient INT REFERENCES Client_Colonne(IdClient), -- FK simple
    DateCommande DATE
);

-- 5. FK simple au niveau table
CREATE TABLE Commande_Table (
    IdCommande INT PRIMARY KEY, -- PK simple
    IdClient INT,
    DateCommande DATE,
    CONSTRAINT FK_Commande_Table_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Table(IdClient)
);

-- 6. FK composite au niveau table
CREATE TABLE LigneProduit (
    IdLigne INT PRIMARY KEY, -- PK simple
    IdProduit INT NOT NULL,
    VersionProduit INT NOT NULL,
    Quantite INT,
    CONSTRAINT FK_LigneProduit_Produit
        FOREIGN KEY (IdProduit, VersionProduit)
        REFERENCES Produit(IdProduit, VersionProduit)
);

-- ============================================================
-- 7. FK déclarée après création avec ALTER TABLE
-- ============================================================
CREATE TABLE Facture (
    IdFacture INT PRIMARY KEY, -- PK simple
    IdClient INT NULL,
    Montant DECIMAL(10,2)
);

ALTER TABLE Facture
ADD CONSTRAINT FK_Facture_Client
    FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient);

-- ============================================================
-- 8. Cardinalité 1..n : FK NOT NULL non UNIQUE
-- ============================================================
CREATE TABLE Commande_1N (
    IdCommande INT PRIMARY KEY, -- PK simple
    IdClient INT NOT NULL,
    CONSTRAINT FK_Commande_1N_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);

-- ============================================================
-- 9. Cardinalité 0..n : FK NULL non UNIQUE
-- ============================================================
CREATE TABLE Facture_0N (
    IdFacture INT PRIMARY KEY, -- PK simple
    IdClient INT NULL,
    CONSTRAINT FK_Facture_0N_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);

-- ============================================================
-- 10. Cardinalité 1..1 / 1..0..1 : FK UNIQUE NOT NULL
-- ============================================================
CREATE TABLE CompteClient_11 (
    IdCompte INT PRIMARY KEY, -- PK simple
    IdClient INT NOT NULL UNIQUE,
    CONSTRAINT FK_CompteClient_11_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);

-- Variante : UNIQUE déclaré au niveau table
CREATE TABLE CarteClient (
    IdCarte INT PRIMARY KEY, -- PK simple
    IdClient INT NOT NULL,
    CONSTRAINT UQ_CarteClient_Client UNIQUE (IdClient),
    CONSTRAINT FK_CarteClient_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);

-- ============================================================
-- 11. Cardinalité 0..1 : FK UNIQUE nullable
-- ============================================================
CREATE TABLE ProfilClient (
    IdProfil INT PRIMARY KEY, -- PK simple
    IdClient INT NULL,
    CONSTRAINT UQ_ProfilClient_Client UNIQUE (IdClient),
    CONSTRAINT FK_ProfilClient_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);

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

-- ============================================================
-- 13. FK composite déclarée par ALTER TABLE
-- ============================================================
CREATE TABLE HistoriqueProduit (
    IdHistorique INT PRIMARY KEY, -- PK simple
    IdProduit INT NOT NULL,
    VersionProduit INT NOT NULL
);

ALTER TABLE HistoriqueProduit
ADD CONSTRAINT FK_HistoriqueProduit_Produit
    FOREIGN KEY (IdProduit, VersionProduit)
    REFERENCES Produit(IdProduit, VersionProduit);

-- ============================================================
-- 14. FK SIMPLE NULLABLE INLINE (niveau colonne)
-- ============================================================
CREATE TABLE Adresse_Colonne_Nullable (
    IdAdresse INTEGER PRIMARY KEY, -- PK simple
    IdClient INTEGER NULL REFERENCES Client_Colonne(IdClient), -- FK simple
    Libelle VARCHAR(100)
);

-- ============================================================
-- 15. FK SIMPLE NULLABLE (niveau table)
-- ============================================================
CREATE TABLE Adresse_Table_Nullable (
    IdAdresse INTEGER PRIMARY KEY, -- PK simple
    IdClient INTEGER NULL,
    Libelle VARCHAR(100),
    CONSTRAINT FK_Adresse_Table_Nullable_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);

-- ============================================================
-- 16. FK COMPOSITE NULLABLE déclarée par ALTER TABLE
-- ============================================================
CREATE TABLE HistoriqueProduit_Nullable (
    IdHistorique INTEGER PRIMARY KEY, -- PK simple
    IdProduit INTEGER NULL,
    VersionProduit INTEGER NULL
);

ALTER TABLE HistoriqueProduit_Nullable
ADD CONSTRAINT FK_HistoriqueProduit_Nullable_Produit
    FOREIGN KEY (IdProduit, VersionProduit)
    REFERENCES Produit(IdProduit, VersionProduit);
