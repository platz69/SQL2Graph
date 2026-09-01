"""
Convertit un .sql en Modèle Physique de Données (MPD)

Enchaînement des conversions :
    SQL   --simple_sql_parser  -->  DataModel (classe basée sur pydantic)
                                    --build_drawpio  -->   .drawio
                                    ----construction_graphml-->   .graphml
"""

# bibliothèques standard (stdlib)
import math
from pathlib import Path

# bibliothèques externes (3rd party)
from pydantic import BaseModel, Field
from simple_ddl_parser import DDLParser
import drawpyo

"""
    Définition de Classes en utilisant pydantic
    Syntaxe :
    • "= True" pour dclarer la valeur par défaut
    • "CleEtrangere | None = None" se lit "(CleEtrangere | None) = None", c-à-d :
        • None est un type explicitement accepté  
        • la valeur par défaut est None
"""

class CleEtrangere(BaseModel):
    """ clé étrangère """
    ref_table: str
    ref_column: str


class Relation(BaseModel):
    """ relation crée par une clé étrangère
       (classe séparée pratique pour tracer les arêtes sans parcourir toutes les tables)"""
    from_table: str
    from_column: str
    to_table: str
    to_column: str


class Colonne(BaseModel):
    """ Colonne """
    name: str
    type: str
    nullable: bool = True # = True fixe la valeur par défaut
    is_pk: bool = False
    fk: CleEtrangere | None = None


class Table(BaseModel):
    """ Table """
    # Exemple :
    #     t = Table(
    #     name="users",
    #     columns=[
    #         Column(name="id", type="INT", is_pk=True),
    #         Column(name="email", type="VARCHAR(255)", nullable=False),
    #     ]
    # )
    name:        str
    schema_name: str | None = None
    columns:     list[Colonne]  = Field(default_factory=list)


class ModelePydantic(BaseModel):
    """ BDD entière """
    tables:    list[Table]    = Field(default_factory=list)
    relations: list[Relation] = Field(default_factory=list)

    # parcours des tables pour retrouver une table par son nom
    def get_table(self, name: str) -> Table | None:
        return next((t for t in self.tables if t.name == name), None)


"""
    Conversion SQL -> DataModel
"""

# parcours des métadonnées de type pour convertir un dictionnaire SQL en chaîne lisible
def conversion_colonne_str(col: dict) -> str:
    """ Conversion dict -> str, exemple: VARCHAR(255)."""
    type_str = col.get("type") or ""
    taille     = col.get("size")
    # si une taille est définie, on l'ajoute au type SQL
    if taille:
        # si la taille est un tuple ou une liste, on la transforme en format (a,b)
        if isinstance(taille, (tuple, list)):
            type_str += f"({','.join(str(s) for s in taille)})"
        else:
            # si la taille est un scalaire, on la met en notation standard
            type_str += f"({taille})"
    return type_str


