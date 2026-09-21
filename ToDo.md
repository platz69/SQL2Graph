-----bonnes pratiques

implémente cette option (networkx + kamada_kawai + anti-collision) dans build_drawio


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
*

----------MCD-------
1/ traiter les bouts 'target' des flèches
2/ détecter les jointurs pour suppressin table + réductions 1-n + table + n-1 > n-n

valeurs possibles des attributs "source/target" en .grapjml Yed :
        Yed                         drawio
?..?    none                            
?..1    crows_foot_one              ERone       
?..n    crows_foot_many             ERmany  

0..1    crows_foot_one_optional     ERzeroToOne                  
0..n    crows_foot_many_optional    ERzeroToMany                       
1..1    crows_foot_one_mandatory    ERmandOne                     
1..n    crows_foot_many_mandatory   ERoneToMany    

vérifier tous les commentaires oui/non et -- PK inline (colonne) -- PK simple générés par copilot
MSSQL.test.Perplexity.sql PAS parsé à partie de : -- 10) Table client_contact (n..n) (rate la table et ses FK)

