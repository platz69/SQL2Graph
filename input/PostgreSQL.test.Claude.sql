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

CREATE TABLE t_pays (
    id_pays    INTEGER      NOT NULL PRIMARY KEY,   -- PK inline (colonne) -- PK simple
    code_iso   CHAR(2)      NOT NULL,
    nom_pays   VARCHAR(100) NOT NULL
);

CREATE TABLE t_region (
    id_region  INTEGER      NOT NULL,
    id_pays    INTEGER      NOT NULL REFERENCES t_pays(id_pays),  -- FK inline (colonne) -- cardinalité 1..N (PAYS -> REGION) -- FK simple
    nom_region VARCHAR(100) NOT NULL,
    CONSTRAINT pk_region PRIMARY KEY (id_region)                  -- PK table-level (simple) -- PK simple
);

CREATE TABLE t_ville (
    id_region  INTEGER      NOT NULL,   -- fait partie de la PK composite + FK vers t_region -- cardinalité 1..N (REGION -> VILLE)
    code_ville VARCHAR(10)  NOT NULL,
    nom_ville  VARCHAR(100) NOT NULL,
    CONSTRAINT pk_ville PRIMARY KEY (id_region, code_ville),                              -- PK table-level (composite) -- PK composite
    CONSTRAINT fk_ville_region FOREIGN KEY (id_region) REFERENCES t_region(id_region)     -- FK table-level (simple) -- FK simple
);

CREATE TABLE t_produit (
    id_produit  INTEGER       NOT NULL PRIMARY KEY,  -- PK inline (colonne) -- PK simple
    nom_produit VARCHAR(100)  NOT NULL,
    prix        NUMERIC(10,2) NOT NULL
);

CREATE TABLE t_client (
    id_client       INTEGER      NOT NULL PRIMARY KEY,  -- PK inline (colonne) -- PK simple
    nom_client      VARCHAR(100) NOT NULL,
    id_pays         INTEGER      NULL,                  -- cardinalité 0..N : FK ajoutée plus bas via ALTER TABLE, NULLABLE (pays de résidence facultatif)
    id_region_fact  INTEGER      NULL,                  -- cardinalité 0..1 : ville de facturation préférée (facultative)
    code_ville_fact VARCHAR(10)  NULL,
    id_produit_favori INTEGER    NULL REFERENCES t_produit(id_produit),  -- FK simple NULLable déclarée au niveau colonne -- FK simple
    CONSTRAINT uq_client_ville_fact UNIQUE (id_region_fact, code_ville_fact),                 -- garantit l'unicité -> 0..1 côté VILLE aussi
    CONSTRAINT fk_client_ville_fact FOREIGN KEY (id_region_fact, code_ville_fact) -- FK composite
        REFERENCES t_ville(id_region, code_ville)                                            -- FK table-level composite, nullable
);

CREATE TABLE t_compte_client (
    id_client      INTEGER     NOT NULL PRIMARY KEY REFERENCES t_client(id_client),  -- cardinalité 1..1 : PK = FK (clé partagée) -- PK simple
    numero_compte  VARCHAR(30) NOT NULL,
    date_ouverture DATE        NOT NULL
);

CREATE TABLE t_commande (
    id_commande          INTEGER     NOT NULL,  -- PK ajoutée plus bas via ALTER TABLE
    id_client            INTEGER     NOT NULL,  -- cardinalité 1..N : FK obligatoire ajoutée plus bas via ALTER TABLE
    id_region            INTEGER     NOT NULL,  -- FK composite ajoutée plus bas via ALTER TABLE
    code_ville           VARCHAR(10) NOT NULL,
    date_commande        DATE        NOT NULL,
    id_produit_promo     INTEGER     NULL,       -- FK simple NULLable déclarée au niveau table (ci-dessous)
    id_region_livraison  INTEGER     NULL,       -- FK composite NULLable ajoutée plus bas via ALTER TABLE (ville de livraison facultative)
    code_ville_livraison VARCHAR(10) NULL,
    CONSTRAINT fk_commande_produit_promo FOREIGN KEY (id_produit_promo) -- FK simple
        REFERENCES t_produit(id_produit)          -- FK simple NULLable déclarée au niveau table
);

CREATE TABLE t_ligne_commande (
    id_commande   INTEGER     NOT NULL,  -- PK composite ajoutée plus bas via ALTER TABLE
    numero_ligne  INTEGER     NOT NULL,
    id_produit    INTEGER     NOT NULL REFERENCES t_produit(id_produit),  -- FK inline (colonne) -- FK simple
    id_region     INTEGER     NOT NULL,
    code_ville    VARCHAR(10) NOT NULL,
    quantite      INTEGER     NOT NULL,
    CONSTRAINT fk_ligne_ville FOREIGN KEY (id_region, code_ville) -- FK composite
        REFERENCES t_ville(id_region, code_ville)   -- FK table-level (composite)
    -- t_ligne_commande est la table d'association qui réalise la cardinalité N..N
    -- entre t_commande et t_produit : une commande contient plusieurs produits
    -- (via plusieurs lignes), et un produit apparaît dans plusieurs commandes.
);

-- ---- Contraintes restantes ajoutées via ALTER TABLE ----

ALTER TABLE t_client
    ADD CONSTRAINT fk_client_pays FOREIGN KEY (id_pays) -- FK simple
        REFERENCES t_pays(id_pays);   -- FK via ALTER (simple), nullable -- cardinalité 0..N

ALTER TABLE t_commande
    ADD CONSTRAINT pk_commande PRIMARY KEY (id_commande);   -- PK via ALTER (simple) -- PK simple

ALTER TABLE t_commande
    ADD CONSTRAINT fk_commande_client FOREIGN KEY (id_client) -- FK simple
        REFERENCES t_client(id_client);   -- FK via ALTER (simple), obligatoire -- cardinalité 1..N

ALTER TABLE t_commande
    ADD CONSTRAINT fk_commande_ville FOREIGN KEY (id_region, code_ville) -- FK composite
        REFERENCES t_ville(id_region, code_ville);   -- FK via ALTER (composite)

ALTER TABLE t_ligne_commande
    ADD CONSTRAINT pk_ligne_commande PRIMARY KEY (id_commande, numero_ligne);   -- PK via ALTER (composite) -- PK composite

ALTER TABLE t_ligne_commande
    ADD CONSTRAINT fk_ligne_commande FOREIGN KEY (id_commande) -- FK simple
        REFERENCES t_commande(id_commande);   -- FK via ALTER (simple), complète la table d'association N..N

ALTER TABLE t_commande
    ADD CONSTRAINT fk_commande_ville_livraison FOREIGN KEY (id_region_livraison, code_ville_livraison) -- FK composite
        REFERENCES t_ville(id_region, code_ville);   -- FK composite NULLable ajoutée via ALTER TABLE
