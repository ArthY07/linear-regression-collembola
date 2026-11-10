# Rapport : modélisation de la richesse S des collemboles

Branche : `prediction-J` · Script qui produit tous les chiffres : `S_H1.R` · Données : `data_finale2.csv`

## Résumé

- **Indice retenu : S** (nombre d'espèces par pot). C'est le mieux expliqué après sélection, et le seul qui se généralise un peu à de nouveaux sites.
- **Modèle retenu : `S ~ city + land_use`** (stepwise AIC sur les 20 variables du sol gardées après H1, plus la ville et le type d'endroit).
- **Variables qui influencent S :**
  1. **Type d'endroit** : les jardins (JP) ont **+1,37 espèce** par rapport à FU (p = 0,0008). LV, PU et RP ne se distinguent pas de FU.
  2. **Ville** : MO est la plus riche. NS (−1,05), NY (−0,67) et PA (−1,03) ont environ une espèce de moins (p < 0,04).
  3. Le **pH** apparaît faiblement (stepwise BIC, Lasso). Aucune autre variable du sol n'est retenue de façon stable.
- **Pouvoir explicatif faible** : R² ajusté = 0,086 ; R² sur sites nouveaux = 0,038. Le sol explique peu S ; le lieu compte plus que la chimie du sol.

## Pipeline

```
data_finale2.csv (418 pots, 140 sites)
 1. Choix de l'indice           A, S, H, J comparés → S
 2. H1 (hypothese_H1.R)         rang, corrélations, VIF → 27 → 20 variables du sol
 3. Modèle complet              S ~ 20 variables + land_use + city
 4. H2 / H3 sur le modèle complet
 5. Sélection                   stepwise AIC, stepwise BIC, Lasso
 6. Comparaison                 R² ajusté, R² sur sites nouveaux
 7. Modèle final + H2 / H3      → variables les plus influentes
 8. Comparaison avec les variantes de l'équipe
```

**Unité statistique** : le pot (3 pots par site). Chaque pot reçoit l'analyse de sol de son site, sans moyenne.

**Validation croisée** : 10 blocs de **sites** (les 3 pots d'un site sont toujours ensemble), graine `set.seed(2026)`. Le « R² sur sites nouveaux » mesure la capacité à prédire des sites jamais vus. S'il est négatif, le modèle fait pire que la moyenne.

## 1. Choix de l'indice

Modèle : 20 variables H1 + land_use + city.

| Y | Pots | R² ajusté (complet) | R² ajusté (stepwise AIC) | R² sur sites nouveaux (stepwise AIC) |
|---|---|---|---|---|
| A | 412 | 0,105 | 0,097 | −0,047 |
| **S** | 412 | 0,064 | **0,086** | **0,038** |
| H | 412 | 0,058 | 0,067 | 0,010 |
| J | 331 | 0,054 | 0,070 | −0,048 |

A a le meilleur R² ajusté en modèle complet, mais il ne prédit pas les sites nouveaux. **S est le seul indice qui se généralise** de façon nette : il est retenu.

J n'existe que pour les pots ayant au moins 2 espèces, d'où n = 331.

## 2. H1 : colinéarité des variables du sol

Détails dans `hypothese_H1.R`. Ce résultat vaut pour toute l'équipe, puisque H1 ne dépend pas de Y.

- Rang de X = 28/28 (27 variables + constante) → **H1 respectée en théorie**.
- Indice de conditionnement = 3 032 560 (seuil usuel : 500) → **colinéarité très forte en pratique**.
- Retrait itératif de la variable au plus grand VIF, jusqu'à ce que tous les VIF soient < 10.

| Tour | Variable retirée | VIF | Raison |
|---|---|---|---|
| 1 | Mat_org | 246 388 | = 1,72 × C.orga (r = 1,00) |
| 2 | Sable | 82 462 | Argile + Limon + Sable = 1000 |
| 3 | C..orga | 219 | r = 0,95 avec Azote |
| 4 | Co | 34 | lié à Ni, Cr, Fe, Mn (r de 0,84 à 0,93) |
| 5 | CEC | 27 | expliquée par l'argile, la matière organique, Ca, Mg |
| 6 | Calcaire | 13 | r = 0,94 avec Carbonates |
| 7 | Cr | 11 | lié à Ni et Fe |

**20 variables gardées** : Argile, Limon, Conduct, pH.eau, Carbonates, Azote, C.N, P2O5, K2O, MgO, CaO, Na2O, Al, Cd, Cu, Fe, Mn, Ni, Pb, Zn.

## 3. Modèle complet

`S ~ 20 variables + land_use + city` (412 pots, 138 sites ; 6 pots sans analyse de sol sont exclus).

- R² = 0,126 ; R² ajusté = 0,064 ; test de Fisher p = 0,0019.
- **Seule variable significative : land_use JP (+1,47 ; p = 0,002).** Aucune variable du sol n'est significative.

## 4. H2 et H3 sur le modèle complet

| Hypothèse | Constat | Verdict |
|---|---|---|
| Linéarité | résidus vs valeurs prédites sans courbure | ✅ |
| H2 : variance constante | la variance augmente un peu avec les valeurs prédites (ncvTest p = 0,001) | ⚠️ légère hétéroscédasticité |
| H3 : normalité | résidus un peu étirés à droite (Shapiro p = 5e−05) | ⚠️ légère asymétrie |

C'est typique d'un comptage. Les transformations log(S+1) et √S ont été testées : elles **dégradent** la normalité (beaucoup de S = 0) et la prédiction. On garde donc S brut.

## 5–6. Sélection et comparaison des modèles

On compare 4 méthodes avec deux scores :
- **R² ajusté** : la part de S expliquée, pénalisée par le nombre de variables (plus grand = mieux) ;
- **R² sur sites nouveaux** : la capacité à prédire des sites jamais vus (plus grand = mieux).

| Méthode | R² ajusté | R² sur sites nouveaux | Variables gardées |
|---|---|---|---|
| Modèle complet (tout garder) | 0,064 | −0,230 | toutes |
| **Stepwise AIC** | **0,086** | **0,038** | **city, land_use** |
| Stepwise BIC (plus sévère) | 0,038 | 0,024 | pH |
| Lasso | – | 0,005 | pH, Carbonates, JP |

**Choix : stepwise AIC.**
- C'est le **meilleur sur les deux scores**.
- Le modèle complet prédit moins bien que la moyenne sur des sites nouveaux : avec trop de variables, il apprend le bruit.
- Le Lasso et le BIC gardent d'autres variables, mais **confirment** que JP et le pH sont les seules pistes en plus de la ville.

## 7. Modèle final : `S ~ city + land_use`

R² ajusté = 0,086 ; test de Fisher p = 2,7e−07 (le modèle est globalement significatif).

Références : ville **MO** et usage **FU**. Chaque effet se lit « par rapport à MO » ou « par rapport à FU ».

| Effet | Espèces en plus / en moins | p | Significatif ? |
|---|---|---|---|
| **Jardins (JP)** | **+1,37** | 0,0008 | ✅ |
| Ville NS | −1,05 | 0,00005 | ✅ |
| Ville PA | −1,03 | 0,037 | ✅ |
| Ville NY | −0,67 | 0,008 | ✅ |
| Usage RP | +0,14 | 0,71 | ❌ |
| Usage LV | −0,14 | 0,71 | ❌ |
| Usage PU | +0,06 | 0,86 | ❌ |

H2 et H3 sur le modèle final donnent le même constat qu'en section 4 : légère hétéroscédasticité et légère asymétrie.

## Les variables les plus influentes sur S

| Rang | Variable | Effet | Retrouvée par |
|---|---|---|---|
| 🥇 | **Type d'endroit : jardins (JP)** | **+1,4 espèce** par rapport aux autres usages | toutes les méthodes |
| 🥈 | **Ville** | MO est la plus riche ; NS, NY et PA ont 0,7 à 1 espèce de moins | stepwise AIC |
| 🥉 | **pH** | effet positif faible | stepwise BIC, Lasso |
| – | Autres variables du sol (métaux, azote, texture…) | aucun effet stable | – |

**En une phrase : le lieu (type d'endroit et ville) influence plus la richesse en collemboles que la chimie du sol.**

## 8. Comparaison avec les variantes de l'équipe

Toutes les variantes sont passées par un stepwise AIC, sur les mêmes 412 pots et avec le même découpage.

| Variante | R² ajusté | R² sur sites nouveaux | Variables retenues |
|---|---|---|---|
| 27 variables quantitatives, sans H1, sans ville/usage (`S.R` sur main) | **0,097** | 0,024 | Na2O, CEC, **Carbonates, Calcaire**, Cd, Pb |
| 20 variables quantitatives H1, sans ville/usage | 0,049 | 0,026 | pH, Na2O |
| **20 variables H1 + ville + usage (ce rapport)** | 0,086 | **0,038** | **city, land_use** |

**Pourquoi retenir la dernière variante, alors que la première a un R² ajusté plus élevé :**
1. Dans la variante à 27 variables, **Carbonates et Calcaire (r = 0,94) sont gardés ensemble, avec des signes opposés**. C'est le symptôme de la colinéarité. Leurs coefficients ne sont pas interprétables, et le R² ajusté est gonflé par leur compensation.
2. Elle **prédit moins bien** les sites nouveaux (0,024 contre 0,038).
3. L'objectif est d'**identifier les variables influentes**, ce qui demande des coefficients fiables.
4. Les variables qualitatives sont légitimes dans une régression linéaire : `lm()` les code en indicatrices (0/1). Sans elles, le modèle ne peut pas voir l'effet le plus fort (JP).

## Limites

- **Pouvoir explicatif faible** : moins de 10 % de la variance de S est expliquée.
- **Non-indépendance** : les 3 pots d'un site partagent le même sol. Les p-valeurs sont donc un peu optimistes (H2). Faire la moyenne par site double le R² ajusté (0,166) avec les mêmes variables retenues, mais on a choisi de garder tous les pots.
- **Résidus** : légère hétéroscédasticité et légère asymétrie, typiques d'un comptage.

## Reproduire

```r
# Dans RStudio : Session > Set Working Directory > To Source File Location
install.packages(c("car", "leaps", "glmnet"))   # si besoin
source("hypothese_H1.R")   # H1 -> 20 variables
source("S_H1.R")           # toutes les tables de ce rapport
```

Graine : `set.seed(2026)`. La validation croisée découpe par site, en 10 blocs.
