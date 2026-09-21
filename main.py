"""
Convertit un .sql en Modèle Physique de Données (MPD)

Enchaînement des conversions :
 SQL --simple_ddl_parser-->  pydantic --build_drawio         -->   .drawio
                                      --generer_graphml_ET -->   .graphml
"""

# bibliothèques standard (stdlib)
import math
from pathlib import Path
import xml.etree.ElementTree as ET

# bibliothèques tierces
from pydantic import BaseModel, Field
# import drawpyo
from simple_ddl_parser import DDLParser  # nom du package (simple_ddl_parser) <> nom du projet (simple-ddl-parser) cf https://pypi.org/project/simple-ddl-parser/
import networkx as nx # nécessite "pip install numpy"
# from scipy import kamada_kawai_layout

# from networkx.drawing.nx_agraph import graphviz_layout # pour gérer l'anti-collision des noeuds du graphe

""" _______________________________________________________________________________________________________________
    Définition de Classes en utilisant pydantic
    Syntaxe :
    • "= True" pour déclarer la valeur par défaut
    • "CleEtrangere | None = None" signifie : le type peut être CleEtrangere ou None, et la valeur par défaut est None
    _______________________________________________________________________________________________________________
"""

class CleEtrangere(BaseModel):
    ref_table: str
    ref_colonne: str


class Relation(BaseModel):
    """ relation crée par une clé étrangère
       (classe séparée pratique pour tracer les arêtes sans parcourir toutes les tables)"""
    table_source: str
    colonne_source: str
    table_destination: str
    colonne_destination: str


class Colonne(BaseModel):
    nom: str
    type: str
    nullable: bool = True # = True fixe la valeur par défaut
    is_pk: bool = False
    is_unique: bool = False
    fk: CleEtrangere | None = None


class Table(BaseModel):
    # Exemple :
    #     t = Table(
    #     nom="users",
    #     colonnes=[
    #         Column(nom="id", type="INT", is_pk=True),
    #         Column(nom="email", type="VARCHAR(255)", nullable=False),
    #     ]
    # )
    nom: str
    colonnes: list[Colonne] = Field(default_factory=list)


class Modele(BaseModel):
    """ BDD entière """
    tables:    list[Table]    = Field(default_factory=list)
    relations: list[Relation] = Field(default_factory=list)

    # parcours des tables pour retrouver une table par son nom
    def get_table(self, nom: str) -> Table | None:
        return next((t for t in self.tables if t.nom == nom), None)

"""_______________________________________________________________________________________________________________
    Conversion SQL -> pydantic -> Objets
    _______________________________________________________________________________________________________________
"""

def conversion_type_colonne_en_str(col: dict) -> str:
    """ Conversion dict -> str, exemple: VARCHAR(255)."""
    type_str = col.get("type") or ""
    taille   = col.get("size") or ""  # éviter taille = None sinon warning
    # si une taille est définie, on l'ajoute au type SQL
    if taille:
        # si la taille est un tuple ou une liste, on la transforme en format (a,b)
        if isinstance(taille, (tuple, list)):
            type_str += f"({','.join(str(s) for s in taille)})"
        else:
            # si la taille est un scalaire, on la met en notation standard
            type_str += f"({taille})"
    return type_str


