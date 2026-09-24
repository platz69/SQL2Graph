-- Présence dans ce script de :
-- Remarques : pas de composites possibles au niveau colonne

-- PK simple	 déclarée au niveau colonne                > oui
-- PK simple	 déclarée au niveau table                  > oui
-- PK composite	 déclarée au niveau table                  > oui
-- PK simple	 déclarée au niveau ALTER                  > oui
-- PK composite	 déclarée au niveau ALTER                  > oui
-- FK simple	NULL     déclarée au niveau colonne        > oui
-- FK simple	NOT NULL déclarée au niveau colonne        > oui
-- FK simple	NULL     déclarée au niveau table          > oui
-- FK simple	NOT NULL déclarée au niveau table          > oui
-- FK composite NULL	 déclarée au niveau table          > oui
-- FK composite NOT NULL déclarée au niveau table          > oui
-- FK simple	NULL     déclarée au niveau ALTER          > oui
-- FK simple	NOT NULL déclarée au niveau ALTER          > oui
-- FK composite	NULL	 déclarée au niveau ALTER          > oui
-- FK composite	NOT NULL déclarée au niveau ALTER          > oui

-- Avec contrainte UNIQUE
-- FK simple	UNIQUE NULL     déclarée au niveau colonne >
-- FK simple	UNIQUE NOT NULL déclarée au niveau colonne >
-- FK simple	UNIQUE NULL     déclarée au niveau table   > oui
-- FK simple	UNIQUE NOT NULL déclarée au niveau table   > oui
-- FK simple	UNIQUE NULL     déclarée au niveau ALTER   >
-- FK simple	UNIQUE NOT NULL déclarée au niveau ALTER   >
-- FK composite UNIQUE NULL	    déclarée au niveau table   >
-- FK composite UNIQUE NOT NULL déclarée au niveau table   >
-- FK composite	UNIQUE NULL	    déclarée au niveau ALTER   >
-- FK composite	UNIQUE NOT NULL déclarée au niveau ALTER   >

-- Conséquences :
-- Cardinalité 0..1-------?..n                             > oui
-- Cardinalité 1..1-------?..n                             > oui
-- Cardinalité 0..1-------?..1                             > oui
-- Cardinalité 1..1-------?..1                             > oui

CREATE DATABASE BaseTestCles;
USE BaseTestCles;

-- ============================================================
-- Sans FK
-- ============================================================
CREATE TABLE Client (
    IdClient INT PRIMARY KEY, -- PK simple	 déclarée au niveau colonne
    Nom NVARCHAR(100)
);

CREATE TABLE ClientProfessionnel (
    IdClient INT NOT NULL,
    Nom NVARCHAR(100),
    CONSTRAINT PK_ClientProfessionnel PRIMARY KEY (IdClient) -- PK simple	 déclarée au niveau table
);

CREATE TABLE Article (
    IdProduit INT NOT NULL,
    VersionProduit INT NOT NULL,
    Nom NVARCHAR(100),
    CONSTRAINT PK_Article PRIMARY KEY (IdProduit, VersionProduit) -- PK composite	 déclarée au niveau table
);

-- ============================================================
-- Cardinalité 0..1-------?..n
-- ============================================================
CREATE TABLE Commande (
    IdCommande INT PRIMARY KEY, -- PK simple	 déclarée au niveau colonne
    IdClient INT REFERENCES Client(IdClient), -- FK simple	NULL     déclarée au niveau colonne
    DateCommande DATE
);

CREATE TABLE Facture (
    IdFacture INT PRIMARY KEY, -- PK simple	 déclarée au niveau colonne
    IdClient INT NULL,
    Montant DECIMAL(10,2)
);

ALTER TABLE Facture
ADD CONSTRAINT FK_Facture_Client
    FOREIGN KEY (IdClient) REFERENCES Client(IdClient); -- FK simple	NULL     déclarée au niveau ALTER

CREATE TABLE CommandeProfessionnelle (
    IdCommande INT PRIMARY KEY, -- PK simple	 déclarée au niveau colonne
    IdClient INT,
    DateCommande DATE,
    CONSTRAINT FK_CommandeProfessionnelle_Client
        FOREIGN KEY (IdClient) REFERENCES ClientProfessionnel(IdClient) -- FK simple	NULL     déclarée au niveau table
);

CREATE TABLE ArticleCategorie (
    IdPK1 INT NOT NULL,
    IdPK2 INT NOT NULL,
    IdProduit INT NULL,
    VersionProduit INT NULL,
    CONSTRAINT FK_ArticleCategorie_Article
        FOREIGN KEY (IdProduit, VersionProduit)
        REFERENCES Article(IdProduit, VersionProduit)          -- FK composite NULL	 déclarée au niveau table
);

ALTER TABLE ArticleCategorie
ADD CONSTRAINT PK_ArticleCategorie PRIMARY KEY (IdPK1, IdPK2); -- PK composite	 déclarée au niveau ALTER

CREATE TABLE FactureClient (
    IdFacture INT PRIMARY KEY,                                 -- PK simple	 déclarée au niveau colonne
    IdClient INT NULL,
    CONSTRAINT FK_FactureClient_Client
        FOREIGN KEY (IdClient) REFERENCES Client(IdClient)     -- FK simple	NULL     déclarée au niveau table
);

