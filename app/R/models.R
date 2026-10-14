# Modèles ODE du chlordécone (sans dépendance à Shiny).
# Chaque modèle suit la signature de deSolve::ode : f(t, y, params).

# -----------------------------------------------------------------------------
# Fonctions communes
# -----------------------------------------------------------------------------

# Fonction d'amplification pluviométrique g(R(t)) (preprint §4.2), avec
# R(t) = R_moy * (1 + A * sin(2 * pi * t / T))
amplification_pluie <- function(t, R_moy, A_saison, T_periode, alpha, R0_sat) {
  R_t <- R_moy * (1 + A_saison * sin(2 * pi * t / T_periode))
  1 + alpha * R_t / (R0_sat + R_t)
}

# Fonction d'exposition λ(F) linéaire par morceaux (preprint §4.3)
taux_exposition <- function(F, beta, F_max) {
  beta * pmin(F, F_max)
}

# -----------------------------------------------------------------------------
# 1. MODÈLE DE BASE
# -----------------------------------------------------------------------------

modele_base <- function(t, y, params) {
  with(as.list(c(y, params)), {
    C <- y[1:n_parcelles]
    E <- y[n_parcelles + 1]
    F_res <- y[n_parcelles + 2]
    H_S <- y[n_parcelles + 3]
    H_I <- y[n_parcelles + 4]

    g_R <- amplification_pluie(t, R_moy, A_saison, T_periode, alpha, R0_sat)
    lambda_F <- taux_exposition(F_res, beta, F_max)

    dC <- -delta * C - r0 * g_R * C
    dE <- sum(r0 * g_R * C) - mu_E * E - kappa * E
    dF <- kappa * E - mu_F * F_res
    dH_S <- Lambda_H - lambda_F * H_S - d_H * H_S + rho * H_I
    dH_I <- lambda_F * H_S - d_H * H_I - rho * H_I

    list(c(dC, dE, dF, dH_S, dH_I))
  })
}

# -----------------------------------------------------------------------------
# 2. MODÈLE AVEC VARIABLE DE CHARGE CORPORELLE B(t)
# -----------------------------------------------------------------------------

modele_avec_charge <- function(t, y, params) {
  with(as.list(c(y, params)), {
    C <- y[1:n_parcelles]
    E <- y[n_parcelles + 1]
    F_res <- y[n_parcelles + 2]
    H_S <- y[n_parcelles + 3]
    H_I <- y[n_parcelles + 4]
    B <- y[n_parcelles + 5]  # Charge corporelle moyenne

    g_R <- amplification_pluie(t, R_moy, A_saison, T_periode, alpha, R0_sat)

    # Dynamique de la charge corporelle (µg/L), forme du preprint (§9.1) :
    # dB/dt = γ·F/H − µ_B·B, avec F/H la disponibilité per capita
    dB <- gamma_B * F_res / (H_S + H_I) - mu_B * B

    # Transition probabiliste basée sur B
    p_I <- 1 / (1 + exp(-k_sigmoid * (B - B_star)))

    lambda_F <- taux_exposition(F_res, beta, F_max)

    dC <- -delta * C - r0 * g_R * C
    dE <- sum(r0 * g_R * C) - mu_E * E - kappa * E
    dF <- kappa * E - mu_F * F_res

    # Transitions basées sur la charge corporelle
    flux_S_to_I <- H_S * p_I * k_trans  # Transition graduelle
    flux_I_to_S <- H_I * (1 - p_I) * k_trans

    dH_S <- Lambda_H - lambda_F * H_S - d_H * H_S + flux_I_to_S - flux_S_to_I
    dH_I <- lambda_F * H_S - d_H * H_I + flux_S_to_I - flux_I_to_S

    list(c(dC, dE, dF, dH_S, dH_I, dB))
  })
}

# -----------------------------------------------------------------------------
# 3. MODÈLE SPATIALISÉ (plusieurs bassins versants)
# -----------------------------------------------------------------------------

