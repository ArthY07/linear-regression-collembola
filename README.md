# Linear regression – Collembola
# Groupe E composé de Arthur Feschet, Clémentine Beaulieu , Raphaël Capristo, Olti Mjeku  
Journée data science : prédire des indices de diversité des collemboles (A, S, H, J) à partir des caractéristiques du sol de sites urbains, avec une régression linéaire.

## Organisation du dépôt

```
donnees/      les données
scripts/      les scripts R
graphiques/   les graphiques produits par les scripts
```

### donnees/
- `collembola_data_year1_train.csv` : comptages d'espèces, 3 prélèvements par site
- `BISES_data_sites.csv` : analyses de sol, 1 ligne par site
- `data_finale2.csv` : jointure des deux fichiers, une ligne par prélèvement (indices A, S, H, J + variables du site)

### scripts/
| Script | Rôle |
|---|---|
| `read_data_collembola.R` | import des données et calcul des indices |
| `jointure.R` | jointure faune + sol, crée `data_finale2.csv` |
| `exploration_X.R` | exploration des variables explicatives |
| `hypothese_H1.R` | rang, corrélations, VIF et retrait des variables redondantes |
| `distribution_Y.R` | distribution des 4 indices |
| `S.R` | régression sur S avec les 27 variables du sol |
| `S_H1.R` | régression sur S avec les 20 variables après H1 + usage + ville |
| `J.R` | régression sur J |
| `analyse_Y.R` | analyse complète d'un indice au choix (`Y_choisi`) |
| `amelioration_S.R` | pistes d'amélioration du modèle de S |
| `entrainement_modeles.R` | modèles candidats et validation croisée pour un indice au choix |
| `vif_modeles.R` | VIF des modèles retenus |
| `graphiques_diapo.R` | graphiques de la présentation |
| `bayes.R` | régression bayésienne (dépend d'objets `data_clean` et `X_vars` à créer avant) |

## Lancer un script

Dans RStudio : ouvrir le script, puis *Session > Set Working Directory > To Source File Location*. Les chemins sont relatifs au dossier `scripts/` (`../donnees/`, `../graphiques/`).

Packages utilisés : `vegan`, `corrplot`, `car`, `leaps`, `GGally` (facultatif), `glmnet` (`S_H1.R`), `arm` (`bayes.R`).
