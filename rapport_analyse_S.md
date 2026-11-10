# Rapport : exploration, H1 et modélisation de la richesse S

Rédigé le 10/11/2026 à partir de la branche `main` (après le commit `8a26f3c`).
Tous les chiffres ci-dessous ont été obtenus en relançant les scripts cités, sur les fichiers du dépôt.

---

## 1. Sur quoi ce rapport s'appuie

### Données
| Fichier | Contenu | Origine |
|---|---|---|
| `collembola_data_year1_train.csv` | 418 prélèvements × 98 espèces de collemboles (+ totaux, acariens) | fourni |
| `BISES_data_sites.csv` | 174 sites : 27 variables du sol, `city`, `land_use`, `site_group` | fourni |
| `data_finale2.csv` | 418 prélèvements : Site, Echantillon, A, S, H, J + 30 variables du site, **sans les colonnes d'espèces** | jointure (`jointure.R`), version allégée |

### Règles suivies
- Les comptages de collemboles servent **uniquement à calculer les indices** (Y). Ils ne sont jamais utilisés comme variables explicatives.
- Pas de regroupement par site : une ligne = un prélèvement. Les 6 prélèvements des 2 sites sans analyse de sol (`BISES_NY_PU_GOD_RU`, `BISES_NY_PU_PEP_RU`) sont retirés : **412 lignes**.
- Méthodes utilisées : uniquement celles du cours de régression linéaire (rang, corrélations, VIF, test de Fisher, AIC/BIC, sélection pas à pas et exhaustive, erreur de test leave-one-out et PRESS, graphes de résidus, Shapiro-Wilk, leviers, distance de Cook).

### Scripts (tous sur `main`)
| Script | Rôle | Auteur |
|---|---|---|
| `jointure.R` | calcul de A, S, H, J par prélèvement et jointure faune + sol | Arthur |
| `exploration_X.R` | exploration des variables explicatives, une ligne par site | Olti |
| `hypothese_H1.R` | rang, corrélations, conditionnement, VIF, retrait des variables redondantes | Arthur |
| `entrainement_modeles.R` | modèles candidats + validation croisée leave-one-out pour n'importe quel indice | Olti |
| `analyse_Y.R` | distribution de Y, modèles, résidus, points influents ; paramètre `Y_choisi` | Olti |
| `amelioration_S.R` | pistes d'amélioration du modèle de S | Olti |
| `S.R` | analyse de S (modèle complet, sélection, diagnostic, log) | Zelyx21 — non relu dans ce rapport |

### Graphiques (dossier `graphiques/`)
| Fichier | Contenu | Produit par |
|---|---|---|
| `exploration_X_1.png` à `_3.png` | histogrammes des 27 variables du sol | `exploration_X.R` |
| `exploration_X_4.png` à `_8.png` | nuages de points : granulométrie, matière organique, calcaire et pH, nutriments, métaux | `exploration_X.R` |
| `hypothese_H1_1.png` | matrice des corrélations (Pearson) des 27 variables du sol | `hypothese_H1.R` |
| `S_1.png` | distribution de S et QQ-plot | `analyse_Y.R` (`Y_choisi <- "S"`) |
| `S_2.png` | 4 graphes de diagnostic de `S ~ pH` | `analyse_Y.R` |
| `S_3.png`, `S_4.png` | histogramme des résidus ; résidus en fonction du pH | `analyse_Y.R` |
| `S_amelioration_1.png` | BIC de la recherche exhaustive selon le nombre de variables | `amelioration_S.R` |
| `S_amelioration_2.png` | 4 graphes de diagnostic de `S ~ pH + land_use` | `amelioration_S.R` |
| `S_amelioration_3.png` | résidus en fonction du pH ; histogramme des résidus | `amelioration_S.R` |
| `A_1.png` à `A_4.png` | même analyse pour A (pour comparaison) | `analyse_Y.R` (`Y_choisi <- "A"`) |

---

## 2. Préparation des données

- Le script fourni comptait la colonne `X` (numéro de ligne) comme une espèce : A et S étaient faussés. Corrigé dans `jointure.R` (`faune$X <- NULL`). Vérification : A recalculé = `total_collembola` pour les 418 prélèvements.
- J n'existe pas avec 0 ou 1 espèce (81 prélèvements) : laissé vide (NA), jamais remplacé par 0.
- Chaque site a 3 prélèvements (un seul site en a 1 : `BISES_PA_JP_13`).

## 3. Exploration des variables explicatives (`exploration_X.R`)

Faite sur **138 sites** (une ligne par site, sinon chaque site compte 3 fois).

- **Redondances exactes** : `Mat_org` = 1,73 × `C..orga` (corrélation 1,00) ; `Argile + Limon + Sable` = 1000 ; chaque `land_use` appartient à un seul `site_group`.
- **Distributions** : régulières pour Argile, Limon, Sable, C.N, CEC, Al, CaO ; très asymétriques pour Carbonates, Calcaire, P2O5, K2O, Na2O, MgO et la plupart des métaux ; **pH à deux bosses** (sols acides vers 5,5–6,5 et basiques vers 8).
- **pH lié à la ville** : pH médian 6,0 à NS (92 % des sites sans carbonates) contre 8,4 à MO.
- **Sites extrêmes en X** : `BISES_PA_FU_8` (C..orga 217, CEC 614), `BISES_PA_FU_19` et `_20` (Pb 906 et 798), `BISES_MO_RP_ALO` (Ni 233, Cr 241).
- **Ville × usage** : dans le train, PA n'a que des sites FU (9) et JP (1).

## 4. Hypothèse H1 (`hypothese_H1.R`)