# parcours des instructions DDL pour reconstruire le modèle de données complet
def conversion_ddl_pydantic(ddl_texte: str) -> ModelePydantic:
    """
    simple-ddl-parser n'exige pas de sélection explicite du dialecte, il gère nativement :
    MySQL, PostgreSQL,TSQL/MSSQL,Oracle,Snowflake Redshift, HQL...
    """
    # extraction du contenu SQL parsé en objets de structure de table
    parsed = DDLParser(ddl_texte, normalize_names=True).run(group_by_type=False)
    # initialisation du modèle pivot qui recevra les tables et relations
    modele  = ModelePydantic()

    # parcours des tables du DDL pour les transformer en objets Table et Column
    for raw_table in parsed:
        # si l'élément ne contient pas de colonnes, il ne s'agit pas d'une table SQL
        if "columns" not in raw_table:
            print("Ce n'est pas un CREATE TABLE (index, alter isolé, etc.)")
            continue

        nom_table = raw_table["table_name"]
        pk_colonnes = set(raw_table.get("primary_key") or [])

        table = Table(name=nom_table, schema_name=raw_table.get("schema"))

        # parcours des colonnes pour construire chaque objet Column et ses relations FK
        for raw_col in raw_table["columns"]:
            nom_colonne = raw_col["name"]
            fk = None
            reference = raw_col.get("references")
            # si la colonne référence une autre table, on construit la clé étrangère associée
            if reference:
                # si la référence est fournie sous forme de liste, on prend le premier élément
                fk = CleEtrangere(ref_table=reference["table"], ref_column=reference["column"][0]
                                 if isinstance(reference["column"], list) else reference["column"])
                modele.relations.append(
                    Relation(
                        from_table=nom_table,
                        from_column=nom_colonne,
                        to_table=fk.ref_table,
                        to_column=fk.ref_column,
                    )
                )

            table.columns.append(
                Colonne(
                    name=nom_colonne,
                    type=conversion_colonne_str(raw_col),
                    nullable=raw_col.get("nullable", True),
                    is_pk=nom_colonne in pk_colonnes,
                    fk=fk,
                )
            )

        modele.tables.append(table)

    # Gère les FK déclarées via ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY,
    # que simple-ddl-parser restitue comme statements 'alter' séparés.
    # parcours des instructions ALTER pour détecter les contraintes FK supplémentaires
    for declaration_alter in parsed:
        for alter in declaration_alter.get("alter", {}).get("columns", []) if isinstance(declaration_alter.get("alter"), dict) else []:
            pass  # structure variable selon version -> à adapter si vos DDL utilisent ce style

    return modele


# --------------------------------------------------------------------------- #
# 3. MODELE PIVOT -> DIAGRAMME DRAWIO (drawpyo)
# --------------------------------------------------------------------------- #

LARGEUR_TABLE, HAUTEUR_LIGNE, HAUTEUR_TITRE, ESPACEMENT_X, ESPACEMENT_Y = 220, 26, 30, 300, 260

# parcours des colonnes pour produire l'étiquette lisible de chaque champ
def calcul_label_colonne(col: Colonne) -> str:
    prefix = ""
    # si la colonne est une clé primaire, on ajoute un symbole PK
    if col.is_pk:
        prefix += "🔑 "
    # si la colonne est une clé étrangère, on ajoute un symbole FK
    if col.fk:
        prefix += "🔗 "
    nul = "" if col.nullable else " NN"
    return f"{prefix}{col.name} : {col.type}{nul}"


# parcours des caractères du nom de table pour générer un identifiant XML sûr
def node_id(table_name: str) -> str:
    return "n_" + ''.join(ch if ch.isalnum() else '_' for ch in table_name).strip('_')


# parcours des colonnes pour construire le libellé complet d'une table en texte multi-ligne
def table_label(table: Table) -> str:
    lines = [table.name.upper()]
    # parcours des colonnes pour ajouter les tags PK/FK et le type
    for col in table.columns:
        tags = []
        # si la colonne est primaire, on marque le tag PK
        if col.is_pk:
            tags.append("PK")
        # si la colonne est étrangère, on marque le tag FK
        if col.fk:
            tags.append("FK")
        prefix = ", ".join(tags) if tags else ""
        # si des tags existent, on espace le libellé pour conserver une colonne alignée
        if prefix:
            prefix = f"{prefix:<5} "
        lines.append(f"{prefix}{col.name} : {col.type}")
    return "\n".join(lines)


