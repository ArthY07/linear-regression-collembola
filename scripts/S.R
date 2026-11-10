
############################################################
# Regression lineaire multiple - Richesse S
############################################################

# Packages
if (!require(car)) install.packages("car")
if (!require(corrplot)) install.packages("corrplot")
if (!require(leaps)) install.packages("leaps")

library(car)
library(corrplot)
library(leaps)


############################################################
# 1. Preparation des donnees
############################################################

data <- read.csv2("../donnees/data_finale2.csv")

indices <- c("A", "S", "H", "J")
ids <- c("Site", "Echantillon")
qualitatives <- c("city", "land_use", "site_group")

soil_vars <- setdiff(
  colnames(data),
  c(indices, ids, qualitatives)
)

# Variable a expliquer : richesse S
Y <- data$S

# Variables explicatives
X <- data[, soil_vars]

# Conversion des variables en numerique
for (v in soil_vars) {
  X[[v]] <- as.numeric(
    gsub(",", ".", as.character(X[[v]]), fixed = TRUE)
  )
}

# Tableau de travail avec les identifiants
d <- data.frame(
  Site = data$Site,
  Echantillon = data$Echantillon,
  S = Y,
  X
)

# Suppression des lignes incompletes
keep <- complete.cases(d)
d <- d[keep, ]

# Variables pour la regression
Y <- d$S
X <- d[, soil_vars]

# Identifiants conserves
identifiants <- d[, c("Site", "Echantillon")]

cat("Nombre d'observations :", nrow(d), "\n")
cat("Nombre de variables explicatives :", ncol(X), "\n")
cat("Nombre de sites :", length(unique(d$Site)), "\n")

# Verification du nombre d'echantillons par site
print(table(table(d$Site)))

summary(d)
str(d)

#distribution du S
hist(Y,
     breaks = 20,
     main = "Distribution de la richesse S",
     xlab = "Richesse S",
     ylab = "Fréquence",
     col = "lightblue",
     border = "white")
############################################################
# 2. Estimation du modele complet
############################################################

formule_complete <- reformulate(
  soil_vars,
  response = "S"
)

modele_complet <- lm(
  formule_complete,
  data = d
)

# Resultats
summary(modele_complet)

# Intervalles de confiance
confint(modele_complet)


############################################################
# 3. Adequation du modele
############################################################

predictions <- fitted(modele_complet)

# Valeurs observees et predites
plot(
  predictions, Y,
  main = "Valeurs observees et predites de S",
  xlab = "Valeurs predites",
  ylab = "Valeurs observees",
  pch = 19,
  col = "steelblue"
)

abline(0, 1, col = "red", lwd = 2)

lines(
  lowess(predictions, Y),
  col = "darkgreen",
  lwd = 2
)

# Coefficients de determination
cat("R2 :", summary(modele_complet)$r.squared, "\n")

cat(
  "R2 ajuste :",
  summary(modele_complet)$adj.r.squared,
  "\n"
)


############################################################
# 4. H2 et H3 : Analyse des residus
############################################################

res <- residuals(modele_complet)


############################################################
# H2 : Erreurs centrees, de meme variance et non correlees
############################################################

cat("\n-----------------------------\n")
cat("RESULTATS H2\n")
cat("-----------------------------\n")

# 1. Erreurs centrees
moyenne_res <- mean(res)

cat("Moyenne des residus :", moyenne_res, "\n")

test_centre <- abs(moyenne_res) < 1e-8

cat("Erreurs centrees :", test_centre, "\n")


# 2. Meme variance : examen graphique
plot(
  predictions, res,
  main = "Residus vs valeurs predites",
  xlab = "Valeurs predites de S",
  ylab = "Residus",
  pch = 19
)

abline(h = 0, col = "red")
lines(lowess(predictions, res), col = "blue")


# 3. Non-correlation : examen graphique
plot(
  res,
  type = "b",
  main = "Residus selon l'ordre des observations",
  xlab = "Observations",
  ylab = "Residus"
)

abline(h = 0, col = "red")


cat("Homogeneite de la variance : a verifier graphiquement\n")
cat("Absence de correlation : a verifier graphiquement\n")

H2 <- NA

cat(
  "\nHypothese 2 - Les erreurs sont centrees, de meme variance et non correlees :",
  H2,
  "\n"
)



