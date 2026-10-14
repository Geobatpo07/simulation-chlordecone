# Graphiques ggplot2 de l'application. Chaque fonction `plots_*` renvoie une liste de
# quatre graphiques, assemblés par gridExtra::grid.arrange dans app.R.

theme_chlordecone <- function(base_size = 13, legende = TRUE) {
  th <- theme_minimal(base_size = base_size)
  if (legende) {
    th <- th + theme(legend.position = "bottom", legend.title = element_blank())
  }
  th
}

# Mise au format long d'un ensemble de colonnes (temps + séries nommées)
melt_series <- function(df, ...) {
  series <- list(...)
  d <- data.frame(time_years = df$time_years, check.names = FALSE)
  for (nom in names(series)) d[[nom]] <- series[[nom]]
  reshape2::melt(d, id.vars = "time_years", variable.name = "Type", value.name = "Valeur")
}

plot_env_ressource <- function(df) {
  d <- melt_series(df, Environnement = df$E, Ressource = df$F)
  ggplot(d, aes(x = time_years, y = Valeur, color = Type)) +
    geom_line(linewidth = 1.2) +
    labs(x = "Temps (années)", y = "Stock (kg)", title = "Environnement et ressource") +
    theme_chlordecone()
}

plot_populations <- function(df, titre = "Dynamique des populations") {
  d <- melt_series(df, `Charge élevée` = df$H_I, `Faible charge` = df$H_S)
  ggplot(d, aes(x = time_years, y = Valeur, color = Type)) +
    geom_line(linewidth = 1.2) +
    labs(x = "Temps (années)", y = "Population", title = titre) +
    theme_chlordecone()
}

plot_prevalence <- function(df, couleur = "darkred") {
  ggplot(df, aes(x = time_years, y = prevalence)) +
    geom_line(linewidth = 1.3, color = couleur) +
    labs(x = "Temps (années)", y = "Prévalence (%)", title = "Prévalence charge élevée") +
    theme_chlordecone(legende = FALSE)
}

# Calque « période d'intervention » : zone ombrée et ligne de début
calque_intervention <- function(t0_line, t_max) {
  list(
    geom_rect(xmin = t0_line, xmax = t_max, ymin = -Inf, ymax = Inf,
              fill = "lightblue", alpha = 0.01),
    geom_vline(xintercept = t0_line, linetype = "dashed", color = "blue", linewidth = 1)
  )
}

# -----------------------------------------------------------------------------
# Un jeu de quatre graphiques par onglet
# -----------------------------------------------------------------------------

plots_base <- function(df) {
  p1 <- ggplot(df) +
    geom_line(aes(x = time_years, y = C1, color = "Parcelle 1"), linewidth = 1) +
    scale_y_log10() +
    labs(x = "Temps (années)", y = "Stock (kg, log)", title = "Contamination parcellaire") +
    theme_chlordecone()
  list(p1, plot_env_ressource(df), plot_populations(df), plot_prevalence(df))
}

plots_charge <- function(df, B_star) {
  p1 <- ggplot(df, aes(x = time_years, y = B)) +
    geom_line(linewidth = 1.3, color = "purple") +
    geom_hline(yintercept = B_star, linetype = "dashed", color = "red") +
    labs(x = "Temps (années)", y = "Charge B (µg/L)", title = "Charge corporelle moyenne") +
    theme_chlordecone(legende = FALSE)
  list(p1, plot_env_ressource(df), plot_populations(df), plot_prevalence(df))
}

plots_spatial <- function(df, n_bassins) {
  long_bassins <- function(prefixe) {
    d <- df[, c("time_years", paste0(prefixe, seq_len(n_bassins)))]
    reshape2::melt(d, id.vars = "time_years", variable.name = "Bassin", value.name = "Valeur")
  }
  p1 <- ggplot(long_bassins("E"), aes(x = time_years, y = Valeur, color = Bassin)) +
    geom_line(linewidth = 1.1) +
    labs(x = "Temps (années)", y = "Stock environnement (kg)", title = "Contamination par bassin versant") +
    theme_minimal(base_size = 13) + theme(legend.position = "bottom")
  p2 <- ggplot(long_bassins("F"), aes(x = time_years, y = Valeur, color = Bassin)) +
    geom_line(linewidth = 1.1) +
    labs(x = "Temps (années)", y = "Ressource (kg)", title = "Ressources alimentaires par bassin") +
    theme_minimal(base_size = 13) + theme(legend.position = "bottom")
  list(p1, p2, plot_populations(df, "Dynamique des populations (agrégée)"),
       plot_prevalence(df, "darkblue"))
}