def conversion_ddl_en_objets(ddl_texte: str) -> Modele:
    """
    analyse via simple-ddl-parser puis conversion en objets Modele, Table, Colonne, Relation, CleEtrangere
    """
    # analyse simple-ddl-parser
    # Possible output_modes: ['redshift', 'spark_sql', 'mysql', 'bigquery', 'mssql', 'databricks', 'sqlite', 'vertics', 'ibm_db2', 'postgres', 'oracle', 'hql', 'snowflake', 'sql']
    parsed = DDLParser(ddl_texte, normalize_names=True).run(group_by_type=False)  #, output_mode='mssql')  # output_mode='sql' est le mode par défaut, mais il ne gère pas les types SQL Server (ex: NVARCHAR))

    # initialisation du modèle pydantic qui recevra les objets tables et relations
    modele = Modele()

    # parcours des tables du résultat de simple-ddl-parser
    for raw_table in parsed:
        if "columns" not in raw_table:
            print(f"L'instruction contenant {raw_table} n'est pas un CREATE TABLE")
            continue

        nom_table = raw_table["table_name"]
        alter = raw_table.get("alter") if isinstance(raw_table.get("alter"), dict) else {}

        # les PK inline (colonne déclarée "PRIMARY KEY" dans le CREATE TABLE) sont dans primary_key,
        # mais quand la PK est ajoutée via ALTER TABLE ... ADD CONSTRAINT ... PRIMARY KEY (cas le plus
        # courant en pg_dump), elle se trouve dans alter["primary_keys"] -> on fusionne les deux sources
        pk_colonnes = set(raw_table.get("primary_key") or [])
        # pour éviter un warning, on vérifie que alter est bien un dict (et pas None ou une autre structure)
        if not isinstance(alter, dict):
            raise ValueError(f"alter est None pour la table {nom_table}")  # sinon ça fait un warning
        for pk_decl in alter.get("primary_keys", []):
            pk_colonnes.update(pk_decl.get("columns", []))

        # idem pour les contraintes UNIQUE : elles peuvent être déclarées inline (col["unique"])
        # ou ajoutées via ALTER TABLE ... ADD CONSTRAINT ... UNIQUE (alter["uniques"])
        unique_colonnes = {
            raw_col["name"] for raw_col in raw_table["columns"] if raw_col.get("unique")
        }
        for unique_decl in alter.get("uniques", []):
            unique_colonnes.update(unique_decl.get("columns", []))

        # idem pour les FK : quand elles sont ajoutées via ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY,
        # simple-ddl-parser les restitue dans alter["columns"] (une entrée par colonne source avec "references")
        fk_par_colonne = {
            alter_col["name"]: alter_col["references"]
            for alter_col in alter.get("columns", [])
            if alter_col.get("references")
        }

        table = Table(nom=nom_table)

        # parcours des colonnes pour construire chaque objet Column et ses relations FK
        for raw_col in raw_table["columns"]:
            nom_colonne = raw_col["name"]
            fk = None
            # la référence peut être inline (raw_col["references"]) ou déclarée via ALTER (fk_par_colonne)
            reference = raw_col.get("references") or fk_par_colonne.get(nom_colonne)
            # si la colonne référence une autre table, on construit la clé étrangère associée
            if reference:
                # pour éviter un warning, on vérifie que la référence est bien un dict (et pas None ou une autre structure)
                if not isinstance(reference, dict):
                    raise ValueError(f"Format de référence invalide pour la colonne {nom_colonne}")
                # si la référence est fournie sous forme de liste, on prend le premier élément
                fk = CleEtrangere(ref_table=reference["table"], ref_colonne=reference["column"][0]
                                 if isinstance(reference["column"], list) else reference["column"])
                modele.relations.append(
                    Relation(
                        table_source=nom_table,
                        colonne_source=nom_colonne,
                        table_destination=fk.ref_table,
                        colonne_destination=fk.ref_colonne,
                    )
                )

            table.colonnes.append(
                Colonne(
                    nom=nom_colonne,
                    type=conversion_type_colonne_en_str(raw_col),
                    nullable=raw_col.get("nullable", True),
                    is_pk=nom_colonne in pk_colonnes,
                    is_unique=nom_colonne in unique_colonnes,
                    fk=fk,
                )
            )

        modele.tables.append(table)

    return modele


""" _____________________________________________________________________________________________________
        Analyse du modèle -> affichage des cardinalités
_________________________________________________________________________________________________________
"""

def calcul_cardinalite(colonne_fk: Colonne) -> str:
    """
    Détermine la cardinalité côté A (table référencée) et côté B (table contenant la FK)
    en fonction des options NOT NULL / UNIQUE de la colonne portant la clé étrangère.
    """
    not_null = not colonne_fk.nullable
    unique   = colonne_fk.is_unique

    if unique and not_null:
        return "1..1 ------------------- 0..1"
    if unique:
        return "0..1 ------------------- 0..1"
    if not_null:
        return "1..1 ------------------- 0..n"
    return "0..1 ------------------- 0..n"


def afficher_cardinalites(modele: Modele) -> None:
    """
    Parcourt toutes les relations (FK) du modèle et affiche la cardinalité
    "A <card_A> ------------------- <card_B> B" pour chacune d'entre elles,
    où A est la table référencée (ref_table) et B la table portant la clé étrangère.
    """
    for rel in modele.relations:
        table_b = modele.get_table(rel.table_source)
        if table_b is None:
            continue

        colonne_fk = next((c for c in table_b.colonnes if c.nom == rel.colonne_source), None)
        if colonne_fk is None:
            continue

        cardinalite = calcul_cardinalite(colonne_fk)
        print(f"{rel.table_destination.ljust(30)} {cardinalite} {rel.table_source}")


""" _____________________________________________________________________________________________________
        Conversion Objet -> drawio ou Yed
_________________________________________________________________________________________________________
"""

LARGEUR_TABLE, HAUTEUR_LIGNE, HAUTEUR_TITRE, ESPACEMENT_X, ESPACEMENT_Y = 220, 26, 26, 300, 250

def calc_nb_cols_par_ligne(nb_tables: int) -> int:
    return max(1, math.ceil(math.sqrt(nb_tables)))


