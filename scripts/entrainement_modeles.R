# Dans RStudio : Session > Set Working Directory > To Source File Location

## =============================================================
## 0. Paramètre : l'indice à prédire
## =============================================================
Y_choisi <- "S"   # "A", "S", "H" ou "J"


## =============================================================
## 1. Données communes
## =============================================================
data <- read.csv2("../donnees/data_finale2.csv", header = TRUE)

# Variables du sol gardées après H1 (tous les VIF < 10)
variables_sol <- c("Argile", "Limon", "Conduct", "pH.eau", "Carbonates", "Azote", "C.N",
                   "P2O5", "K2O", "MgO", "CaO", "Na2O", "Al", "Cd", "Cu", "Fe", "Mn",
                   "Ni", "Pb", "Zn")

# Facteurs : site_group regroupe land_use, on ne garde que land_use
facteurs <- c("land_use", "city")
noms_X   <- c(variables_sol, facteurs)

# On retire les prélèvements sans analyse de sol
data_modele <- data[complete.cases(data[, noms_X]),
                    c("Site", "Echantillon", "A", "S", "H", "J", noms_X)]
dim(data_modele)
write.csv2(data_modele, "../donnees/data_modele.csv", row.names = FALSE)

# Pour l'indice choisi : on retire les lignes où il n'existe pas (J vide)
garde <- !is.na(data_modele[[Y_choisi]])
d     <- data_modele[garde, c(Y_choisi, noms_X)]
ids   <- data_modele$Echantillon[garde]
n     <- nrow(d)
n


## =============================================================
## 2. Modèles candidats
## =============================================================
formule <- function(variables) as.formula(paste(Y_choisi, "~", paste(variables, collapse = " + ")))

modeles <- list()
modeles[["M1 sol"]]                <- lm(formule(variables_sol), data = d)
modeles[["M2 sol + usage"]]        <- lm(formule(c(variables_sol, "land_use")), data = d)
modeles[["M3 sol + usage + ville"]] <- lm(formule(noms_X), data = d)

# Sélection pas à pas avec le BIC, du modèle vide vers le modèle complet
null  <- lm(as.formula(paste(Y_choisi, "~ 1")), data = d)
scope <- list(lower = ~1, upper = formule(noms_X))
modeles[["M4 step BIC"]] <- step(null, scope, k = log(n), trace = FALSE)
formula(modeles[["M4 step BIC"]])


## =============================================================
## 3. Validation croisée leave-one-out
## =============================================================
# Erreur de test d'un prélèvement : prédit par un modèle estimé sans lui,
# soit résidu / (1 - levier), sans avoir à réestimer n modèles.
# PRESS = somme des carrés de ces erreurs de test
# RMSE_LOO = racine(PRESS / n) : erreur de prédiction typique, dans l'unité de Y

resume_modele <- function(fit, nom) {
  s <- summary(fit)
  h <- hatvalues(fit)
  erreur_test <- residuals(fit) / (1 - h)
  data.frame(modele = nom, p = length(coef(fit)) - 1, n = length(residuals(fit)),
             R2_ajuste = s$adj.r.squared, sigma_hat = s$sigma,
             AIC = AIC(fit), BIC = BIC(fit),
             PRESS = sum(erreur_test^2),
             RMSE_LOO = sqrt(sum(erreur_test^2) / length(residuals(fit))))
}

comparaison <- do.call(rbind, lapply(names(modeles), function(m) resume_modele(modeles[[m]], m)))
comparaison[, 4:9] <- round(comparaison[, 4:9], 3)
comparaison[order(comparaison$PRESS), ]    # du meilleur au moins bon en prédiction

# Test de Fisher entre modèles emboîtés
anova(modeles[["M1 sol"]], modeles[["M2 sol + usage"]], modeles[["M3 sol + usage + ville"]])


## =============================================================
## 4. Diagnostic du modèle retenu
## =============================================================
modele_retenu <- modeles[["M4 step BIC"]]   # à changer selon le tableau ci-dessus
summary(modele_retenu)
confint(modele_retenu)

par(mfrow = c(2, 2))
plot(modele_retenu)                         # résidus, QQ-plot, scale-location, leviers
par(mfrow = c(1, 1))
shapiro.test(residuals(modele_retenu))      # H0 : les résidus sont gaussiens

p_param <- length(coef(modele_retenu))
h    <- hatvalues(modele_retenu)
cook <- cooks.distance(modele_retenu)
ids[h > 2 * p_param / n]                    # points leviers (seuil 2p/n)
ids[order(cook, decreasing = TRUE)[1:5]]    # 5 plus fortes distances de Cook
