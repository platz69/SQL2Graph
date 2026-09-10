-- Résultats OK

-- table parente
CREATE TABLE [dbo].[Client] (
    [Id] [int] NOT NULL,
    [ClientId] [int] NOT NULL,
    [SocieteId] [int] NOT NULL
);

-- tables filles avec différentes façons de déclarer les contraintes de clé étrangère

--1. FK inline sur la colonne — sans nom : C'est la forme la plus compacte
CREATE TABLE [dbo].[Commande1] (
    [Id] [int] NOT NULL,
    [ClientId] [int] NOT NULL
        FOREIGN KEY REFERENCES [dbo].[Client] ([Id])
);

--2. FK inline sur la colonne — avec CONSTRAINT : Même chose, mais avec un nom explicite
CREATE TABLE [dbo].[Commande2] (
    [Id] [int] NOT NULL,
    [ClientId] [int] NOT NULL
        CONSTRAINT [FK_Commande_Client2]
        FOREIGN KEY
        REFERENCES [dbo].[Client] ([Id])
);

--3. FK au niveau table — sans nom
CREATE TABLE [dbo].[Commande3] (
    [Id] [int] NOT NULL,
    [ClientId] [int] NOT NULL,

    PRIMARY KEY ([Id]),

    FOREIGN KEY ([ClientId])
        REFERENCES [dbo].[Client] ([Id])
);

--4. FK au niveau table — avec CONSTRAINT
CREATE TABLE [dbo].[Commande4] (
    [Id] [int] NOT NULL,
    [ClientId] [int] NOT NULL,

    CONSTRAINT [PK_Commande4]
        PRIMARY KEY ([Id]),

    CONSTRAINT [FK_Commande_Client4]
        FOREIGN KEY ([ClientId])
        REFERENCES [dbo].[Client] ([Id])
);

--5. PK inline + FK inline :on peut également mettre les deux contraintes directement sur les colonnes :
CREATE TABLE [dbo].[Commande5] (
    [Id] [int] NOT NULL
        CONSTRAINT [PK_Commande5]
        PRIMARY KEY,

    [ClientId] [int] NOT NULL
        CONSTRAINT [FK_Commande_Client5]
        FOREIGN KEY
        REFERENCES [dbo].[Client] ([Id])
);

--6. PK inline + FK au niveau table
CREATE TABLE [dbo].[Commande6] (
    [Id] [int] NOT NULL
        CONSTRAINT [PK_Commande6]
        PRIMARY KEY,

    [ClientId] [int] NOT NULL,

    CONSTRAINT [FK_Commande_Client6]
        FOREIGN KEY ([ClientId])
        REFERENCES [dbo].[Client] ([Id])
);

--7. PK et FK avec crochets partout : SQL Server accepte également cette écriture très courante dans les scripts générés par SSMS :
CREATE TABLE [dbo].[Commande7]
(
    [Id] [int] NOT NULL,
    [ClientId] [int] NOT NULL,

    CONSTRAINT [PK_Commande7]
        PRIMARY KEY CLUSTERED
        (
            [Id] ASC
        ),

    CONSTRAINT [FK_Commande_Client7]
        FOREIGN KEY
        (
            [ClientId]
        )
        REFERENCES [dbo].[Client]
        (
            [Id]
        )
);

--8. ALTER TABLE avec FK
CREATE TABLE [dbo].[Commande8] (
    [Id] [int] NOT NULL,
    [ClientId] [int] NOT NULL,

    CONSTRAINT [PK_Commande8]
        PRIMARY KEY ([Id])
);

ALTER TABLE [dbo].[Commande8]
ADD CONSTRAINT [FK_Commande_Client8]
    FOREIGN KEY ([ClientId])
    REFERENCES [dbo].[Client] ([Id]);

--9. ALTER TABLE avec FK sans nom
CREATE TABLE [dbo].[Commande9] (
    [Id] [int] NOT NULL,
    [ClientId] [int] NOT NULL,

    CONSTRAINT [PK_Commande9]
        PRIMARY KEY ([Id])
);

ALTER TABLE [dbo].[Commande9]
ADD FOREIGN KEY ([ClientId])
REFERENCES [dbo].[Client] ([Id]);

--10. FK avec ON DELETE : La FK peut comporter des actions référentielles
CREATE TABLE [dbo].[Commande10] (
    [Id] [int] NOT NULL,
    [ClientId] [int] NOT NULL,

    CONSTRAINT [PK_Commande10]
        PRIMARY KEY ([Id]),

    CONSTRAINT [FK_Commande_Client10]
        FOREIGN KEY ([ClientId])
        REFERENCES [dbo].[Client] ([Id])
        ON DELETE CASCADE
);

--11. FK avec ON UPDATE : Même principe
CREATE TABLE [dbo].[Commande11] (
    [Id] [int] NOT NULL,
    [ClientId] [int] NOT NULL,

CONSTRAINT [FK_Commande_Client11]
    FOREIGN KEY ([ClientId])
    REFERENCES [dbo].[Client] ([Id])
    ON UPDATE CASCADE
);

--12. FK composite : plusieurs colonnes peuvent être référencées.
CREATE TABLE [dbo].[Commande12] (
    [Id] [int] NOT NULL,
    [SocieteId] [int] NOT NULL,
    [ClientId] [int] NOT NULL,

    CONSTRAINT [PK_Commande12]
        PRIMARY KEY ([Id]),

    CONSTRAINT [FK_Commande_Client12]
        FOREIGN KEY ([SocieteId], [ClientId])
        REFERENCES [dbo].[Client] ([SocieteId], [ClientId])
);