# Dans RStudio : Session > Set Working Directory > To Source File Location
# (au lieu d'un setwd() avec le chemin de quelqu'un d'autre)

## -------------------------------------------------------------
## 1. Import 
## -------------------------------------------------------------
data_finale <- read.csv2("../donnees/data_finale2.csv", header = TRUE)
dim(data_finale)   # 418 lignes = 418 prélèvements

## -------------------------------------------------------------
## 2. Une ligne par site pour explorer les X
## -------------------------------------------------------------
# Les X (sol, ville, usage) sont identiques pour les 3 prélèvements d'un site.
# Si on les explorait sur les 418 lignes, chaque site compterait 3 fois.
# On garde donc la première ligne de chaque site : 140 sites.
noms_X <- c("Argile", "Limon", "Sable", "Conduct", "pH.eau", "Carbonates",
            "Calcaire", "C..orga", "Mat_org", "Azote", "C.N", "P2O5", "CEC",
            "K2O", "MgO", "CaO", "Na2O", "Al", "Cd", "Co", "Cr", "Cu", "Fe",
            "Mn", "Ni", "Pb", "Zn")                       # 27 variables du sol
noms_facteurs <- c("city", "land_use", "site_group")     # 3 variables qualitatives

sites_X <- data_finale[!duplicated(data_finale$Site), c("Site", noms_X, noms_facteurs)]
dim(sites_X)       # 140 sites

# Les 2 sites sans analyse de sol (NA) ne peuvent pas entrer dans le modèle
sites_X$Site[is.na(sites_X$Argile)]
sites_X <- sites_X[!is.na(sites_X$Argile), ]
dim(sites_X)       # 138 sites
head(sites_X)

## -------------------------------------------------------------
## 3. Résumé de chaque variable du sol 
## -------------------------------------------------------------
# Min, quartiles, médiane, moyenne, max : repérer les ordres de grandeur
# et les valeurs extrêmes (max très loin du 3e quartile).
summary(sites_X[, noms_X])

## -------------------------------------------------------------
## 4. Distribution de chaque variable du sol 
## -------------------------------------------------------------
# Un histogramme par variable, 9 par page.
k <- length(noms_X)
par(mfrow = c(3, 3))
for (i in 1:k) {
  hist(sites_X[, noms_X[i]], freq = FALSE,
       main = paste0("Distribution de ", noms_X[i]), xlab = noms_X[i])
}
par(mfrow = c(1, 1))

## -------------------------------------------------------------
## 5. Liens entre les X deux à deux 
## -------------------------------------------------------------
# 27 variables d'un coup donneraient une grille illisible (27 x 27).
# On fait donc des groupes de variables qui vont ensemble.
granulometrie <- c("Argile", "Limon", "Sable")
matiere_org   <- c("C..orga", "Mat_org", "Azote", "C.N", "CEC")
calcaire_pH   <- c("pH.eau", "Conduct", "Carbonates", "Calcaire", "CaO")
nutriments    <- c("P2O5", "K2O", "MgO", "Na2O", "Al")
metaux        <- c("Cd", "Co", "Cr", "Cu", "Fe", "Mn", "Ni", "Pb", "Zn")

pairs(sites_X[, granulometrie], pch = 20, cex = 0.5, main = "Granulométrie")
pairs(sites_X[, matiere_org],   pch = 20, cex = 0.5, main = "Matière organique")
pairs(sites_X[, calcaire_pH],   pch = 20, cex = 0.5, main = "Calcaire et pH")
pairs(sites_X[, nutriments],    pch = 20, cex = 0.5, main = "Nutriments")
pairs(sites_X[, metaux],        pch = 20, cex = 0.5, main = "Métaux")

# Version GGally (si le package est installé : install.packages("GGally"))
library(GGally)
ggpairs(sites_X[, metaux])

## -------------------------------------------------------------
## 6. Les variables qualitatives 
## -------------------------------------------------------------
# table() compte le nombre de sites dans chaque catégorie.
table(sites_X$city)
table(sites_X$land_use)
table(sites_X$site_group)

# Croisement usage x groupe : chaque usage tombe-t-il dans un seul groupe ?
table(sites_X$land_use, sites_X$site_group)

# Croisement ville x usage : a-t-on des sites de chaque usage dans chaque ville ?
table(sites_X$city, sites_X$land_use)