- Rang de X (constante + 27 variables) : **28 / 28**, plein rang.
- Indice de conditionnement de la matrice des corrélations : **environ 3 millions** (seuil 500) → colinéarité très forte.
- Retrait de la variable au plus grand VIF, une par une, jusqu'à VIF < 10 : **retirées** Mat_org, Sable, C..orga, Co, CEC, Calcaire, Cr.
- **20 variables gardées** : Argile, Limon, Conduct, pH.eau, Carbonates, Azote, C.N, P2O5, K2O, MgO, CaO, Na2O, Al, Cd, Cu, Fe, Mn, Ni, Pb, Zn (VIF max : Zn 7,6).
- Facteurs : on garde `land_use` (et non `site_group`, qui le regroupe) et `city`.

## 5. Modélisation de S (`analyse_Y.R`, `amelioration_S.R`)

### Distribution de S (`S_1.png`)
0 à 13 espèces ; médiane 3 ; moyenne 3,34 ; écart-type 2,12 ; 28 prélèvements à 0. Légère asymétrie à droite, valeurs entières (marches sur le QQ-plot).
Moyenne par usage : JP 4,65 ; RP 3,36 ; PU 3,22 ; FU 3,03 ; LV 2,96. Par ville : MO 3,96 ; NY 3,35 ; NS 2,76 ; PA 2,75.

### Modèle complet (20 variables du sol)
Aucune variable significative à 5 % prise seule (Cd et Cu à 10 %) ; test de Fisher global p = 0,01 ; R² = 0,089, R² ajusté = 0,043.

### Validation croisée et sélection
Erreur de test leave-one-out = résidu / (1 − levier) ; RMSE_LOO = racine(PRESS / n), en nombre d'espèces.

| Modèle | Variables | R² ajusté | BIC | RMSE_LOO |
|---|---|---|---|---|
| step AIC | city + land_use | 0,086 | 1796,1 | 2,044 |
| **S ~ pH + land_use** | | **0,076** | **1790,5** | **2,049** |
| S ~ pH + pH² + land_use | | 0,075 | 1795,7 | 2,052 |
| S ~ pH × land_use | | 0,071 | 1812,8 | 2,064 |
| S ~ pH (step BIC et recherche exhaustive) | | 0,038 | 1786,9 | 2,079 |
| log(S+1) ~ pH + land_use | | 0,057 | — | 2,110 |
| Prédire toujours la moyenne | | | | 2,116 |

- Les modèles à 20–27 variables prédisent moins bien (RMSE_LOO 2,10 à 2,12) : sur-ajustement.
- Step BIC et recherche exhaustive (`S_amelioration_1.png`) : **seul le pH** parmi les variables du sol.
- Tests de Fisher : + land_use **p = 0,0004** ; + pH² p = 0,39 ; + interaction pH × land_use p = 0,78 ; + city (après sol + usage) p = 0,83.
- log(S+1) : normalité des résidus moins bonne (Shapiro p = 1,6e-9) et prédiction moins bonne.
- Step AIC remplace le pH par la ville (la ville porte l'information du pH) ; écarté car il dépend de la ville alors que PA est très peu représentée.

### Modèle retenu : `S ~ pH.eau + land_use`
| Terme | Estimation | IC 95 % | p |
|---|---|---|---|
| pH | +0,36 espèce par unité | [0,16 ; 0,56] | 0,0005 |
| JP (vs FU) | +1,56 | [0,84 ; 2,29] | 0,00003 |
| LV, PU, RP (vs FU) | +0,14 à +0,39 | contiennent 0 | non significatifs |

R² = 0,087 ; RMSE_LOO = 2,05 espèces (contre 2,12 en prédisant la moyenne).

### Diagnostic (`S_amelioration_2.png`, `S_amelioration_3.png`)
- Linéarité : courbe des résidus plate, pas de courbure en fonction du pH.
- Variance (H2) : à peu près constante.
- Normalité (H3) : queue droite (prélèvements très riches, ex. `BISES_MO_JP_GRB_1` à 13 espèces) ; Shapiro W = 0,98, p < 0,001 → rejetée.
- Points influents : distance de Cook max 0,055 (seuil 1) → aucun.

## 6. Pour comparaison : A (`A_1.png` à `A_4.png`)
A très asymétrique (médiane 7, max 593). `A ~ K2O + MgO + C.N + Cu` : R² 0,094, RMSE_LOO 55,3 contre 56,6 pour la moyenne ; prédictions négatives, hétéroscédasticité, Shapiro W = 0,48 ; `BISES_MO_LV_SKT_1` et `_2` (593 et 590) avec Cook 0,85. Modèle non valide en l'état ; piste : log(A + 1), non testée.

## 7. Limites et points de vigilance
1. Les 3 prélèvements d'un site partagent les mêmes X : erreurs non indépendantes, validation croisée un peu optimiste.
2. H3 non respectée pour S : p-valeurs et intervalles à prendre avec prudence.
3. PA très peu représentée dans le train (10 sites, uniquement FU et JP).
4. La matrice de corrélation montrée en réunion était de Spearman ; celle de `hypothese_H1.R` est de Pearson (`hypothese_H1_1.png`).
5. `S.R` (Zelyx21) analyse aussi S mais avec les 27 variables du sol, sans le retrait du H1 : ses résultats peuvent différer, à comparer avant la présentation.

## 8. Reproduire
Dans RStudio : ouvrir le script, *Session > Set Working Directory > To Source File Location*, puis exécuter. Packages : `vegan` (jointure), `corrplot` (H1), `GGally` (exploration, facultatif), `leaps` (recherche exhaustive).
