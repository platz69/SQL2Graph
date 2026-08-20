Je te conseille de faire un outil volontairement simple : il lit un fichier SQL, extrait les tables, colonnes, types, clés primaires et clés étrangères, puis génère un diagramme éditable. Tu n’as pas besoin de modéliser les index, contraintes `UNIQUE`, valeurs par défaut, vues ou procédures.

## Périmètre fonctionnel

Entrée :

```sql
CREATE TABLE customer (
    id BIGINT PRIMARY KEY,
    email VARCHAR(255) NOT NULL
);

CREATE TABLE orders (
    id BIGINT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    total DECIMAL(10,2),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customer(id)
);
```

Données à extraire :

- Nom de la table, éventuellement avec son schéma : `public.customer`
- Nom de chaque colonne : `customer_id`
- Type SQL associé : `BIGINT`, `VARCHAR(255)`, `DECIMAL(10,2)`
- Colonnes de clé primaire
- Contraintes de clé étrangère

Sortie logique attendue :

```json
{
  "tables": [
    {
      "name": "customer",
      "columns": [
        {"name": "id", "type": "BIGINT", "primary_key": true},
        {"name": "email", "type": "VARCHAR(255)", "primary_key": false}
      ],
      "foreign_keys": []
    },
    {
      "name": "orders",
      "columns": [
        {"name": "id", "type": "BIGINT", "primary_key": true},
        {"name": "customer_id", "type": "BIGINT", "primary_key": false},
        {"name": "total", "type": "DECIMAL(10,2)", "primary_key": false}
      ],
      "foreign_keys": [
        {
          "columns": ["customer_id"],
          "target_table": "customer",
          "target_columns": ["id"]
        }
      ]
    }
  ]
}
```

## Stack minimale

| Besoin                | Choix conseillé         | Pourquoi                                                 |
|-----------------------|-------------------------|----------------------------------------------------------|
| Langage               | Python                  | Rapide à développer, très bon support XML et CLI         |
| Parsing SQL           | SQLGlot                 | Évite d’écrire un parseur SQL fragile avec des regex     |
| Modèle intermédiaire  | `dataclasses`           | Suffisant pour représenter tables, colonnes et relations |
| Sortie principale     | draw.io XML (`.drawio`) | Diagramme facilement éditable et partageable             |
| Interface de commande | Typer                   | CLI propre avec peu de code                              |

Le dialecte est fourni explicitement par l’utilisateur :

```bash
sql2mpd schema.sql --dialect postgres --output schema.drawio
sql2mpd schema.sql --dialect mysql --output schema.drawio
sql2mpd schema.sql --dialect tsql --output schema.graphml
```

## Modèle Python

Un modèle interne simple suffit :

```python
from dataclasses import dataclass, field

@dataclass
class Column:
    name: str
    sql_type: str
    is_primary_key: bool = False

@dataclass
class ForeignKey:
    source_columns: list[str]
    target_table: str
    target_columns: list[str]

@dataclass
class Table:
    name: str
    columns: list[Column] = field(default_factory=list)
    foreign_keys: list[ForeignKey] = field(default_factory=list)
```

## Cas SQL à prendre en charge

Ton extracteur doit reconnaître les deux styles usuels de clés primaires.

Clé définie au niveau de la colonne :

```sql
id INTEGER PRIMARY KEY
```

Clé définie au niveau de la table, utile notamment pour les clés composites :

```sql
CREATE TABLE order_line (
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL,
    PRIMARY KEY (order_id, product_id)
);
```

Même principe pour les clés étrangères.

Déclaration sur une colonne :

```sql
customer_id BIGINT REFERENCES customer(id)
```

Déclaration comme contrainte de table :

```sql
CONSTRAINT fk_order_customer
    FOREIGN KEY (customer_id)
    REFERENCES customer(id)
```

Il faut aussi prendre en charge les clés étrangères composites :

```sql
FOREIGN KEY (order_id, line_no)
REFERENCES order_line(order_id, line_no)
```

## Diagramme produit

Chaque table peut être rendue comme un bloc draw.io :

```text
┌───────────────────────────────┐
│ orders                        │
├───────────────────────────────┤
│ PK  id             BIGINT     │
│ FK  customer_id    BIGINT     │
│     total          DECIMAL    │
└───────────────────────────────┘
```

Une clé qui est à la fois primaire et étrangère peut apparaître ainsi :

```text
PK, FK  customer_id   BIGINT
```

Chaque contrainte FK devient une flèche reliant la table source à la table cible :

```text
orders.customer_id ───────→ customer.id
```

## Placement des tables

Tu peux commencer sans Graphviz :

- Placer les tables dans une grille.
- Une table par colonne horizontale.
- Retourner à la ligne après 4 ou 5 tables.
- Utiliser des dimensions calculées selon le nombre de champs.

C’est suffisant pour obtenir un fichier éditable dans draw.io, où tu pourras repositionner manuellement les tables.

Ajoute Graphviz seulement plus tard si tu veux un placement automatique plus intelligent, en rapprochant les tables liées par des clés étrangères.

## MVP recommandé

La première version peut se résumer à :

```bash
sql2mpd input.sql \
  --dialect postgres \
  --format drawio \
  --output modele.drawio
```

Fonctionnalités :

- Lire un fichier SQL.
- Extraire tous les `CREATE TABLE`.
- Lister les colonnes et leurs types.
- Identifier PK simples et composites.
- Identifier FK simples et composites.
- Générer un `.drawio`.
- Émettre des avertissements quand une instruction ne peut pas être interprétée.

Exemple de rapport :

```json
{
  "dialect": "postgres",
  "tables": 12,
  "columns": 86,
  "primary_keys": 12,
  "foreign_keys": 17,
  "warnings": [
    "CREATE TYPE ignoré",
    "CREATE INDEX ignoré"
  ]
}
```

Le choix concret pour cette version est donc :

```text
Python + SQLGlot + dataclasses + Typer + générateur XML draw.io
```

C’est une base petite, robuste et maintenable, sur laquelle tu pourras ensuite ajouter yEd, un placement Graphviz, les cardinalités, les index ou les contraintes métier si le besoin apparaît.