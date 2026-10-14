# Tests de la couche simulation (R/simulation.R) : noms de colonnes, prévalence,
# comparaison des modèles, scénario de référence de l'intervention.
# Usage (depuis la racine du dépôt) : Rscript tests/test_simulation.R

suppressMessages(library(deSolve))
source("app/R/models.R")
source("app/R/simulation.R")

ok <- function(nom) cat("OK ", nom, "\n")

# 1. Les noms de colonnes correspondent au nombre de variables de chaque modèle
n <- 3
etats <- c(
  base = n + 4, intervention = n + 4, charge = n + 5, markov = n + 6
)
for (m in names(etats)) stopifnot(length(noms_colonnes(m, n)) == etats[[m]] + 1)
stopifnot(length(noms_colonnes("spatial", 5, n_bassins = 3)) == 5 + 2 * 3 + 2 + 1)
ok("noms_colonnes")

# 2. ajouter_prevalence : calcul par nom de colonne (régression du bug d'indexation)
df <- data.frame(H_S = c(98, 50), H_I = c(2, 50))
p <- ajouter_prevalence(df)
stopifnot(all.equal(p$prevalence, c(2, 50)), all.equal(p$H_total, c(100, 100)))
dm <- data.frame(H1 = 80, H2 = 16, H3 = 3, H4 = 1)
pm <- ajouter_prevalence(dm)
stopifnot(all.equal(pm$prevalence_elevee, 1), all.equal(pm$prevalence_moderee, 4))
ok("ajouter_prevalence")

# 3. simuler_comparaison : prévalence initiale de chaque modèle
cmp <- simuler_comparaison(annees = 2, C0 = 1000, H0 = 50000, delta = 0.001, r0 = 0.01, gamma_B = 2.5)
stopifnot(identical(names(cmp), c("time_years", "Base", "Charge", "Markov")),
          nrow(cmp) == 2 * 365 + 1)
# À t = 0 : Base et Charge = H_I / H = 2 % ; Markov = (H3 + H4) / H = 4 %
stopifnot(abs(cmp$Base[1] - 2) < 1e-9, abs(cmp$Charge[1] - 2) < 1e-9, abs(cmp$Markov[1] - 4) < 1e-9)
stopifnot(all(cmp[, -1] >= 0), all(cmp[, -1] <= 100))
ok("simuler_comparaison (prévalences initiales 2 / 2 / 4 %)")

# 4. Comparaison identique à un calcul direct du modèle de base
params <- params_defaut(3, 0.001, 0.01, 50000)
direct <- resoudre_edo(modele_base, c(rep(1000, 3), 50, 10, 50000 * 0.98, 50000 * 0.02), params, 2, "base")
stopifnot(max(abs(cmp$Base - 100 * direct$H_I / (direct$H_S + direct$H_I))) < 1e-9)
ok("comparaison = calcul direct")

# 5. Intervention : sans réduction, le scénario avec intervention égale la référence
pi_ <- params_defaut(3, 0.001, 0.01, t0_intervention = 0, tau_intervention = 365,
                     reduction_r0 = 0, reduction_beta = 0, augmentation_muF = 0)
y0 <- c(rep(1000, 3), 50, 10, 40000, 10000)
neutre <- simuler_intervention(pi_, y0, 3)
stopifnot(max(abs(neutre$prevalence - neutre$prevalence_ref)) < 1e-9,
          max(abs(neutre$F - neutre$F_ref)) < 1e-9)

pi_$reduction_r0 <- 0.4
pi_$reduction_beta <- 0.4
actif <- simuler_intervention(pi_, y0, 3)
stopifnot(tail(actif$prevalence, 1) != tail(actif$prevalence_ref, 1),
          all(actif$intervention >= 0 & actif$intervention <= 1))
# La référence ne dépend pas des paramètres d'intervention
stopifnot(max(abs(actif$prevalence_ref - neutre$prevalence_ref)) < 1e-9)
ok("simuler_intervention")