# parcours des tables pour écrire le fichier GraphML de sortie
def construction_graphml(model: ModelePydantic, output_path: Path) -> None:
    """Génère un fichier GraphML exploitable par yEd."""
    output_path.parent.mkdir(parents=True, exist_ok=True)

    import xml.etree.ElementTree as ET

    ET.register_namespace("", "http://graphml.graphdrawing.org/xmlns")
    ET.register_namespace("x", "http://www.yworks.com/xml/graphml")
    ET.register_namespace("y", "http://www.yworks.com/xml/graphml")

    # création de la racine GraphML et des clés de nœuds / arêtes
    root = ET.Element(
        "{http://graphml.graphdrawing.org/xmlns}graphml",
        {"version": "3.0"},
    )

    ET.SubElement(root, "{http://graphml.graphdrawing.org/xmlns}key", {
        "id": "d0",
        "for": "node",
        "yfiles.type": "nodegraphics",
    })
    ET.SubElement(root, "{http://graphml.graphdrawing.org/xmlns}key", {
        "id": "d1",
        "for": "edge",
        "yfiles.type": "edgegraphics",
    })

    # création du graphe GraphML principal
    graph = ET.SubElement(root, "{http://graphml.graphdrawing.org/xmlns}graph", {"edgedefault": "directed"})

    # calcul du nombre de tables par ligne dans le graphe
    nb_tables_par_ligne = max(1, math.ceil(math.sqrt(len(model.tables))))

    # positionnement de chaque table
    for i, table in enumerate(model.tables):
        grid_col = i % nb_tables_par_ligne
        grid_row = i // nb_tables_par_ligne
        x = grid_col * ESPACEMENT_X
        y = grid_row * ESPACEMENT_Y

        nid = node_id(table.name)
        node = ET.SubElement(graph, "{http://graphml.graphdrawing.org/xmlns}node", {"id": nid})
        data = ET.SubElement(node, "{http://graphml.graphdrawing.org/xmlns}data", {"key": "d0"})
        shape = ET.SubElement(data, "{http://www.yworks.com/xml/graphml}GenericNode", {"configuration": "com.yworks.entityRelationship.big_entity"})
        ET.SubElement(shape, "{http://www.yworks.com/xml/graphml}Geometry",
                      {"x": str(x), "y": str(y), "width": str(LARGEUR_TABLE), "height": str(HAUTEUR_TITRE + HAUTEUR_LIGNE * max(1, len(table.columns)))})
        # ET.SubElement(shape, "{http://www.yworks.com/xml/graphml}Fill",
        #               {"color": "#dae8fc", "transparent": "false"})
        # ET.SubElement(shape, "{http://www.yworks.com/xml/graphml}BorderStyle",
        #               {"color": "#6c8ebf", "type": "line", "width": "1.0"})
        header_label = ET.SubElement(shape, "{http://www.yworks.com/xml/graphml}NodeLabel",
                                     {
                                         "alignment": "center",
                                         "autoSizePolicy": "content",
                                         "backgroundColor": "#FFFFE1",
                                         "configuration": "com.yworks.entityRelationship.label.name",
                                         "fontFamily": "Courier",
                                         "fontSize": "12",
                                         "fontStyle": "plain",
                                         "hasLineColor": "false",
                                         "horizontalTextPosition": "center",
                                         "iconTextGap": "4",
                                         "modelName": "internal",
                                         "modelPosition": "t",
                                         "textColor": "#000000",
                                         "verticalTextPosition": "bottom",
                                         "visible": "true",
                                         "xml:space": "preserve",
                                     })
        header_label.text = table.name.upper()

        # Parcours des colonnes de la table
        field_lines = []
        for col in table.columns:
            tags = []
            # si la colonne est clé primaire, on ajoute le tag PK
            if col.is_pk:
                tags.append("PK")
            # si la colonne est clé étrangère, on ajoute le tag FK
            if col.fk:
                tags.append("FK")
            prefix = ", ".join(tags) if tags else ""
            # si des tags existent, on aligne le préfixe pour garder un format lisible
            if prefix:
                prefix = f"{prefix:<5} "
            field_lines.append(f"{prefix}{col.name} : {col.type}")

        fields_label = ET.SubElement(shape, "{http://www.yworks.com/xml/graphml}NodeLabel",
                                     {
                                         "alignment": "left",
                                         "autoSizePolicy": "content",
                                         "backgroundColor": "#FFFFFF",
                                         "configuration": "com.yworks.entityRelationship.label.attributes",
                                         "fontFamily": "Courier",
                                         "fontSize": "12",
                                         "underlined": "false",
                                         "fontStyle": "plain",
                                         "hasLineColor": "false",
                                         "horizontalTextPosition": "center",
                                         "iconTextGap": "4",
                                         "modelName": "custom",
                                         "textColor": "#000000",
                                         "verticalTextPosition": "bottom",
                                         "visible": "true",
                                         "xml:space": "preserve",
                                     })
        fields_label.text = "\n".join(field_lines)

    for rel in model.relations:
        source_id = node_id(rel.from_table)
        target_id = node_id(rel.to_table)
        # si la relation est bien définie entre deux nœuds graphml, on crée l'arête
        edge = ET.SubElement(graph, "{http://graphml.graphdrawing.org/xmlns}edge",
                             {"id": f"e_{source_id}_{target_id}", "source": source_id, "target": target_id})
        data = ET.SubElement(edge, "{http://graphml.graphdrawing.org/xmlns}data", {"key": "d1"})
        poly = ET.SubElement(data, "{http://www.yworks.com/xml/graphml}PolyLineEdge")
        ET.SubElement(poly, "{http://www.yworks.com/xml/graphml}LineStyle",
                      {"color": "#000000", "type": "line", "width": "1.0"})
        ET.SubElement(poly, "{http://www.yworks.com/xml/graphml}Arrows", {"source": "none", "target": "standard"})
        label = ET.SubElement(poly, "{http://www.yworks.com/xml/graphml}EdgeLabel",
                              {"alignment": "center", "backgroundColor": "#ffffff", "fontFamily": "Dialog", "fontSize": "11"})
        label.text = rel.from_column

    # écriture du fichier GraphML final sur disque
    tree = ET.ElementTree(root)
    tree.write(output_path, encoding="utf-8", xml_declaration=True)


