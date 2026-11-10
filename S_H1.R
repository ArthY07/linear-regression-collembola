# =====================================================================
# Richesse S : pipeline complete (variables H1 + ville + type d'endroit)
#
# Rapport associe : RAPPORT_S.md
#
# Etapes :
#   0. Donnees et decoupage pour la validation croisee
#   1. Choix de l'indice a predire (A, S, H, J)
#   2. Modele complet pour S
#   3. Hypotheses H2 et H3 sur le modele complet
#   4. Selection de modeles (stepwise, best subset, Lasso, Ridge, Elastic Net)
#   5. Comparaison avec les variantes de l'equipe
#   6. Modele final et H2 / H3
# =====================================================================

# Dans RStudio : Session > Set Working Directory > To Source File Location
library(car)       # ncvTest
library(leaps)     # regsubsets (best subset)
library(glmnet)    # Lasso, Ridge, Elastic Net  -> install.packages("glmnet")


# ---------------------------------------------------------------------
# 0. Donnees
# ---------------------------------------------------------------------
data <- read.csv2("data_finale2.csv")

# 20 variables du sol gardees apres H1 (voir hypothese_H1.R)
var_H1 <- c("Argile","Limon","Conduct","pH.eau","Carbonates","Azote","C.N",
            "P2O5","K2O","MgO","CaO","Na2O","Al","Cd","Cu","Fe","Mn","Ni","Pb","Zn")

# 27 variables du sol (sans tri H1), pour comparaison
var_27 <- c("Argile","Limon","Sable","Conduct","pH.eau","Carbonates","Calcaire",
            "C..orga","Mat_org","Azote","C.N","P2O5","CEC","K2O","MgO","CaO","Na2O",
            "Al","Cd","Co","Cr","Cu","Fe","Mn","Ni","Pb","Zn")

# Variables qualitatives (transformees automatiquement en indicatrices par lm)
var_quali <- c("land_use", "city")

data$land_use <- factor(data$land_use)
data$city     <- factor(data$city)

# Validation croisee "par site" : 10 blocs de sites, graine commune 2026.
# On retire un site entier (ses 3 pots) pour ne pas tricher :
# les 3 pots d'un site ont exactement le meme sol.
set.seed(2026)
tous_sites <- sort(unique(data$Site))
bloc_site  <- setNames(sample(rep(1:10, length.out = length(tous_sites))), tous_sites)

r2 <- function(y, pred) 1 - sum((y - pred)^2) / sum((y - mean(y))^2)

# R2 sur sites nouveaux pour un modele lm
r2_sites_nouveaux <- function(formule, d, y) {
  bloc <- bloc_site[d$Site]
  pred <- rep(NA, nrow(d))
  for (k in 1:10) {
    m <- lm(formule, data = d[bloc != k, ])
    pred[bloc == k] <- predict(m, d[bloc == k, ])
  }
  r2(d[[y]], pred)
}

# PRESS : erreur de prediction en retirant chaque pot tour a tour
press <- function(m) sum((residuals(m) / (1 - hatvalues(m)))^2)

# Stepwise "both" a partir du modele nul
stepwise <- function(formule, d, y, k) {
  nul <- lm(as.formula(paste(y, "~ 1")), data = d)
  step(nul, scope = formule, direction = "both", k = k, trace = 0)
}

formule_de <- function(y, vars) as.formula(paste(y, "~", paste(vars, collapse = " + ")))


# ---------------------------------------------------------------------
# 1. Choix de l'indice a predire
# ---------------------------------------------------------------------
choix_Y <- data.frame()
for (y in c("A", "S", "H", "J")) {
  d <- na.omit(data[, c("Site", y, var_H1, var_quali)])
  f <- formule_de(y, c(var_H1, var_quali))
  complet <- lm(f, data = d)
  st      <- stepwise(f, d, y, k = 2)
  choix_Y <- rbind(choix_Y, data.frame(
    Y = y, n = nrow(d),
    R2aj_complet       = round(summary(complet)$adj.r.squared, 3),
    R2aj_stepAIC       = round(summary(st)$adj.r.squared, 3),
    R2_sites_nouveaux  = round(r2_sites_nouveaux(formula(st), d, y), 3)))
}
print(choix_Y, row.names = FALSE)
# -> on garde S


# ---------------------------------------------------------------------
# 2. Modele complet pour S
# ---------------------------------------------------------------------
d <- na.omit(data[, c("Site", "S", var_27, var_quali)])
n <- nrow(d)
cat("Pots :", n, " Sites :", length(unique(d$Site)), "\n")

f_complet <- formule_de("S", c(var_H1, var_quali))
complet   <- lm(f_complet, data = d)
summary(complet)


# ---------------------------------------------------------------------
# 3. H2 et H3 sur le modele complet
# ---------------------------------------------------------------------
par(mfrow = c(2, 2)); plot(complet); par(mfrow = c(1, 1))