# hauteur totale d'une table ( 1 nom de table + n lignes)
def hauteur_table(table: Table) -> int:
    return HAUTEUR_TITRE + HAUTEUR_LIGNE * max(1, len(table.colonnes))


# position (x, y) d'une table dans le graphe
def calcul_position_tables(model: Modele) -> dict[str, tuple[int, int]]:
    nb_cols_par_ligne = calc_nb_cols_par_ligne(len(model.tables))
    positions: dict[str, tuple[int, int]] = {}

    # la position de la table est obtenue par la division euclidienne de i par le nb max de table par ligne
    for i, table in enumerate(model.tables):
        numero_de_colonne = i % nb_cols_par_ligne
        numero_de_ligne = i // nb_cols_par_ligne
        positions[table.nom] = numero_de_colonne * ESPACEMENT_X, numero_de_ligne * ESPACEMENT_Y
    return positions


# position (x, y) d'une table dans le graphe sans chevauchement ('shelf packing')
def calcul_position_tables_sans_chevauchement(model: Modele) -> dict[str, tuple[int, int]]:
    nb_cols_par_ligne = calc_nb_cols_par_ligne(len(model.tables))
    positions: dict[str, tuple[int, int]] = {}

    x, y = 0, 0
    col_courante = 0
    hauteur_max_ligne = 0

    for table in model.tables:
        if col_courante == nb_cols_par_ligne:
            x = 0
            y += hauteur_max_ligne + ESPACEMENT_Y
            col_courante = 0
            hauteur_max_ligne = 0

        positions[table.nom] = (x, y)
        x += LARGEUR_TABLE + ESPACEMENT_X
        hauteur_max_ligne = max(hauteur_max_ligne, hauteur_table(table))
        col_courante += 1

    return positions



# position (x, y) des tables dans le graphe en fonction de leurs relations FK (networkx)
def calcul_position_tables_networkx(model: Modele) -> dict[str, tuple[int, int]]:
    """Dispose les tables en s'appuyant sur un algorithme de layout de graphe (spring layout) :
    les tables reliées par une FK sont rapprochées, ce qui limite les croisements d'arêtes.

    ATTENTION : les tables peuvent encore se chevaucher, networx considérant les tables comme des points et ne tenant
    pas compte de leur taille (on pourra cependant ajuster le paramètre k et l'échelle finale).
    """
    graphe = nx.Graph()
    graphe.add_nodes_from(table.nom for table in model.tables)
    graphe.add_edges_from((rel.table_source, rel.table_destination) for rel in model.relations)

    nb_tables = len(model.tables)

    # k = distance "naturelle" cible entre deux nœuds pour spring_layout ; on la relie à la taille
    # réelle des tables pour que les nœuds non reliés ne soient pas artificiellement tassés
    k = 8.0 / max(1, math.sqrt(nb_tables))
    positions_normalisees = nx.spring_layout(graphe,
                                             k=k,             # distance idéale entre nœuds
                                             iterations=200,  # plus d'itérations = meilleure convergence
                                             scale=0.8,       # échelle finale du layout (homothétie)
                                             seed=42,         # pour reproductibilité
                                             threshold=1e-4,  # seuil de convergence : arrête l’algorithme si le déplacement relatif moyen des nœuds entre deux itérations est inférieur à ce seuil.(défaut 1e-4, peut baisser)
                                             dim=2            # tester la 3D ! :)
                                             )
    # positions_normalisees = nx.kamada_kawai_layout(graphe)
    # spring_layout renvoie des coordonnées normalisées (~[-1, 1]) : on les remet à l'échelle
    # de la grille en pixels, en tenant compte de la hauteur max des tables pour l'axe vertical
    hauteur_max = max((hauteur_table(table) for table in model.tables), default=HAUTEUR_TITRE)
    echelle_x = (LARGEUR_TABLE + ESPACEMENT_X) * math.sqrt(nb_tables)
    echelle_y = (hauteur_max + ESPACEMENT_Y) * math.sqrt(nb_tables)

    positions: dict[str, tuple[int, int]] = {}
    for table in model.tables:
        x_normalise, y_normalise = positions_normalisees[table.nom]
        # l'axe y de networkx pointe vers le haut, celui de drawio/Yed vers le bas -> on l'inverse
        x = round((x_normalise + 1) / 2 * echelle_x)
        y = round((1 - y_normalise) / 2 * echelle_y)
        positions[table.nom] = (x, y)

    return positions


