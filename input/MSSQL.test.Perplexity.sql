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

CREATE TABLE client (
    id_client        INT NOT NULL PRIMARY KEY,  -- PK simple	 déclarée au niveau colonne
    id_responsable   INT NULL,
    nom              NVARCHAR(100) NOT NULL,
    prenom           NVARCHAR(100) NULL,
    email            NVARCHAR(255) NULL,
    CONSTRAINT uq_client_responsable UNIQUE (id_responsable)
);

CREATE TABLE categorie (
    id_categorie     INT NOT NULL,
    nom_categorie    NVARCHAR(100) NOT NULL
);

ALTER TABLE categorie
ADD CONSTRAINT pk_categorie PRIMARY KEY (id_categorie); -- PK simple	 déclarée au niveau ALTER

CREATE TABLE produit (
    id_produit            INT NOT NULL PRIMARY KEY,  -- PK simple	 déclarée au niveau colonne
    code                  NVARCHAR(50) NOT NULL,
    libelle               NVARCHAR(200) NOT NULL,
    prix_unitaire         DECIMAL(10, 2) NOT NULL,
    id_categorie_principale INT NULL
        REFERENCES categorie(id_categorie)           -- FK simple	NULL     déclarée au niveau colonne
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    id_categorie_secondaire INT NULL
    -- UNIQUE inline possible ici si besoin
);

ALTER TABLE produit
ADD CONSTRAINT fk_produit_categorie_secondaire      -- FK simple	NULL     déclarée au niveau ALTER
    FOREIGN KEY (id_categorie_secondaire)
    REFERENCES categorie(id_categorie)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

CREATE TABLE version_produit (
    id_produit       INT NOT NULL,
    version_produit  INT NOT NULL,
    date_publication DATE NOT NULL,
    CONSTRAINT pk_version_produit PRIMARY KEY (id_produit, version_produit), -- PK composite	 déclarée au niveau table
    CONSTRAINT fk_version_produit_produit
        FOREIGN KEY (id_produit) REFERENCES produit(id_produit)          -- FK simple	NOT NULL déclarée au niveau table
);

CREATE TABLE famille_produit (
    id_famille       INT NOT NULL,
    code_famille     NVARCHAR(50) NOT NULL,
    nom_famille      NVARCHAR(200) NOT NULL,
    CONSTRAINT pk_famille_produit PRIMARY KEY (id_famille, code_famille) -- PK composite	 déclarée au niveau table
);

CREATE TABLE article_categorie_associee (
    id_article       INT NULL,
    version_article  INT NULL,
    id_famille       INT NULL,
    code_famille     NVARCHAR(50) NULL,
    CONSTRAINT fk_article_categorie_associee_famille
        FOREIGN KEY (id_famille, code_famille)
        REFERENCES famille_produit(id_famille, code_famille) -- FK composite NULL	 déclarée au niveau table
);

CREATE TABLE produit_famille (
    id_produit       INT NOT NULL
        REFERENCES produit(id_produit)               -- FK simple	NOT NULL déclarée au niveau colonne
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    id_famille       INT NULL,                       -- pour FK composite nullable
    code_famille     NVARCHAR(50) NULL,              -- pour FK composite nullable
    rang             INT NOT NULL,
    CONSTRAINT pk_produit_famille PRIMARY KEY (id_produit, rang) -- PK composite	 déclarée au niveau table
);

ALTER TABLE produit_famille
ADD CONSTRAINT fk_produit_famille_famille
    FOREIGN KEY (id_famille, code_famille)
    REFERENCES famille_produit(id_famille, code_famille) -- FK composite	NULL	 déclarée au niveau ALTER
    ON DELETE SET NULL
    ON UPDATE CASCADE;

CREATE TABLE adresse_livraison (
    id_adresse       INT NOT NULL PRIMARY KEY,      -- PK simple	 déclarée au niveau colonne
    id_client        INT NOT NULL,
    ligne1           NVARCHAR(200) NOT NULL,
    ligne2           NVARCHAR(200) NULL,
    code_postal      NVARCHAR(20) NOT NULL,
    ville            NVARCHAR(100) NOT NULL,
    CONSTRAINT uq_adresse_client UNIQUE (id_client),
    CONSTRAINT fk_adresse_livraison_client
        FOREIGN KEY (id_client) REFERENCES client(id_client) -- FK simple	NOT NULL déclarée au niveau table
);

CREATE TABLE commande (
    id_commande      INT NOT NULL,
    id_client        INT NOT NULL,
    id_adresse       INT NULL,
    date_commande    DATETIME2 NOT NULL,
    statut           NVARCHAR(50) NOT NULL,
    CONSTRAINT pk_commande PRIMARY KEY (id_commande), -- PK simple	 déclarée au niveau table
    CONSTRAINT fk_commande_adresse_livraison
        FOREIGN KEY (id_adresse) REFERENCES adresse_livraison(id_adresse) -- FK simple	NULL     déclarée au niveau table
);

ALTER TABLE commande
ADD CONSTRAINT fk_commande_client                -- FK simple	NOT NULL déclarée au niveau ALTER
    FOREIGN KEY (id_client)
    REFERENCES client(id_client)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

CREATE TABLE ligne_commande (
    id_commande      INT NOT NULL
        REFERENCES commande(id_commande)            -- FK simple	NOT NULL déclarée au niveau colonne
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    numero_ligne     INT NOT NULL,
    id_produit       INT NOT NULL
        REFERENCES produit(id_produit)              -- FK simple	NOT NULL déclarée au niveau colonne
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    quantite         INT NOT NULL,
    prix_unitaire    DECIMAL(10, 2) NOT NULL,
    CONSTRAINT pk_ligne_commande PRIMARY KEY (id_commande, numero_ligne) -- PK composite	 déclarée au niveau table
);

CREATE TABLE contact (
    id_contact       INT NOT NULL PRIMARY KEY,      -- PK simple	 déclarée au niveau colonne
    nom              NVARCHAR(100) NOT NULL,
    prenom           NVARCHAR(100) NULL,
    email            NVARCHAR(255) NULL
);

CREATE TABLE client_contact (
    id_client        INT NOT NULL
        REFERENCES client(id_client)                -- FK simple	NOT NULL déclarée au niveau colonne
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    id_contact       INT NOT NULL
        REFERENCES contact(id_contact)              -- FK simple	NOT NULL déclarée au niveau colonne
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    role             NVARCHAR(100) NULL,
    CONSTRAINT pk_client_contact PRIMARY KEY (id_client, id_contact) -- PK composite	 déclarée au niveau table
);

CREATE TABLE stock_article (
    id_article       INT NOT NULL,
    version_article  INT NOT NULL,
    id_famille       INT NOT NULL,
    code_famille     NVARCHAR(50) NOT NULL,
    quantite         INT NOT NULL,
    CONSTRAINT fk_stock_article_article
        FOREIGN KEY (id_article, version_article)
        REFERENCES version_produit(id_produit, version_produit) -- FK composite NOT NULL déclarée au niveau table
);

ALTER TABLE stock_article
ADD CONSTRAINT pk_stock_article PRIMARY KEY (id_article, version_article); -- PK composite	 déclarée au niveau ALTER

ALTER TABLE stock_article
ADD CONSTRAINT fk_stock_article_famille
    FOREIGN KEY (id_famille, code_famille)
    REFERENCES famille_produit(id_famille, code_famille); -- FK composite	NOT NULL déclarée au niveau ALTER