-- Présence dans ce script de :

-- PK simple	 déclarée au niveau colonne         >
-- PK simple	 déclarée au niveau table           >
-- PK composite	 déclarée au niveau table           >
-- PK simple	 déclarée au niveau ALTER           > impossible avec SQLite
-- PK composite	 déclarée au niveau ALTER           > impossible avec SQLite
-- FK simple	NULL     déclarée au niveau colonne >
-- FK simple	NOT NULL déclarée au niveau colonne >
-- FK simple	NULL     déclarée au niveau table   >
-- FK simple	NOT NULL déclarée au niveau table   >
-- FK composite NULL	 déclarée au niveau table   >
-- FK composite NOT NULL déclarée au niveau table   >
-- FK simple	NULL     déclarée au niveau ALTER   > impossible avec SQLite
-- FK simple	NOT NULL déclarée au niveau ALTER   > impossible avec SQLite
-- FK composite	NULL	 déclarée au niveau ALTER   > impossible avec SQLite
-- FK composite	NOT NULL déclarée au niveau ALTER   > impossible avec SQLite

-- Cardinalité 0..1-------?..n                      >
-- Cardinalité 1..1-------?..n                      >
-- Cardinalité 0..1-------?..1                      >
-- Cardinalité 1..1-------?..1                      >

PRAGMA foreign_keys = ON;

-- 1) Table client
CREATE TABLE client (
    id_client        INTEGER NOT NULL PRIMARY KEY,  -- PK inline -- PK simple
    id_responsable   INTEGER NULL,
    nom              TEXT NOT NULL,
    prenom           TEXT NULL,
    email            TEXT NULL,
    CONSTRAINT uq_client_responsable UNIQUE (id_responsable)
);

-- 2) Table categorie
CREATE TABLE categorie (
    id_categorie     INTEGER NOT NULL PRIMARY KEY,  -- PK inline -- PK simple
    nom_categorie    TEXT NOT NULL
);

-- 3) Table produit
CREATE TABLE produit (
    id_produit            INTEGER NOT NULL PRIMARY KEY,  -- PK inline -- PK simple
    code                  TEXT NOT NULL,
    libelle               TEXT NOT NULL,
    prix_unitaire         REAL NOT NULL,
    id_categorie_principale INTEGER NULL
        REFERENCES categorie(id_categorie)               -- FK inline nullable
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    id_categorie_secondaire INTEGER NULL                 -- FK table-level via ALTER
);

-- FK simple nullable au niveau table
ALTER TABLE produit
ADD CONSTRAINT fk_produit_categorie_secondaire
    FOREIGN KEY (id_categorie_secondaire)
    REFERENCES categorie(id_categorie)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

-- 4) Table famille_produit
CREATE TABLE famille_produit (
    id_famille       INTEGER NOT NULL,
    code_famille     TEXT NOT NULL,
    nom_famille      TEXT NOT NULL,
    CONSTRAINT pk_famille_produit PRIMARY KEY (id_famille, code_famille) -- PK composite
);

-- 5) Table produit_famille
CREATE TABLE produit_famille (
    id_produit       INTEGER NOT NULL
        REFERENCES produit(id_produit)               -- FK inline
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    id_famille       INTEGER NULL,
    code_famille     TEXT NULL,
    rang             INTEGER NOT NULL,
    CONSTRAINT pk_produit_famille PRIMARY KEY (id_produit, rang) -- PK composite
);

-- FK composite nullable via ALTER
ALTER TABLE produit_famille
ADD CONSTRAINT fk_produit_famille_famille
    FOREIGN KEY (id_famille, code_famille)
    REFERENCES famille_produit(id_famille, code_famille)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

-- 6) Table adresse_livraison
CREATE TABLE adresse_livraison (
    id_adresse       INTEGER NOT NULL PRIMARY KEY,  -- PK inline -- PK simple
    id_client        INTEGER NOT NULL
        REFERENCES client(id_client)                -- FK inline
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    ligne1           TEXT NOT NULL,
    ligne2           TEXT NULL,
    code_postal      TEXT NOT NULL,
    ville            TEXT NOT NULL,
    CONSTRAINT uq_adresse_client UNIQUE (id_client)
);

-- 7) Table commande
CREATE TABLE commande (
    id_commande      INTEGER NOT NULL PRIMARY KEY,  -- PK inline -- PK simple
    id_client        INTEGER NOT NULL,
    id_adresse       INTEGER NULL,
    date_commande    TEXT NOT NULL,
    statut           TEXT NOT NULL
);

ALTER TABLE commande
ADD CONSTRAINT fk_commande_client
    FOREIGN KEY (id_client)
    REFERENCES client(id_client)
    ON DELETE RESTRICT
    ON UPDATE CASCADE;

ALTER TABLE commande
ADD CONSTRAINT fk_commande_adresse
    FOREIGN KEY (id_adresse)
    REFERENCES adresse_livraison(id_adresse)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

-- 8) Table ligne_commande
CREATE TABLE ligne_commande (
    id_commande      INTEGER NOT NULL
        REFERENCES commande(id_commande)            -- FK inline
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    numero_ligne     INTEGER NOT NULL,
    id_produit       INTEGER NOT NULL
        REFERENCES produit(id_produit)              -- FK inline
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    quantite         INTEGER NOT NULL,
    prix_unitaire    REAL NOT NULL,
    CONSTRAINT pk_ligne_commande PRIMARY KEY (id_commande, numero_ligne) -- PK composite
);

-- 9) Table contact
CREATE TABLE contact (
    id_contact       INTEGER NOT NULL PRIMARY KEY,  -- PK inline -- PK simple
    nom              TEXT NOT NULL,
    prenom           TEXT NULL,
    email            TEXT NULL
);

-- 10) Table client_contact (n..n)
CREATE TABLE client_contact (
    id_client        INTEGER NOT NULL
        REFERENCES client(id_client)                -- FK inline
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    id_contact       INTEGER NOT NULL
        REFERENCES contact(id_contact)              -- FK inline
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    role             TEXT NULL,
    CONSTRAINT pk_client_contact PRIMARY KEY (id_client, id_contact) -- PK composite
);