# Test de fumée : app.R se charge et les modèles ODE donnent des solutions finies.
# Usage (depuis la racine du dépôt) : Rscript tests/smoke.R

suppressMessages(library(deSolve))

exprs <- parse("app/app.R", encoding = "UTF-8")

# Évalue uniquement les fonctions modele_*, sans lancer l'application
for (e in exprs) {
  if (is.call(e) && identical(e[[1]], as.name("<-")) && grepl("^modele_", as.character(e[[2]]))) eval(e)
}
stopifnot(exists("modele_base"), exists("modele_avec_charge"), exists("modele_spatialise"),
          exists("modele_markov"), exists("modele_intervention"))

params <- list(
  n_parcelles = 3, delta = rep(0.001, 3), r0 = rep(0.01, 3), alpha = 0.8, R0_sat = 50,
  R_moy = 6, A_saison = 0.5, T_periode = 365, mu_E = 0.05, kappa = 0.03, mu_F = 0.02,
  Lambda_H = 50000 / (70 * 365), d_H = 1 / (70 * 365), rho = 0.005, beta = 0.001, F_max = 100
)
times <- seq(0, 20 * 365, by = 1)
check <- function(nom, sol) {
  stopifnot(is.finite(sum(sol)), all(sol[, -1] > -1e-6))
  cat(sprintf("OK  %-12s (%d états)\n", nom, ncol(sol) - 1))
}

sol <- ode(c(rep(1000, 3), 50, 10, 49000, 1000), times, modele_base, params)
check("base", sol)
# Démographie à l'équilibre : H = Lambda_H / d_H = 50 000
stopifnot(abs(sol[nrow(sol), 7] + sol[nrow(sol), 8] - 50000) < 50)

pc <- c(params, list(gamma_B = 2.5, k_trans = 0.01, mu_B = 0.005, B_star = 1, k_sigmoid = 5))
check("charge", ode(c(rep(1000, 3), 50, 10, 49000, 1000, 0), times, modele_avec_charge, pc))

pm <- c(params, list(beta_1 = 0.0005, beta_2 = 0.0007, beta_3 = 0.001))
check("markov", ode(c(rep(1000, 3), 50, 10, 40000, 8000, 1800, 200), times, modele_markov, pm))

pi_ <- c(params, list(t0_intervention = 5 * 365, tau_intervention = 2 * 365, reduction_r0 = 0.4,
                      reduction_beta = 0.4, augmentation_muF = 0.5))
check("intervention", ode(c(rep(1000, 3), 50, 10, 49000, 1000), times, modele_intervention, pi_))

# Spatial : la masse du compartiment E doit être conservée lors des transferts inter-bassins
ps <- c(params, list(n_bassins = 3, parcelles_to_bassin = c(1, 2, 3), w_transfer = 0.05))
ps$mu_E <- 0; ps$kappa <- 0; ps$delta <- rep(0, 3)
sol_s <- ode(c(rep(1000, 3), rep(0, 3), rep(0, 3), 49000, 1000), times, modele_spatialise, ps)
masse <- rowSums(sol_s[, 2:7])  # C1..C3 + E1..E3
stopifnot(abs(masse[nrow(sol_s)] - 3000) < 1e-3 * 3000)
cat("OK  spatialisé (masse conservée)\n")
