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

CREATE TABLE
-- correspondant (mêmes tables, mêmes colonnes, mêmes contraintes -- seul le
-- moment de la déclaration change). Un commentaire "(normalement via ALTER)"
-- indique chaque cas concerné.
--
-- N'oublie pas d'activer l'application des clés étrangères (désactivée par
-- défaut dans SQLite) :
PRAGMA foreign_keys = ON;
-- ============================================================================
-- STYLES DE DÉCLARATION PK/FK :
--   T_PAYS            : PK inline (colonne)
--   T_REGION          : FK inline (colonne)              + PK table-level simple
--   T_VILLE           : FK table-level simple             + PK table-level composite
--   T_PRODUIT         : PK inline (colonne)
--   T_CLIENT          : PK inline (colonne) + FK inline simple NULLable (produit favori)
--                        + FK table-level composite + UNIQUE (inline)
--                        + FK table-level simple (normalement via ALTER)
--   T_COMPTE_CLIENT   : PK inline = FK inline (clé partagée)
--   T_COMMANDE        : PK table-level simple (normalement via ALTER)
--                        + FK table-level simple et composite (normalement via ALTER)
--                        + FK table-level simple NULLable (produit en promotion)
--                        + FK table-level composite NULLable (normalement via ALTER : ville de livraison)
--   T_LIGNE_COMMANDE  : FK inline (colonne) + FK table-level composite
--                        + PK table-level composite (normalement via ALTER)
--                        + FK table-level simple (normalement via ALTER)
--
-- CARDINALITÉS DÉMONTRÉES :
--   1..1  : T_CLIENT <-> T_COMPTE_CLIENT   (clé partagée : PK = FK, NOT NULL)
--   0..1  : T_CLIENT <-> T_VILLE           (ville de facturation préférée : FK nullable + UNIQUE)
--   1..N  : T_CLIENT <-> T_COMMANDE        (FK obligatoire, non unique)
--           (également T_PAYS<->T_REGION et T_REGION<->T_VILLE : FK obligatoires)
--   0..N  : T_PAYS <-> T_CLIENT            (FK nullable, non unique)
--   N..N  : T_COMMANDE <-> T_PRODUIT       (via la table d'association T_LIGNE_COMMANDE)
-- ============================================================================

CREATE TABLE T_PAYS (
    id_pays    INTEGER      NOT NULL PRIMARY KEY,   -- PK inline (colonne) -- PK simple
    code_iso   CHAR(2)      NOT NULL,
    nom_pays   VARCHAR(100) NOT NULL
);

CREATE TABLE T_REGION (
    id_region  INTEGER      NOT NULL,
    id_pays    INTEGER      NOT NULL REFERENCES T_PAYS(id_pays),  -- FK inline (colonne) -- cardinalité 1..N (PAYS -> REGION) -- FK simple
    nom_region VARCHAR(100) NOT NULL,
    CONSTRAINT PK_REGION PRIMARY KEY (id_region)                  -- PK table-level (simple) -- PK simple
);

CREATE TABLE T_VILLE (
    id_region  INTEGER      NOT NULL,   -- fait partie de la PK composite + FK vers T_REGION -- cardinalité 1..N (REGION -> VILLE)
    code_ville VARCHAR(10)  NOT NULL,
    nom_ville  VARCHAR(100) NOT NULL,
    CONSTRAINT PK_VILLE PRIMARY KEY (id_region, code_ville),                              -- PK table-level (composite) -- PK composite
    CONSTRAINT FK_VILLE_REGION FOREIGN KEY (id_region) REFERENCES T_REGION(id_region)     -- FK table-level (simple) -- FK simple
);

CREATE TABLE T_PRODUIT (
    id_produit  INTEGER       NOT NULL PRIMARY KEY,  -- PK inline (colonne) -- PK simple
    nom_produit VARCHAR(100)  NOT NULL,
    prix        DECIMAL(10,2) NOT NULL
);

CREATE TABLE T_CLIENT (
    id_client       INTEGER      NOT NULL PRIMARY KEY,  -- PK inline (colonne) -- PK simple
    nom_client      VARCHAR(100) NOT NULL,
    id_pays         INTEGER      NULL,                  -- cardinalité 0..N, NULLABLE (pays de résidence facultatif)
    id_region_fact  INTEGER      NULL,                  -- cardinalité 0..1 : ville de facturation préférée (facultative)
    code_ville_fact VARCHAR(10)  NULL,
    id_produit_favori INTEGER    NULL REFERENCES T_PRODUIT(id_produit),  -- FK simple NULLable déclarée au niveau colonne -- FK simple
    CONSTRAINT FK_CLIENT_PAYS FOREIGN KEY (id_pays) -- FK simple
        REFERENCES T_PAYS(id_pays),                                                          -- FK table-level (normalement via ALTER)
    CONSTRAINT UQ_CLIENT_VILLE_FACT UNIQUE (id_region_fact, code_ville_fact),                 -- garantit l'unicité -> 0..1 côté VILLE aussi
    CONSTRAINT FK_CLIENT_VILLE_FACT FOREIGN KEY (id_region_fact, code_ville_fact) -- FK composite
        REFERENCES T_VILLE(id_region, code_ville)                                            -- FK table-level composite, nullable
);

CREATE TABLE T_COMPTE_CLIENT (
    id_client      INTEGER     NOT NULL PRIMARY KEY REFERENCES T_CLIENT(id_client),  -- cardinalité 1..1 : PK = FK (clé partagée) -- PK simple
    numero_compte  VARCHAR(30) NOT NULL,
    date_ouverture DATE        NOT NULL
);

CREATE TABLE T_COMMANDE (
    id_commande          INTEGER     NOT NULL,
    id_client            INTEGER     NOT NULL,  -- cardinalité 1..N : FK obligatoire
    id_region            INTEGER     NOT NULL,
    code_ville           VARCHAR(10) NOT NULL,
    date_commande        DATE        NOT NULL,
    id_produit_promo     INTEGER     NULL,       -- FK simple NULLable, table-level
    id_region_livraison  INTEGER     NULL,       -- FK composite NULLable (normalement via ALTER : ville de livraison facultative)
    code_ville_livraison VARCHAR(10) NULL,
    CONSTRAINT PK_COMMANDE PRIMARY KEY (id_commande),                                 -- PK table-level (normalement via ALTER) -- PK simple
    CONSTRAINT FK_COMMANDE_CLIENT FOREIGN KEY (id_client) -- FK simple
        REFERENCES T_CLIENT(id_client),                                              -- FK table-level (normalement via ALTER)
    CONSTRAINT FK_COMMANDE_VILLE FOREIGN KEY (id_region, code_ville) -- FK composite
        REFERENCES T_VILLE(id_region, code_ville),                                   -- FK table-level composite (normalement via ALTER)
    CONSTRAINT FK_COMMANDE_PRODUIT_PROMO FOREIGN KEY (id_produit_promo) -- FK simple
        REFERENCES T_PRODUIT(id_produit),                                            -- FK simple NULLable, table-level
    CONSTRAINT FK_COMMANDE_VILLE_LIVRAISON FOREIGN KEY (id_region_livraison, code_ville_livraison) -- FK composite
        REFERENCES T_VILLE(id_region, code_ville)                                    -- FK composite NULLable (normalement via ALTER)
);

CREATE TABLE T_LIGNE_COMMANDE (
    id_commande   INTEGER     NOT NULL,
    numero_ligne  INTEGER     NOT NULL,
    id_produit    INTEGER     NOT NULL REFERENCES T_PRODUIT(id_produit),  -- FK inline (colonne) -- FK simple
    id_region     INTEGER     NOT NULL,
    code_ville    VARCHAR(10) NOT NULL,
    quantite      INTEGER     NOT NULL,
    CONSTRAINT PK_LIGNE_COMMANDE PRIMARY KEY (id_commande, numero_ligne),             -- PK table-level composite (normalement via ALTER) -- PK composite
    CONSTRAINT FK_LIGNE_COMMANDE FOREIGN KEY (id_commande) -- FK simple
        REFERENCES T_COMMANDE(id_commande),                                          -- FK table-level (normalement via ALTER)
    CONSTRAINT FK_LIGNE_VILLE FOREIGN KEY (id_region, code_ville) -- FK composite
        REFERENCES T_VILLE(id_region, code_ville)                                    -- FK table-level (composite)
    -- T_LIGNE_COMMANDE est la table d'association qui réalise la cardinalité N..N
    -- entre T_COMMANDE et T_PRODUIT : une commande contient plusieurs produits
    -- (via plusieurs lignes), et un produit apparaît dans plusieurs commandes.
);