############################################################
# H3 : Normalite des erreurs
############################################################

cat("\n-----------------------------\n")
cat("RESULTATS H3\n")
cat("-----------------------------\n")

# Test de Shapiro-Wilk
shapiro_resultat <- shapiro.test(res)

cat("Statistique W :", shapiro_resultat$statistic, "\n")
cat("p-value :", shapiro_resultat$p.value, "\n")

H3 <- shapiro_resultat$p.value >= 0.05

cat(
  "\nHypothese 3 - Les erreurs suivent une loi normale :",
  H3,
  "\n"
)


# Histogramme des residus
hist(
  res,
  main = "Distribution des residus de S",
  xlab = "Residus",
  col = "lightblue"
)


# QQ-plot
qqnorm(
  res,
  main = "QQ-plot des residus",
  pch = 19
)

qqline(res, col = "red")


# Residus en fonction de chaque variable explicative
par(mfrow = c(2, 3))

for (v in soil_vars) {
  
  plot(
    X[[v]], res,
    main = paste("Residus vs", v),
    xlab = v,
    ylab = "Residus",
    pch = 19,
    cex = 0.5
  )
  
  abline(h = 0, col = "red")
}

par(mfrow = c(1, 1))


############################################################
# 5. Leviers et distances de Cook
############################################################

# Residus studentises
res_studentises <- rstudent(modele_complet)

# Leviers
leviers <- hatvalues(modele_complet)

# Distances de Cook
cook <- cooks.distance(modele_complet)

n <- nrow(d)
p <- length(coef(modele_complet))

# Seuils
seuil_residus <- 3
seuil_leviers <- 2 * p / n
seuil_cook <- 4 / n


# Tableau des diagnostics
diag <- data.frame(
  Site = identifiants$Site,
  Echantillon = identifiants$Echantillon,
  S_observe = Y,
  S_predit = predictions,
  Residus = res,
  Residus_studentises = res_studentises,
  Leviers = leviers,
  Cook = cook
)

diag$Residus_atypiques <-
  abs(res_studentises) > seuil_residus

diag$Leviers_eleves <-
  leviers > seuil_leviers

diag$Cook_eleve <-
  cook > seuil_cook

diag$A_examiner <-
  diag$Residus_atypiques |
  diag$Leviers_eleves |
  diag$Cook_eleve


# Observations a examiner
points_atypiques <- diag[diag$A_examiner, ]

print(points_atypiques)


# Graphique des leviers
plot(
  leviers,
  type = "h",
  main = "Leviers",
  xlab = "Observations",
  ylab = "Leviers"
)

abline(h = seuil_leviers, col = "red")


# Graphique des distances de Cook
plot(
  cook,
  type = "h",
  main = "Distances de Cook",
  xlab = "Observations",
  ylab = "Distance de Cook"
)

abline(h = seuil_cook, col = "red")


############################################################
# 6. Selection des variables
############################################################

# Recherche par remplacement successif
selection <- regsubsets(
  formule_complete,
  data = d,
  nvmax = ncol(X),
  method = "seqrep"
)

resume_selection <- summary(selection)


# Criteres de selection
table_selection <- data.frame(
  Nombre_variables = 1:ncol(X),
  Cp = resume_selection$cp,
  R2_ajuste = resume_selection$adjr2,
  BIC = resume_selection$bic
)

print(table_selection)


# Graphique du Cp
plot(
  table_selection$Nombre_variables,
  table_selection$Cp,
  type = "b",
  main = "Cp de Mallows",
  xlab = "Nombre de variables",
  ylab = "Cp"
)


# Graphique du R2 ajuste
plot(
  table_selection$Nombre_variables,
  table_selection$R2_ajuste,
  type = "b",
  main = "R2 ajuste",
  xlab = "Nombre de variables",
  ylab = "R2 ajuste"
)


# Graphique du BIC
plot(
  table_selection$Nombre_variables,
  table_selection$BIC,
  type = "b",
  main = "BIC",
  xlab = "Nombre de variables",
  ylab = "BIC"
)


# Meilleur modele selon le BIC
meilleur_BIC <- which.min(table_selection$BIC)

coef_best <- coef(selection, id = meilleur_BIC)

variables_best <- setdiff(
  names(coef_best),
  "(Intercept)"
)

