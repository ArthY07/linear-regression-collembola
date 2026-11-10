setwd("C:/Users/arthu/OneDrive/Bureau/JDATA")
library(vegan)

# 1. Lire les deux fichiers
faune <- read.csv2("collembola_data_year1_train.csv")
sites <- read.csv2("BISES_data_sites.csv", fileEncoding = "UTF-8-BOM")

# 2. Garder seulement les colonnes d'especes (on enleve le numero de ligne,
#    le nom de l'echantillon et les totaux)
a_enlever <- c("X", "Echantillon", "total_collembola",
               "Acari_Gamasides", "Acari_Oribates", "Acari_others",
               "Acari_total", "Other_microarthropodes", "total_microarthropodes")
especes <- faune[, !(colnames(faune) %in% a_enlever)]

# 3. Calculer A, S, H, J pour chaque pot
pots <- data.frame(Echantillon = faune$Echantillon)
pots$A <- rowSums(especes)
pots$S <- specnumber(especes)
pots$H <- diversity(especes, index = "shannon")
pots$J <- pots$H / log(pots$S)

# 4. Enlever le numero du pot : "BISES_MO_FU_CDN_1" -> "BISES_MO_FU_CDN"
pots$Site <- sub("_[0-9]+$", "", pots$Echantillon)

# 5. On remet les comptages d'especes a cote (pour ne rien perdre)
pots <- cbind(pots, especes)

# 6. Jointure pot par pot : chaque pot recoit le sol de son site
data_finale <- merge(pots, sites, by = "Site")

# 7. Verifier et sauvegarder
dim(data_finale)
head(data_finale)
write.csv2(data_finale, "data_finale.csv", row.names = FALSE)
