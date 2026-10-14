# Construction des paramètres, résolution et post-traitement (sans dépendance à Shiny).
# Les fonctions de R/models.R sont chargées avant celles-ci (ordre alphabétique de Shiny).

D_H <- 1 / (70 * 365)  # sortie naturelle de la population (espérance de vie de 70 ans)

# Paramètres communs à tous les modèles. `...` écrase ou ajoute des paramètres.
# Λ_H = H0 · d_H : la population reste à son équilibre démographique (preprint §6.4.1).
params_defaut <- function(n_parcelles, delta, r0, H0 = 50000, ...) {
  base <- list(
    n_parcelles = n_parcelles,
    delta = rep(delta, n_parcelles),
    r0 = rep(r0, n_parcelles),
    alpha = 0.8,
    R0_sat = 50,
    R_moy = 6,
    A_saison = 0.5,
    T_periode = 365,
    mu_E = 0.05,
    kappa = 0.03,
    mu_F = 0.02,
    Lambda_H = H0 * D_H,
    d_H = D_H,
    rho = 0.005,
    beta = 0.001,
    F_max = 100
  )
  modifyList(base, list(...))
}

# Noms des colonnes de la solution, selon le modèle. Évite tout indexage par position.
noms_colonnes <- function(modele = c("base", "charge", "spatial", "markov", "intervention"),
                          n_parcelles, n_bassins = NULL) {
  modele <- match.arg(modele)
  C <- paste0("C", seq_len(n_parcelles))
  noms <- switch(
    modele,
    base = , intervention = c(C, "E", "F", "H_S", "H_I"),
    charge = c(C, "E", "F", "H_S", "H_I", "B"),
    markov = c(C, "E", "F", "H1", "H2", "H3", "H4"),
    spatial = c(C, paste0("E", seq_len(n_bassins)), paste0("F", seq_len(n_bassins)), "H_S", "H_I")
  )
  c("time", noms)
}

# Résout le système sur `annees` années (pas d'un jour) et renvoie un data.frame nommé.
resoudre_edo <- function(func, y0, params, annees, modele, n_bassins = NULL) {
  times <- seq(0, annees * 365, by = 1)
  solution <- deSolve::ode(y = y0, times = times, func = func, parms = params)
  df <- as.data.frame(solution)
  colnames(df) <- noms_colonnes(modele, params$n_parcelles, n_bassins)
  df$time_years <- df$time / 365
  df
}

# Ajoute H_total et la prévalence (%) :
# - modèles à deux classes : prevalence = H_I / (H_S + H_I)
# - modèle de Markov : prevalence_elevee = H4 / H, prevalence_moderee = (H3 + H4) / H
ajouter_prevalence <- function(df) {
  if (all(c("H_S", "H_I") %in% names(df))) {
    df$H_total <- df$H_S + df$H_I
    df$prevalence <- df$H_I / df$H_total * 100
  } else {
    df$H_total <- df$H1 + df$H2 + df$H3 + df$H4
    df$prevalence_elevee <- df$H4 / df$H_total * 100
    df$prevalence_moderee <- (df$H3 + df$H4) / df$H_total * 100
  }
  df
}

# Simule l'intervention et un scénario de référence sans intervention (mêmes paramètres).
simuler_intervention <- function(params, y0, annees) {
  params_ref <- params
  params_ref$reduction_r0 <- 0
  params_ref$reduction_beta <- 0
  params_ref$augmentation_muF <- 0

  df <- resoudre_edo(modele_intervention, y0, params, annees, "intervention")
  ref <- resoudre_edo(modele_intervention, y0, params_ref, annees, "intervention")

  df <- ajouter_prevalence(df)
  df$E_ref <- ref$E
  df$F_ref <- ref$F
  df$H_I_ref <- ref$H_I
  df$prevalence_ref <- ref$H_I / (ref$H_S + ref$H_I) * 100
  df$intervention <- progression_intervention(df$time, params$t0_intervention, params$tau_intervention)
  df
}

# Prévalence des trois modèles sur un scénario commun (3 parcelles).
# Base et charge B(t) : H_I / H ; Markov : (H3 + H4) / H.
simuler_comparaison <- function(annees, C0, H0, delta, r0, gamma_B) {
  n <- 3
  params <- params_defaut(n, delta, r0, H0)
  C_init <- rep(C0, n)

  base <- resoudre_edo(modele_base, c(C_init, 50, 10, H0 * 0.98, H0 * 0.02),
                       params, annees, "base")
  charge <- resoudre_edo(
    modele_avec_charge, c(C_init, 50, 10, H0 * 0.98, H0 * 0.02, 0),
    c(params, list(gamma_B = gamma_B, k_trans = 0.01, mu_B = 0.005, B_star = 1, k_sigmoid = 5)),
    annees, "charge"
  )
  markov <- resoudre_edo(
    modele_markov, c(C_init, 50, 10, H0 * 0.8, H0 * 0.16, H0 * 0.03, H0 * 0.01),
    c(params, list(beta_1 = 0.0005, beta_2 = 0.0007, beta_3 = 0.001,
                   rho_1 = 0.0025, rho_2 = 0.0035, rho_3 = 0.005)),
    annees, "markov"
  )

  data.frame(
    time_years = base$time_years,
    Base = ajouter_prevalence(base)$prevalence,
    Charge = ajouter_prevalence(charge)$prevalence,
    Markov = ajouter_prevalence(markov)$prevalence_moderee
  )
}