modele_spatialise <- function(t, y, params) {
  with(as.list(c(y, params)), {
    # n_parcelles parcelles, n_bassins bassins versants
    C <- y[1:n_parcelles]
    E <- y[(n_parcelles + 1):(n_parcelles + n_bassins)]
    F_res <- y[(n_parcelles + n_bassins + 1):(n_parcelles + 2 * n_bassins)]
    H_S <- y[n_parcelles + 2 * n_bassins + 1]
    H_I <- y[n_parcelles + 2 * n_bassins + 2]

    g_R <- amplification_pluie(t, R_moy, A_saison, T_periode, alpha, R0_sat)

    dC <- -delta * C - r0 * g_R * C

    dE <- numeric(n_bassins)
    for (j in 1:n_bassins) {
      # Flux depuis les parcelles du bassin j
      parcelles_bassin <- which(parcelles_to_bassin == j)
      flux_entrant <- sum(r0[parcelles_bassin] * g_R * C[parcelles_bassin])

      # Apports et pertes locales (accumulés, sans écraser les transferts)
      dE[j] <- dE[j] + flux_entrant - mu_E * E[j] - kappa * E[j]

      # Transfert vers bassin aval (simplifié: bassin j -> bassin j+1)
      if (j < n_bassins) {
        dE[j] <- dE[j] - w_transfer * E[j]
        dE[j + 1] <- dE[j + 1] + w_transfer * E[j]
      }
    }

    # Ressources alimentaires (une par bassin)
    dF <- kappa * E - mu_F * F_res

    # Exposition humaine agrégée sur tous les bassins
    lambda_F <- taux_exposition(sum(F_res), beta, F_max)

    dH_S <- Lambda_H - lambda_F * H_S - d_H * H_S + rho * H_I
    dH_I <- lambda_F * H_S - d_H * H_I - rho * H_I

    list(c(dC, dE, dF, dH_S, dH_I))
  })
}

# -----------------------------------------------------------------------------
# 4. MODÈLE AVEC CHAÎNE DE MARKOV (4 classes de charge)
# -----------------------------------------------------------------------------

modele_markov <- function(t, y, params) {
  with(as.list(c(y, params)), {
    C <- y[1:n_parcelles]
    E <- y[n_parcelles + 1]
    F_res <- y[n_parcelles + 2]
    H1 <- y[n_parcelles + 3]  # Classe 1: charge nulle
    H2 <- y[n_parcelles + 4]  # Classe 2: charge faible
    H3 <- y[n_parcelles + 5]  # Classe 3: charge modérée
    H4 <- y[n_parcelles + 6]  # Classe 4: charge élevée

    g_R <- amplification_pluie(t, R_moy, A_saison, T_periode, alpha, R0_sat)

    dC <- -delta * C - r0 * g_R * C
    dE <- sum(r0 * g_R * C) - mu_E * E - kappa * E
    dF <- kappa * E - mu_F * F_res

    # Taux de progression dépendant de F
    q12 <- beta_1 * F_res  # Classe 1 -> 2
    q23 <- beta_2 * F_res  # Classe 2 -> 3
    q34 <- beta_3 * F_res  # Classe 3 -> 4

    # Taux de régression ρ_i : paramètres libres (rho_1, rho_2, rho_3), cf. preprint §10.3.2
    dH1 <- Lambda_H - q12 * H1 - d_H * H1 + rho_1 * H2
    dH2 <- q12 * H1 - (q23 + rho_1) * H2 - d_H * H2 + rho_2 * H3
    dH3 <- q23 * H2 - (q34 + rho_2) * H3 - d_H * H3 + rho_3 * H4
    dH4 <- q34 * H3 - (rho_3 + d_H) * H4

    list(c(dC, dE, dF, dH1, dH2, dH3, dH4))
  })
}

# -----------------------------------------------------------------------------
# 5. MODÈLE AVEC INTERVENTION (réduction progressive des paramètres)
# -----------------------------------------------------------------------------

# Progression de l'intervention σ(t) (preprint §8.2.1), de 0 à 1
progression_intervention <- function(t, t0_intervention, tau_intervention) {
  0.5 * (1 + tanh((t - t0_intervention) / tau_intervention))
}

modele_intervention <- function(t, y, params) {
  with(as.list(c(y, params)), {
    phi_t <- progression_intervention(t, t0_intervention, tau_intervention)

    # Paramètres modifiés par l'intervention
    r0_eff <- r0 * (1 - reduction_r0 * phi_t)
    beta_eff <- beta * (1 - reduction_beta * phi_t)
    mu_F_eff <- mu_F * (1 + augmentation_muF * phi_t)  # renouvellement forcé de la ressource

    C <- y[1:n_parcelles]
    E <- y[n_parcelles + 1]
    F_res <- y[n_parcelles + 2]
    H_S <- y[n_parcelles + 3]
    H_I <- y[n_parcelles + 4]

    g_R <- amplification_pluie(t, R_moy, A_saison, T_periode, alpha, R0_sat)
    lambda_F <- taux_exposition(F_res, beta_eff, F_max)

    dC <- -delta * C - r0_eff * g_R * C
    dE <- sum(r0_eff * g_R * C) - mu_E * E - kappa * E
    dF <- kappa * E - mu_F_eff * F_res
    dH_S <- Lambda_H - lambda_F * H_S - d_H * H_S + rho * H_I
    dH_I <- lambda_F * H_S - d_H * H_I - rho * H_I

    list(c(dC, dE, dF, dH_S, dH_I))
  })
}