CREATE TABLE AdresseClient (
    IdAdresse INT PRIMARY KEY, -- PK simple	 déclarée au niveau colonne
    IdClient INT NULL REFERENCES Client(IdClient), -- FK simple	NULL     déclarée au niveau colonne
    Libelle NVARCHAR(100)
);

CREATE TABLE AdresseLivraison (
    IdAdresse INT PRIMARY KEY, -- PK simple	 déclarée au niveau colonne
    IdClient INT NULL,
    Libelle NVARCHAR(100),
    CONSTRAINT FK_AdresseLivraison_Client
        FOREIGN KEY (IdClient) REFERENCES Client(IdClient) -- FK simple	NULL     déclarée au niveau table
);

CREATE TABLE SuiviArticle (
    IdHistorique INT PRIMARY KEY, -- PK simple	 déclarée au niveau colonne
    IdProduit INT NULL,
    VersionProduit INT NULL
);

ALTER TABLE SuiviArticle
ADD CONSTRAINT FK_SuiviArticle_Article
    FOREIGN KEY (IdProduit, VersionProduit)
    REFERENCES Article(IdProduit, VersionProduit); -- FK composite	NULL déclarée au niveau ALTER

-- ============================================================
-- Cardinalité 1..1-------?..n
-- ============================================================
CREATE TABLE LigneCommande (
    IdLigne INT PRIMARY KEY, -- PK simple	 déclarée au niveau colonne
    IdProduit INT NOT NULL,
    VersionProduit INT NOT NULL,
    Quantite INT,
    CONSTRAINT FK_LigneCommande_Article
        FOREIGN KEY (IdProduit, VersionProduit)
        REFERENCES Article(IdProduit, VersionProduit)-- FK composite NOT NULL	 déclarée au niveau table
);

CREATE TABLE ContactClient (
    IdPK INT NOT NULL REFERENCES Client(IdClient), -- FK simple	NOT NULL déclarée au niveau colonne
    IdClient INT NOT NULL,
    Nom NVARCHAR(100)
);

ALTER TABLE ContactClient
ADD CONSTRAINT PK_ContactClient PRIMARY KEY (IdPK); -- PK simple	 déclarée au niveau ALTER

ALTER TABLE ContactClient
ADD CONSTRAINT FK_ContactClient_Client
            FOREIGN KEY (IdClient)
            REFERENCES Client(IdClient);           -- FK simple	NOT NULL déclarée au niveau ALTER

CREATE TABLE CommandeClient (
    IdCommande INT PRIMARY KEY, -- PK simple	 déclarée au niveau colonne
    IdClient INT NOT NULL,
    CONSTRAINT FK_CommandeClient_Client
        FOREIGN KEY (IdClient) REFERENCES Client(IdClient) -- FK simple	NOT NULL     déclarée au niveau table
);

CREATE TABLE ClientArticle (
    IdClient INT NOT NULL,
    IdProduit INT NOT NULL,
    VersionProduit INT NOT NULL,
    CONSTRAINT PK_Client_Produit PRIMARY KEY (IdClient, IdProduit, VersionProduit), -- PK composite	 déclarée au niveau table
    CONSTRAINT FK_ClientArticle_Client
        FOREIGN KEY (IdClient) REFERENCES Client(IdClient), -- FK simple	NOT NULL     déclarée au niveau table
    CONSTRAINT FK_ClientArticle_Article
        FOREIGN KEY (IdProduit, VersionProduit)
        REFERENCES Article(IdProduit, VersionProduit)-- FK composite NOT NULL	 déclarée au niveau table
);

CREATE TABLE MouvementStock (
    IdHistorique INT PRIMARY KEY, -- PK simple	 déclarée au niveau colonne
    IdProduit INT NOT NULL,
    VersionProduit INT NOT NULL
);

ALTER TABLE MouvementStock
ADD CONSTRAINT FK_MouvementStock_Article
    FOREIGN KEY (IdProduit, VersionProduit)
    REFERENCES Article(IdProduit, VersionProduit); -- FK composite	NOT NULL déclarée au niveau ALTER

-- ============================================================
-- Cardinalité 0..1-------?..1
-- ============================================================
CREATE TABLE Profil (
    IdProfil INT PRIMARY KEY, -- PK simple	 déclarée au niveau colonne
    IdClient INT NULL,
    CONSTRAINT UQ_ProfilClient_Client UNIQUE (IdClient),
    CONSTRAINT FK_Profil_Client
        FOREIGN KEY (IdClient) REFERENCES Client(IdClient) -- FK simple	UNIQUE NULL     déclarée au niveau table
);

-- ============================================================
-- Cardinalité 1..1-------?..1
-- ============================================================
CREATE TABLE CompteClient (
    IdCompte INT PRIMARY KEY, -- PK simple	 déclarée au niveau colonne
    IdClient INT NOT NULL UNIQUE,
    CONSTRAINT FK_CompteClient_Client
        FOREIGN KEY (IdClient) REFERENCES Client(IdClient) -- FK simple	UNIQUE NOT NULL déclarée au niveau table
);

CREATE TABLE CarteFidelite (
    IdCarte INT PRIMARY KEY, -- PK simple	 déclarée au niveau colonne
    IdClient INT NOT NULL,
    CONSTRAINT UQ_CarteClient_Client UNIQUE (IdClient),
    CONSTRAINT FK_CarteFidelite_Client
        FOREIGN KEY (IdClient) REFERENCES Client(IdClient) -- FK simple	UNIQUE NOT NULL déclarée au niveau table
);