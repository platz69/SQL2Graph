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

-- 1) Table client
CREATE TABLE client (
    id_client        INT NOT NULL PRIMARY KEY,      -- PK inline -- PK simple
    id_responsable   INT NULL,
    nom              VARCHAR(100) NOT NULL,
    prenom           VARCHAR(100) NULL,
    email            VARCHAR(255) NULL,
    CONSTRAINT uq_client_responsable UNIQUE (id_responsable)
) ENGINE=InnoDB;

-- 2) Table categorie
CREATE TABLE categorie (
    id_categorie     INT NOT NULL PRIMARY KEY,      -- PK inline -- PK simple
    nom_categorie    VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- 3) Table produit
CREATE TABLE produit (
    id_produit            INT NOT NULL PRIMARY KEY,  -- PK inline -- PK simple
    code                  VARCHAR(50) NOT NULL,
    libelle               VARCHAR(200) NOT NULL,
    prix_unitaire         DECIMAL(10, 2) NOT NULL,
    id_categorie_principale INT NULL
        REFERENCES categorie(id_categorie)           -- FK inline nullable
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    id_categorie_secondaire INT NULL                 -- FK table-level via ALTER
) ENGINE=InnoDB;

-- FK simple nullable au niveau table
ALTER TABLE produit
ADD CONSTRAINT fk_produit_categorie_secondaire
    FOREIGN KEY (id_categorie_secondaire)
    REFERENCES categorie(id_categorie)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

-- 4) Table famille_produit
CREATE TABLE famille_produit (
    id_famille       INT NOT NULL,
    code_famille     VARCHAR(50) NOT NULL,
    nom_famille      VARCHAR(200) NOT NULL,
    CONSTRAINT pk_famille_produit PRIMARY KEY (id_famille, code_famille) -- PK composite
) ENGINE=InnoDB;

-- 5) Table produit_famille
CREATE TABLE produit_famille (
    id_produit       INT NOT NULL
        REFERENCES produit(id_produit)               -- FK inline
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    id_famille       INT NULL,
    code_famille     VARCHAR(50) NULL,
    rang             INT NOT NULL,
    CONSTRAINT pk_produit_famille PRIMARY KEY (id_produit, rang) -- PK composite
) ENGINE=InnoDB;

-- FK composite nullable via ALTER
ALTER TABLE produit_famille
ADD CONSTRAINT fk_produit_famille_famille
    FOREIGN KEY (id_famille, code_famille)
    REFERENCES famille_produit(id_famille, code_famille)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

-- 6) Table adresse_livraison
CREATE TABLE adresse_livraison (
    id_adresse       INT NOT NULL PRIMARY KEY,      -- PK inline -- PK simple
    id_client        INT NOT NULL
        REFERENCES client(id_client)                -- FK inline
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    ligne1           VARCHAR(200) NOT NULL,
    ligne2           VARCHAR(200) NULL,
    code_postal      VARCHAR(20) NOT NULL,
    ville            VARCHAR(100) NOT NULL,
    CONSTRAINT uq_adresse_client UNIQUE (id_client)
) ENGINE=InnoDB;

-- 7) Table commande
CREATE TABLE commande (
    id_commande      INT NOT NULL PRIMARY KEY,      -- PK inline -- PK simple
    id_client        INT NOT NULL,
    id_adresse       INT NULL,
    date_commande    DATETIME NOT NULL,
    statut           VARCHAR(50) NOT NULL
) ENGINE=InnoDB;

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
    id_commande      INT NOT NULL
        REFERENCES commande(id_commande)            -- FK inline
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    numero_ligne     INT NOT NULL,
    id_produit       INT NOT NULL
        REFERENCES produit(id_produit)              -- FK inline
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    quantite         INT NOT NULL,
    prix_unitaire    DECIMAL(10, 2) NOT NULL,
    CONSTRAINT pk_ligne_commande PRIMARY KEY (id_commande, numero_ligne) -- PK composite
) ENGINE=InnoDB;

-- 9) Table contact
CREATE TABLE contact (
    id_contact       INT NOT NULL PRIMARY KEY,      -- PK inline -- PK simple
    nom              VARCHAR(100) NOT NULL,
    prenom           VARCHAR(100) NULL,
    email            VARCHAR(255) NULL
) ENGINE=InnoDB;

-- 10) Table client_contact (n..n)
CREATE TABLE client_contact (
    id_client        INT NOT NULL
        REFERENCES client(id_client)                -- FK inline
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    id_contact       INT NOT NULL
        REFERENCES contact(id_contact)              -- FK inline
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    role             VARCHAR(100) NULL,
    CONSTRAINT pk_client_contact PRIMARY KEY (id_client, id_contact) -- PK composite
) ENGINE=InnoDB;