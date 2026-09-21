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
--    FK simple		NULL     déclarée au niveau colonne > oui
--    FK simple	    NOT NULL déclarée au niveau colonne > oui
--    FK composite	NULL	 déclarée au niveau colonne > impossible (une PK/FK composite ne peut être déclarée au niveau colonne)
--    FK composite	NOT NULL déclarée au niveau colonne > impossible (une PK/FK composite ne peut être déclarée au niveau colonne)
--    FK simple		NULL     déclarée au niveau table   > oui
--    FK simple	    NOT NULL déclarée au niveau table   > oui
--    FK composite	NULL	 déclarée au niveau table   > oui
--    FK composite	NOT NULL déclarée au niveau table   > oui
--    FK simple		NULL     déclarée au niveau ALTER   > oui
--    FK simple	    NOT NULL déclarée au niveau ALTER   > oui
--    FK composite	NULL	 déclarée au niveau ALTER   > oui
--    FK composite	NOT NULL déclarée au niveau ALTER   > oui

CREATE TABLE T_PAYS (
    id_pays    INT          NOT NULL PRIMARY KEY,   -- PK inline (colonne) -- PK simple
    code_iso   CHAR(2)      NOT NULL,
    nom_pays   VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE T_REGION (
    id_region  INT          NOT NULL,
    id_pays    INT          NOT NULL REFERENCES T_PAYS(id_pays),  -- FK inline (colonne) -- cardinalité 1..N (PAYS -> REGION) -- FK simple
    nom_region VARCHAR(100) NOT NULL,
    CONSTRAINT PK_REGION PRIMARY KEY (id_region)                  -- PK table-level (simple) -- PK simple
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE T_VILLE (
    id_region  INT          NOT NULL,   -- fait partie de la PK composite + FK vers T_REGION -- cardinalité 1..N (REGION -> VILLE)
    code_ville VARCHAR(10)  NOT NULL,
    nom_ville  VARCHAR(100) NOT NULL,
    CONSTRAINT PK_VILLE PRIMARY KEY (id_region, code_ville),                              -- PK table-level (composite) -- PK composite
    CONSTRAINT FK_VILLE_REGION FOREIGN KEY (id_region) REFERENCES T_REGION(id_region)     -- FK table-level (simple) -- FK simple
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE T_PRODUIT (
    id_produit  INT           NOT NULL PRIMARY KEY,  -- PK inline (colonne) -- PK simple
    nom_produit VARCHAR(100)  NOT NULL,
    prix        DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE T_CLIENT (
    id_client       INT          NOT NULL PRIMARY KEY,  -- PK inline (colonne) -- PK simple
    nom_client      VARCHAR(100) NOT NULL,
    id_pays         INT          NULL,                  -- cardinalité 0..N : FK ajoutée plus bas via ALTER TABLE, NULLABLE (pays de résidence facultatif)
    id_region_fact  INT          NULL,                  -- cardinalité 0..1 : ville de facturation préférée (facultative)
    code_ville_fact VARCHAR(10)  NULL,
    id_produit_favori INT        NULL REFERENCES T_PRODUIT(id_produit),  -- FK simple NULLable déclarée au niveau colonne -- FK simple
    CONSTRAINT UQ_CLIENT_VILLE_FACT UNIQUE (id_region_fact, code_ville_fact),                 -- garantit l'unicité -> 0..1 côté VILLE aussi
    CONSTRAINT FK_CLIENT_VILLE_FACT FOREIGN KEY (id_region_fact, code_ville_fact) -- FK composite
        REFERENCES T_VILLE(id_region, code_ville)                                            -- FK table-level composite, nullable
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE T_COMPTE_CLIENT (
    id_client      INT         NOT NULL PRIMARY KEY REFERENCES T_CLIENT(id_client),  -- cardinalité 1..1 : PK = FK (clé partagée) -- PK simple
    numero_compte  VARCHAR(30) NOT NULL,
    date_ouverture DATE        NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE T_COMMANDE (
    id_commande          INT         NOT NULL,  -- PK ajoutée plus bas via ALTER TABLE
    id_client            INT         NOT NULL,  -- cardinalité 1..N : FK obligatoire ajoutée plus bas via ALTER TABLE
    id_region            INT         NOT NULL,  -- FK composite ajoutée plus bas via ALTER TABLE
    code_ville           VARCHAR(10) NOT NULL,
    date_commande        DATE        NOT NULL,
    id_produit_promo     INT         NULL,       -- FK simple NULLable déclarée au niveau table (ci-dessous)
    id_region_livraison  INT         NULL,       -- FK composite NULLable ajoutée plus bas via ALTER TABLE (ville de livraison facultative)
    code_ville_livraison VARCHAR(10) NULL,
    CONSTRAINT FK_COMMANDE_PRODUIT_PROMO FOREIGN KEY (id_produit_promo) -- FK simple
        REFERENCES T_PRODUIT(id_produit)          -- FK simple NULLable déclarée au niveau table
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE T_LIGNE_COMMANDE (
    id_commande   INT         NOT NULL,  -- PK composite ajoutée plus bas via ALTER TABLE
    numero_ligne  INT         NOT NULL,
    id_produit    INT         NOT NULL REFERENCES T_PRODUIT(id_produit),  -- FK inline (colonne) -- FK simple
    id_region     INT         NOT NULL,
    code_ville    VARCHAR(10) NOT NULL,
    quantite      INT         NOT NULL,
    CONSTRAINT FK_LIGNE_VILLE FOREIGN KEY (id_region, code_ville) -- FK composite
        REFERENCES T_VILLE(id_region, code_ville)   -- FK table-level (composite)
    -- T_LIGNE_COMMANDE est la table d'association qui réalise la cardinalité N..N
    -- entre T_COMMANDE et T_PRODUIT : une commande contient plusieurs produits
    -- (via plusieurs lignes), et un produit apparaît dans plusieurs commandes.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- Contraintes restantes ajoutées via ALTER TABLE ----

ALTER TABLE T_CLIENT
    ADD CONSTRAINT FK_CLIENT_PAYS FOREIGN KEY (id_pays) -- FK simple
        REFERENCES T_PAYS(id_pays);   -- FK via ALTER (simple), nullable -- cardinalité 0..N

ALTER TABLE T_COMMANDE
    ADD CONSTRAINT PK_COMMANDE PRIMARY KEY (id_commande);   -- PK via ALTER (simple) -- PK simple

ALTER TABLE T_COMMANDE
    ADD CONSTRAINT FK_COMMANDE_CLIENT FOREIGN KEY (id_client) -- FK simple
        REFERENCES T_CLIENT(id_client);   -- FK via ALTER (simple), obligatoire -- cardinalité 1..N

ALTER TABLE T_COMMANDE
    ADD CONSTRAINT FK_COMMANDE_VILLE FOREIGN KEY (id_region, code_ville) -- FK composite
        REFERENCES T_VILLE(id_region, code_ville);   -- FK via ALTER (composite)

ALTER TABLE T_LIGNE_COMMANDE
    ADD CONSTRAINT PK_LIGNE_COMMANDE PRIMARY KEY (id_commande, numero_ligne);   -- PK via ALTER (composite) -- PK composite

ALTER TABLE T_LIGNE_COMMANDE
    ADD CONSTRAINT FK_LIGNE_COMMANDE FOREIGN KEY (id_commande) -- FK simple
        REFERENCES T_COMMANDE(id_commande);   -- FK via ALTER (simple), complète la table d'association N..N

ALTER TABLE T_COMMANDE
    ADD CONSTRAINT FK_COMMANDE_VILLE_LIVRAISON FOREIGN KEY (id_region_livraison, code_ville_livraison) -- FK composite
        REFERENCES T_VILLE(id_region, code_ville);   -- FK composite NULLable ajoutée via ALTER TABLE
