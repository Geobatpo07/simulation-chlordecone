# Analyse de sensibilité du modèle de base (sans dépendance à Shiny) :
# - locale (un paramètre à la fois, OAT) : effets d'un facteur 0,5 et 2, et élasticité ;
# - globale (indices de Sobol, estimateurs de Saltelli 2010 et de Jansen) avec intervalles bootstrap.
# Les fonctions `analyse_oat` et `indices_sobol` acceptent n'importe quelle fonction f(valeurs) -> vecteur nommé.

SORTIES_SENSIBILITE <- c(
  prevalence_max = "Prévalence maximale (%)",
  prevalence_5ans = "Prévalence à 5 ans (%)",
  F_pic = "Pic de la ressource F (kg)"
)

# Paramètres étudiés et valeurs de référence du scénario ("preprint" ou "persist")
parametres_sensibilite <- function(scenario = "preprint") {
  persist <- identical(scenario, "persist")
  data.frame(
    nom = c("delta", "r0", "alpha", "mu_E", "kappa", "mu_F", "beta", "rho", "F_max"),
    label = c("δ (dégradation du sol)", "r0 (ruissellement)", "α (amplification pluie)",
              "µ_E (élimination environnement)", "κ (transfert E→F)", "µ_F (renouvellement ressource)",
              "β (exposition)", "ρ (dépuration)", "F_max (saturation)"),
    ref = c(if (persist) 5e-5 else 1e-3, if (persist) 4e-5 else 1e-2, 0.8, 0.05, 0.03, 0.02, 0.001, 0.005, 100),
    stringsAsFactors = FALSE
  )
}

# Sorties d'intérêt du modèle de base pour un jeu de paramètres (vecteur nommé).
# Sorties tous les 5 jours : résultat quasi identique à un pas d'un jour, environ 5 fois plus rapide.
sorties_modele <- function(valeurs, annees = 20, prev0 = 0.2, n_parcelles = 3, H0 = 50000, C0 = 1000) {
  stopifnot(annees >= 5)
  params <- params_defaut(
    n_parcelles, delta = valeurs[["delta"]], r0 = valeurs[["r0"]], H0 = H0,
    alpha = valeurs[["alpha"]], mu_E = valeurs[["mu_E"]], kappa = valeurs[["kappa"]],
    mu_F = valeurs[["mu_F"]], beta = valeurs[["beta"]], rho = valeurs[["rho"]], F_max = valeurs[["F_max"]]
  )
  y0 <- c(rep(C0, n_parcelles), 50, 10, H0 * (1 - prev0), H0 * prev0)
  df <- resoudre_edo(modele_base, y0, params, annees, "base", pas_jours = 5)
  prevalence <- df$H_I / (df$H_S + df$H_I) * 100
  c(prevalence_max = max(prevalence),
    prevalence_5ans = prevalence[which.min(abs(df$time - 5 * 365))],
    F_pic = max(df$F))
}

# -----------------------------------------------------------------------------
# Analyse locale (OAT)
# -----------------------------------------------------------------------------