# parcours des colonnes pour produire l'étiquette lisible de chaque champ
def calcul_label_colonne(col: Colonne) -> str:
    prefix = ""
    # si la colonne est une clé primaire, on ajoute un symbole PK
    if col.is_pk:
        prefix += "🔑 "
    # si la colonne est une clé étrangère, on ajoute un symbole FK
    if col.fk:
        prefix += "🔗 "
    # si la colonne n'est ni une clé primaire ni une clé étrangère, on ajoute quand même un préfixe pour respecter l'alignement des champs

    nul = "" if col.nullable else " NN"
    return f"{prefix}{col.nom} : {col.type}{nul}"


# parcours des caractères du nom de table pour générer un identifiant XML sûr
def ET_node_to_clean_str(table_nom: str) -> str:
    return "n_" + ''.join(caractere if caractere.isalnum() else '_' for caractere in table_nom).strip('_')


# parcours des tables pour écrire le fichier Yed de sortie
def generer_MPD_Yed_ET(model: Modele, chemin_de_sortie: Path, diag_type: str) -> None:
    """Génère un fichier GraphML exploitable par Yed."""
    chemin_de_sortie.parent.mkdir(parents=True, exist_ok=True)

    # --- 1. structure racine du document Yed ---

    """ ----------en-tête graphml à construire------------------
        <?xml version='1.0' encoding='utf-8'?>
            <graphml xmlns="http://graphml.graphdrawing.org/xmlns" xmlns:y="http://www.yworks.com/xml/graphml" version="3.0">
                <key id="d0" for="node" yfiles.type="nodegraphics"/>
                <key id="d1" for="edge" yfiles.type="edgegraphics"/>
                <graph edgedefault="directed">
        ---------------------------------------------------------"""

    ET.register_namespace("", "http://graphml.graphdrawing.org/xmlns")
    ET.register_namespace("x", "http://www.yworks.com/xml/graphml")
    ET.register_namespace("y", "http://www.yworks.com/xml/graphml")

    root = ET.Element("{http://graphml.graphdrawing.org/xmlns}graphml", {"version": "3.0"})
    ET.SubElement(root, "{http://graphml.graphdrawing.org/xmlns}key", {"id": "d0", "for": "node", "yfiles.type": "nodegraphics"})
    ET.SubElement(root, "{http://graphml.graphdrawing.org/xmlns}key", {"id": "d1", "for": "edge", "yfiles.type": "edgegraphics"})
    graph = ET.SubElement(root, "{http://graphml.graphdrawing.org/xmlns}graph", {"edgedefault": "directed"})

    # --- 2. calcul de la disposition des tables en grille +/- carrée ---
    # factorisé et appelé dans main()

    # --- 3. création d'un nœud <mxCell> par table, avec ses colonnes en libellé ---
    for i, table in enumerate(model.tables):
        # x, y = calcul_position_tables_unique(i, nb_cols_par_ligne)
        # x, y = calcul_position_tables_sans_chevauchement(table.nom)

        node = ET.SubElement(graph, "{http://graphml.graphdrawing.org/xmlns}node", {"id": ET_node_to_clean_str(table.nom)})
        data = ET.SubElement(node, "{http://graphml.graphdrawing.org/xmlns}data", {"key": "d0"})
        shape = ET.SubElement(data, "{http://www.yworks.com/xml/graphml}GenericNode", {"configuration": "com.yworks.entityRelationship.big_entity"})
        ET.SubElement(shape, "{http://www.yworks.com/xml/graphml}Geometry",
                      {"x": str(position_table[table.nom][0]), "y": str(position_table[table.nom][1]), "width": str(LARGEUR_TABLE), "height": str(hauteur_table(table))})

        # libellé du titre (nom de la table)
        header_label = ET.SubElement(shape, "{http://www.yworks.com/xml/graphml}NodeLabel", {
            "alignment": "center", "autoSizePolicy": "content", "backgroundColor": "#FFFFE1",
            "configuration": "com.yworks.entityRelationship.label.nom", "fontFamily": "Courier", "fontSize": "12",
            "fontStyle": "plain", "hasLineColor": "false", "horizontalTextPosition": "center", "iconTextGap": "4",
            "modelName": "internal", "modelPosition": "t", "textColor": "#000000", "verticalTextPosition": "bottom",
            "visible": "true", "xml:space": "preserve",
        })
        header_label.text = table.nom.upper()
        field_lines = [calcul_label_colonne(col) for col in table.colonnes]
        fields_label = ET.SubElement(shape, "{http://www.yworks.com/xml/graphml}NodeLabel", {
            "alignment": "left", "autoSizePolicy": "content", "backgroundColor": "#FFFFFF",
            "configuration": "com.yworks.entityRelationship.label.attributes", "fontFamily": "Courier", "fontSize": "12",
            "underlined": "false", "fontStyle": "plain", "hasLineColor": "false", "horizontalTextPosition": "center",
            "iconTextGap": "4", "modelName": "custom", "textColor": "#000000", "verticalTextPosition": "bottom",
            "visible": "true", "xml:space": "preserve",
        })
        fields_label.text = "\n".join(field_lines)

    # --- 4. création d'une arête par relation FK, en ignorant les relations incomplètes ---
    noms_tables = {table.nom for table in model.tables}
    compteur_cles_etrangeres: dict[str, int] = {}
    for rel in model.relations:
        # si la table source ou la table cible n'existe pas, on ignore la relation incomplète
        if rel.table_source not in noms_tables or rel.table_destination not in noms_tables:
            print(red+f"au moins l'une des tables {rel.table_source} ou {rel.table_destination} n'existe pas"+reset)
            break
        compteur_cles_etrangeres[rel.table_source] = compteur_cles_etrangeres.get(rel.table_source, 0) + 1
        edge_id = f"{rel.table_source}.cle_etrangere_{compteur_cles_etrangeres[rel.table_source]}"

        edge = ET.SubElement(graph, "{http://graphml.graphdrawing.org/xmlns}edge",
                             {"id": edge_id, "source": ET_node_to_clean_str(rel.table_source), "target": ET_node_to_clean_str(rel.table_destination)})
        data = ET.SubElement(edge, "{http://graphml.graphdrawing.org/xmlns}data", {"key": "d1"})
        poly = ET.SubElement(data, "{http://www.yworks.com/xml/graphml}PolyLineEdge")
        ET.SubElement(poly, "{http://www.yworks.com/xml/graphml}LineStyle", {"color": "#000000", "type": "line", "width": "1.0"})
        if diag_type == 'mpd':
            ET.SubElement(poly, "{http://www.yworks.com/xml/graphml}Arrows", {"source": "none", "target": "standard"})
        elif diag_type == 'mcd':
            ET.SubElement(poly, "{http://www.yworks.com/xml/graphml}Arrows", {"source": "crows_foot_many", "target": "none"})
        else:
            print(red + f"le type de diagramme {diag_type} est inconnu" + reset)
        label = ET.SubElement(poly, "{http://www.yworks.com/xml/graphml}EdgeLabel",
                              {"alignment": "center", "backgroundColor": "#ffffff", "fontFamily": "Dialog", "fontSize": "11"})
        label.text = rel.colonne_source

    # --- 5. écriture du fichier GraphML final sur disque ---
    tree = ET.ElementTree(root)
    ET.indent(tree, space="  ")
    tree.write(chemin_de_sortie, encoding="utf-8", xml_declaration=True)


