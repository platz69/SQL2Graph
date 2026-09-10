CREATE TABLE [dbo].[Client]
(
    [Id] [int] NOT NULL,

    CONSTRAINT [PK_Client]
        PRIMARY KEY ([Id])
);
GO

CREATE TABLE [dbo].[Commande]
(
    [Id] [int] NOT NULL,
    [ClientId] [int] NOT NULL,

    CONSTRAINT [PK_Commande]
        PRIMARY KEY ([Id])
);
GO

ALTER TABLE [dbo].[Commande]
ADD CONSTRAINT [FK_Commande_Client]
    FOREIGN KEY ([ClientId])
    REFERENCES [dbo].[Client] ([Id]);
GO