# Dans RStudio : Session > Set Working Directory > To Source File Location

## =============================================================
## 0. Paramètre : l'indice à étudier
## =============================================================
Y_choisi <- "S"   # "A", "S", "H" ou "J"


## =============================================================
## 1. Données
## =============================================================
data <- read.csv2("../donnees/data_finale2.csv", header = TRUE)

# Variables du sol gardées après H1 (tous les VIF < 10)
variables_sol <- c("Argile", "Limon", "Conduct", "pH.eau", "Carbonates", "Azote", "C.N",
                   "P2O5", "K2O", "MgO", "CaO", "Na2O", "Al", "Cd", "Cu", "Fe", "Mn",
                   "Ni", "Pb", "Zn")
facteurs <- c("land_use", "city")
noms_X   <- c(variables_sol, facteurs)

# On garde les prélèvements avec une analyse de sol et une valeur de Y (J peut être vide)
garde <- complete.cases(data[, noms_X]) & !is.na(data[[Y_choisi]])
d     <- data[garde, c(Y_choisi, noms_X)]
ids   <- data$Echantillon[garde]
y     <- d[[Y_choisi]]
n     <- nrow(d)
n


## =============================================================
## 2. Distribution de Y
## =============================================================
summary(y)
c(moyenne = mean(y), variance = var(y), ecart_type = sd(y))

par(mfrow = c(1, 2))
hist(y, freq = FALSE, main = paste("Distribution de", Y_choisi), xlab = Y_choisi)
curve(dnorm(x, mean(y), sd(y)), add = TRUE, col = 2, lwd = 2)   # loi normale de même moyenne et écart-type
qqnorm(y, pch = 20, main = paste("QQ-plot de", Y_choisi))
qqline(y, col = 2)
par(mfrow = c(1, 1))

# Y selon l'usage du sol et selon la ville
round(tapply(y, d$land_use, mean), 2)
round(tapply(y, d$city, mean), 2)


## =============================================================
## 3. Modèles candidats et validation croisée leave-one-out
## =============================================================
formule <- function(variables) as.formula(paste(Y_choisi, "~", paste(variables, collapse = " + ")))

modeles <- list()
modeles[["M1 sol"]]                 <- lm(formule(variables_sol), data = d)
modeles[["M2 sol + usage"]]         <- lm(formule(c(variables_sol, "land_use")), data = d)
modeles[["M3 sol + usage + ville"]] <- lm(formule(noms_X), data = d)
null  <- lm(as.formula(paste(Y_choisi, "~ 1")), data = d)
scope <- list(lower = ~1, upper = formule(noms_X))
modeles[["M4 step BIC"]] <- step(null, scope, k = log(n), trace = FALSE)

# Erreur de test = résidu / (1 - levier) ; PRESS = somme de leurs carrés
resume_modele <- function(fit, nom) {
  s <- summary(fit)
  erreur_test <- residuals(fit) / (1 - hatvalues(fit))
  data.frame(modele = nom, p = length(coef(fit)) - 1,
             R2 = s$r.squared, R2_ajuste = s$adj.r.squared, sigma_hat = s$sigma,
             AIC = AIC(fit), BIC = BIC(fit), PRESS = sum(erreur_test^2),
             RMSE_LOO = sqrt(mean(erreur_test^2)))
}
comparaison <- do.call(rbind, lapply(names(modeles), function(m) resume_modele(modeles[[m]], m)))
comparaison[, 3:9] <- round(comparaison[, 3:9], 3)
comparaison[order(comparaison$PRESS), ]
sd(y)    # erreur d'un modèle qui prédirait toujours la moyenne, pour comparer à RMSE_LOO

anova(modeles[["M1 sol"]], modeles[["M2 sol + usage"]], modeles[["M3 sol + usage + ville"]])


## =============================================================
## 4. Modèle retenu
## =============================================================
reg <- modeles[["M4 step BIC"]]   # à changer selon le tableau ci-dessus
formula(reg)
summary(reg)
confint(reg)


## =============================================================
## 5. Résidus
## =============================================================
par(mfrow = c(2, 2))
plot(reg)
par(mfrow = c(1, 1))

hist(residuals(reg), freq = FALSE, main = "Histogramme des résidus", xlab = "Résidus")
curve(dnorm(x, 0, sd(residuals(reg))), add = TRUE, col = 2, lwd = 2)

# Résidus en fonction de chaque variable du sol du modèle retenu
var_modele <- intersect(all.vars(formula(reg)), variables_sol)
if (length(var_modele) > 0) {
  par(mfrow = c(2, 2))
  for (v in var_modele) {
    plot(d[[v]], residuals(reg), pch = 20, xlab = v, ylab = "Résidus",
         main = paste("Résidus en fonction de", v))
    abline(h = 0, col = 2)
    lines(lowess(d[[v]], residuals(reg)), col = 4, lwd = 2)
  }
  par(mfrow = c(1, 1))
}

shapiro.test(residuals(reg))      # H0 : les résidus sont gaussiens


## =============================================================
## 6. Points influents
## =============================================================
p_param <- length(coef(reg))
h      <- hatvalues(reg)
cook   <- cooks.distance(reg)
r_stud <- rstudent(reg)

sum(h > 2 * p_param / n)                        # nombre de points leviers (seuil 2p/n)
sum(abs(r_stud) > qt(0.975, n - p_param - 1))   # résidus studentisés trop grands
top <- order(cook, decreasing = TRUE)[1:5]
data.frame(prelevement = ids[top], Y = y[top],
           levier = round(h[top], 3), res_stud = round(r_stud[top], 2), cook = round(cook[top], 3))
max(cook)                                       # à comparer à 1
