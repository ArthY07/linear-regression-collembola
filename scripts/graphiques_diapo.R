# Dans RStudio : Session > Set Working Directory > To Source File Location
# Graphiques de la présentation : nombre de variables, résidus par variable, effets, VIF
library(leaps)
library(car)

data <- read.csv2("../donnees/data_finale2.csv", header = TRUE)
d <- data[!is.na(data$Argile), ]            # 412 prélèvements
d$land_use <- factor(d$land_use)
d$city     <- factor(d$city)

var_27 <- c("Argile", "Limon", "Sable", "Conduct", "pH.eau", "Carbonates", "Calcaire",
            "C..orga", "Mat_org", "Azote", "C.N", "P2O5", "CEC", "K2O", "MgO", "CaO", "Na2O",
            "Al", "Cd", "Co", "Cr", "Cu", "Fe", "Mn", "Ni", "Pb", "Zn")
var_H1 <- c("Argile", "Limon", "Conduct", "pH.eau", "Carbonates", "Azote", "C.N", "P2O5",
            "K2O", "MgO", "CaO", "Na2O", "Al", "Cd", "Cu", "Fe", "Mn", "Ni", "Pb", "Zn")
formule <- function(vars) as.formula(paste("S ~", paste(vars, collapse = " + ")))


## =============================================================
## 1. Combien de variables garder ? Cp de Mallows et BIC
## =============================================================
bs_H1 <- summary(regsubsets(formule(c(var_H1, "land_use", "city")), data = d,
                            nvmax = 15, really.big = TRUE))          # avec H1
bs_27 <- summary(regsubsets(formule(var_27), data = d,
                            nvmax = 27, method = "seqrep"))          # sans H1

trace_critere <- function(valeurs, titre, nom) {
  k <- which.min(valeurs)
  plot(seq_along(valeurs), valeurs, type = "b", pch = 20, main = titre,
       xlab = "Nombre de variables", ylab = nom)
  points(k, valeurs[k], col = 2, pch = 19, cex = 2)
  abline(v = k, col = 2, lty = 2)
}

png("../graphiques/choix_nb_variables.png", width = 1400, height = 1000, res = 110)
par(mfrow = c(2, 2))
trace_critere(bs_H1$cp,  "Avec H1 : Cp de Mallows", "Cp")
trace_critere(bs_H1$bic, "Avec H1 : BIC", "BIC")
trace_critere(bs_27$cp,  "Sans H1 (27 variables) : Cp de Mallows", "Cp")
trace_critere(bs_27$bic, "Sans H1 (27 variables) : BIC", "BIC")
dev.off()

c(H1_Cp = which.min(bs_H1$cp), H1_BIC = which.min(bs_H1$bic),
  sansH1_Cp = which.min(bs_27$cp), sansH1_BIC = which.min(bs_27$bic))
names(which(bs_H1$which[which.min(bs_H1$bic), ]))[-1]   # variables au minimum du BIC
names(which(bs_27$which[which.min(bs_27$bic), ]))[-1]


## =============================================================
## 2. Distribution des résidus par variable importante
## =============================================================
m_pH_usage    <- lm(S ~ pH.eau + land_use, data = d)
m_ville_usage <- lm(S ~ city + land_use, data = d)
m_sans_H1     <- lm(S ~ Carbonates + Calcaire + CEC, data = d)   # best subset sans H1

nuage_residus <- function(x, res, nom, titre) {
  plot(x, res, pch = 20, xlab = nom, ylab = "Résidus", main = titre)
  abline(h = 0, col = 2)
  lines(lowess(x, res), col = 4, lwd = 2)
}

png("../graphiques/residus_variables.png", width = 1500, height = 1000, res = 110)
par(mfrow = c(2, 3))
nuage_residus(d$pH.eau, residuals(m_pH_usage), "pH", "S ~ pH + usage : résidus selon le pH")
plot(d$land_use, residuals(m_pH_usage), xlab = "Usage du sol", ylab = "Résidus",
     main = "S ~ pH + usage : résidus par usage")
abline(h = 0, col = 2)
plot(d$city, residuals(m_ville_usage), xlab = "Ville", ylab = "Résidus",
     main = "S ~ ville + usage : résidus par ville")
abline(h = 0, col = 2)
nuage_residus(d$Carbonates, residuals(m_sans_H1), "Carbonates", "Sans H1 : résidus selon Carbonates")
nuage_residus(d$Calcaire, residuals(m_sans_H1), "Calcaire", "Sans H1 : résidus selon Calcaire")
nuage_residus(d$CEC, residuals(m_sans_H1), "CEC", "Sans H1 : résidus selon CEC")
dev.off()


## =============================================================
## 3. Les deux effets : pH et usage du sol
## =============================================================
png("../graphiques/effets_pH_usage.png", width = 900, height = 1000, res = 110)
par(mfrow = c(2, 1))
plot(d$pH.eau, d$S, pch = 20, xlab = "pH", ylab = "S (nombre d'espèces)",
     main = "S en fonction du pH")
abline(lm(S ~ pH.eau, data = d), col = 2, lwd = 2)
plot(d$land_use, d$S, xlab = "Usage du sol", ylab = "S (nombre d'espèces)",
     main = "S selon l'usage du sol")
dev.off()


## =============================================================
## 4. VIF avant et après H1
## =============================================================
vif_sans_H1 <- vif(lm(S ~ Na2O + CEC + Carbonates + Calcaire + Cd + Pb, data = d))
vif_avec_H1 <- vif(lm(formule(var_H1), data = d))

png("../graphiques/vif_barplots.png", width = 1400, height = 1000, res = 110)
par(mfrow = c(1, 2), mar = c(8, 4, 4, 1))
barplot(vif_sans_H1, las = 2, ylim = c(0, 12), col = ifelse(vif_sans_H1 > 10, "#A64B2A", "grey70"),
        main = "Sans H1 : sélection AIC (S.R)", ylab = "VIF")
abline(h = 10, col = 2, lty = 2, lwd = 2)
barplot(vif_avec_H1, las = 2, ylim = c(0, 12), col = "grey70",
        main = "Avec H1 : les 20 variables du sol", ylab = "VIF")
abline(h = 10, col = 2, lty = 2, lwd = 2)
dev.off()

round(vif_sans_H1, 2)
round(max(vif_avec_H1), 2)
