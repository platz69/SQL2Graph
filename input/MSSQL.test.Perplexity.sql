-- Présence dans ce script de :
--    PK simple		NULL     déclarée au niveau colonne > impossible (une PK ne peut être NULL)
--    PK simple	    NOT NULL déclarée au niveau colonne > oui
--    PK composite	NULL	 déclarée au niveau colonne > impossible (une PK/FK composite ne peut être déclarée au niveau colonne)
--    PK composite	NOT NULL déclarée au niveau colonne > impossible (une PK/FK composite ne peut être déclarée au niveau colonne)
--    PK simple		NULL     déclarée au niveau table   > impossible (une PK ne peut être NULL)
--    PK simple	    NOT NULL déclarée au niveau table   > ************NON
--    PK composite	NULL	 déclarée au niveau table   > impossible (une PK ne peut être NULL)
--    PK composite	NOT NULL déclarée au niveau table   > oui
--    PK simple		NULL     déclarée au niveau ALTER   > impossible (une PK ne peut être NULL)
--    PK simple	    NOT NULL déclarée au niveau ALTER   > oui
--    PK composite	NULL	 déclarée au niveau ALTER   > impossible (une PK ne peut être NULL)
--    PK composite	NOT NULL déclarée au niveau ALTER   > ************NON
--    FK simple		NULL     déclarée au niveau colonne > oui
--    FK simple	    NOT NULL déclarée au niveau colonne > oui
--    FK composite	NULL	 déclarée au niveau colonne > impossible (une PK/FK composite ne peut être déclarée au niveau colonne)
--    FK composite	NOT NULL déclarée au niveau colonne > impossible (une PK/FK composite ne peut être déclarée au niveau colonne)
--    FK simple		NULL     déclarée au niveau table   > ************NON
--    FK simple	    NOT NULL déclarée au niveau table   > ************NON
--    FK composite	NULL	 déclarée au niveau table   > ************NON
--    FK composite	NOT NULL déclarée au niveau table   > ************NON
--    FK simple		NULL     déclarée au niveau ALTER   > oui
--    FK simple	    NOT NULL déclarée au niveau ALTER   > oui
--    FK composite	NULL	 déclarée au niveau ALTER   > oui
--    FK composite	NOT NULL déclarée au niveau ALTER   > ************NON

-- 1) Table client
-- PK déclarée au niveau de la colonne
CREATE TABLE client (
    id_client        INT NOT NULL PRIMARY KEY,  -- PK inline -- PK simple
    id_responsable   INT NULL,
    nom              NVARCHAR(100) NOT NULL,
    prenom           NVARCHAR(100) NULL,
    email            NVARCHAR(255) NULL,
    CONSTRAINT uq_client_responsable UNIQUE (id_responsable)
);

-- 2) Table categorie
-- PK déclarée au niveau de la colonne
CREATE TABLE categorie (
    id_categorie     INT NOT NULL PRIMARY KEY,  -- PK inline -- PK simple
    nom_categorie    NVARCHAR(100) NOT NULL
);

-- 3) Table produit
-- - PK inline
-- - FK simple nullable inline (colonne)
-- - FK simple nullable au niveau table (via ALTER)
CREATE TABLE produit (
    id_produit            INT NOT NULL PRIMARY KEY,  -- PK inline -- PK simple
    code                  NVARCHAR(50) NOT NULL,
    libelle               NVARCHAR(200) NOT NULL,
    prix_unitaire         DECIMAL(10, 2) NOT NULL,
    id_categorie_principale INT NULL
        REFERENCES categorie(id_categorie)           -- FK inline nullable (niveau colonne)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    id_categorie_secondaire INT NULL                 -- FK table-level ajoutée via ALTER
    -- UNIQUE inline possible ici si besoin
);

-- FK simple nullable déclarée au niveau table
ALTER TABLE produit
ADD CONSTRAINT fk_produit_categorie_secondaire
    FOREIGN KEY (id_categorie_secondaire)
    REFERENCES categorie(id_categorie)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

