-- Présence dans ce script de :

-- PK simple	 déclarée au niveau colonne         > oui
-- PK simple	 déclarée au niveau table           > oui
-- PK composite	 déclarée au niveau table           > oui
-- PK simple	 déclarée au niveau ALTER           > oui
-- PK composite	 déclarée au niveau ALTER           > oui
-- FK simple	NULL     déclarée au niveau colonne > oui
-- FK simple	NOT NULL déclarée au niveau colonne > oui
-- FK simple	NULL     déclarée au niveau table   > oui
-- FK simple	NOT NULL déclarée au niveau table   > oui
-- FK composite NULL	 déclarée au niveau table   > oui
-- FK composite NOT NULL déclarée au niveau table   > oui
-- FK simple	NULL     déclarée au niveau ALTER   > oui
-- FK simple	NOT NULL déclarée au niveau ALTER   > oui
-- FK composite	NULL	 déclarée au niveau ALTER   > oui
-- FK composite	NOT NULL déclarée au niveau ALTER   > oui

-- Cardinalité 0..1-------?..n                      >
-- Cardinalité 1..1-------?..n                      >
-- Cardinalité 0..1-------?..1                      >
-- Cardinalité 1..1-------?..1                      >

CREATE TABLE PAYS (
    id_pays    INT          NOT NULL PRIMARY KEY,   -- PK simple	 déclarée au niveau colonne
    code_iso   CHAR(2)      NOT NULL,
    nom_pays   VARCHAR(100) NOT NULL
);

CREATE TABLE REGION (
    id_region  INT          NOT NULL,
    id_pays    INT          NOT NULL REFERENCES PAYS(id_pays),  -- cardinalité 1..N (PAYS -> REGION) -- FK simple	NOT NULL déclarée au niveau colonne
    nom_region VARCHAR(100) NOT NULL,
    CONSTRAINT PK_REGION PRIMARY KEY (id_region)                  -- PK simple	 déclarée au niveau table
);

CREATE TABLE VILLE (
    id_region  INT          NOT NULL,   -- fait partie de la PK composite + FK vers REGION -- cardinalité 1..N (REGION -> VILLE)
    code_ville VARCHAR(10)  NOT NULL,
    nom_ville  VARCHAR(100) NOT NULL,
    CONSTRAINT PK_VILLE PRIMARY KEY (id_region, code_ville),                              -- PK composite	 déclarée au niveau table
    CONSTRAINT FK_VILLE_REGION FOREIGN KEY (id_region) REFERENCES REGION(id_region)     -- FK simple	NOT NULL déclarée au niveau table
);

CREATE TABLE PRODUIT (
    id_produit  INT           NOT NULL PRIMARY KEY,  -- PK simple	 déclarée au niveau colonne
    nom_produit VARCHAR(100)  NOT NULL,
    prix        DECIMAL(10,2) NOT NULL
);

CREATE TABLE CLIENT (
    id_client       INT          NOT NULL PRIMARY KEY,  -- PK simple	 déclarée au niveau colonne
    nom_client      VARCHAR(100) NOT NULL,
    id_pays         INT          NULL,                  -- cardinalité 0..N : FK ajoutée plus bas via ALTER TABLE, NULLABLE (pays de résidence facultatif)
    id_region_fact  INT          NULL,                  -- cardinalité 0..1 : ville de facturation préférée (facultative)
    code_ville_fact VARCHAR(10)  NULL,
    id_produit_favori INT        NULL REFERENCES PRODUIT(id_produit),           -- FK simple	NULL     déclarée au niveau colonne
    CONSTRAINT UQ_CLIENT_VILLE_FACT UNIQUE (id_region_fact, code_ville_fact),     -- garantit l'unicité -> 0..1 côté VILLE aussi
    CONSTRAINT FK_CLIENT_VILLE_FACT FOREIGN KEY (id_region_fact, code_ville_fact) -- FK composite NULL	 déclarée au niveau table
        REFERENCES VILLE(id_region, code_ville)
);

