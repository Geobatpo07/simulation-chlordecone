# Application Shiny - Modélisation de l'exposition humaine au chlordécone
# Auteur: Geovany Batista Polo Laguerre
# Date: 2026-01-23

library(shiny)
library(deSolve)
library(ggplot2)
library(gridExtra)
library(shinydashboard)
library(DT)

# =============================================================================
# FONCTIONS DE MODÉLISATION
# =============================================================================

# -----------------------------------------------------------------------------
# 1. MODÈLE DE BASE (CC1)
# -----------------------------------------------------------------------------

modele_base <- function(t, y, params) {
  with(as.list(c(y, params)), {
    # Extraction des variables
    C <- y[1:n_parcelles]
    E <- y[n_parcelles + 1]
    F_res <- y[n_parcelles + 2]
    H_S <- y[n_parcelles + 3]
    H_I <- y[n_parcelles + 4]
    
    # Forçage pluviométrique
    R_t <- R_moy * (1 + A_saison * sin(2 * pi * t / T_periode))
    
    # Fonction d'amplification pluviométrique
    g_R <- 1 + alpha * R_t / (R0_sat + R_t)
    
    # Fonction d'exposition
    lambda_F <- ifelse(F_res <= F_max, beta * F_res, beta * F_max)
    
    # Équations différentielles
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
    # Extraction des variables
    C <- y[1:n_parcelles]
    E <- y[n_parcelles + 1]
    F_res <- y[n_parcelles + 2]
    H_S <- y[n_parcelles + 3]
    H_I <- y[n_parcelles + 4]
    B <- y[n_parcelles + 5]  # Charge corporelle moyenne
    
    # Forçage pluviométrique
    R_t <- R_moy * (1 + A_saison * sin(2 * pi * t / T_periode))
    g_R <- 1 + alpha * R_t / (R0_sat + R_t)
    
    # Population totale
    H_total <- H_S + H_I
    
    # Dynamique de la charge corporelle
    dB <- gamma_B * F_res / H_total - mu_B * B
    
    # Transition probabiliste basée sur B
    p_I <- 1 / (1 + exp(-k_sigmoid * (B - B_star)))
    
    # Fonction d'exposition
    lambda_F <- ifelse(F_res <= F_max, beta * F_res, beta * F_max)
    
    # Équations différentielles
    dC <- -delta * C - r0 * g_R * C
    dE <- sum(r0 * g_R * C) - mu_E * E - kappa * E
    dF <- kappa * E - mu_F * F_res
    
    # Transitions basées sur la charge corporelle
    flux_S_to_I <- H_S * p_I * 0.01  # Transition graduelle
    flux_I_to_S <- H_I * (1 - p_I) * 0.01
    
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
    F_res <- y[(n_parcelles + n_bassins + 1):(n_parcelles + 2*n_bassins)]
    H_S <- y[n_parcelles + 2*n_bassins + 1]
    H_I <- y[n_parcelles + 2*n_bassins + 2]
    
    # Forçage pluviométrique
    R_t <- R_moy * (1 + A_saison * sin(2 * pi * t / T_periode))
    g_R <- 1 + alpha * R_t / (R0_sat + R_t)
    
    # Dynamique des parcelles
    dC <- -delta * C - r0 * g_R * C
    
    # Dynamique des bassins versants
    dE <- numeric(n_bassins)
    for (j in 1:n_bassins) {
      # Flux depuis les parcelles du bassin j
      parcelles_bassin <- which(parcelles_to_bassin == j)
      flux_entrant <- sum(r0[parcelles_bassin] * g_R * C[parcelles_bassin])
      
      # Pertes et transferts inter-bassins
      dE[j] <- flux_entrant - mu_E * E[j] - kappa * E[j]
      
      # Transfert vers bassin aval (simplifié: bassin j -> bassin j+1)
      if (j < n_bassins) {
        dE[j] <- dE[j] - w_transfer * E[j]
        dE[j + 1] <- dE[j + 1] + w_transfer * E[j]
      }
    }
    
    # Dynamique des ressources alimentaires (une par bassin)
    dF <- kappa * E - mu_F * F_res
    
    # Exposition humaine (agrégée sur tous les bassins)
    F_total <- sum(F_res)
    lambda_F <- ifelse(F_total <= F_max, beta * F_total, beta * F_max)
    
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
    # Extraction des variables
    C <- y[1:n_parcelles]
    E <- y[n_parcelles + 1]
    F_res <- y[n_parcelles + 2]
    H1 <- y[n_parcelles + 3]  # Classe 1: charge nulle
    H2 <- y[n_parcelles + 4]  # Classe 2: charge faible
    H3 <- y[n_parcelles + 5]  # Classe 3: charge modérée
    H4 <- y[n_parcelles + 6]  # Classe 4: charge élevée
    
    # Forçage pluviométrique
    R_t <- R_moy * (1 + A_saison * sin(2 * pi * t / T_periode))
    g_R <- 1 + alpha * R_t / (R0_sat + R_t)
    
    # Équations environnementales
    dC <- -delta * C - r0 * g_R * C
    dE <- sum(r0 * g_R * C) - mu_E * E - kappa * E
    dF <- kappa * E - mu_F * F_res
    
    # Taux de transition dépendant de F
    q12 <- beta_1 * F_res  # Classe 1 -> 2
    q23 <- beta_2 * F_res  # Classe 2 -> 3
    q34 <- beta_3 * F_res  # Classe 3 -> 4
    
    # Taux de régression (dépuration)
    rho_1 <- rho * 0.5
    rho_2 <- rho * 0.7
    rho_3 <- rho
    
    # Population totale
    H_total <- H1 + H2 + H3 + H4
    
    # Dynamique markovienne
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

modele_intervention <- function(t, y, params) {
  with(as.list(c(y, params)), {
    # Fonction sigmoïde pour intervention progressive
    phi_t <- 0.5 * (1 + tanh((t - t0_intervention) / tau_intervention))
    
    # Paramètres modifiés par l'intervention
    r0_eff <- r0 * (1 - reduction_r0 * phi_t)
    beta_eff <- beta * (1 - reduction_beta * phi_t)
    
    # Extraction des variables
    C <- y[1:n_parcelles]
    E <- y[n_parcelles + 1]
    F_res <- y[n_parcelles + 2]
    H_S <- y[n_parcelles + 3]
    H_I <- y[n_parcelles + 4]
    
    # Forçage pluviométrique
    R_t <- R_moy * (1 + A_saison * sin(2 * pi * t / T_periode))
    g_R <- 1 + alpha * R_t / (R0_sat + R_t)
    
    # Fonction d'exposition avec paramètre réduit
    lambda_F <- ifelse(F_res <= F_max, beta_eff * F_res, beta_eff * F_max)
    
    # Équations différentielles
    dC <- -delta * C - r0_eff * g_R * C
    dE <- sum(r0_eff * g_R * C) - mu_E * E - kappa * E
    dF <- kappa * E - mu_F * F_res
    dH_S <- Lambda_H - lambda_F * H_S - d_H * H_S + rho * H_I
    dH_I <- lambda_F * H_S - d_H * H_I - rho * H_I
    
    list(c(dC, dE, dF, dH_S, dH_I))
  })
}

# =============================================================================
# INTERFACE UTILISATEUR
# =============================================================================

ui <- dashboardPage(
  skin = "blue",
  
  # En-tête
  dashboardHeader(title = "Modélisation Chlordécone", titleWidth = 300),
  
  # Barre latérale
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      id = "tabs",
      menuItem("Accueil", tabName = "accueil", icon = icon("home")),
      menuItem("Modèle de base", tabName = "base", icon = icon("chart-line")),
      menuItem("Variable charge B(t)", tabName = "charge", icon = icon("heartbeat")),
      menuItem("Spatialisation", tabName = "spatial", icon = icon("map")),
      menuItem("Chaîne de Markov", tabName = "markov", icon = icon("random")),
      menuItem("Intervention", tabName = "intervention", icon = icon("medkit")),
      menuItem("Comparaison", tabName = "comparaison", icon = icon("balance-scale")),
      menuItem("À propos", tabName = "about", icon = icon("info-circle"))
    )
  ),
  
  # Corps principal
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .box-title { font-weight: bold; }
        .info-box { margin-bottom: 15px; }
        .small-box { margin-bottom: 15px; }
      "))
    ),
    
    tabItems(
      # -----------------------------------------------------------------------
      # ONGLET ACCUEIL
      # -----------------------------------------------------------------------
      tabItem(
        tabName = "accueil",
        fluidRow(
          box(
            width = 12,
            title = "Bienvenue dans l'application de modélisation du chlordécone",
            status = "primary",
            solidHeader = TRUE,
            h3("Objectif"),
            p("Cette application interactive permet d'explorer différentes approches de modélisation 
              de l'exposition humaine au chlordécone aux Antilles françaises."),
            br(),
            h3("Modèles disponibles"),
            tags$ul(
              tags$li(tags$b("Modèle de base :"), "Modèle compartimental à 6 compartiments (parcelles, environnement, ressource, populations)"),
              tags$li(tags$b("Variable de charge B(t) :"), "Extension avec biomarqueur sanguin de charge corporelle"),
              tags$li(tags$b("Spatialisation :"), "Modèle multi-bassins versants avec réseau hydrographique"),
              tags$li(tags$b("Chaîne de Markov :"), "Discrétisation de la charge en 4 classes avec transitions stochastiques"),
              tags$li(tags$b("Intervention :"), "Simulation de politiques publiques (réduction progressive de l'exposition)")
            ),
            br(),
            h3("Instructions"),
            p("1. Sélectionnez un modèle dans le menu latéral"),
            p("2. Ajustez les paramètres selon vos besoins"),
            p("3. Cliquez sur 'Simuler' pour lancer le calcul"),
            p("4. Explorez les graphiques et téléchargez les résultats si nécessaire")
          )
        ),
        fluidRow(
          valueBox(6, "Compartiments", icon = icon("cubes"), color = "aqua", width = 3),
          valueBox("20 ans", "Horizon", icon = icon("calendar"), color = "green", width = 3),
          valueBox("5 modèles", "Disponibles", icon = icon("cogs"), color = "yellow", width = 3),
          valueBox("deSolve", "Solveur ODE", icon = icon("calculator"), color = "red", width = 3)
        )
      ),
      
      # -----------------------------------------------------------------------
      # ONGLET MODÈLE DE BASE
      # -----------------------------------------------------------------------
      tabItem(
        tabName = "base",
        fluidRow(
          box(
            width = 4,
            title = "Paramètres du modèle",
            status = "primary",
            solidHeader = TRUE,
            
            h4("Parcelles"),
            sliderInput("base_n_parcelles", "Nombre de parcelles", 1, 5, 3, step = 1),
            sliderInput("base_C0", "Stock initial (kg)", 100, 2000, 1000, step = 100),
            sliderInput("base_delta", "Taux dégradation (j⁻¹)", 0.0001, 0.01, 0.001, step = 0.0001),
            sliderInput("base_r0", "Ruissellement base (j⁻¹)", 0.001, 0.05, 0.01, step = 0.001),
            
            h4("Environnement et ressource"),
            sliderInput("base_alpha", "Amplification pluie", 0, 2, 0.8, step = 0.1),
            sliderInput("base_mu_E", "Élimination environnement (j⁻¹)", 0.01, 0.1, 0.05, step = 0.01),
            sliderInput("base_kappa", "Transfert E→F (j⁻¹)", 0.01, 0.1, 0.03, step = 0.01),
            sliderInput("base_mu_F", "Renouvellement ressource (j⁻¹)", 0.005, 0.05, 0.02, step = 0.005),
            
            h4("Population"),
            sliderInput("base_beta", "Taux exposition (j⁻¹·kg⁻¹)", 0.0001, 0.01, 0.001, step = 0.0001),
            sliderInput("base_rho", "Taux dépuration (j⁻¹)", 0.001, 0.02, 0.005, step = 0.001),
            sliderInput("base_H0", "Population initiale", 10000, 100000, 50000, step = 1000),
            
            h4("Simulation"),
            sliderInput("base_duree", "Durée (années)", 1, 50, 20, step = 1),
            actionButton("base_simulate", "Simuler", icon = icon("play"), class = "btn-success"),
            br(), br(),
            downloadButton("base_download", "Télécharger les résultats")
          ),
          
          box(
            width = 8,
            title = "Résultats de simulation",
            status = "success",
            solidHeader = TRUE,
            plotOutput("base_plot", height = "700px")
          )
        )
      ),
      
      # -----------------------------------------------------------------------
      # ONGLET VARIABLE CHARGE B(t)
      # -----------------------------------------------------------------------
      tabItem(
        tabName = "charge",
        fluidRow(
          box(
            width = 4,
            title = "Paramètres du modèle avec B(t)",
            status = "warning",
            solidHeader = TRUE,
            
            h4("Paramètres de base (hérités)"),
            sliderInput("charge_n_parcelles", "Nombre de parcelles", 1, 5, 3, step = 1),
            sliderInput("charge_delta", "Taux dégradation (j⁻¹)", 0.0001, 0.01, 0.001, step = 0.0001),
            sliderInput("charge_kappa", "Transfert E→F (j⁻¹)", 0.01, 0.1, 0.03, step = 0.01),
            sliderInput("charge_beta", "Taux exposition (j⁻¹·kg⁻¹)", 0.0001, 0.01, 0.001, step = 0.0001),
            
            h4("Paramètres spécifiques B(t)"),
            sliderInput("charge_gamma_B", "Coeff. absorption γ (µg·L⁻¹·kg⁻¹)", 0.001, 0.1, 0.01, step = 0.001),
            sliderInput("charge_mu_B", "Élimination corporelle µ_B (j⁻¹)", 0.001, 0.02, 0.005, step = 0.001),
            sliderInput("charge_B_star", "Seuil charge B* (µg/L)", 0.5, 2, 1, step = 0.1),
            sliderInput("charge_k_sigmoid", "Raideur sigmoïde k", 1, 10, 5, step = 0.5),
            
            sliderInput("charge_duree", "Durée (années)", 1, 50, 20, step = 1),
            actionButton("charge_simulate", "Simuler", icon = icon("play"), class = "btn-warning"),
            br(), br(),
            downloadButton("charge_download", "Télécharger les résultats")
          ),
          
          box(
            width = 8,
            title = "Résultats avec charge corporelle B(t)",
            status = "warning",
            solidHeader = TRUE,
            plotOutput("charge_plot", height = "700px")
          )
        )
      ),
      
      # -----------------------------------------------------------------------
      # ONGLET SPATIALISATION
      # -----------------------------------------------------------------------
      tabItem(
        tabName = "spatial",
        fluidRow(
          box(
            width = 4,
            title = "Paramètres du modèle spatialisé",
            status = "info",
            solidHeader = TRUE,
            
            h4("Structure spatiale"),
            sliderInput("spatial_n_parcelles", "Nombre de parcelles", 2, 6, 4, step = 1),
            sliderInput("spatial_n_bassins", "Nombre de bassins versants", 2, 4, 3, step = 1),
            sliderInput("spatial_w_transfer", "Taux transfert inter-bassins (j⁻¹)", 0, 0.1, 0.02, step = 0.01),
            
            h4("Paramètres environnementaux"),
            sliderInput("spatial_delta", "Taux dégradation (j⁻¹)", 0.0001, 0.01, 0.001, step = 0.0001),
            sliderInput("spatial_kappa", "Transfert E→F (j⁻¹)", 0.01, 0.1, 0.03, step = 0.01),
            sliderInput("spatial_mu_E", "Élimination environnement (j⁻¹)", 0.01, 0.1, 0.05, step = 0.01),
            
            h4("Simulation"),
            sliderInput("spatial_duree", "Durée (années)", 1, 50, 20, step = 1),
            actionButton("spatial_simulate", "Simuler", icon = icon("play"), class = "btn-info"),
            br(), br(),
            downloadButton("spatial_download", "Télécharger les résultats")
          ),
          
          box(
            width = 8,
            title = "Résultats du modèle spatialisé",
            status = "info",
            solidHeader = TRUE,
            plotOutput("spatial_plot", height = "700px")
          )
        )
      ),
      
      # -----------------------------------------------------------------------
      # ONGLET CHAÎNE DE MARKOV
      # -----------------------------------------------------------------------
      tabItem(
        tabName = "markov",
        fluidRow(
          box(
            width = 4,
            title = "Paramètres chaîne de Markov",
            status = "danger",
            solidHeader = TRUE,
            
            h4("Paramètres environnementaux"),
            sliderInput("markov_n_parcelles", "Nombre de parcelles", 1, 5, 3, step = 1),
            sliderInput("markov_delta", "Taux dégradation (j⁻¹)", 0.0001, 0.01, 0.001, step = 0.0001),
            sliderInput("markov_kappa", "Transfert E→F (j⁻¹)", 0.01, 0.1, 0.03, step = 0.01),
            
            h4("Taux de transition (exposition)"),
            sliderInput("markov_beta_1", "β₁: Classe 1→2 (j⁻¹·kg⁻¹)", 0.0001, 0.01, 0.0005, step = 0.0001),
            sliderInput("markov_beta_2", "β₂: Classe 2→3 (j⁻¹·kg⁻¹)", 0.0001, 0.01, 0.0007, step = 0.0001),
            sliderInput("markov_beta_3", "β₃: Classe 3→4 (j⁻¹·kg⁻¹)", 0.0001, 0.01, 0.001, step = 0.0001),
            
            h4("Taux de dépuration"),
            sliderInput("markov_rho", "Taux base ρ (j⁻¹)", 0.001, 0.02, 0.005, step = 0.001),
            
            sliderInput("markov_duree", "Durée (années)", 1, 50, 20, step = 1),
            actionButton("markov_simulate", "Simuler", icon = icon("play"), class = "btn-danger"),
            br(), br(),
            downloadButton("markov_download", "Télécharger les résultats")
          ),
          
          box(
            width = 8,
            title = "Résultats chaîne de Markov (4 classes)",
            status = "danger",
            solidHeader = TRUE,
            plotOutput("markov_plot", height = "700px")
          )
        )
      ),
      
      # -----------------------------------------------------------------------
      # ONGLET INTERVENTION
      # -----------------------------------------------------------------------
      tabItem(
        tabName = "intervention",
        fluidRow(
          box(
            width = 4,
            title = "Paramètres intervention",
            status = "success",
            solidHeader = TRUE,
            
            h4("Politique d'intervention"),
            sliderInput("interv_t0", "Début intervention (années)", 0, 20, 5, step = 0.5),
            sliderInput("interv_tau", "Durée transition (années)", 0.5, 5, 2, step = 0.5),
            sliderInput("interv_reduction_r0", "Réduction ruissellement (%)", 0, 80, 40, step = 5),
            sliderInput("interv_reduction_beta", "Réduction exposition (%)", 0, 80, 40, step = 5),
            
            h4("Paramètres de base"),
            sliderInput("interv_n_parcelles", "Nombre de parcelles", 1, 5, 3, step = 1),
            sliderInput("interv_delta", "Taux dégradation (j⁻¹)", 0.0001, 0.01, 0.001, step = 0.0001),
            sliderInput("interv_kappa", "Transfert E→F (j⁻¹)", 0.01, 0.1, 0.03, step = 0.01),
            
            sliderInput("interv_duree", "Durée (années)", 1, 50, 20, step = 1),
            actionButton("interv_simulate", "Simuler", icon = icon("play"), class = "btn-success"),
            br(), br(),
            downloadButton("interv_download", "Télécharger les résultats")
          ),
          
          box(
            width = 8,
            title = "Impact de l'intervention",
            status = "success",
            solidHeader = TRUE,
            plotOutput("interv_plot", height = "700px")
          )
        )
      ),
      
      # -----------------------------------------------------------------------
      # ONGLET COMPARAISON
      # -----------------------------------------------------------------------
      tabItem(
        tabName = "comparaison",
        fluidRow(
          box(
            width = 12,
            title = "Comparaison des modèles",
            status = "primary",
            solidHeader = TRUE,
            p("Cette section permet de comparer les prédictions des différents modèles sur un même scénario."),
            p("Utilisez les paramètres ci-dessous pour définir un scénario commun, puis lancez la simulation comparative."),
            br(),
            
            fluidRow(
              column(
                width = 4,
                h4("Paramètres communs"),
                sliderInput("comp_duree", "Durée (années)", 5, 50, 20, step = 5),
                sliderInput("comp_C0", "Stock initial parcelles (kg)", 500, 2000, 1000, step = 100),
                sliderInput("comp_H0", "Population initiale", 10000, 100000, 50000, step = 5000),
                actionButton("comp_simulate", "Comparer les modèles", icon = icon("balance-scale"), class = "btn-primary btn-lg")
              ),
              column(
                width = 8,
                plotOutput("comp_plot", height = "500px")
              )
            )
          )
        )
      ),
      
      # -----------------------------------------------------------------------
      # ONGLET À PROPOS
      # -----------------------------------------------------------------------
      tabItem(
        tabName = "about",
        fluidRow(
          box(
            width = 12,
            title = "À propos de cette application",
            status = "primary",
            solidHeader = TRUE,
            
            # Auteur
            h3("Auteur"),
            p(strong("Geovany Batista Polo Laguerre"), br(), 
              "Data Scientist", br(),
              style = "font-size: 16px; margin-bottom: 20px;"),
            p("Spécialisé en modélisation mathématique appliquée, analyse de données et santé publique environnementale, 
              avec un intérêt particulier pour la modélisation dynamique des expositions chroniques aux contaminants 
              environnementaux."),
            br(),
            
            # Domaines d'expertise
            h4("Domaines d'expertise", style = "color: #0066cc; font-weight: bold;"),
            tags$ul(
              tags$li("Data science et analyse de données"),
              tags$li("Modélisation mathématique et compartimentale"),
              tags$li("Santé publique et épidémiologie"),
              tags$li("Environnement et contamination chronique")
            ),
            br(),
            
            # Liens professionnels
            h4("Liens professionnels", style = "color: #0066cc; font-weight: bold;"),
            p(tags$a(href = "https://linkedin.com/in/geobatpo07", target = "_blank", icon("linkedin"), "LinkedIn"), 
              " | ",
              tags$a(href = "https://github.com/geobatpo07", target = "_blank", icon("github"), "GitHub"),
              style = "font-size: 15px;"),
            br(),
            
            # Contexte scientifique
            h3("Contexte scientifique"),
            p("Le chlordécone est un pesticide organochloré persistant utilisé dans les bananeraies des Antilles 
              françaises entre 1972 et 1993. En raison de sa demi-vie exceptionnellement longue dans les sols tropicaux, 
              il demeure une source majeure de contamination environnementale et d'exposition humaine chronique, 
              principalement via la chaîne alimentaire."),
            p("La complexité des transferts entre sols, milieux aquatiques, ressources alimentaires et population humaine, 
              fortement modulés par la pluviométrie tropicale, rend l'analyse de ces dynamiques particulièrement délicate 
              et justifie le recours à des approches de modélisation mathématique dynamique."),
            br(),
            
            # Modélisation mathématique
            h3("Modélisation mathématique"),
            p("Cette application implémente plusieurs approches de modélisation compartimentale issues du travail de 
              recherche associé :"),
            tags$ul(
              tags$li("Modèle déterministe en temps continu basé sur des équations différentielles ordinaires (EDO)"),
              tags$li("Principe de conservation de la masse dans chaque compartiment"),
              tags$li("Couplage explicite entre contamination environnementale et exposition humaine"),
              tags$li("Forçage pluviométrique saisonnier"),
              tags$li("Extensions méthodologiques : spatialisation, biomarqueurs de charge corporelle, chaînes de Markov")
            ),
            p(HTML("<strong style='color: #d9534f;'>Note importante :</strong> Cette application a un objectif exploratoire 
              et pédagogique. Elle vise à illustrer les mécanismes dynamiques du modèle et à analyser l'influence qualitative 
              des paramètres. Elle ne constitue pas un outil opérationnel d'aide à la décision sanitaire."),
              style = "background-color: #f5f5f5; padding: 10px; border-left: 4px solid #d9534f; margin: 15px 0;"),
            br(),
            
            # Outils utilisés
            h3("Outils utilisés"),
            tags$ul(
              tags$li(strong("R :"), " langage de programmation statistique"),
              tags$li(strong("Shiny :"), " framework pour applications web interactives"),
              tags$li(strong("deSolve :"), " résolution numérique des équations différentielles ordinaires"),
              tags$li(strong("ggplot2 :"), " visualisation des résultats")
            ),
            br(),
            
            # Références
            h3("Références"),
            tags$ul(
              tags$li("ANSES / Santé publique France — Travaux sur l'exposition au chlordécone aux Antilles françaises"),
              tags$li("Soetaert, K., Petzoldt, T., & Setzer, R. W. (2010). Solving Differential Equations in R: Package deSolve. ", 
                      em("Journal of Statistical Software"), "."),
              tags$li("Brauer, F., & Castillo-Chavez, C. (2012). ", em("Mathematical Models in Population Biology and Epidemiology"), 
                      ". Springer.")
            ),
            br(),
            
            # Contact
            h3("Contact"),
            p("Pour toute question ou suggestion : ", 
              tags$a(href = "mailto:lgeobatpo98@gmail.com", "lgeobatpo98@gmail.com")),
            br(),
            
            p(em("Version 1.0 — Janvier 2026"), style = "color: #666; font-size: 13px;")
          )
        )
      )
    )
  )
)

# =============================================================================
# SERVEUR
# =============================================================================

server <- function(input, output, session) {
  
  # ---------------------------------------------------------------------------
  # SIMULATION MODÈLE DE BASE
  # ---------------------------------------------------------------------------
  
  base_results <- eventReactive(input$base_simulate, {
    # Paramètres
    params <- list(
      n_parcelles = input$base_n_parcelles,
      delta = rep(input$base_delta, input$base_n_parcelles),
      r0 = rep(input$base_r0, input$base_n_parcelles),
      alpha = input$base_alpha,
      R0_sat = 50,
      R_moy = 6,
      A_saison = 0.5,
      T_periode = 365,
      mu_E = input$base_mu_E,
      kappa = input$base_kappa,
      mu_F = input$base_mu_F,
      Lambda_H = 10,
      d_H = 1 / (70 * 365),
      rho = input$base_rho,
      beta = input$base_beta,
      F_max = 100
    )
    
    # Conditions initiales
    C0 <- rep(input$base_C0, input$base_n_parcelles)
    E0 <- 50
    F0 <- 10
    H_S0 <- input$base_H0 * 0.98
    H_I0 <- input$base_H0 * 0.02
    
    y0 <- c(C0, E0, F0, H_S0, H_I0)
    
    # Temps
    times <- seq(0, input$base_duree * 365, by = 1)
    
    # Résolution
    withProgress(message = 'Simulation en cours...', value = 0, {
      solution <- ode(y = y0, times = times, func = modele_base, parms = params)
      incProgress(1)
    })
    
    # Formatage
    sol_df <- as.data.frame(solution)
    colnames(sol_df) <- c("time", paste0("C", 1:input$base_n_parcelles), "E", "F", "H_S", "H_I")
    sol_df$time_years <- sol_df$time / 365
    sol_df$H_total <- sol_df$H_S + sol_df$H_I
    sol_df$prevalence <- sol_df$H_I / sol_df$H_total * 100
    
    return(sol_df)
  })
  
  output$base_plot <- renderPlot({
    req(base_results())
    df <- base_results()
    
    p1 <- ggplot(df) +
      geom_line(aes(x = time_years, y = C1, color = "Parcelle 1"), linewidth = 1) +
      scale_y_log10() +
      labs(x = "Temps (années)", y = "Stock (kg, log)", title = "Contamination parcellaire") +
      theme_minimal(base_size = 13) +
      theme(legend.position = "bottom", legend.title = element_blank())
    
    # Préparer données pour environnement
    df_env <- data.frame(
      time_years = df$time_years,
      Environnement = df$E,
      Ressource = df$F
    )
    df_env_long <- reshape2::melt(df_env, id.vars = "time_years",
                                  variable.name = "Type", value.name = "Stock")
    
    p2 <- ggplot(df_env_long, aes(x = time_years, y = Stock, color = Type)) +
      geom_line(linewidth = 1.2) +
      labs(x = "Temps (années)", y = "Stock (kg)", title = "Environnement et ressource") +
      theme_minimal(base_size = 13) +
      theme(legend.position = "bottom", legend.title = element_blank())
    
    # Préparer données pour populations
    df_pop <- data.frame(
      time_years = df$time_years,
      "Charge élevée" = df$H_I,
      "Faible charge" = df$H_S,
      check.names = FALSE
    )
    df_pop_long <- reshape2::melt(df_pop, id.vars = "time_years",
                                  variable.name = "Type", value.name = "Population")
    
    p3 <- ggplot(df_pop_long, aes(x = time_years, y = Population, color = Type)) +
      geom_line(linewidth = 1.2) +
      labs(x = "Temps (années)", y = "Population", title = "Dynamique des populations") +
      theme_minimal(base_size = 13) +
      theme(legend.position = "bottom", legend.title = element_blank())
    
    p4 <- ggplot(df, aes(x = time_years, y = prevalence)) +
      geom_line(linewidth = 1.3, color = "darkred") +
      labs(x = "Temps (années)", y = "Prévalence (%)", title = "Prévalence charge élevée") +
      theme_minimal(base_size = 13)
    
    grid.arrange(p1, p2, p3, p4, ncol = 2)
  })
  
  output$base_download <- downloadHandler(
    filename = function() {
      paste0("simulation_base_", format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".csv")
    },
    content = function(file) {
      write.csv(base_results(), file, row.names = FALSE)
    }
  )
  
  # ---------------------------------------------------------------------------
  # SIMULATION AVEC CHARGE B(t)
  # ---------------------------------------------------------------------------
  
  charge_results <- eventReactive(input$charge_simulate, {
    params <- list(
      n_parcelles = input$charge_n_parcelles,
      delta = rep(input$charge_delta, input$charge_n_parcelles),
      r0 = rep(0.01, input$charge_n_parcelles),
      alpha = 0.8,
      R0_sat = 50,
      R_moy = 6,
      A_saison = 0.5,
      T_periode = 365,
      mu_E = 0.05,
      kappa = input$charge_kappa,
      mu_F = 0.02,
      Lambda_H = 10,
      d_H = 1 / (70 * 365),
      rho = 0.005,
      beta = input$charge_beta,
      F_max = 100,
      gamma_B = input$charge_gamma_B,
      mu_B = input$charge_mu_B,
      B_star = input$charge_B_star,
      k_sigmoid = input$charge_k_sigmoid
    )
    
    C0 <- rep(1000, input$charge_n_parcelles)
    y0 <- c(C0, 50, 10, 49000, 1000, 0)  # + B0 = 0
    times <- seq(0, input$charge_duree * 365, by = 1)
    
    withProgress(message = 'Simulation en cours...', value = 0, {
      solution <- ode(y = y0, times = times, func = modele_avec_charge, parms = params)
      incProgress(1)
    })
    
    sol_df <- as.data.frame(solution)
    colnames(sol_df) <- c("time", paste0("C", 1:input$charge_n_parcelles), "E", "F", "H_S", "H_I", "B")
    sol_df$time_years <- sol_df$time / 365
    sol_df$H_total <- sol_df$H_S + sol_df$H_I
    sol_df$prevalence <- sol_df$H_I / sol_df$H_total * 100
    
    return(sol_df)
  })
  
  output$charge_plot <- renderPlot({
    req(charge_results())
    df <- charge_results()
    
    p1 <- ggplot(df, aes(x = time_years, y = B)) +
      geom_line(linewidth = 1.3, color = "purple") +
      geom_hline(yintercept = input$charge_B_star, linetype = "dashed", color = "red") +
      labs(x = "Temps (années)", y = "Charge B (µg/L)", title = "Charge corporelle moyenne") +
      theme_minimal(base_size = 13)
    
    # Préparer données pour environnement
    df_env <- data.frame(
      time_years = df$time_years,
      Environnement = df$E,
      Ressource = df$F
    )
    df_env_long <- reshape2::melt(df_env, id.vars = "time_years",
                                  variable.name = "Type", value.name = "Stock")
    
    p2 <- ggplot(df_env_long, aes(x = time_years, y = Stock, color = Type)) +
      geom_line(linewidth = 1.2) +
      labs(x = "Temps (années)", y = "Stock (kg)", title = "Environnement et ressource") +
      theme_minimal(base_size = 13) +
      theme(legend.position = "bottom", legend.title = element_blank())
    
    # Préparer données pour populations
    df_pop <- data.frame(
      time_years = df$time_years,
      "Charge élevée" = df$H_I,
      "Faible charge" = df$H_S,
      check.names = FALSE
    )
    df_pop_long <- reshape2::melt(df_pop, id.vars = "time_years",
                                  variable.name = "Type", value.name = "Population")
    
    p3 <- ggplot(df_pop_long, aes(x = time_years, y = Population, color = Type)) +
      geom_line(linewidth = 1.2) +
      labs(x = "Temps (années)", y = "Population", title = "Dynamique des populations") +
      theme_minimal(base_size = 13) +
      theme(legend.position = "bottom", legend.title = element_blank())
    
    p4 <- ggplot(df, aes(x = time_years, y = prevalence)) +
      geom_line(linewidth = 1.3, color = "darkred") +
      labs(x = "Temps (années)", y = "Prévalence (%)", title = "Prévalence charge élevée") +
      theme_minimal(base_size = 13)
    
    grid.arrange(p1, p2, p3, p4, ncol = 2)
  })
  
  output$charge_download <- downloadHandler(
    filename = function() { paste0("simulation_charge_", format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".csv") },
    content = function(file) { write.csv(charge_results(), file, row.names = FALSE) }
  )
  
  # ---------------------------------------------------------------------------
  # SIMULATION SPATIALISÉE
  # ---------------------------------------------------------------------------
  
  spatial_results <- eventReactive(input$spatial_simulate, {
    n_p <- input$spatial_n_parcelles
    n_b <- input$spatial_n_bassins
    
    # Attribution parcelles -> bassins (distribution simple)
    parcelles_to_bassin <- rep(1:n_b, length.out = n_p)
    
    params <- list(
      n_parcelles = n_p,
      n_bassins = n_b,
      parcelles_to_bassin = parcelles_to_bassin,
      delta = rep(input$spatial_delta, n_p),
      r0 = rep(0.01, n_p),
      alpha = 0.8,
      R0_sat = 50,
      R_moy = 6,
      A_saison = 0.5,
      T_periode = 365,
      mu_E = input$spatial_mu_E,
      kappa = input$spatial_kappa,
      mu_F = 0.02,
      Lambda_H = 10,
      d_H = 1 / (70 * 365),
      rho = 0.005,
      beta = 0.001,
      F_max = 100,
      w_transfer = input$spatial_w_transfer
    )
    
    C0 <- rep(1000, n_p)
    E0 <- rep(50, n_b)
    F0 <- rep(10, n_b)
    H_S0 <- 49000
    H_I0 <- 1000
    
    y0 <- c(C0, E0, F0, H_S0, H_I0)
    times <- seq(0, input$spatial_duree * 365, by = 1)
    
    withProgress(message = 'Simulation spatiale...', value = 0, {
      solution <- ode(y = y0, times = times, func = modele_spatialise, parms = params)
      incProgress(1)
    })
    
    sol_df <- as.data.frame(solution)
    col_names <- c("time", paste0("C", 1:n_p), paste0("E", 1:n_b), paste0("F", 1:n_b), "H_S", "H_I")
    colnames(sol_df) <- col_names
    sol_df$time_years <- sol_df$time / 365
    sol_df$H_total <- sol_df$H_S + sol_df$H_I
    sol_df$prevalence <- sol_df$H_I / sol_df$H_total * 100
    
    return(sol_df)
  })
  
  output$spatial_plot <- renderPlot({
    req(spatial_results())
    df <- spatial_results()
    n_b <- input$spatial_n_bassins
    
    # Agrégation environnement par bassin
    df_E <- df[, c("time_years", paste0("E", 1:n_b))]
    df_E_long <- reshape2::melt(df_E, id.vars = "time_years", variable.name = "Bassin", value.name = "E")
    
    p1 <- ggplot(df_E_long, aes(x = time_years, y = E, color = Bassin)) +
      geom_line(linewidth = 1.1) +
      labs(x = "Temps (années)", y = "Stock environnement (kg)", title = "Contamination par bassin versant") +
      theme_minimal(base_size = 13) +
      theme(legend.position = "bottom")
    
    # Agrégation ressources par bassin
    df_F <- df[, c("time_years", paste0("F", 1:n_b))]
    df_F_long <- reshape2::melt(df_F, id.vars = "time_years", variable.name = "Bassin", value.name = "F")
    
    p2 <- ggplot(df_F_long, aes(x = time_years, y = F, color = Bassin)) +
      geom_line(linewidth = 1.1) +
      labs(x = "Temps (années)", y = "Ressource (kg)", title = "Ressources alimentaires par bassin") +
      theme_minimal(base_size = 13) +
      theme(legend.position = "bottom")
    
    # Préparer données pour populations
    df_pop_spatial <- data.frame(
      time_years = df$time_years,
      "Charge élevée" = df$H_I,
      "Faible charge" = df$H_S,
      check.names = FALSE
    )
    df_pop_spatial_long <- reshape2::melt(df_pop_spatial, id.vars = "time_years",
                                          variable.name = "Type", value.name = "Population")
    
    p3 <- ggplot(df_pop_spatial_long, aes(x = time_years, y = Population, color = Type)) +
      geom_line(linewidth = 1.2) +
      labs(x = "Temps (années)", y = "Population", title = "Dynamique des populations (agrégée)") +
      theme_minimal(base_size = 13) +
      theme(legend.position = "bottom", legend.title = element_blank())
    
    p4 <- ggplot(df, aes(x = time_years, y = prevalence)) +
      geom_line(linewidth = 1.3, color = "darkblue") +
      labs(x = "Temps (années)", y = "Prévalence (%)", title = "Prévalence charge élevée") +
      theme_minimal(base_size = 13)
    
    grid.arrange(p1, p2, p3, p4, ncol = 2)
  })
  
  output$spatial_download <- downloadHandler(
    filename = function() { paste0("simulation_spatial_", format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".csv") },
    content = function(file) { write.csv(spatial_results(), file, row.names = FALSE) }
  )
  
  # ---------------------------------------------------------------------------
  # SIMULATION CHAÎNE DE MARKOV
  # ---------------------------------------------------------------------------
  
  markov_results <- eventReactive(input$markov_simulate, {
    params <- list(
      n_parcelles = input$markov_n_parcelles,
      delta = rep(input$markov_delta, input$markov_n_parcelles),
      r0 = rep(0.01, input$markov_n_parcelles),
      alpha = 0.8,
      R0_sat = 50,
      R_moy = 6,
      A_saison = 0.5,
      T_periode = 365,
      mu_E = 0.05,
      kappa = input$markov_kappa,
      mu_F = 0.02,
      Lambda_H = 10,
      d_H = 1 / (70 * 365),
      rho = input$markov_rho,
      beta_1 = input$markov_beta_1,
      beta_2 = input$markov_beta_2,
      beta_3 = input$markov_beta_3,
      F_max = 100
    )
    
    C0 <- rep(1000, input$markov_n_parcelles)
    y0 <- c(C0, 50, 10, 40000, 8000, 1800, 200)  # H1, H2, H3, H4
    times <- seq(0, input$markov_duree * 365, by = 1)
    
    withProgress(message = 'Simulation Markov...', value = 0, {
      solution <- ode(y = y0, times = times, func = modele_markov, parms = params)
      incProgress(1)
    })
    
    sol_df <- as.data.frame(solution)
    colnames(sol_df) <- c("time", paste0("C", 1:input$markov_n_parcelles), "E", "F", "H1", "H2", "H3", "H4")
    sol_df$time_years <- sol_df$time / 365
    sol_df$H_total <- sol_df$H1 + sol_df$H2 + sol_df$H3 + sol_df$H4
    sol_df$prevalence_elevee <- (sol_df$H4 / sol_df$H_total) * 100
    sol_df$prevalence_moderee <- ((sol_df$H3 + sol_df$H4) / sol_df$H_total) * 100
    
    return(sol_df)
  })
  
  output$markov_plot <- renderPlot({
    req(markov_results())
    df <- markov_results()
    
    # Préparer données pour graphique empilé
    df_stack <- data.frame(
      time_years = df$time_years,
      H1 = df$H1,
      H2 = df$H2,
      H3 = df$H3,
      H4 = df$H4
    )
    
    df_long <- reshape2::melt(df_stack, id.vars = "time_years", 
                              variable.name = "Classe", value.name = "Population")
    df_long$Classe <- factor(df_long$Classe, 
                             levels = c("H4", "H3", "H2", "H1"),
                             labels = c("Classe 4 (élevée)", "Classe 3 (modérée)", 
                                       "Classe 2 (faible)", "Classe 1 (nulle)"))
    
    p1 <- ggplot(df_long, aes(x = time_years, y = Population, fill = Classe)) +
      geom_area(position = "stack", alpha = 0.7) +
      labs(x = "Temps (années)", y = "Population", title = "Distribution par classes de charge") +
      scale_fill_manual(values = c("red", "orange", "yellow", "lightgreen")) +
      theme_minimal(base_size = 13) +
      theme(legend.position = "bottom", legend.title = element_blank())
    
    # Préparer données pour graphique environnement
    df_env <- data.frame(
      time_years = df$time_years,
      Environnement = df$E,
      Ressource = df$F
    )
    df_env_long <- reshape2::melt(df_env, id.vars = "time_years", 
                                  variable.name = "Type", value.name = "Stock")
    
    p2 <- ggplot(df_env_long, aes(x = time_years, y = Stock, color = Type)) +
      geom_line(linewidth = 1.2) +
      labs(x = "Temps (années)", y = "Stock (kg)", title = "Environnement et ressource") +
      theme_minimal(base_size = 13) +
      theme(legend.position = "bottom", legend.title = element_blank())
    
    # Préparer données pour graphique prévalence
    df_prev <- data.frame(
      time_years = df$time_years,
      "Charge élevée (H4)" = df$prevalence_elevee,
      "Charge modérée+ (H3+H4)" = df$prevalence_moderee,
      check.names = FALSE
    )
    df_prev_long <- reshape2::melt(df_prev, id.vars = "time_years",
                                   variable.name = "Niveau", value.name = "Prevalence")
    
    p3 <- ggplot(df_prev_long, aes(x = time_years, y = Prevalence, color = Niveau)) +
      geom_line(linewidth = 1.2) +
      labs(x = "Temps (années)", y = "Prévalence (%)", title = "Prévalence par niveau de charge") +
      theme_minimal(base_size = 13) +
      theme(legend.position = "bottom", legend.title = element_blank())
    
    # Proportions finales
    df_final <- tail(df, 1)
    props <- data.frame(
      Classe = c("H1 (nulle)", "H2 (faible)", "H3 (modérée)", "H4 (élevée)"),
      Proportion = c(df_final$H1, df_final$H2, df_final$H3, df_final$H4) / df_final$H_total * 100
    )
    
    p4 <- ggplot(props, aes(x = Classe, y = Proportion, fill = Classe)) +
      geom_bar(stat = "identity") +
      scale_fill_manual(values = c("lightgreen", "yellow", "orange", "red")) +
      labs(x = "", y = "Proportion (%)", title = "Distribution finale (t = fin)") +
      theme_minimal(base_size = 13) +
      theme(legend.position = "none", axis.text.x = element_text(angle = 15, hjust = 1))
    
    grid.arrange(p1, p2, p3, p4, ncol = 2)
  })
  
  output$markov_download <- downloadHandler(
    filename = function() { paste0("simulation_markov_", format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".csv") },
    content = function(file) { write.csv(markov_results(), file, row.names = FALSE) }
  )
  
  # ---------------------------------------------------------------------------
  # SIMULATION AVEC INTERVENTION
  # ---------------------------------------------------------------------------
  
  interv_results <- eventReactive(input$interv_simulate, {
    params <- list(
      n_parcelles = input$interv_n_parcelles,
      delta = rep(input$interv_delta, input$interv_n_parcelles),
      r0 = rep(0.01, input$interv_n_parcelles),
      alpha = 0.8,
      R0_sat = 50,
      R_moy = 6,
      A_saison = 0.5,
      T_periode = 365,
      mu_E = 0.05,
      kappa = input$interv_kappa,
      mu_F = 0.02,
      Lambda_H = 10,
      d_H = 1 / (70 * 365),
      rho = 0.005,
      beta = 0.001,
      F_max = 100,
      t0_intervention = input$interv_t0 * 365,
      tau_intervention = input$interv_tau * 365,
      reduction_r0 = input$interv_reduction_r0 / 100,
      reduction_beta = input$interv_reduction_beta / 100
    )
    
    C0 <- rep(1000, input$interv_n_parcelles)
    y0 <- c(C0, 50, 10, 49000, 1000)
    times <- seq(0, input$interv_duree * 365, by = 1)
    
    withProgress(message = 'Simulation intervention...', value = 0, {
      solution <- ode(y = y0, times = times, func = modele_intervention, parms = params)
      incProgress(1)
    })
    
    sol_df <- as.data.frame(solution)
    colnames(sol_df) <- c("time", paste0("C", 1:input$interv_n_parcelles), "E", "F", "H_S", "H_I")
    sol_df$time_years <- sol_df$time / 365
    sol_df$H_total <- sol_df$H_S + sol_df$H_I
    sol_df$prevalence <- sol_df$H_I / sol_df$H_total * 100
    
    # Indicateur d'intervention
    sol_df$intervention <- 0.5 * (1 + tanh((sol_df$time - params$t0_intervention) / params$tau_intervention))
    
    return(sol_df)
  })
  
  output$interv_plot <- renderPlot({
    req(interv_results())
    df <- interv_results()
    
    # Ligne verticale pour début intervention
    t0_line <- input$interv_t0
    
    p1 <- ggplot(df, aes(x = time_years, y = prevalence)) +
      geom_rect(xmin = t0_line, xmax = max(df$time_years), ymin = -Inf, ymax = Inf, 
                fill = "lightblue", alpha = 0.01) +
      geom_vline(xintercept = t0_line, linetype = "dashed", color = "blue", linewidth = 1) +
      geom_line(linewidth = 1.3, color = "darkred") +
      annotate("text", x = t0_line + 1, y = max(df$prevalence) * 0.9, 
               label = "Début intervention", hjust = 0, color = "blue") +
      labs(x = "Temps (années)", y = "Prévalence (%)", title = "Impact sur la prévalence") +
      theme_minimal(base_size = 13)
    
    p2 <- ggplot(df, aes(x = time_years)) +
      geom_rect(xmin = t0_line, xmax = max(df$time_years), ymin = -Inf, ymax = Inf, 
                fill = "lightblue", alpha = 0.01) +
      geom_vline(xintercept = t0_line, linetype = "dashed", color = "blue", linewidth = 1) +
      geom_line(aes(y = F), linewidth = 1.2, color = "darkorange") +
      labs(x = "Temps (années)", y = "Ressource (kg)", title = "Impact sur la ressource alimentaire") +
      theme_minimal(base_size = 13)
    
    p3 <- ggplot(df, aes(x = time_years)) +
      geom_rect(xmin = t0_line, xmax = max(df$time_years), ymin = -Inf, ymax = Inf, 
                fill = "lightblue", alpha = 0.01) +
      geom_vline(xintercept = t0_line, linetype = "dashed", color = "blue", linewidth = 1)
    
    # Préparer données pour populations
    df_pop_interv <- data.frame(
      time_years = df$time_years,
      "Charge élevée" = df$H_I,
      "Faible charge" = df$H_S,
      check.names = FALSE
    )
    df_pop_interv_long <- reshape2::melt(df_pop_interv, id.vars = "time_years",
                                         variable.name = "Type", value.name = "Population")
    
    p3 <- p3 + 
      geom_line(data = df_pop_interv_long, 
                aes(x = time_years, y = Population, color = Type), linewidth = 1.2) +
      labs(x = "Temps (années)", y = "Population", title = "Dynamique des populations") +
      theme_minimal(base_size = 13) +
      theme(legend.position = "bottom", legend.title = element_blank())
    
    p4 <- ggplot(df, aes(x = time_years, y = intervention * 100)) +
      geom_area(fill = "steelblue", alpha = 0.5) +
      labs(x = "Temps (années)", y = "Niveau d'intervention (%)", 
           title = "Progression de l'intervention") +
      theme_minimal(base_size = 13)
    
    grid.arrange(p1, p2, p3, p4, ncol = 2)
  })
  
  output$interv_download <- downloadHandler(
    filename = function() { paste0(
  "simulation_intervention_",
  format(Sys.time(), "%Y-%m-%d_%H-%M-%S"),
  ".csv"
) },
    content = function(file) { write.csv(interv_results(), file, row.names = FALSE) }
  )
  
  # ---------------------------------------------------------------------------
  # COMPARAISON DES MODÈLES
  # ---------------------------------------------------------------------------
  
  comp_results <- eventReactive(input$comp_simulate, {
    # Paramètres communs
    duree <- input$comp_duree * 365
    C0_val <- input$comp_C0
    H0_val <- input$comp_H0
    
    times <- seq(0, duree, by = 1)
    
    # 1. Modèle de base
    params_base <- list(n_parcelles = 3, delta = rep(0.001, 3), r0 = rep(0.01, 3),
                        alpha = 0.8, R0_sat = 50, R_moy = 6, A_saison = 0.5, T_periode = 365,
                        mu_E = 0.05, kappa = 0.03, mu_F = 0.02, Lambda_H = 10, 
                        d_H = 1/(70*365), rho = 0.005, beta = 0.001, F_max = 100)
    y0_base <- c(rep(C0_val, 3), 50, 10, H0_val*0.98, H0_val*0.02)
    
    sol_base <- ode(y = y0_base, times = times, func = modele_base, parms = params_base)
    df_base <- as.data.frame(sol_base)
    df_base$model <- "Base"
    df_base$prevalence <- df_base[, 7] / (df_base[, 6] + df_base[, 7]) * 100
    
    # 2. Modèle avec charge
    params_charge <- c(params_base, list(gamma_B = 0.01, mu_B = 0.005, B_star = 1, k_sigmoid = 5))
    y0_charge <- c(rep(C0_val, 3), 50, 10, H0_val*0.98, H0_val*0.02, 0)
    
    sol_charge <- ode(y = y0_charge, times = times, func = modele_avec_charge, parms = params_charge)
    df_charge <- as.data.frame(sol_charge)
    df_charge$model <- "Charge B(t)"
    df_charge$prevalence <- df_charge[, 7] / (df_charge[, 6] + df_charge[, 7]) * 100
    
    # 3. Modèle Markov (somme H3 + H4 comme "exposés")
    params_markov <- c(params_base, list(beta_1 = 0.0005, beta_2 = 0.0007, beta_3 = 0.001))
    y0_markov <- c(rep(C0_val, 3), 50, 10, H0_val*0.8, H0_val*0.16, H0_val*0.03, H0_val*0.01)
    
    sol_markov <- ode(y = y0_markov, times = times, func = modele_markov, parms = params_markov)
    df_markov <- as.data.frame(sol_markov)
    df_markov$model <- "Markov"
    df_markov$prevalence <- (df_markov[, 8] + df_markov[, 9]) / 
      (df_markov[, 6] + df_markov[, 7] + df_markov[, 8] + df_markov[, 9]) * 100
    
    # Compilation
    comparison <- data.frame(
      time_years = df_base$time / 365,
      Base = df_base$prevalence,
      Charge = df_charge$prevalence,
      Markov = df_markov$prevalence
    )
    
    return(comparison)
  })
  
  output$comp_plot <- renderPlot({
    req(comp_results())
    df <- comp_results()
    
    df_long <- reshape2::melt(df, id.vars = "time_years", variable.name = "Modèle", value.name = "Prévalence")
    
    ggplot(df_long, aes(x = time_years, y = Prévalence, color = Modèle)) +
      geom_line(linewidth = 1.4) +
      labs(x = "Temps (années)", y = "Prévalence de charge élevée (%)", 
           title = "Comparaison des modèles : prévalence de l'exposition") +
      scale_color_manual(values = c("Base" = "darkred", "Charge" = "purple", "Markov" = "darkblue")) +
      theme_minimal(base_size = 15) +
      theme(legend.position = "bottom", legend.title = element_blank())
  })
}

# =============================================================================
# LANCEMENT DE L'APPLICATION
# =============================================================================

shinyApp(ui = ui, server = server)