# parcours du modèle pour générer le diagramme MPD drawio final, en ElementTree pur (sans drawpyo)
def generer_MPD_drawio_ET(model: Modele, chemin_de_sortie: Path, diag_type: str) -> None:
    """Génère un fichier .drawio exploitable par drawio / diagrams.net, en ElementTree pur (sans drawpyo)."""
    chemin_de_sortie.parent.mkdir(parents=True, exist_ok=True)

    # --- 1. structure racine du document drawio ---

    """ ----------en-tête drawio à obtenir------------------
    <mxfile host="ElementTree" type="device">
	<diagram name="Page-1" id="1">
		<mxGraphModel dx="800" dy="600" grid="0" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="0" pageScale="1" pageWidth="850" pageHeight="1100" math="0" shadow="0">
			<root>
				<mxCell id="0"/>
				<mxCell id="1" parent="0"/>
		-----------------------------------------------------"""

    mxfile = ET.Element("mxfile", {"host": "ElementTree","type": "device"})
    diagram = ET.SubElement(mxfile, "diagram", {"name": "Page-1", "id": "1"})
    graph_model = ET.SubElement(diagram, "mxGraphModel", {
        "dx": "800", "dy": "600", "grid": "0", "gridSize": "10", "guides": "1",
        "tooltips": "1", "connect": "1", "arrows": "1", "fold": "1", "page": "0",
        "pageScale": "1", "pageWidth": "850", "pageHeight": "1100", "math": "0", "shadow": "0",
    })
    root = ET.SubElement(graph_model, "root")
    ET.SubElement(root, "mxCell", {"id": "0"})
    ET.SubElement(root, "mxCell", {"id": "1", "parent": "0"})

    # --- 2. calcul de la disposition des tables en grille +/- carrée ---
    # factorisé et appelé dans main()
    # nb_cols_par_ligne = calc_nb_cols_par_ligne(len(model.tables))
    # positions = {}
    # for i, table in enumerate(model.tables):
    #     positions[table.nom] = calcul_position_tables_unique(i, nb_cols_par_ligne)

    # --- 3. création d'un nœud <mxCell> par table, avec ses colonnes en libellé ---
    for i, table in enumerate(model.tables):
        # x, y = calcul_position_tables_unique(i, nb_cols_par_ligne)

        # libellé du titre (nom de la table)
        header_cell = ET.SubElement(root, "mxCell", {
            "id": table.nom,
            "value": table.nom.upper(),
            "style": "whiteSpace=wrap;rounded=0;dashed=0;align=center;verticalAlign=top;",
            "vertex": "1",
            "parent": "1",
        })
        ET.SubElement(header_cell, "mxGeometry", {
            "x": str(position_table[table.nom][0]), "y": str(position_table[table.nom][1]), "width": str(LARGEUR_TABLE), "height": str(hauteur_table(table)), "as": "geometry",
        })

        # libellé des champs (une ligne par colonne, avec tags PK/FK)
        for j, col in enumerate(table.colonnes):
            row_cell = ET.SubElement(root, "mxCell", {
                "id": f"{table.nom}.{col.nom}",
                "value": calcul_label_colonne(col),
                "style": "whiteSpace=wrap;rounded=0;dashed=0;align=left;verticalAlign=middle;spacingLeft=8;",
                "vertex": "1",
                "parent": table.nom,
            })
            ET.SubElement(row_cell, "mxGeometry", {
                "x": "0", "y": str(HAUTEUR_TITRE + j * HAUTEUR_LIGNE), "width": str(LARGEUR_TABLE), "height": str(HAUTEUR_LIGNE), "as": "geometry",
            })

    # --- 4. création d'une arête par relation FK, en ignorant les relations incomplètes ---
    noms_colonnes = {f"{table.nom}.{col.nom}" for table in model.tables for col in table.colonnes}

    # compteur qui sert à réjouter un suffixe et éviter les ids en doublon
    compteur_cles_etrangeres: dict[str, int] = {}

    # ---- boucle sur les relations
    for rel in model.relations:
        source_id      = f"{rel.table_source}.{rel.colonne_source}"
        destination_id = f"{rel.table_destination}.{rel.colonne_destination}"
        # si la colonne source ou la colonne cible n'existe pas, on ignore la relation incomplète
        if source_id not in noms_colonnes or destination_id not in noms_colonnes:
            continue

        # ---- 2ème boucle : recherche de la table puis de la colonne source concernée par la relation
        # pour identifier les propriétés nullable et unique éventuelles
        table_source = next((table for table in model.tables if table.nom == rel.table_source), None)
        fk_col       = next((col for col in (table_source.colonnes if table_source else []) if col.nom == rel.colonne_source), None)

        if fk_col is None:
            continue

        nullable = fk_col.nullable
        unique   = fk_col.is_unique

        # valeurs par défaut qui permet de détecter visuellement des extrémités de flèches qui n'auraient pas été traitées dans les tests qui suivent
        start_arrow = 'ERmany'
        end_arrow   = 'ERone'

        if nullable :
            end_arrow  ='ERzeroToOne'
        elif not nullable:
            end_arrow  ='ERmandOne'

        if unique:
            start_arrow = 'ERzeroToOne'
        elif not unique:
            start_arrow = 'ERzeroToMany'

        # incrémentation du compteur de FK
        compteur_cles_etrangeres[rel.table_source] = compteur_cles_etrangeres.get(rel.table_source, 0) + 1

        edge_id    = f'{rel.table_source}.cle_etrangere_{compteur_cles_etrangeres[rel.table_source]}'
        edge_style = f"edgeStyle=entityRelationEdgeStyle;elbow=vertical;rounded=0;jettySize=auto;startArrow={start_arrow};endArrow={end_arrow};"
        edge_cell  = ET.SubElement(root, "mxCell", {
            "id": edge_id,
            "style": edge_style,
            "edge": "1",
            "parent": "1",
            "source": source_id,
            "target": destination_id,
        })
        ET.SubElement(edge_cell, "mxGeometry", {"relative": "1", "as": "geometry"})

    # --- 5. écriture du fichier drawio final sur disque ---
    tree = ET.ElementTree(mxfile)
    ET.indent(tree, space="  ")
    tree.write(chemin_de_sortie, encoding="utf-8", xml_declaration=False)