ALTER TABLE CLIENT
    ADD CONSTRAINT FK_CLIENT_PAYS FOREIGN KEY (id_pays) -- FK simple	NULL     déclarée au niveau ALTER
        REFERENCES PAYS(id_pays);                     -- cardinalité 0..N

CREATE TABLE COMPTE_CLIENT (
    id_client      INT         NOT NULL PRIMARY KEY              -- PK simple	 déclarée au niveau colonne
                                REFERENCES CLIENT(id_client),  -- cardinalité 1..1 : PK = FK (clé partagée) -- FK simple	NOT NULL déclarée au niveau colonne
    numero_compte  VARCHAR(30) NOT NULL,
    date_ouverture DATE        NOT NULL
);

CREATE TABLE COMMANDE (
    id_commande          INT         NOT NULL,
    id_client            INT         NOT NULL,  -- cardinalité 1..N : FK obligatoire ajoutée plus bas via ALTER TABLE
    id_region            INT         NOT NULL,
    code_ville           VARCHAR(10) NOT NULL,
    date_commande        DATE        NOT NULL,
    id_produit_promo     INT         NULL,
    id_region_livraison  INT         NULL,
    code_ville_livraison VARCHAR(10) NULL,
    CONSTRAINT FK_COMMANDE_PRODUIT_PROMO FOREIGN KEY (id_produit_promo)
        REFERENCES PRODUIT(id_produit)          -- FK simple	NULL     déclarée au niveau table
);

ALTER TABLE COMMANDE
    ADD CONSTRAINT PK_COMMANDE PRIMARY KEY (id_commande);   -- PK simple	 déclarée au niveau ALTER

ALTER TABLE COMMANDE
    ADD CONSTRAINT FK_COMMANDE_CLIENT FOREIGN KEY (id_client) -- FK simple	NOT NULL déclarée au niveau ALTER
        REFERENCES CLIENT(id_client);                       -- cardinalité 1..N

ALTER TABLE COMMANDE
    ADD CONSTRAINT FK_COMMANDE_VILLE FOREIGN KEY (id_region, code_ville) -- FK composite	NOT NULL déclarée au niveau ALTER
        REFERENCES VILLE(id_region, code_ville);

ALTER TABLE COMMANDE
    ADD CONSTRAINT FK_COMMANDE_VILLE_LIVRAISON FOREIGN KEY (id_region_livraison, code_ville_livraison)
        REFERENCES VILLE(id_region, code_ville);   -- FK composite	NULL	 déclarée au niveau ALTER

CREATE TABLE LIGNE_COMMANDE (
    id_commande   INT         NOT NULL,
    numero_ligne  INT         NOT NULL,
    id_produit    INT         NOT NULL REFERENCES PRODUIT(id_produit),  -- FK simple	NOT NULL déclarée au niveau colonne
    id_region     INT         NOT NULL,
    code_ville    VARCHAR(10) NOT NULL,
    quantite      INT         NOT NULL,
    CONSTRAINT FK_LIGNE_VILLE FOREIGN KEY (id_region, code_ville) -- FK composite NOT NULL	 déclarée au niveau table
        REFERENCES VILLE(id_region, code_ville)   -- FK table-level (composite)
    -- LIGNE_COMMANDE est la table d'association qui réalise la cardinalité N..N
    -- entre COMMANDE et PRODUIT : une commande contient plusieurs produits
    -- (via plusieurs lignes), et un produit apparaît dans plusieurs commandes.
);

ALTER TABLE LIGNE_COMMANDE
    ADD CONSTRAINT PK_LIGNE_COMMANDE PRIMARY KEY (id_commande, numero_ligne);   -- PK composite	 déclarée au niveau ALTER

ALTER TABLE LIGNE_COMMANDE
    ADD CONSTRAINT FK_LIGNE_COMMANDE FOREIGN KEY (id_commande) -- FK simple	NOT NULL déclarée au niveau ALTER
        REFERENCES COMMANDE(id_commande);                    -- complète la table d'association N..N
