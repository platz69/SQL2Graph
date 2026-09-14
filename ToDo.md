y a plus de liens pour mssql53 !!!!
implémente cette option (networkx + kamada_kawai + anti-collision) dans build_drawio
peut-on appliquer networkx  avant construction_drawio et construction_graphml
est-ce que from pathlib import Path peut être remplacé par basename() / dirname()
je crois que simple-ddl-parser ne pige pas les "WITH CHECK" qu'il faudrait purger avant traitement
tester les autres algos de networx : spectral_layout, planar_layout, shell_layout with explicit nlist
tester spring_layout en dim=3 :)
faire un test de verif en comptant mes "CREATE TABLE" et les FOREIGN Keys
---------------------------------------------
Un vrai algorithme de layout de graphe :
* networkx (layout spring_layout ou kamada_kawai_layout)

rajouter une couche anti-collision :
* Graphviz (dot/neato via pydot ou l'exécutable dot), qui gèrent nativement l'anti-collision et l'agencement 
selon les relations. C'est plus lourd (nouvelle dépendance, conversion de coordonnées flottantes vers la
grille en pixels) mais donne des diagrammes bien plus lisibles pour un schéma avec beaucoup de FK.
Dans le cas MPD avec tables rectangulaires de largeur fixe networkx devrait suffire on et reste dans l'esprit 
du script actuel.