# # parcours du modèle pour générer le diagramme MPD drawio final
# def generer_MPD_drawio_drawpyo(model: Modele, chemin_de_sortie: Path, diag_type: str) -> None:
#     file = drawpyo.File()
#     file.file_path = str(chemin_de_sortie.parent)
#     file.file_name = chemin_de_sortie.name
#
#     # --- 1. structure racine du document drawio ---
#
#     page = drawpyo.Page(file=file)
#
#     # retirer l'aperçu de la grille
#     page.grid = 0
#
#     # table_nom -> objet drawpyo "conteneur"
#     table_objects: dict[str, "drawpyo.diagram.Object"] = {}
#     # (table_nom, column_nom) -> objet drawpyo "ligne", utile pour les arêtes FK
#     row_objects: dict[tuple[str, str], "drawpyo.diagram.Object"] = {}
#
#     # --- 2. calcul de la disposition des tables en grille +/- carrée ---
#     # factorisé et appel& dans main()
#     # nb_tables = len(model.tables)
#     # nb_cols_par_ligne = calc_nb_cols_par_ligne(nb_tables)
#
#     # --- 3. création d'un nœud par table, avec ses colonnes en libellé ---
#     for i, table in enumerate(model.tables):
#         # x, y = calcul_position_tables_unique(i, nb_cols_par_ligne)
#
#         # création du conteneur de table (nom de la table)
#         header = drawpyo.diagram.Object(
#             page=page,
#             id=table.nom,
#             value=table.nom.upper(),
#             position=(position_table[table.nom][0], position_table[table.nom][1])
#         )
#         header.width = LARGEUR_TABLE
#         header.height = hauteur_table(table)
#         header.apply_style_string(
#             "whiteSpace=wrap;rounded=0;dashed=0;align=center;verticalAlign=top;"
#         )
#         table_objects[table.nom] = header
#
#         # parcours des colonnes pour créer les lignes de champs de la table
#         for j, col in enumerate(table.colonnes):
#             row = drawpyo.diagram.Object(
#                 page=page,
#                 id=f"{table.nom}.{col.nom}",
#                 value=calcul_label_colonne(col),
#                 parent=header,
#                 position_rel_to_parent=(0, HAUTEUR_TITRE + j * HAUTEUR_LIGNE),
#             )
#             row.width = LARGEUR_TABLE
#             row.height = HAUTEUR_LIGNE
#             row.apply_style_string(
#                 "whiteSpace=wrap;rounded=0;dashed=0;align=left;verticalAlign=middle;spacingLeft=8;"
#             )
#             row_objects[(table.nom, col.nom)] = row
#
#     # --- 4. création d'une arête par relation FK, en ignorant les relations incomplètes ---
#     compteur_cles_etrangeres: dict[str, int] = {}
#     for rel in model.relations:
#         source      = row_objects.get((rel.table_source, rel.colonne_source))
#         destination = row_objects.get((rel.table_destination, rel.colonne_destination))
#         # si l'origine ou la cible n'existe pas, on ignore la relation incomplète
#         if source is None or destination is None:
#             # La table référencée n'est pas définie dans le fichier -> on ignore l'arête
#             continue
#
#         compteur_cles_etrangeres[rel.table_source] = compteur_cles_etrangeres.get(rel.table_source, 0) + 1
#         edge_id = f"{rel.table_source}.cle_etrangere_{compteur_cles_etrangeres[rel.table_source]}"
#
#         edge = drawpyo.diagram.Edge(page=page, id=edge_id, source=source, target=destination)
#         edge.waypoints       = "entity_relation"
#         edge.line_end_target = "ERone"
#         edge.line_end_source = "ERmany"
#         edge.endFill_target  = False
#         edge.endFill_source  = False
#
#     # conversion en ElementTree (nécessaire pour l'indentation)
#     xml_root = ET.fromstring(file.xml)
#     # désactive l'aperçu de la page
#     # xml_root.find(".//mxGraphModel").set("page", "0")  # cette ligne seule déclenche un warning donc on coupe en 2
#     mx_graph_model = xml_root.find(".//mxGraphModel")
#     if mx_graph_model is None:
#         raise ValueError("Balise <mxGraphModel> introuvable dans le XML généré par drawpyo")
#     mx_graph_model.set("page", "0")
#     # indentation
#     xml_tree = ET.ElementTree(xml_root)
#     ET.indent(xml_tree, space="  ")
#
#     # --- 5. écriture du fichier drawio final sur disque ---
#     chemin_de_sortie.parent.mkdir(parents=True, exist_ok=True)
#     xml_tree.write(chemin_de_sortie, encoding="utf-8", xml_declaration=True)