# Pour chaque paramètre : sortie avec le paramètre multiplié par chaque facteur de `facteurs`,
# et élasticité centrale (variation relative de la sortie / variation relative du paramètre, ±eps).
analyse_oat <- function(f, ref, facteurs = c(0.5, 2), eps = 0.1, progression = NULL) {
  y_ref <- f(ref)
  total <- length(ref) * 4
  fait <- 0
  avancer <- function() {
    fait <<- fait + 1
    if (!is.null(progression)) progression(fait, total)
  }
  evaluer <- function(nom, k) {
    v <- ref
    v[[nom]] <- v[[nom]] * k
    avancer()
    f(v)
  }

  lignes <- lapply(names(ref), function(nom) {
    y_bas <- evaluer(nom, facteurs[1])
    y_haut <- evaluer(nom, facteurs[2])
    y_moins <- evaluer(nom, 1 - eps)
    y_plus <- evaluer(nom, 1 + eps)
    data.frame(
      parametre = nom,
      sortie = names(y_ref),
      y_ref = unname(y_ref),
      y_bas = unname(y_bas),
      y_haut = unname(y_haut),
      elasticite = ifelse(abs(y_ref) > 0, unname((y_plus - y_moins) / y_ref / (2 * eps)), NA_real_),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, lignes)
}

# -----------------------------------------------------------------------------
# Analyse globale (Sobol)
# -----------------------------------------------------------------------------

# Indices de premier ordre S1 (Saltelli 2010) et totaux ST (Jansen), avec IC à 95 % par bootstrap.
# f : fonction(vecteur nommé) -> vecteur nommé ; bas/haut : bornes (vecteurs nommés) ;
# echelle_log : tirage uniforme sur le logarithme (adapté aux taux qui varient d'un facteur 2 vers le haut et le bas) ;
# applique : fonction(liste, f) -> liste (par défaut lapply ; peut être parallélisée) ;
# progression : fonction(fait, total) appelée par blocs.
indices_sobol <- function(f, bas, haut, N = 128, seed = 1, echelle_log = TRUE, B = 200,
                          applique = function(X, f) lapply(X, f), progression = NULL) {
  stopifnot(identical(names(bas), names(haut)), all(bas < haut))
  noms <- names(bas)
  k <- length(noms)
  set.seed(seed)

  tirer <- function() {
    u <- matrix(runif(N * k), N, k, dimnames = list(NULL, noms))
    if (echelle_log) {
      exp(sweep(u, 2, log(haut) - log(bas), `*`) + rep(log(bas), each = N))
    } else {
      sweep(u, 2, haut - bas, `*`) + rep(bas, each = N)
    }
  }
  A <- tirer()
  Bm <- tirer()

  lignes <- function(M) lapply(seq_len(nrow(M)), function(i) M[i, ])
  X <- c(lignes(A), lignes(Bm))
  for (i in seq_len(k)) {
    AB <- A
    AB[, i] <- Bm[, i]
    X <- c(X, lignes(AB))
  }

  # Évaluation par blocs pour suivre la progression
  total <- length(X)
  taille_bloc <- max(1, ceiling(total / 50))
  sorties <- vector("list", total)
  debut <- 1
  while (debut <= total) {
    fin <- min(total, debut + taille_bloc - 1)
    sorties[debut:fin] <- applique(X[debut:fin], f)
    if (!is.null(progression)) progression(fin, total)
    debut <- fin + 1
  }
  noms_sorties <- names(sorties[[1]])
  Y <- do.call(rbind, sorties)
  colnames(Y) <- noms_sorties

  yA <- Y[1:N, , drop = FALSE]
  yB <- Y[N + 1:N, , drop = FALSE]
  yAB <- lapply(seq_len(k), function(i) Y[(2 + i - 1) * N + 1:N, , drop = FALSE])

  # Estimateurs sur un échantillon d'indices `idx` (utile pour le bootstrap)
  estimer <- function(idx) {
    V <- apply(rbind(yA[idx, , drop = FALSE], yB[idx, , drop = FALSE]), 2, var)
    # Sorties centrées : l'estimateur S1 est instable quand la moyenne est grande devant l'écart-type
    mu <- colMeans(rbind(yA[idx, , drop = FALSE], yB[idx, , drop = FALSE]))
    centrer <- function(M) sweep(M, 2, mu)
    S1 <- ST <- matrix(NA_real_, k, length(noms_sorties), dimnames = list(noms, noms_sorties))
    for (i in seq_len(k)) {
      a <- centrer(yA[idx, , drop = FALSE]); b <- centrer(yB[idx, , drop = FALSE])
      ab <- centrer(yAB[[i]][idx, , drop = FALSE])
      S1[i, ] <- colMeans(b * (ab - a)) / V
      ST[i, ] <- colMeans((a - ab)^2) / (2 * V)
    }
    S1[, V <= 0] <- NA_real_
    ST[, V <= 0] <- NA_real_
    list(S1 = S1, ST = ST)
  }

  point <- estimer(seq_len(N))
  boot_S1 <- boot_ST <- array(NA_real_, c(B, k, length(noms_sorties)))
  for (b in seq_len(B)) {
    e <- estimer(sample.int(N, N, replace = TRUE))
    boot_S1[b, , ] <- e$S1
    boot_ST[b, , ] <- e$ST
  }
  ic <- function(arr, j, s, p) unname(quantile(arr[, j, s], p, na.rm = TRUE))

  lignes_res <- list()
  for (s in seq_along(noms_sorties)) {
    for (j in seq_len(k)) {
      lignes_res[[length(lignes_res) + 1]] <- data.frame(
        parametre = noms[j], sortie = noms_sorties[s],
        S1 = point$S1[j, s], S1_inf = ic(boot_S1, j, s, 0.025), S1_sup = ic(boot_S1, j, s, 0.975),
        ST = point$ST[j, s], ST_inf = ic(boot_ST, j, s, 0.025), ST_sup = ic(boot_ST, j, s, 0.975),
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, lignes_res)
}

# Sobol sur le modèle de base : paramètres variant d'un facteur `facteur` autour de la référence
sobol_modele <- function(ref, f, facteur = 2, ...) {
  indices_sobol(f, bas = ref / facteur, haut = ref * facteur, echelle_log = TRUE, ...)
}