# parcours du modèle pour générer le diagramme Draw.io final
def construction_drawio(model: ModelePydantic, output_path: Path) -> None:
    file = drawpyo.File()
    file.file_path = str(output_path.parent)
    file.file_name = output_path.name
    page = drawpyo.Page(file=file)

    # retirer l'aperçu de la grille
    page.grid = 0

    # table_name -> objet drawpyo "conteneur"
    table_objects: dict[str, "drawpyo.diagram.Object"] = {}
    # (table_name, column_name) -> objet drawpyo "ligne", utile pour les arêtes FK
    row_objects: dict[tuple[str, str], "drawpyo.diagram.Object"] = {}

    n_tables = len(model.tables)
    cols_per_row = max(1, math.ceil(math.sqrt(n_tables)))

    # parcours des tables pour les placer dans la grille drawio
    for i, table in enumerate(model.tables):
        grid_col = i % cols_per_row
        grid_row = i // cols_per_row
        x = grid_col * ESPACEMENT_X
        y = grid_row * ESPACEMENT_Y

        # création du conteneur de table (nom de la table)
        header = drawpyo.diagram.Object(
            page=page,
            id=table.name,
            value=table.name.upper(),
            position=(x, y)
        )
        header.width = LARGEUR_TABLE
        header.height = HAUTEUR_TITRE + HAUTEUR_LIGNE * max(1, len(table.columns))
        header.apply_style_string(
            "whiteSpace=wrap;rounded=0;dashed=0;align=center;verticalAlign=top;"
        )
        table_objects[table.name] = header

        # parcours des colonnes pour créer les lignes de champs de la table
        for j, col in enumerate(table.columns):
            row = drawpyo.diagram.Object(
                page=page,
                id=f"{table.name}.{col.name}",
                value=calcul_label_colonne(col),
                parent=header,
                position_rel_to_parent=(0, HAUTEUR_TITRE + j * HAUTEUR_LIGNE),
            )
            row.width = LARGEUR_TABLE
            row.height = HAUTEUR_LIGNE
            row.apply_style_string(
                "whiteSpace=wrap;rounded=0;dashed=0;align=left;verticalAlign=middle;spacingLeft=8;"
            )
            row_objects[(table.name, col.name)] = row

    # parcours des relations pour tracer les arêtes FK entre tables
    compteur_cles_etrangeres: dict[str, int] = {}
    for rel in model.relations:
        source      = row_objects.get((rel.from_table, rel.from_column))
        destination = row_objects.get((rel.to_table, rel.to_column))
        # si l'origine ou la cible n'existe pas, on ignore la relation incomplète
        if source is None or destination is None:
            # La table référencée n'est pas définie dans le fichier -> on ignore l'arête
            continue

        compteur_cles_etrangeres[rel.from_table] = compteur_cles_etrangeres.get(rel.from_table, 0) + 1
        edge_id = f"{rel.from_table}.cle_etrangere_{compteur_cles_etrangeres[rel.from_table]}"

        edge = drawpyo.diagram.Edge(page=page, id=edge_id, source=source, target=destination)
        edge.waypoints       = "entity_relation"
        edge.line_end_target = "ERone"
        edge.line_end_source = "ERmany"
        edge.endFill_target  = False
        edge.endFill_source  = False

    file.write()
    # parcours du fichier XML généré pour forcer la grille et la page en mode masqué
    generated_file = Path(file.file_path) / file.file_name
    # si le fichier drawio a bien été généré, on le nettoie pour masquer la grille et la page
    if generated_file.exists():
        content = generated_file.read_text(encoding="utf-8")
        # si la grille est activée, on la désactive pour obtenir un rendu plus propre
        if 'grid="1"' in content:
            content = content.replace('grid="1"', 'grid="0"')
        # si l'aperçu de page est actif, on le désactive pour un rendu plein écran
        if 'page="1"' in content:
            content = content.replace('page="1"', 'page="0"')
        generated_file.write_text(content, encoding="utf-8")