-- 4) Table famille_produit
-- PK composite déclarée au niveau de la table
CREATE TABLE famille_produit (
    id_famille       INT NOT NULL,
    code_famille     NVARCHAR(50) NOT NULL,
    nom_famille      NVARCHAR(200) NOT NULL,
    CONSTRAINT pk_famille_produit PRIMARY KEY (id_famille, code_famille) -- PK composite
);

-- 5) Table produit_famille
-- - PK composite (table-level)
-- - FK simple inline vers produit
-- - FK composite nullable via ALTER
CREATE TABLE produit_famille (
    id_produit       INT NOT NULL
        REFERENCES produit(id_produit)               -- FK inline (niveau colonne)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    id_famille       INT NULL,                       -- pour FK composite nullable
    code_famille     NVARCHAR(50) NULL,              -- pour FK composite nullable
    rang             INT NOT NULL,
    CONSTRAINT pk_produit_famille PRIMARY KEY (id_produit, rang) -- PK composite
    -- FK composite ajoutée via ALTER ci-dessous
);

-- FK composite nullable via ALTER TABLE
ALTER TABLE produit_famille
ADD CONSTRAINT fk_produit_famille_famille
    FOREIGN KEY (id_famille, code_famille)
    REFERENCES famille_produit(id_famille, code_famille)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

-- 6) Table adresse_livraison
-- PK inline, FK inline
CREATE TABLE adresse_livraison (
    id_adresse       INT NOT NULL PRIMARY KEY,      -- PK inline -- PK simple
    id_client        INT NOT NULL
        REFERENCES client(id_client)                -- FK inline
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    ligne1           NVARCHAR(200) NOT NULL,
    ligne2           NVARCHAR(200) NULL,
    code_postal      NVARCHAR(20) NOT NULL,
    ville            NVARCHAR(100) NOT NULL,
    CONSTRAINT uq_adresse_client UNIQUE (id_client)
);

-- 7) Table commande
-- PK inline, FK via ALTER
CREATE TABLE commande (
    id_commande      INT NOT NULL PRIMARY KEY,      -- PK inline -- PK simple
    id_client        INT NOT NULL,                  -- FK via ALTER
    id_adresse       INT NULL,                      -- FK via ALTER
    date_commande    DATETIME2 NOT NULL,
    statut           NVARCHAR(50) NOT NULL
);

ALTER TABLE commande
ADD CONSTRAINT fk_commande_client
    FOREIGN KEY (id_client)
    REFERENCES client(id_client)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

ALTER TABLE commande
ADD CONSTRAINT fk_commande_adresse
    FOREIGN KEY (id_adresse)
    REFERENCES adresse_livraison(id_adresse)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

-- 8) Table ligne_commande
-- PK composite, FK inline
CREATE TABLE ligne_commande (
    id_commande      INT NOT NULL
        REFERENCES commande(id_commande)            -- FK inline
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    numero_ligne     INT NOT NULL,
    id_produit       INT NOT NULL
        REFERENCES produit(id_produit)              -- FK inline
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    quantite         INT NOT NULL,
    prix_unitaire    DECIMAL(10, 2) NOT NULL,
    CONSTRAINT pk_ligne_commande PRIMARY KEY (id_commande, numero_ligne) -- PK composite
);

-- 9) Table contact
-- PK inline
CREATE TABLE contact (
    id_contact       INT NOT NULL PRIMARY KEY,      -- PK inline -- PK simple
    nom              NVARCHAR(100) NOT NULL,
    prenom           NVARCHAR(100) NULL,
    email            NVARCHAR(255) NULL
);

-- 10) Table client_contact (n..n)
-- PK composite, FK inline
CREATE TABLE client_contact (
    id_client        INT NOT NULL
        REFERENCES client(id_client)                -- FK inline
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    id_contact       INT NOT NULL
        REFERENCES contact(id_contact)              -- FK inline
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    role             NVARCHAR(100) NULL,
    CONSTRAINT pk_client_contact PRIMARY KEY (id_client, id_contact) -- PK composite
);