plots_markov <- function(df) {
  classes <- c(H4 = "Classe 4 (élevée)", H3 = "Classe 3 (modérée)",
               H2 = "Classe 2 (faible)", H1 = "Classe 1 (nulle)")
  d <- reshape2::melt(df[, c("time_years", "H1", "H2", "H3", "H4")], id.vars = "time_years",
                      variable.name = "Classe", value.name = "Population")
  d$Classe <- factor(d$Classe, levels = names(classes), labels = unname(classes))

  p1 <- ggplot(d, aes(x = time_years, y = Population, fill = Classe)) +
    geom_area(position = "stack", alpha = 0.7) +
    labs(x = "Temps (années)", y = "Population", title = "Distribution par classes de charge") +
    scale_fill_manual(values = c("red", "orange", "yellow", "lightgreen")) +
    theme_chlordecone()

  d_prev <- melt_series(df, `Charge élevée (H4)` = df$prevalence_elevee,
                        `Charge modérée+ (H3+H4)` = df$prevalence_moderee)
  p3 <- ggplot(d_prev, aes(x = time_years, y = Valeur, color = Type)) +
    geom_line(linewidth = 1.2) +
    labs(x = "Temps (années)", y = "Prévalence (%)", title = "Prévalence par niveau de charge") +
    theme_chlordecone()

  fin <- tail(df, 1)
  props <- data.frame(
    Classe = c("H1 (nulle)", "H2 (faible)", "H3 (modérée)", "H4 (élevée)"),
    Proportion = c(fin$H1, fin$H2, fin$H3, fin$H4) / fin$H_total * 100
  )
  p4 <- ggplot(props, aes(x = Classe, y = Proportion, fill = Classe)) +
    geom_bar(stat = "identity") +
    scale_fill_manual(values = c("lightgreen", "yellow", "orange", "red")) +
    labs(x = "", y = "Proportion (%)", title = "Distribution finale (t = fin)") +
    theme_minimal(base_size = 13) +
    theme(legend.position = "none", axis.text.x = element_text(angle = 15, hjust = 1))

  list(p1, plot_env_ressource(df), p3, p4)
}

plots_intervention <- function(df, t0_line) {
  t_max <- max(df$time_years)
  n_fin <- nrow(df)

  sous_titre <- sprintf("Finale : %.1f %% avec vs %.1f %% sans intervention",
                        df$prevalence[n_fin], df$prevalence_ref[n_fin])
  if (t_max >= 5) {
    i5 <- which.min(abs(df$time_years - 5))
    red5 <- if (df$prevalence_ref[i5] > 0) {
      100 * (1 - df$prevalence[i5] / df$prevalence_ref[i5])
    } else {
      NA_real_
    }
    sous_titre <- paste0(sous_titre, sprintf("\nÀ 5 ans : %.1f %% vs %.1f %% (réduction relative : %.0f %%)",
                                             df$prevalence[i5], df$prevalence_ref[i5], red5))
  }

  p1 <- ggplot(df, aes(x = time_years)) +
    calque_intervention(t0_line, t_max) +
    geom_line(aes(y = prevalence_ref, color = "Sans intervention"), linewidth = 1.1, linetype = "dashed") +
    geom_line(aes(y = prevalence, color = "Avec intervention"), linewidth = 1.3) +
    annotate("text", x = t0_line + 1, y = max(c(df$prevalence, df$prevalence_ref)) * 0.9,
             label = "Début intervention", hjust = 0, color = "blue") +
    scale_color_manual(values = c("Avec intervention" = "darkred", "Sans intervention" = "grey40")) +
    labs(x = "Temps (années)", y = "Prévalence (%)", title = "Impact sur la prévalence",
         subtitle = sous_titre) +
    theme_chlordecone()

  p2 <- ggplot(df, aes(x = time_years)) +
    calque_intervention(t0_line, t_max) +
    geom_line(aes(y = F_ref, color = "Sans intervention"), linewidth = 1.1, linetype = "dashed") +
    geom_line(aes(y = F, color = "Avec intervention"), linewidth = 1.2) +
    scale_color_manual(values = c("Avec intervention" = "darkorange", "Sans intervention" = "grey40")) +
    labs(x = "Temps (années)", y = "Ressource (kg)", title = "Impact sur la ressource alimentaire") +
    theme_chlordecone()

  d_pop <- melt_series(df, `Charge élevée` = df$H_I, `Faible charge` = df$H_S)
  p3 <- ggplot(d_pop, aes(x = time_years, y = Valeur, color = Type)) +
    calque_intervention(t0_line, t_max) +
    geom_line(linewidth = 1.2) +
    labs(x = "Temps (années)", y = "Population", title = "Dynamique des populations") +
    theme_chlordecone()

  p4 <- ggplot(df, aes(x = time_years, y = intervention * 100)) +
    geom_area(fill = "steelblue", alpha = 0.5) +
    labs(x = "Temps (années)", y = "Niveau d'intervention (%)", title = "Progression de l'intervention") +
    theme_minimal(base_size = 13)

  list(p1, p2, p3, p4)
}