hist(residuals(complet), breaks = 30, main = "Residus du modele complet", xlab = "Residus")

cat("H2 - variance constante (ncvTest) p =", signif(ncvTest(complet)$p, 2), "\n")
cat("H3 - normalite (Shapiro)          p =", signif(shapiro.test(residuals(complet))$p.value, 2), "\n")


# ---------------------------------------------------------------------
# 4. Selection de modeles
# ---------------------------------------------------------------------
modeles <- list(
  "Complet"      = complet,
  "Forward AIC"  = step(lm(S ~ 1, d), scope = f_complet, direction = "forward", trace = 0),
  "Backward AIC" = step(complet, direction = "backward", trace = 0),
  "Both AIC"     = stepwise(f_complet, d, "S", k = 2),
  "Both BIC"     = stepwise(f_complet, d, "S", k = log(n)))

resume_lm <- function(nom, m) {
  data.frame(modele = nom,
             nb_coef = length(coef(m)) - 1,
             R2   = round(summary(m)$r.squared, 3),
             R2aj = round(summary(m)$adj.r.squared, 3),
             AIC  = round(AIC(m), 1),
             BIC  = round(BIC(m), 1),
             PRESS = round(press(m)),
             R2_sites_nouveaux = round(r2_sites_nouveaux(formula(m), d, "S"), 3),
             variables = paste(attr(terms(m), "term.labels"), collapse = " "))
}
selection <- do.call(rbind, lapply(names(modeles), function(nom) resume_lm(nom, modeles[[nom]])))
print(selection[, 1:8], row.names = FALSE)
print(selection[, c("modele", "variables")], row.names = FALSE)

# Best subset : meilleur modele pour chaque nombre de termes
bs  <- summary(regsubsets(f_complet, data = d, nvmax = 15, really.big = TRUE))
plot(bs$adjr2, type = "b", xlab = "Nombre de termes", ylab = "R2 ajuste", main = "Best subset - R2 ajuste")
plot(bs$cp,    type = "b", xlab = "Nombre de termes", ylab = "Cp",        main = "Best subset - Cp de Mallows")
plot(bs$bic,   type = "b", xlab = "Nombre de termes", ylab = "BIC",       main = "Best subset - BIC")
cat("Best subset : BIC min a", which.min(bs$bic), "termes (",
    paste(names(which(bs$which[which.min(bs$bic), ]))[-1], collapse = " "), ")",
    "; Cp min a", which.min(bs$cp), "; R2aj max a", which.max(bs$adjr2), "\n")

# Lasso (alpha = 1), Elastic Net (alpha = 0.5), Ridge (alpha = 0)
X <- model.matrix(as.formula(paste("~", paste(c(var_H1, var_quali), collapse = " + "))), d)[, -1]
bloc <- bloc_site[d$Site]
regularisation <- data.frame()
for (cfg in list(c("Lasso", 1), c("Elastic Net", 0.5), c("Ridge", 0))) {
  set.seed(2026)
  cv <- cv.glmnet(X, d$S, alpha = as.numeric(cfg[2]), foldid = bloc)
  b  <- as.matrix(coef(cv, s = "lambda.min"))[-1, 1]
  regularisation <- rbind(regularisation, data.frame(
    modele = cfg[1],
    nb_coef = sum(b != 0),
    R2 = round(r2(d$S, predict(cv, X, s = "lambda.min")), 3),
    R2_sites_nouveaux = round(1 - min(cv$cvm) / mean((d$S - mean(d$S))^2), 3),
    variables = paste(names(b)[b != 0], collapse = " ")))
}
print(regularisation, row.names = FALSE)


# ---------------------------------------------------------------------
# 5. Comparaison avec les variantes de l'equipe (stepwise AIC)
# ---------------------------------------------------------------------
variantes <- list(
  "27 quanti, sans H1, sans ville/usage" = var_27,
  "20 quanti H1, sans ville/usage"       = var_H1,
  "20 quanti H1 + ville + usage"         = c(var_H1, var_quali))
comparaison <- do.call(rbind, lapply(names(variantes), function(nom) {
  st <- stepwise(formule_de("S", variantes[[nom]]), d, "S", k = 2)
  resume_lm(nom, st)
}))
print(comparaison[, c("modele", "R2aj", "R2_sites_nouveaux", "variables")], row.names = FALSE)


# ---------------------------------------------------------------------
# 6. Modele final : S ~ city + land_use
# ---------------------------------------------------------------------
final <- modeles[["Both AIC"]]
summary(final)
confint(final)

par(mfrow = c(2, 2)); plot(final); par(mfrow = c(1, 1))
cat("Final - H2 (ncvTest) p =", signif(ncvTest(final)$p, 2),
    " H3 (Shapiro) p =", signif(shapiro.test(residuals(final))$p.value, 2), "\n")
