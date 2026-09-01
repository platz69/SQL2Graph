Prend un ficherSQL de type DDL et le convertit en graphes pour Drawio et Yed.

Exemple avec 1 seule table ayant 1 clé étrangère:

```SQL
CREATE TABLE orders (
    id BIGINT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    total DECIMAL(10,2),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customer(id)
);
```

Devient :

```json
{
  "tables": [
    {
      "name": "orders",
      "schema_name": null,
      "columns": [
        {
          "name": "id",
          "type": "INT",
          "nullable": false,
          "is_pk": true,
          "fk": null
        },
        {
          "name": "customer_id",
          "type": "INT",
          "nullable": false,
          "is_pk": false,
          "fk": {
            "ref_table": "customer",
            "ref_column": "id"
          }
        },
        {
          "name": "order_date",
          "type": "DATE",
          "nullable": false,
          "is_pk": false,
          "fk": null
        }
      ]
    }
  ],
  (partie concernant les clés étrangères)
  "relations": [
    {
      "from_table": "orders",
      "from_column": "customer_id",
      "to_table": "customer",
      "to_column": "id"
    }
  ]
}
```
Puis XML au format .drawio :

```xml
<mxfile host="Drawpyo" modified="2026-08-31T12:18:46" agent="Python 3.14, Drawpyo 0.23" version="21.6.5" type="device">
	<diagram name="Page-1" id="2158300260272">
		<mxGraphModel dx="2037" dy="830" grid="0" gridSize="10" guides="1" toolTips="1" connect="1" arrows="1" fold="1" page="0" pageScale="1" pageWidth="850" pageHeight="1100" math="0" shadow="0">
			<root>
				<mxCell id="0"/>
				<mxCell id="1" parent="0"/>
                <!-- .....définition des tables ....... -->
				<mxCell id="orders" value="ORDERS" style="whiteSpace=wrap;rounded=0;dashed=0;align=center;verticalAlign=top;" vertex="1" parent="1">
					<mxGeometry x="0" y="260" width="220" height="108" as="geometry"/>
				</mxCell>
                <!-- .....définition des champs ....... -->
				<mxCell id="orders.customer_id" value="🔗 customer_id : INT NN" style="whiteSpace=wrap;rounded=0;dashed=0;align=left;verticalAlign=middle;spacingLeft=8;" vertex="1" parent="orders">
					<mxGeometry x="0" y="56" width="220" height="26" as="geometry"/>
				</mxCell>
                <!-- .....définition des clés étrangères ....... -->
				<mxCell id="orders.cle_etrangere_1" style="edgeStyle=entityRelationEdgeStyle;elbow=vertical;rounded=0;jettySize=auto;startArrow=ERmany;endArrow=ERone;" edge="1" parent="1" source="orders.customer_id" target="customer_id">
					<mxGeometry relative="1" as="geometry"/>
				</mxCell>
            </root>
        </mxGraphModel>
    </diagram>
</mxfile>
```
Visuellement :
┌───────────────────────────────┐

│ orders                        │

├───────────────────────────────┤

│ PK  id             BIGINT     │

│ FK  customer_id    BIGINT     │

│     order_date     DATE       │

└───────────────────────────────┘

## Cas SQL à prendre en charge

reconnaître les deux styles usuels de clés primaires.

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
