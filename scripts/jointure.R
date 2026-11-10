# Dans RStudio : Session > Set Working Directory > To Source File Location
library(vegan)

# 1. Lire les deux fichiers
faune <- read.csv2("../donnees/collembola_data_year1_train.csv")
sites <- read.csv2("../donnees/BISES_data_sites.csv", fileEncoding = "UTF-8-BOM")

# 2. Enlever la colonne X (simple numero de ligne, inutile)
faune$X <- NULL

# 3. Garder seulement les colonnes d'especes pour calculer les indices
#    (on enleve le nom de l'echantillon, les totaux et les acariens)
pas_especes <- c("Echantillon", "total_collembola",
                 "Acari_Gamasides", "Acari_Oribates", "Acari_others",
                 "Acari_total", "Other_microarthropodes", "total_microarthropodes")
especes <- faune[, !(colnames(faune) %in% pas_especes)]

# 4. Calculer A, S, H, J pour chaque pot
faune$A <- rowSums(especes)
faune$S <- specnumber(especes)
faune$H <- diversity(especes, index = "shannon")
faune$J <- faune$H / log(faune$S)
faune$J[faune$S <= 1] <- NA   # J n'existe pas avec 0 ou 1 espece

# 5. Enlever le numero du pot : "BISES_MO_FU_CDN_1" -> "BISES_MO_FU_CDN"
faune$Site <- sub("_[0-9]+$", "", faune$Echantillon)

# 6. Jointure pot par pot : chaque pot recoit le sol de son site
#    On garde : identifiants + indices A, S, H, J + toutes les colonnes du sol
indices <- faune[, c("Site", "Echantillon", "A", "S", "H", "J")]
data_finale2 <- merge(indices, sites, by = "Site")

# 7. Verifier et sauvegarder (418 lignes, 36 colonnes)
dim(data_finale2)
write.csv2(data_finale2, "../donnees/data_finale2.csv", row.names = FALSE, quote = FALSE)
