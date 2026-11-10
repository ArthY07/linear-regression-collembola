# =====================================================================
# Hypothese H1 : la matrice X des variables explicatives est de plein rang
#                (aucune variable ne se calcule a partir des autres)
#
# Verification faite UNE fois pour toute l'equipe (A, S, H, J) :
# H1 ne concerne que les variables du sol, pas ce qu'on predit.
#
# Resultat attendu :
#   - rang plein          -> H1 validee en theorie
#   - mais VIF tres eleves -> on retire les variables redondantes
# =====================================================================

setwd("C:/Users/arthu/OneDrive/Bureau/JDATA")
library(corrplot)


# ---------------------------------------------------------------------
# 1. Les 27 variables numeriques du sol
# ---------------------------------------------------------------------
data <- read.csv2("data_finale.csv")

variables_sol <- c("Argile","Limon","Sable","Conduct","pH.eau","Carbonates","Calcaire",
                   "C..orga","Mat_org","Azote","C.N","P2O5","CEC","K2O","MgO","CaO","Na2O",
                   "Al","Cd","Co","Cr","Cu","Fe","Mn","Ni","Pb","Zn")

sol <- na.omit(data[, variables_sol])   # enleve les 6 pots sans analyse de sol


# ---------------------------------------------------------------------
# 2. Rang de X (colonne de 1 pour la constante + 27 variables)
#    Plein rang si rang = 28
# ---------------------------------------------------------------------
X <- cbind(1, as.matrix(sol))
cat("Rang de X :", qr(X)$rank, "/", ncol(X), "\n")


# ---------------------------------------------------------------------
# 3. Correlations 2 a 2 et indice de conditionnement
# ---------------------------------------------------------------------
cor_mat <- cor(sol)
corrplot(cor_mat, type = "upper", order = "hclust", tl.col = "black", tl.srt = 45)

# Paires tres correlees (|r| > 0.8)
paires <- which(abs(cor_mat) > 0.8 & upper.tri(cor_mat), arr.ind = TRUE)
print(data.frame(var1 = rownames(cor_mat)[paires[, 1]],
                 var2 = colnames(cor_mat)[paires[, 2]],
                 correlation = round(cor_mat[paires], 2)))

# Indice de conditionnement (probleme si > 500)
vp <- eigen(cor_mat)$values
cat("Indice de conditionnement :", round(vp[1] / vp[length(vp)]), "\n")


# ---------------------------------------------------------------------
# 4. Calcul du VIF
#    Pour chaque variable : regression "variable ~ toutes les autres"
#    -> R2 -> VIF = 1 / (1 - R2)
# ---------------------------------------------------------------------
calcul_vif <- function(tableau) {
  vif <- c()
  for (v in colnames(tableau)) {
    autres <- tableau[, colnames(tableau) != v]
    r2 <- summary(lm(tableau[[v]] ~ ., data = autres))$r.squared
    vif[v] <- 1 / (1 - r2)
  }
  return(vif)
}


# ---------------------------------------------------------------------
# 5. Boucle : on retire la variable au plus gros VIF, une par une,
#    jusqu'a ce que tous les VIF soient < 10
# ---------------------------------------------------------------------
retirees <- c()
tour <- 1

repeat {
  vif <- calcul_vif(sol)
  pire <- names(which.max(vif))

  cat("\nTour", tour, ":", ncol(sol), "variables - plus gros VIF :",
      pire, "=", round(max(vif), 1), "\n")

  if (max(vif) < 10) break      # tout est sous 10 : on s'arrete

  sol[[pire]] <- NULL           # on retire la pire variable
  retirees <- c(retirees, pire)
  tour <- tour + 1
}


# ---------------------------------------------------------------------
# 6. Resultat final
# ---------------------------------------------------------------------
cat("\nVariables retirees :", retirees, "\n")
cat("Variables gardees  :", colnames(sol), "\n\n")
print(round(sort(vif, decreasing = TRUE), 1))

# Liste a utiliser par toute l'equipe dans les regressions
variables_gardees <- colnames(sol)
