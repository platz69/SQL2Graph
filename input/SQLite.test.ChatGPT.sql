-- Présence dans ce script de :
--    PK simple		NULL     déclarée au niveau colonne > impossible (une PK ne peut être NULL)
--    PK simple	    NOT NULL déclarée au niveau colonne > oui
--    PK composite	NULL	 déclarée au niveau colonne > impossible (une PK/FK composite ne peut être déclarée au niveau colonne)
--    PK composite	NOT NULL déclarée au niveau colonne > impossible (une PK/FK composite ne peut être déclarée au niveau colonne)
--    PK simple		NULL     déclarée au niveau table   > impossible (une PK ne peut être NULL)
--    PK simple	    NOT NULL déclarée au niveau table   > oui
--    PK composite	NULL	 déclarée au niveau table   > impossible (une PK ne peut être NULL)
--    PK composite	NOT NULL déclarée au niveau table   > oui
--    PK simple		NULL     déclarée au niveau ALTER   > impossible (une PK ne peut être NULL)
--    PK simple	    NOT NULL déclarée au niveau ALTER   > impossible avec SQLite
--    PK composite	NULL	 déclarée au niveau ALTER   > impossible (une PK ne peut être NULL)
--    PK composite	NOT NULL déclarée au niveau ALTER   > impossible avec SQLite
--    FK simple		NULL     déclarée au niveau colonne > oui
--    FK simple	    NOT NULL déclarée au niveau colonne > oui
--    FK composite	NULL	 déclarée au niveau colonne > impossible (une PK/FK composite ne peut être déclarée au niveau colonne)
--    FK composite	NOT NULL déclarée au niveau colonne > impossible (une PK/FK composite ne peut être déclarée au niveau colonne)
--    FK simple		NULL     déclarée au niveau table   > oui
--    FK simple	    NOT NULL déclarée au niveau table   > oui
--    FK composite	NULL	 déclarée au niveau table   > oui
--    FK composite	NOT NULL déclarée au niveau table   > oui
--    FK simple		NULL     déclarée au niveau ALTER   > impossible avec SQLite
--    FK simple	    NOT NULL déclarée au niveau ALTER   > impossible avec SQLite
--    FK composite	NULL	 déclarée au niveau ALTER   > impossible avec SQLite
--    FK composite	NOT NULL déclarée au niveau ALTER   > impossible avec SQLite

PRAGMA foreign_keys = ON;

-- ============================================================
-- 1. CLES PRIMAIRES : définition au niveau colonne
-- ============================================================
CREATE TABLE Client_Colonne (
    IdClient INTEGER PRIMARY KEY, -- PK simple
    Nom TEXT
);

-- 2. CLE PRIMAIRE : définition au niveau table
CREATE TABLE Client_Table (
    IdClient INTEGER NOT NULL,
    Nom TEXT,
    CONSTRAINT PK_Client_Table PRIMARY KEY (IdClient) -- PK simple
);

-- 3. CLE PRIMAIRE COMPOSITE : niveau table
CREATE TABLE Produit (
    IdProduit INTEGER NOT NULL,
    VersionProduit INTEGER NOT NULL,
    Nom TEXT,
    CONSTRAINT PK_Produit PRIMARY KEY (IdProduit, VersionProduit) -- PK composite
);

-- 4. FK simple inline au niveau colonne
CREATE TABLE Commande_Colonne (
    IdCommande INTEGER PRIMARY KEY, -- PK simple
    IdClient INTEGER REFERENCES Client_Colonne(IdClient), -- FK simple
    DateCommande TEXT
);

-- 5. FK simple au niveau table
CREATE TABLE Commande_Table (
    IdCommande INTEGER PRIMARY KEY, -- PK simple
    IdClient INTEGER,
    DateCommande TEXT,
    CONSTRAINT FK_Commande_Table_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Table(IdClient)
);

-- 6. FK composite au niveau table
CREATE TABLE LigneProduit (
    IdLigne INTEGER PRIMARY KEY, -- PK simple
    IdProduit INTEGER NOT NULL,
    VersionProduit INTEGER NOT NULL,
    Quantite INTEGER,
    CONSTRAINT FK_LigneProduit_Produit
        FOREIGN KEY (IdProduit, VersionProduit)
        REFERENCES Produit(IdProduit, VersionProduit)
);

-- 7. FK déclarée après création avec ALTER TABLE
CREATE TABLE Facture (
    IdFacture INTEGER PRIMARY KEY, -- PK simple
    IdClient INTEGER NULL,
    Montant NUMERIC
);