# --------------------------------------------------------------------------- #
# 4. CLI
# --------------------------------------------------------------------------- #

# parcours du fichier SQL d'entrée pour générer le diagramme et le graphml
def main() -> None:
    # gestion des arguments de la ligne de commande
    # parser = argparse.ArgumentParser(description="Génère un MPD .drawio ou .graphml depuis un DDL SQL")
    # parser.add_argument("--input", default="./input/MySQL.sql", help="Chemin du fichier DDL")
    # parser.add_argument("--dialect", default="mysql", help="Dialecte SQL (informatif)")
    # parser.add_argument("--format", choices=["drawio", "graphml", "both"], default="drawio",
    #                     help="Format de sortie : drawio, graphml ou both")
    # parser.add_argument("--output", default=None, help="Fichier de sortie; si omis, le nom est généré selon le format")
    # args = parser.parse_args()

    # fabrication des chemins à partir des arguments fournis en ligne de commande

    input_path = Path("./input") / "MySQL.sql"
    # stem = ddl_path.stem if ddl_path.stem else "MySQL"
    output_dir = Path("./output")
    output_dir.mkdir(parents=True, exist_ok=True)
    drawio_path  = output_dir / "MySQL.drawio"
    graphml_path = output_dir / "MySQL.graphml"

    # lecture du fichier sql en entrée
    ddl_text = input_path.read_text(encoding="utf-8")

    # fabrication du DataModel à partir du contenu du fichier sql en entrée
    model = conversion_ddl_pydantic(ddl_text)

    # affichage du résumé détecté dans le modèle SQL
    print(f"{len(model.tables)} tables détectées :")
    for t in model.tables:
        pk = [c.name for c in t.columns if c.is_pk]
        fk = [c.name for c in t.columns if c.fk]
        print(f"  - {t.name} : {len(t.columns)} colonnes, PK={pk}, FK={fk}")
    print(f"{len(model.relations)} relations FK détectées.")

    # génération du diagramme drawio à partir du modèle
    construction_drawio(model, drawio_path)
    print(f"Fichier drawio généré : {drawio_path}")

    # génération du diagramme graphml à partir du même modèle
    construction_graphml(model, graphml_path)
    print(f"Fichier graphml généré : {graphml_path}")
    # print(model.model_dump_json(indent=2))


# si le script est exécuté directement, on lance le traitement principal
if __name__ == "__main__":
    main()
