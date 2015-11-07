SimComp -- Compilateur NetList -> C++
=====================================

Ce court fichier readme donne un bref aperçu des commandes et options
utilisables. Pour une documentation plus détaillée, consultez plutôt le
rapport remis en PDF.


Compilation de SimComp
----------------------

Les seules dépendances sont ocaml*, mehnir et un invite bash disposant des
commandes habituelles.

$ make

produit un exécutable ./simcomp à la racine du projet.


Compilation d'une NetList
-------------------------

$ ./compile.sh [fichier netlist] [fichier binaire de sortie] [options]

où les options sont
* --ramSize k : change la taille de la RAM allouée (voir rapport)
* -n : supprime les LF (\n) de l'entrée et la sortie standard entre les bits
* -On : niveau d'optimisation ; actuellement n=0 ou 1.


Pour générer seulement un code C++ sur stdout :
$ ./simcomp [options] [fichier netlist]


Utilisation du binaire produit
------------------------------

Le format d'entrée/sortie est détaillé dans le rapport. À titre de résumé,

Entrée :
* le nombre N de cycles sur la première ligne,
* k bits par ligne sur les N lignes suivantes, les bits attendus ; sauf si -n
  est passé au compilateur auquel cas ces lignes sont concaténées sans \n.

Sortie :
* N lignes contenant les bits de sortie attendus ; sauf si -n est passé au
  compilateur auquel cas ces lignes sont concaténées sans \n.

Paramètres :
* en premier paramètre, un éventuel fichier ROM binaire.

Toutes les nappes sont gérées en lisant/affichant le bit indicé 0 d'abord.
