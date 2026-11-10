# Dans RStudio : Session > Set Working Directory > To Source File Location
# Objectif : partir du modèle S ~ pH et chercher à l'améliorer

## =============================================================
## 1. Données
## =============================================================
data <- read.csv2("data_finale2.csv", header = TRUE)

variables_sol <- c("Argile", "Limon", "Conduct", "pH.eau", "Carbonates", "Azote", "C.N",
                   "P2O5", "K2O", "MgO", "CaO", "Na2O", "Al", "Cd", "Cu", "Fe", "Mn",
                   "Ni", "Pb", "Zn")
facteurs <- c("land_use", "city")

garde <- complete.cases(data[, c(variables_sol, facteurs)])
d     <- data[garde, c("S", variables_sol, facteurs)]
ids   <- data$Echantillon[garde]
n     <- nrow(d)


## =============================================================
## 2. Piste 1 : la sélection de variables
## =============================================================
null  <- lm(S ~ 1, data = d)
scope <- list(lower = ~1,
              upper = as.formula(paste("S ~", paste(c(variables_sol, facteurs), collapse = " + "))))

# BIC (pénalité forte) contre AIC (pénalité plus faible)
step_BIC <- step(null, scope, k = log(n), trace = FALSE)
step_AIC <- step(null, scope, k = 2,      trace = FALSE)
formula(step_BIC)
formula(step_AIC)

# Recherche exhaustive sur les variables du sol : meilleur modèle pour chaque taille
library(leaps)
out <- regsubsets(as.formula(paste("S ~", paste(variables_sol, collapse = " + "))),
                  data = d, nvmax = 10)
bss <- summary(out)
plot(1:10, bss$bic, type = "b", col = "red2", xlab = "Nombre de variables", ylab = "BIC",
     main = "Recherche exhaustive : BIC selon la taille")
which(bss$which[which.min(bss$bic), ])   # variables du meilleur modèle selon le BIC


## =============================================================
## 3. Pistes 2 à 4 : usage du sol, courbure, interaction
## =============================================================
m_pH        <- lm(S ~ pH.eau, data = d)                              # modèle de départ
m_pH_usage  <- lm(S ~ pH.eau + land_use, data = d)                   # + usage du sol
m_pH2_usage <- lm(S ~ pH.eau + I(pH.eau^2) + land_use, data = d)     # + courbure du pH
m_inter     <- lm(S ~ pH.eau * land_use, data = d)                   # effet du pH différent selon l'usage

# Tests de Fisher entre modèles emboîtés
anova(m_pH, m_pH_usage)          # l'usage du sol apporte-t-il quelque chose ?
anova(m_pH_usage, m_pH2_usage)   # la courbure du pH apporte-t-elle quelque chose ?
anova(m_pH_usage, m_inter)       # l'interaction apporte-t-elle quelque chose ?


## =============================================================
## 4. Piste 5 : transformer S pour corriger l'asymétrie des résidus
## =============================================================
m_log <- lm(log(S + 1) ~ pH.eau + land_use, data = d)   # +1 car S peut valoir 0


## =============================================================
## 5. Comparaison de tous les candidats
## =============================================================
# Erreur de test (leave-one-out) = résidu / (1 - levier), ramenée sur l'échelle de S
rmse_loo_S <- function(fit, log_S = FALSE) {
  e <- residuals(fit) / (1 - hatvalues(fit))
  if (!log_S) return(sqrt(mean(e^2)))
  prediction_loo <- exp(log(d$S + 1) - e) - 1      # prédiction sans l'individu, remise en espèces
  sqrt(mean((d$S - prediction_loo)^2))
}

candidats <- list("S ~ pH" = m_pH, "step BIC" = step_BIC, "step AIC" = step_AIC,
                  "S ~ pH + usage" = m_pH_usage, "S ~ pH + pH² + usage" = m_pH2_usage,
                  "S ~ pH x usage" = m_inter, "log(S+1) ~ pH + usage" = m_log)

comparaison <- do.call(rbind, lapply(names(candidats), function(nom) {
  fit   <- candidats[[nom]]
  log_S <- nom == "log(S+1) ~ pH + usage"
  data.frame(modele = nom, p = length(coef(fit)) - 1,
             R2_ajuste = round(summary(fit)$adj.r.squared, 3),
             AIC = if (log_S) NA else round(AIC(fit), 1),   # AIC et BIC non comparables après transformation
             BIC = if (log_S) NA else round(BIC(fit), 1),
             RMSE_LOO = round(rmse_loo_S(fit, log_S), 3),
             shapiro_p = signif(shapiro.test(residuals(fit))$p.value, 2),
             cook_max = round(max(cooks.distance(fit)), 3))
}))
comparaison[order(comparaison$RMSE_LOO), ]
sd(d$S)   # erreur d'un modèle qui prédirait toujours la moyenne


## =============================================================
## 6. Modèle retenu : interprétation et diagnostic
## =============================================================
reg <- m_pH_usage                # à changer selon le tableau ci-dessus
summary(reg)
confint(reg)

par(mfrow = c(2, 2))
plot(reg)
par(mfrow = c(1, 1))

par(mfrow = c(1, 2))
plot(d$pH.eau, residuals(reg), pch = 20, xlab = "pH", ylab = "Résidus", main = "Résidus en fonction du pH")
abline(h = 0, col = 2)
lines(lowess(d$pH.eau, residuals(reg)), col = 4, lwd = 2)
hist(residuals(reg), freq = FALSE, main = "Histogramme des résidus", xlab = "Résidus")
curve(dnorm(x, 0, sd(residuals(reg))), add = TRUE, col = 2, lwd = 2)
par(mfrow = c(1, 1))

shapiro.test(residuals(reg))
max(cooks.distance(reg))