plot_comparaison <- function(df) {
  d <- reshape2::melt(df, id.vars = "time_years", variable.name = "Modèle", value.name = "Prévalence")
  ggplot(d, aes(x = time_years, y = Prévalence, color = Modèle)) +
    geom_line(linewidth = 1.4) +
    labs(x = "Temps (années)", y = "Prévalence de charge élevée (%)",
         title = "Comparaison des modèles : prévalence de l'exposition") +
    scale_color_manual(values = c("Base" = "darkred", "Charge" = "purple", "Markov" = "darkblue")) +
    theme_chlordecone(base_size = 15)
}

# -----------------------------------------------------------------------------
# Sensibilité
# -----------------------------------------------------------------------------

# Diagramme en tornade (OAT) : valeur de la sortie quand chaque paramètre est multiplié par 0,5 puis 2
plot_tornado <- function(df_oat, sortie, etiquettes) {
  d <- df_oat[df_oat$sortie == sortie, ]
  d$label <- etiquettes[d$parametre]
  d$amplitude <- abs(d$y_haut - d$y_bas)
  d$label <- factor(d$label, levels = d$label[order(d$amplitude)])
  y_ref <- d$y_ref[1]

  ggplot(d) +
    geom_segment(aes(x = label, xend = label, y = y_ref, yend = y_bas, color = "Paramètre × 0,5"), linewidth = 6) +
    geom_segment(aes(x = label, xend = label, y = y_ref, yend = y_haut, color = "Paramètre × 2"), linewidth = 6) +
    geom_hline(yintercept = y_ref, linetype = "dashed") +
    coord_flip() +
    scale_color_manual(values = c("Paramètre × 0,5" = "steelblue", "Paramètre × 2" = "darkorange")) +
    labs(x = NULL, y = SORTIES_SENSIBILITE[[sortie]], title = "Analyse locale (un paramètre à la fois)",
         subtitle = sprintf("Valeur de référence : %.3g (ligne pointillée)", y_ref)) +
    theme_chlordecone()
}

# Indices de Sobol : premier ordre (S1) et total (ST) avec intervalles de confiance bootstrap à 95 %
plot_sobol <- function(df_sobol, sortie, etiquettes) {
  d <- df_sobol[df_sobol$sortie == sortie, ]
  if (all(is.na(d$ST))) {
    return(ggplot() + annotate("text", x = 0, y = 0, label = "Sortie constante : indices non définis") + theme_void())
  }
  d$label <- etiquettes[d$parametre]
  d$label <- factor(d$label, levels = d$label[order(d$ST)])
  long <- rbind(
    data.frame(label = d$label, Indice = "Premier ordre (S1)", valeur = d$S1, inf = d$S1_inf, sup = d$S1_sup),
    data.frame(label = d$label, Indice = "Total (ST)", valeur = d$ST, inf = d$ST_inf, sup = d$ST_sup)
  )
  ggplot(long, aes(x = label, y = valeur, fill = Indice)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    geom_errorbar(aes(ymin = inf, ymax = sup), position = position_dodge(width = 0.8), width = 0.25) +
    coord_flip() +
    scale_fill_manual(values = c("Premier ordre (S1)" = "steelblue", "Total (ST)" = "darkorange")) +
    labs(x = NULL, y = "Part de la variance de la sortie", title = "Analyse globale (indices de Sobol)",
         subtitle = SORTIES_SENSIBILITE[[sortie]]) +
    theme_chlordecone()
}
