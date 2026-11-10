data <- read.csv2("data_finale.csv")

indices <- c("A", "S", "H", "J")
ids     <- c("Site", "Echantillon")

Y <- data$A
X <- data[, !(colnames(data) %in% c(indices, ids))]

d_tout <- na.omit(data[, !(colnames(data) %in% c("S", "H", "J", ids))])
mod <- lm(A ~ ., data = d_tout)
summary(mod)
qr(model.matrix(mod))$rank ; ncol(model.matrix(mod))   # rang < nb de colonnes