-- SQLite ne permet pas ALTER TABLE ... ADD CONSTRAINT FOREIGN KEY.
-- La relation équivalente doit être déclarée dans CREATE TABLE.
-- Ce cas est donc documenté comme syntaxe non supportée par SQLite.

-- 8. Cardinalité 1..n
CREATE TABLE Commande_1N (
    IdCommande INTEGER PRIMARY KEY, -- PK simple
    IdClient INTEGER NOT NULL,
    CONSTRAINT FK_Commande_1N_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);

-- 9. Cardinalité 0..n
CREATE TABLE Facture_0N (
    IdFacture INTEGER PRIMARY KEY, -- PK simple
    IdClient INTEGER NULL,
    CONSTRAINT FK_Facture_0N_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);

-- 10. Cardinalité 1..1 / 1..0..1 : UNIQUE NOT NULL
CREATE TABLE CompteClient_11 (
    IdCompte INTEGER PRIMARY KEY, -- PK simple
    IdClient INTEGER NOT NULL UNIQUE,
    CONSTRAINT FK_CompteClient_11_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);

-- UNIQUE au niveau table
CREATE TABLE CarteClient (
    IdCarte INTEGER PRIMARY KEY, -- PK simple
    IdClient INTEGER NOT NULL,
    CONSTRAINT UQ_CarteClient_Client UNIQUE (IdClient),
    CONSTRAINT FK_CarteClient_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);

-- 11. Cardinalité 0..1
CREATE TABLE ProfilClient (
    IdProfil INTEGER PRIMARY KEY, -- PK simple
    IdClient INTEGER NULL,
    CONSTRAINT UQ_ProfilClient_Client UNIQUE (IdClient),
    CONSTRAINT FK_ProfilClient_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);

-- 12. n..n : table d'association
CREATE TABLE Client_Produit (
    IdClient INTEGER NOT NULL,
    IdProduit INTEGER NOT NULL,
    VersionProduit INTEGER NOT NULL,
    CONSTRAINT PK_Client_Produit PRIMARY KEY (IdClient, IdProduit, VersionProduit), -- PK composite
    CONSTRAINT FK_Client_Produit_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient),
    CONSTRAINT FK_Client_Produit_Produit
        FOREIGN KEY (IdProduit, VersionProduit)
        REFERENCES Produit(IdProduit, VersionProduit)
);

-- 13. FK composite par ALTER TABLE :
-- SQLite ne supporte pas l'ajout d'une contrainte FK via ALTER TABLE.
CREATE TABLE HistoriqueProduit (
    IdHistorique INTEGER PRIMARY KEY, -- PK simple
    IdProduit INTEGER NOT NULL,
    VersionProduit INTEGER NOT NULL
);

-- ============================================================
-- 14. FK SIMPLE NULLABLE INLINE (niveau colonne)
-- ============================================================
CREATE TABLE Adresse_Colonne_Nullable (
    IdAdresse INTEGER PRIMARY KEY, -- PK simple
    IdClient INTEGER NULL REFERENCES Client_Colonne(IdClient), -- FK simple
    Libelle TEXT
);

-- ============================================================
-- 15. FK SIMPLE NULLABLE (niveau table)
-- ============================================================
CREATE TABLE Adresse_Table_Nullable (
    IdAdresse INTEGER PRIMARY KEY, -- PK simple
    IdClient INTEGER NULL,
    Libelle TEXT,
    CONSTRAINT FK_Adresse_Table_Nullable_Client
        FOREIGN KEY (IdClient) REFERENCES Client_Colonne(IdClient)
);

-- ============================================================
-- 16. FK COMPOSITE NULLABLE déclarée par ALTER TABLE
-- ============================================================
-- IMPOSSIBLE en SQLite : ALTER TABLE ... ADD CONSTRAINT FOREIGN KEY
-- n'est pas supporté. L'équivalent doit être défini dans CREATE TABLE.
CREATE TABLE HistoriqueProduit_Nullable (
    IdHistorique INTEGER PRIMARY KEY, -- PK simple
    IdProduit INTEGER NULL,
    VersionProduit INTEGER NULL,
    CONSTRAINT FK_HistoriqueProduit_Nullable_Produit
        FOREIGN KEY (IdProduit, VersionProduit)
        REFERENCES Produit(IdProduit, VersionProduit)
);