# # Charge un fichier Yed et adapte le style des flèches pour un MCD.
# def yed_to_MCD(fichier: str):
#
#     tree = ET.parse(fichier)
#     root = tree.getroot()
#
#     # parcours des flèches et remplacement des extrémités
#     for element in root.iter():
#         if element.tag.rsplit("}", 1)[-1] != "Arrows":
#             continue
#
#         attrs = element.attrib
#         if attrs.get("source") == "none":
#             attrs["source"] = "crows_foot_many"
#         if attrs.get("target") == "standard":
#             attrs["target"] = "none"
#
#     ET.register_namespace("", "http://graphml.graphdrawing.org/xmlns")
#     ET.register_namespace("x", "http://www.yworks.com/xml/graphml")
#     ET.register_namespace("y", "http://www.yworks.com/xml/graphml")
#     ET.indent(tree, space="  ")
#     tree.write(fichier+'MCD.graphml', encoding="utf-8", xml_declaration=True)

""" constantes """
# couleurs d'affichage dans la console
blue, green, red = '\033[34m', '\033[32m', "\033[0;31m"
reset = '\033[0m'

"""" variables globales """
position_table : dict[str, tuple[int, int]] = {}

# parcours du fichier SQL d'entrée pour générer les MPD/MCD drawio/Yed
def main() -> None:
    global position_table, blue, green, reset

    input_dir  = Path("./input")
    output_dir = Path("./output")

    output_dir.mkdir(parents=True, exist_ok=True)

    # --- tables pour tester toutes syntaxes PK/FK et cardinalités ----
    # input_file = input_dir / "MSSQL.test.ChatGPT.sql"
    # input_file = input_dir / "MySQL.test.ChatGPT.sql"
    # input_file = input_dir / "PostgreSQL.test.ChatGPT.sql"
    # input_file = input_dir / "SQLite.test.ChatGPT.sql" # absence des relations sur les tables HISTORIQUEPRODUIT et FACTURE
    # input_file = input_dir / "MSSQL.test.Claude.sql"
    # input_file = input_dir / "MySQL.test.Claude.sql"
    # input_file = input_dir / "PostgreSQL.test.Claude.sql"
    # input_file = input_dir / "SQLite.test.Claude.sql"
    input_file = input_dir / "MSSQL.test.Perplexity.sql"
    # input_file = input_dir / "MySQL.test.Perplexity.sql"
    # input_file = input_dir / "PostgreSQL.test.Perplexity.sql"
    # input_file = input_dir / "SQLite.test.Perplexity.sql"

    # --- autres exemples ----
    # input_file = input_dir / "old/MySQL.3.sql"
    # input_file = input_dir / "old/MySQL.3.sql"
    # input_file = input_dir / "old/PostgreSQL.34.sql"
    # input_file = input_dir / "old/SQLite.145.sql"
    # input_file = input_dir / "old/MSSQL.53.sql"
    # input_file = input_dir / "old/MSSQL.53.WITH CHECK.sql"
    # input_file = input_dir / "old/MSSQL.sans.GO.sql"
    # input_file = input_dir / "old/MSSQL.GO.sql"
    # input_file = input_dir / "old/MSSQL.188.sql"  # Le caractère ‑ est un tiret cadratin/insécable (U+2011),U pas un tiret ASCII - : source d'erreurs silencieuses si quelqu'un retape le nom du fichier à la main.

    # lecture du fichier sql en entrée
    ddl_text = input_file.read_text(encoding="utf-8")
    ddl_text = ddl_text.replace(' WITH CHECK', '')  # au 15/09/2026, simple_ddl_parser ne gère pas les lignes contenant cette expression, ce qui fait perdre des clés étrangères

    # fabrication du modèle pydantic à partir du contenu du fichier sql en entrée
    model = conversion_ddl_en_objets(ddl_text)

    # affichage du résumé détecté dans le modèle SQL
    print(f"{len(model.tables)} tables détectées :")
    for t in model.tables:
        pk = [c.nom for c in t.colonnes if c.is_pk]
        fk = [c.nom for c in t.colonnes if c.fk]
        print(f"  - {t.nom} : {len(t.colonnes)} colonnes, PK={pk}, FK={fk}")
    print(f"{len(model.relations)} relations détectées (attention : plusieurs relations pour 1 FK composite).")
    if model.relations:
        print("FK détectées :")
        for rel in model.relations:
            print(f"  - {rel.table_source}.{rel.colonne_source} -> {rel.table_destination}.{rel.colonne_destination}")

    # print("\nCardinalités détectées :")
    # afficher_cardinalites(model)

    """ 
        positionnment (x,y) des tables à l'avance car commun à tous les graphes
    """
    # position_table = calcul_position_tables(model)
    # position_table = calcul_position_tables_sans_chevauchement(model)
    position_table = calcul_position_tables_networkx(model)

    """ 
        génération du diagramme MPD Yed
    """
    yed_file = output_dir / f"{input_file.stem}.graphml"
    generer_MPD_Yed_ET(model, yed_file, 'mpd')
    print(f"Fichier Yed généré : {yed_file}")
    # print(model.model_dump_json(indent=2))

    """ 
        génération du MPD drawio
    """
    # generer_MPD_drawio_drawpyo(model, drawio_file)
    drawio_file  = output_dir / f"{input_file.stem}.drawio"
    generer_MPD_drawio_ET(model, drawio_file, 'mpd')
    print(f"Fichier drawio généré : {drawio_file}")


# si le script est exécuté directement, on lance le traitement principal
if __name__ == "__main__":
    main()
