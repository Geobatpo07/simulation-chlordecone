# Test de fumée : les modèles ODE donnent des solutions finies et respectent
# l'équilibre démographique et la conservation de la masse.
# Usage (depuis la racine du dépôt) : Rscript tests/smoke.R

suppressMessages(library(deSolve))
source("app/R/models.R")
source("app/R/simulation.R")

check <- function(nom, df) {
  valeurs <- df[, setdiff(names(df), c("time", "time_years"))]
  stopifnot(all(is.finite(as.matrix(df))), all(valeurs > -1e-6))
  cat(sprintf("OK  %-12s (%d colonnes)\n", nom, ncol(df)))
}

n <- 3
params <- params_defaut(n, delta = 0.001, r0 = 0.01)
base <- resoudre_edo(modele_base, c(rep(1000, n), 50, 10, 49000, 1000), params, 20, "base")
check("base", base)
# Démographie à l'équilibre : H = Lambda_H / d_H = 50 000
stopifnot(abs(tail(base$H_S + base$H_I, 1) - 50000) < 50)

pc <- c(params, list(gamma_B = 2.5, k_trans = 0.01, mu_B = 0.005, B_star = 1, k_sigmoid = 5))
check("charge", resoudre_edo(modele_avec_charge, c(rep(1000, n), 50, 10, 49000, 1000, 0), pc, 20, "charge"))

pm <- c(params, list(beta_1 = 0.0005, beta_2 = 0.0007, beta_3 = 0.001,
                     rho_1 = 0.0025, rho_2 = 0.0035, rho_3 = 0.005))
check("markov", resoudre_edo(modele_markov, c(rep(1000, n), 50, 10, 40000, 8000, 1800, 200), pm, 20, "markov"))

pi_ <- c(params, list(t0_intervention = 5 * 365, tau_intervention = 2 * 365, reduction_r0 = 0.4,
                      reduction_beta = 0.4, augmentation_muF = 0.5))
check("intervention", resoudre_edo(modele_intervention, c(rep(1000, n), 50, 10, 49000, 1000), pi_, 20, "intervention"))

# Spatial : la masse (parcelles + bassins) est conservée quand il n'y a ni dégradation ni élimination
ps <- params_defaut(3, delta = 0, r0 = 0.01, mu_E = 0, kappa = 0,
                    n_bassins = 3, parcelles_to_bassin = c(1, 2, 3), w_transfer = 0.05)
sp <- resoudre_edo(modele_spatialise, c(rep(1000, 3), rep(0, 3), rep(0, 3), 49000, 1000), ps, 20,
                   "spatial", n_bassins = 3)
masse <- rowSums(sp[, c(paste0("C", 1:3), paste0("E", 1:3))])
stopifnot(abs(tail(masse, 1) - 3000) < 1e-3 * 3000)
cat("OK  spatialisé (masse conservée)\n")
