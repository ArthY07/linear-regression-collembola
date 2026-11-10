# 1. Installer et charger le package arm (si ce n'est pas déjà fait)
 install.packages("arm")
library(arm)

# 2. Ajuster le modèle linéaire bayésien standard
set.seed(123)
modele_bayes_lin <- bayesglm(
  S ~ ., 
  data = data_clean[, c("S", X_vars)], 
  family = gaussian()
)

# 3. Afficher le résumé des résultats
print("--- RESUME DE LA REGRESSION BAYESIENNE CLASSIQUE ---")
summary(modele_bayes_lin)

# 4. Calculer le R² sur l'échantillon
y_pred <- predict(modele_bayes_lin, newdata = data_clean)

SCT <- sum((data_clean$S - mean(data_clean$S))^2)
SCR <- sum((data_clean$S - y_pred)^2)
r2_bayes_lin <- 1 - (SCR / SCT)

cat("R² de la Régression Linéaire Bayésienne classique :", round(r2_bayes_lin, 4), "\n")