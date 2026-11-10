# =====================================================================
# Prediction de J (equitabilite de Pielou) par regression lineaire
#
# Ordre suivi (cours 8 et 9, TP2) :
#   1. Donnees et variables (H1 deja faite dans hypothese_H1.R)
#   2. Modele complet : tests de Student, test de Fisher, R2
#   3. Validation (H2, H3) : residus, QQ-plot, points influents
#   4. Choix de modele : stepwise AIC et BIC, comparaison
#   5. Modele final : interpretation
# =====================================================================

# Dans RStudio : Session > Set Working Directory > To Source File Location


# ---------------------------------------------------------------------
# 1. Donnees
# ---------------------------------------------------------------------
data <- read.csv2("../donnees/data_finale2.csv")

# Les 20 variables du sol gardees apres H1 (voir hypothese_H1.R)
variables_sol <- c("Argile","Limon","Conduct","pH.eau","Carbonates","Azote","C.N",
                   "P2O5","K2O","MgO","CaO","Na2O","Al","Cd","Cu","Fe","Mn","Ni","Pb","Zn")

# + le type d'endroit et la ville (variables qualitatives)
variables <- c(variables_sol, "land_use", "city")

# On garde les pots ou J existe (au moins 2 especes) et ou le sol est mesure
donnees <- na.omit(data[, c("J", variables)])
donnees$land_use <- factor(donnees$land_use)
donnees$city     <- factor(donnees$city)
cat("Nombre de pots utilises :", nrow(donnees), "\n")

# Distribution de J
hist(donnees$J, breaks = 30, main = "Distribution de J", xlab = "J")


# ---------------------------------------------------------------------
# 2. Modele complet
# ---------------------------------------------------------------------
modele_complet <- lm(J ~ ., data = donnees)
summary(modele_complet)
# A lire :
#  - Pr(>|t|)      : test de Student, la variable compte-t-elle ? (< 0.05)
#  - F-statistic   : test de Fisher, le modele sert-il a quelque chose ?
#  - R2 / R2 ajuste : part de J expliquee


# ---------------------------------------------------------------------
# 3. Validation du modele (H2 et H3)
# ---------------------------------------------------------------------
residus <- residuals(modele_complet)
predits <- fitted(modele_complet)

par(mfrow = c(2, 2))

# J observe vs J predit : les points doivent suivre la droite
plot(donnees$J, predits, pch = 20, xlab = "J observe", ylab = "J predit",
     main = "Observe vs predit")
abline(0, 1, col = 2)

# H2 : residus vs valeurs predites (aucune forme attendue)
plot(predits, residus, pch = 20, xlab = "Valeurs predites", ylab = "Residus",
     main = "Residus vs predits")
abline(h = 0, col = 2)
lines(lowess(predits, residus), col = 4, lwd = 2)

# H3 : normalite des residus
hist(residus, breaks = 30, main = "Histogramme des residus", xlab = "Residus")
qqnorm(residus, pch = 20, main = "QQ-plot des residus")
qqline(residus, col = 2)

par(mfrow = c(1, 1))

# Graphiques de diagnostic de R (dont distance de Cook)
par(mfrow = c(2, 2))
plot(modele_complet)
par(mfrow = c(1, 1))

# Points atypiques et influents
n <- nrow(donnees)
p <- length(coef(modele_complet)) - 1

rstud  <- rstudent(modele_complet)        # residus studentises
levier <- hatvalues(modele_complet)       # leviers h_ii
cook   <- cooks.distance(modele_complet)  # distance de Cook

cat("Residus studentises > seuil :", sum(abs(rstud) > qt(0.975, n - p - 2)), "\n")
cat("Leviers > 2(p+1)/n          :", sum(levier > 2 * (p + 1) / n), "\n")
cat("Distance de Cook > 1        :", sum(cook > 1), "\n")


# ---------------------------------------------------------------------
# 4. Choix de modele (selection de variables)
# ---------------------------------------------------------------------
modele_nul <- lm(J ~ 1, data = donnees)

# Stepwise "both" avec AIC (k = 2)
modele_aic <- step(modele_nul, scope = formula(modele_complet),
                   direction = "both", k = 2, trace = FALSE)

# Stepwise "both" avec BIC (k = log(n)), plus severe
modele_bic <- step(modele_nul, scope = formula(modele_complet),
                   direction = "both", k = log(n), trace = FALSE)

# PRESS : erreur de prediction quand chaque pot est retire tour a tour
press <- function(fit) sum((residuals(fit) / (1 - hatvalues(fit)))^2)

# Tableau de comparaison
resume_modele <- function(fit, nom) {
  s <- summary(fit)
  data.frame(modele = nom,
             nb_variables = length(coef(fit)) - 1,
             R2 = round(s$r.squared, 3),
             R2_ajuste = round(s$adj.r.squared, 3),
             AIC = round(AIC(fit), 1),
             BIC = round(BIC(fit), 1),
             PRESS = round(press(fit), 2))
}

comparaison <- rbind(resume_modele(modele_complet, "Complet"),
                     resume_modele(modele_aic,     "Stepwise AIC"),
                     resume_modele(modele_bic,     "Stepwise BIC"))
comparaison


# ---------------------------------------------------------------------
# 5. Modele final
# ---------------------------------------------------------------------
modele_final <- modele_aic      # a changer selon la comparaison
summary(modele_final)
confint(modele_final)           # intervalles de confiance a 95 %

# Re-verifier les residus du modele final
par(mfrow = c(2, 2))
plot(modele_final)
par(mfrow = c(1, 1))
