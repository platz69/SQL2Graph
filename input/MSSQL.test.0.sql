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
--    PK simple	    NOT NULL déclarée au niveau ALTER   > oui
--    PK composite	NULL	 déclarée au niveau ALTER   > impossible (une PK ne peut être NULL)
--    PK composite	NOT NULL déclarée au niveau ALTER   > oui
--    FK simple		NULL     déclarée au niveau colonne > ************NON
--    FK simple	    NOT NULL déclarée au niveau colonne > oui
--    FK composite	NULL	 déclarée au niveau colonne > impossible (une PK/FK composite ne peut être déclarée au niveau colonne)
--    FK composite	NOT NULL déclarée au niveau colonne > impossible (une PK/FK composite ne peut être déclarée au niveau colonne)
--    FK simple		NULL     déclarée au niveau table   > ***********NON
--    FK simple	    NOT NULL déclarée au niveau table   > oui
--    FK composite	NULL	 déclarée au niveau table   > oui
--    FK composite	NOT NULL déclarée au niveau table   > oui
--    FK simple		NULL     déclarée au niveau ALTER   > oui
--    FK simple	    NOT NULL déclarée au niveau ALTER   > oui
--    FK composite	NULL	 déclarée au niveau ALTER   > ************NON
--    FK composite	NOT NULL déclarée au niveau ALTER   > oui
--    Unicité !
--
-- ============================================================================
-- STYLES DE DÉCLARATION PK/FK :
--   T_PAYS            : PK inline (colonne)
--   T_REGION          : FK inline (colonne)              + PK table-level simple
--   T_VILLE           : FK table-level simple             + PK composite déclarée au niveau table
--   T_PRODUIT         : PK inline (colonne)
--   T_CLIENT          : PK inline (colonne) + FK composite déclarée au niveau table + UNIQUE (inline)
--                        + FK via ALTER TABLE (simple)
--   T_COMPTE_CLIENT   : PK inline = FK inline (clé partagée)
--   T_COMMANDE        : PK via ALTER TABLE (simple) + FK via ALTER TABLE (simple et composite)
--   T_LIGNE_COMMANDE  : FK inline (colonne) + FK composite déclarée au niveau table + PK via ALTER TABLE (composite)
--
-- CARDINALITÉS DÉMONTRÉES :
--  T_CLIENT   -> 1..1 T_COMPTE_CLIENT   (clé partagée : PK = FK, NOT NULL)
--  T_CLIENT   -> 0..1 T_VILLE           (ville de facturation préférée : FK nullable + UNIQUE)
--  T_CLIENT   -> 1..N T_COMMANDE        (FK obligatoire, non unique)
--  T_PAYS     -> 1..N T_REGION
--  T_REGION   -> 1..N T_VILLE           (FK obligatoires)
--  T_PAYS     -> 0..N T_CLIENT          (FK nullable, non unique)
--  T_COMMANDE -> N..N T_PRODUIT         (via la table d'association T_LIGNE_COMMANDE)
-- ============================================================================

CREATE TABLE T_PAYS (
    id_pays    INT          NOT NULL PRIMARY KEY,                 -- PK simple	    NOT NULL déclarée au niveau colonne -- PK simple
    code_iso   CHAR(2)      NOT NULL,
    nom_pays   VARCHAR(100) NOT NULL
);

CREATE TABLE T_REGION (
    id_region  INT          NOT NULL,
    id_pays    INT          NOT NULL REFERENCES T_PAYS(id_pays),  -- FK simple	    NOT NULL déclarée au niveau colonne -- FK simple
    nom_region VARCHAR(100) NOT NULL,
    CONSTRAINT PK_REGION PRIMARY KEY (id_region)                  -- PK simple	    NOT NULL déclarée au niveau table -- PK simple
);

CREATE TABLE T_VILLE (
    id_region  INT          NOT NULL,   -- fait partie de la PK composite + FK vers T_REGION -- cardinalité 1..N (REGION -> VILLE)
    code_ville VARCHAR(10)  NOT NULL,
    nom_ville  VARCHAR(100) NOT NULL,
    CONSTRAINT PK_VILLE PRIMARY KEY (id_region, code_ville),                              -- PK composite	NOT NULL déclarée au niveau table -- PK composite
    CONSTRAINT FK_VILLE_REGION FOREIGN KEY (id_region) REFERENCES T_REGION(id_region)     -- FK simple	    NOT NULL déclarée au niveau table -- FK simple
);

CREATE TABLE T_PRODUIT (
    id_produit  INT           NOT NULL PRIMARY KEY,               -- PK simple	    NOT NULL déclarée au niveau colonne -- PK simple
    nom_produit VARCHAR(100)  NOT NULL,
    prix        DECIMAL(10,2) NOT NULL
);

CREATE TABLE T_CLIENT (
    id_client       INT          NOT NULL PRIMARY KEY,             -- PK simple	    NOT NULL déclarée au niveau colonne -- PK simple
    nom_client      VARCHAR(100) NOT NULL,
    id_pays         INT          NULL,                             -- cardinalité 0..N : FK ajoutée plus bas via ALTER TABLE, NULLABLE (pays de résidence facultatif)
    id_region_fact  INT          NULL,                             -- cardinalité 0..1 : ville de facturation préférée (facultative)
    code_ville_fact VARCHAR(10)  NULL,
    CONSTRAINT UQ_CLIENT_VILLE_FACT UNIQUE (id_region_fact, code_ville_fact),                 -- garantit l'unicité -> 0..1 côté VILLE aussi
    CONSTRAINT FK_CLIENT_VILLE_FACT FOREIGN KEY (id_region_fact, code_ville_fact) -- FK composite
        REFERENCES T_VILLE(id_region, code_ville)                                            -- FK composite	NULL	 déclarée au niveau table
);

CREATE TABLE T_COMPTE_CLIENT (
    id_client      INT         NOT NULL PRIMARY KEY REFERENCES T_CLIENT(id_client),  -- PK simple	    NOT NULL déclarée au niveau colonne, cardinalité 1..1 : PK = FK (clé partagée) -- PK simple
    numero_compte  VARCHAR(30) NOT NULL,                                             -- & FK simple	    NOT NULL déclarée au niveau colonne
    date_ouverture DATE        NOT NULL
);

CREATE TABLE T_COMMANDE (
    id_commande    INT         NOT NULL,                         -- PK ajoutée plus bas via ALTER TABLE
    id_client      INT         NOT NULL,                         -- cardinalité 1..N : FK obligatoire ajoutée plus bas via ALTER TABLE
    id_region      INT         NOT NULL,                         -- FK composite ajoutée plus bas via ALTER TABLE
    code_ville     VARCHAR(10) NOT NULL,
    date_commande  DATE        NOT NULL
);

CREATE TABLE T_LIGNE_COMMANDE (
    id_commande   INT         NOT NULL,                          -- PK composite ajoutée plus bas via ALTER TABLE
    numero_ligne  INT         NOT NULL,
    id_produit    INT         NOT NULL REFERENCES T_PRODUIT(id_produit),  -- FK simple	    NOT NULL déclarée au niveau colonne -- FK simple
    id_region     INT         NOT NULL,
    code_ville    VARCHAR(10) NOT NULL,
    quantite      INT         NOT NULL,
    CONSTRAINT FK_LIGNE_VILLE FOREIGN KEY (id_region, code_ville) -- FK composite
        REFERENCES T_VILLE(id_region, code_ville)   -- FK composite	NOT NULL déclarée au niveau table
    -- T_LIGNE_COMMANDE est la table d'association qui réalise la cardinalité N..N
    -- entre T_COMMANDE et T_PRODUIT : une commande contient plusieurs produits
    -- (via plusieurs lignes), et un produit apparaît dans plusieurs commandes.
);

-- ---- Contraintes restantes ajoutées via ALTER TABLE ----

ALTER TABLE T_CLIENT
    ADD CONSTRAINT FK_CLIENT_PAYS FOREIGN KEY (id_pays) -- FK simple
        REFERENCES T_PAYS(id_pays);                                     -- FK simple		NULL     déclarée au niveau ALTER -- cardinalité 0..N

ALTER TABLE T_COMMANDE
    ADD CONSTRAINT PK_COMMANDE PRIMARY KEY (id_commande);               -- PK simple	    NOT NULL déclarée au niveau ALTER -- PK simple

ALTER TABLE T_COMMANDE
    ADD CONSTRAINT FK_COMMANDE_CLIENT FOREIGN KEY (id_client) -- FK simple
        REFERENCES T_CLIENT(id_client);                                 -- FK simple	    NOT NULL déclarée au niveau ALTER -- cardinalité 1..N

ALTER TABLE T_COMMANDE
    ADD CONSTRAINT FK_COMMANDE_VILLE FOREIGN KEY (id_region, code_ville) -- FK composite
        REFERENCES T_VILLE(id_region, code_ville);                      -- FK composite	NOT NULL déclarée au niveau ALTER

ALTER TABLE T_LIGNE_COMMANDE
    ADD CONSTRAINT PK_LIGNE_COMMANDE PRIMARY KEY (id_commande, numero_ligne);   -- PK composite	NOT NULL déclarée au niveau ALTER -- PK composite

ALTER TABLE T_LIGNE_COMMANDE
    ADD CONSTRAINT FK_LIGNE_COMMANDE FOREIGN KEY (id_commande) -- FK simple
        REFERENCES T_COMMANDE(id_commande);                               --  FK simple	    NOT NULL déclarée au niveau ALTER, complète la table d'association N..N
