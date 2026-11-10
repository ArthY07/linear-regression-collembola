# Dans RStudio : Session > Set Working Directory > To Source File Location
# Distribution des 4 indices : lequel a une forme en cloche ?

data <- read.csv2("../donnees/data_finale2.csv", header = TRUE)
data <- data[!is.na(data$Argile), ]   # mêmes 412 prélèvements que les modèles

par(mfrow = c(2, 2))
for (y in c("A", "S", "H", "J")) {
  v <- data[[y]][!is.na(data[[y]])]
  hist(v, breaks = 20, freq = FALSE, col = "lightblue", border = "white",
       main = paste0("Distribution de ", y, " (n = ", length(v), ")"), xlab = y)
  curve(dnorm(x, mean(v), sd(v)), add = TRUE, col = 2, lwd = 2)   # loi normale de même moyenne et écart-type
}
par(mfrow = c(1, 1))

# Résumé numérique de chaque indice
resume <- t(sapply(c("A", "S", "H", "J"), function(y) {
  v <- data[[y]][!is.na(data[[y]])]
  c(n = length(v), min = min(v), mediane = median(v), moyenne = round(mean(v), 2),
    max = max(v), nb_zeros = sum(v == 0),
    shapiro_W = round(shapiro.test(v)$statistic, 3))
}))
resume
