# Dans RStudio : Session > Set Working Directory > To Source File Location
# VIF des variables de chaque modèle retenu
library(car)

data <- read.csv2("../donnees/data_finale2.csv", header = TRUE)
d <- data[!is.na(data$Argile), ]   # 412 prélèvements

modeles <- list(
  "Best subset sans H1 (S.R)" = lm(S ~ Carbonates + Calcaire + CEC, data = d),
  "Stepwise AIC sans H1 (S.R)" = lm(S ~ Na2O + CEC + Carbonates + Calcaire + Cd + Pb, data = d),
  "S ~ pH + usage"            = lm(S ~ pH.eau + land_use, data = d),
  "S ~ ville + usage"         = lm(S ~ city + land_use, data = d),
  "Complet 20 H1 + usage + ville" = lm(as.formula(paste("S ~", paste(c(
    "Argile", "Limon", "Conduct", "pH.eau", "Carbonates", "Azote", "C.N", "P2O5", "K2O",
    "MgO", "CaO", "Na2O", "Al", "Cd", "Cu", "Fe", "Mn", "Ni", "Pb", "Zn",
    "land_use", "city"), collapse = " + "))), data = d)
)

# VIF (pour une variable qualitative, R donne le GVIF : on lit GVIF^(1/(2*Df)) au carré)
for (nom in names(modeles)) {
  cat("\n==", nom, "\n")
  print(round(vif(modeles[[nom]]), 2))
}