cat("\nVariables retenues par Best Subset :\n")
print(variables_best)


############################################################
# 7. Selection stepwise AIC et BIC
############################################################

# Modele nul
modele_nul <- lm(S ~ 1, data = d)

# Etendue de la recherche
borne <- list(
  lower = formula(modele_nul),
  upper = formula(modele_complet)
)


# Selection AIC
modele_AIC <- step(
  modele_nul,
  scope = borne,
  direction = "both",
  k = 2,
  trace = 0
)


# Selection BIC
modele_BIC <- step(
  modele_nul,
  scope = borne,
  direction = "both",
  k = log(n),
  trace = 0
)


# Resultats
cat("\nModele AIC :\n")
summary(modele_AIC)

cat("\nModele BIC :\n")
summary(modele_BIC)


############################################################
# 8. Comparaison des modeles
############################################################

modele_best <- lm(
  reformulate(variables_best, response = "S"),
  data = d
)


comparaison <- data.frame(
  
  Modele = c(
    "Modele complet",
    "Best Subset",
    "Stepwise AIC",
    "Stepwise BIC"
  ),
  
  R2 = c(
    summary(modele_complet)$r.squared,
    summary(modele_best)$r.squared,
    summary(modele_AIC)$r.squared,
    summary(modele_BIC)$r.squared
  ),
  
  R2_ajuste = c(
    summary(modele_complet)$adj.r.squared,
    summary(modele_best)$adj.r.squared,
    summary(modele_AIC)$adj.r.squared,
    summary(modele_BIC)$adj.r.squared
  ),
  
  AIC = c(
    AIC(modele_complet),
    AIC(modele_best),
    AIC(modele_AIC),
    AIC(modele_BIC)
  ),
  
  BIC = c(
    BIC(modele_complet),
    BIC(modele_best),
    BIC(modele_AIC),
    BIC(modele_BIC)
  )
)

print(comparaison)


############################################################
# 9. Choix du modele final
############################################################

modeles <- list(
  Complet = modele_complet,
  Best_Subset = modele_best,
  Stepwise_AIC = modele_AIC,
  Stepwise_BIC = modele_BIC
)

bic_modeles <- sapply(modeles, BIC)

nom_final <- names(which.min(bic_modeles))

modele_final <- modeles[[nom_final]]

cat("\nModele final retenu :", nom_final, "\n")

summary(modele_final)

confint(modele_final)


############################################################
# 10. Diagnostics du modele final
############################################################

res_final <- residuals(modele_final)

pred_final <- fitted(modele_final)


# Test de Shapiro-Wilk
shapiro_final <- shapiro.test(res_final)

cat("\nShapiro-Wilk du modele final :\n")
print(shapiro_final)


# Graphiques de diagnostic
par(mfrow = c(2, 2))

plot(modele_final)

par(mfrow = c(1, 1))


# Tableau des diagnostics
diag_final <- data.frame(
  Site = identifiants$Site,
  Echantillon = identifiants$Echantillon,
  S_observe = Y,
  S_predit = pred_final,
  Residus = res_final,
  Residus_studentises = rstudent(modele_final),
  Leviers = hatvalues(modele_final),
  Cook = cooks.distance(modele_final)
)

print(diag_final)


############################################################
# 11. Comparaison avec log(1+S)
############################################################

d_log <- d

d_log$logS <- log1p(d_log$S)


# Modele avec variable transformee
modele_log <- lm(
  reformulate(soil_vars, response = "logS"),
  data = d_log
)


# Resultats
summary(modele_log)


# Test de Shapiro-Wilk
shapiro_log <- shapiro.test(residuals(modele_log))

cat("\nShapiro-Wilk du modele log(1+S) :\n")
print(shapiro_log)


# Graphiques de diagnostic
par(mfrow = c(2, 2))

plot(modele_log)

par(mfrow = c(1, 1))


# Comparaison des tests de normalite
comparaison_normalite <- data.frame(
  Modele = c("S", "log1p(S)"),
  
  W = c(
    shapiro_final$statistic,
    shapiro_log$statistic
  ),
  
  p_value = c(
    shapiro_final$p.value,
    shapiro_log$p.value
  )
)

print(comparaison_normalite)


############################################################
# Fin de l'analyse
############################################################

cat("\nAnalyse terminee\n")
