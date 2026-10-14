# Application Shiny - Modélisation de l'exposition humaine au chlordécone
# Auteur: Geovany Batista Polo Laguerre
# Date: 2026-01-23
#
# Les modèles ODE, la simulation et les graphiques sont dans le dossier R/
# (chargé automatiquement par Shiny) : models.R, plots.R, simulation.R.

library(shiny)
library(deSolve)
library(ggplot2)
library(gridExtra)
library(shinydashboard)

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
    ),
    hr(),
    radioButtons(
      "scenario_env", "Scénario environnemental",
      choices = c("Preprint (δ = 0,001 ; r0 = 0,01)" = "preprint",
                  "Persistance longue (δ = 5e-5 ; r0 = 4e-5)" = "persist"),
      selected = "preprint"
    ),
    p("Le scénario règle δ et r0 dans tous les onglets. Persistance longue : demi-vie du sol d'environ 15 ans.",
      style = "padding: 0 15px; font-size: 12px; color: #b8c7ce;")
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
            sliderInput("base_n_parcelles", "Nombre de parcelles", 1, 7, 3, step = 1),
            sliderInput("base_C0", "Stock initial (kg)", 100, 2000, 1000, step = 100),
            sliderInput("base_delta", "Taux dégradation (j⁻¹)", 0.00001, 0.01, 0.001, step = 0.00001),
            sliderInput("base_r0", "Ruissellement base (j⁻¹)", 0.00001, 0.05, 0.01, step = 0.00001),
            
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
            sliderInput("charge_n_parcelles", "Nombre de parcelles", 1, 7, 3, step = 1),
            sliderInput("charge_delta", "Taux dégradation (j⁻¹)", 0.00001, 0.01, 0.001, step = 0.00001),
            sliderInput("charge_kappa", "Transfert E→F (j⁻¹)", 0.01, 0.1, 0.03, step = 0.01),
            sliderInput("charge_beta", "Taux exposition (j⁻¹·kg⁻¹)", 0.0001, 0.01, 0.001, step = 0.0001),
            
            h4("Paramètres spécifiques B(t)"),
            sliderInput("charge_gamma_B", "Coeff. absorption γ (µg·L⁻¹·kg⁻¹·pers.)", 0.1, 100, 2.5, step = 0.1),
            sliderInput("charge_k_trans", "Vitesse de transition S↔I (j⁻¹)", 0.001, 0.05, 0.01, step = 0.001),
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
            sliderInput("spatial_n_parcelles", "Nombre de parcelles", 2, 7, 4, step = 1),
            sliderInput("spatial_n_bassins", "Nombre de bassins versants", 2, 4, 3, step = 1),
            sliderInput("spatial_w_transfer", "Taux transfert inter-bassins (j⁻¹)", 0, 0.1, 0.02, step = 0.01),
            
            h4("Paramètres environnementaux"),
            sliderInput("spatial_delta", "Taux dégradation (j⁻¹)", 0.00001, 0.01, 0.001, step = 0.00001),
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
            sliderInput("markov_n_parcelles", "Nombre de parcelles", 1, 7, 3, step = 1),
            sliderInput("markov_delta", "Taux dégradation (j⁻¹)", 0.00001, 0.01, 0.001, step = 0.00001),
            sliderInput("markov_kappa", "Transfert E→F (j⁻¹)", 0.01, 0.1, 0.03, step = 0.01),
            
            h4("Taux de transition (exposition)"),
            sliderInput("markov_beta_1", "β₁: Classe 1→2 (j⁻¹·kg⁻¹)", 0.0001, 0.01, 0.0005, step = 0.0001),
            sliderInput("markov_beta_2", "β₂: Classe 2→3 (j⁻¹·kg⁻¹)", 0.0001, 0.01, 0.0007, step = 0.0001),
            sliderInput("markov_beta_3", "β₃: Classe 3→4 (j⁻¹·kg⁻¹)", 0.0001, 0.01, 0.001, step = 0.0001),
            
            h4("Taux de dépuration"),
            sliderInput("markov_rho_1", "ρ₁: Classe 2→1 (j⁻¹)", 0.0005, 0.02, 0.0025, step = 0.0005),
            sliderInput("markov_rho_2", "ρ₂: Classe 3→2 (j⁻¹)", 0.0005, 0.02, 0.0035, step = 0.0005),
            sliderInput("markov_rho_3", "ρ₃: Classe 4→3 (j⁻¹)", 0.0005, 0.02, 0.005, step = 0.0005),
            
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
            sliderInput("interv_t0", "Début intervention (années)", 0, 20, 0, step = 0.5),
            sliderInput("interv_tau", "Durée transition (années)", 0.5, 5, 1, step = 0.5),
            sliderInput("interv_reduction_r0", "Réduction ruissellement (%)", 0, 80, 40, step = 5),
            sliderInput("interv_reduction_beta", "Réduction exposition (%)", 0, 80, 40, step = 5),
            sliderInput("interv_aug_muF", "Augmentation renouvellement ressource µF (%)", 0, 200, 0, step = 10),

            h4("Paramètres de base"),
            sliderInput("interv_n_parcelles", "Nombre de parcelles", 1, 7, 3, step = 1),
            sliderInput("interv_prev0", "Prévalence initiale H_I/H (%)", 0, 50, 20, step = 1),
            sliderInput("interv_delta", "Taux dégradation (j⁻¹)", 0.00001, 0.01, 0.001, step = 0.00001),
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
  # SCÉNARIO ENVIRONNEMENTAL (preprint vs persistance longue)
  # ---------------------------------------------------------------------------

  delta_scen <- reactive(if (identical(input$scenario_env, "persist")) 5e-5 else 0.001)
  r0_scen    <- reactive(if (identical(input$scenario_env, "persist")) 4e-5 else 0.01)
  # γ ajusté pour que B approche B* au niveau de F de chaque scénario (F ~ 100 en pic transitoire, ~ 4 en régime persistant)
  gamma_scen <- reactive(if (identical(input$scenario_env, "persist")) 60 else 2.5)

  observeEvent(input$scenario_env, {
    for (id in c("base_delta", "charge_delta", "spatial_delta", "markov_delta", "interv_delta")) {
      updateSliderInput(session, id, value = delta_scen())
    }
    updateSliderInput(session, "base_r0", value = r0_scen())
    updateSliderInput(session, "charge_gamma_B", value = gamma_scen())
  }, ignoreInit = TRUE)

  # Nom de fichier horodaté pour les exports CSV
  nom_export <- function(prefixe) {
    paste0("simulation_", prefixe, "_", format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".csv")
  }

  # ---------------------------------------------------------------------------
  # SIMULATION MODÈLE DE BASE
  # ---------------------------------------------------------------------------

  base_results <- eventReactive(input$base_simulate, {
    n <- input$base_n_parcelles
    params <- params_defaut(
      n, delta = input$base_delta, r0 = input$base_r0, H0 = input$base_H0,
      alpha = input$base_alpha, mu_E = input$base_mu_E, kappa = input$base_kappa,
      mu_F = input$base_mu_F, rho = input$base_rho, beta = input$base_beta
    )
    y0 <- c(rep(input$base_C0, n), 50, 10, input$base_H0 * 0.98, input$base_H0 * 0.02)

    withProgress(message = "Simulation en cours...", value = 0, {
      df <- resoudre_edo(modele_base, y0, params, input$base_duree, "base")
      incProgress(1)
    })
    ajouter_prevalence(df)
  })

  output$base_plot <- renderPlot({
    req(base_results())
    grid.arrange(grobs = plots_base(base_results()), ncol = 2)
  })

  output$base_download <- downloadHandler(
    filename = function() nom_export("base"),
    content = function(file) write.csv(base_results(), file, row.names = FALSE)
  )

  # ---------------------------------------------------------------------------
  # SIMULATION AVEC CHARGE B(t)
  # ---------------------------------------------------------------------------

  charge_results <- eventReactive(input$charge_simulate, {
    n <- input$charge_n_parcelles
    params <- params_defaut(
      n, delta = input$charge_delta, r0 = r0_scen(),
      kappa = input$charge_kappa, beta = input$charge_beta,
      gamma_B = input$charge_gamma_B, k_trans = input$charge_k_trans,
      mu_B = input$charge_mu_B, B_star = input$charge_B_star, k_sigmoid = input$charge_k_sigmoid
    )
    y0 <- c(rep(1000, n), 50, 10, 49000, 1000, 0)  # + B0 = 0

    withProgress(message = "Simulation en cours...", value = 0, {
      df <- resoudre_edo(modele_avec_charge, y0, params, input$charge_duree, "charge")
      incProgress(1)
    })
    ajouter_prevalence(df)
  })

  output$charge_plot <- renderPlot({
    req(charge_results())
    grid.arrange(grobs = plots_charge(charge_results(), input$charge_B_star), ncol = 2)
  })

  output$charge_download <- downloadHandler(
    filename = function() nom_export("charge"),
    content = function(file) write.csv(charge_results(), file, row.names = FALSE)
  )

  # ---------------------------------------------------------------------------
  # SIMULATION SPATIALISÉE
  # ---------------------------------------------------------------------------

  spatial_results <- eventReactive(input$spatial_simulate, {
    n_p <- input$spatial_n_parcelles
    n_b <- input$spatial_n_bassins

    params <- params_defaut(
      n_p, delta = input$spatial_delta, r0 = r0_scen(),
      mu_E = input$spatial_mu_E, kappa = input$spatial_kappa,
      n_bassins = n_b,
      parcelles_to_bassin = rep(1:n_b, length.out = n_p),  # attribution simple parcelles -> bassins
      w_transfer = input$spatial_w_transfer
    )
    y0 <- c(rep(1000, n_p), rep(50, n_b), rep(10, n_b), 49000, 1000)

    withProgress(message = "Simulation spatiale...", value = 0, {
      df <- resoudre_edo(modele_spatialise, y0, params, input$spatial_duree, "spatial", n_bassins = n_b)
      incProgress(1)
    })
    ajouter_prevalence(df)
  })

  output$spatial_plot <- renderPlot({
    req(spatial_results())
    grid.arrange(grobs = plots_spatial(spatial_results(), input$spatial_n_bassins), ncol = 2)
  })

  output$spatial_download <- downloadHandler(
    filename = function() nom_export("spatial"),
    content = function(file) write.csv(spatial_results(), file, row.names = FALSE)
  )

  # ---------------------------------------------------------------------------
  # SIMULATION CHAÎNE DE MARKOV
  # ---------------------------------------------------------------------------

  markov_results <- eventReactive(input$markov_simulate, {
    n <- input$markov_n_parcelles
    params <- params_defaut(
      n, delta = input$markov_delta, r0 = r0_scen(), kappa = input$markov_kappa,
      beta_1 = input$markov_beta_1, beta_2 = input$markov_beta_2, beta_3 = input$markov_beta_3,
      rho_1 = input$markov_rho_1, rho_2 = input$markov_rho_2, rho_3 = input$markov_rho_3
    )
    y0 <- c(rep(1000, n), 50, 10, 40000, 8000, 1800, 200)  # H1, H2, H3, H4

    withProgress(message = "Simulation Markov...", value = 0, {
      df <- resoudre_edo(modele_markov, y0, params, input$markov_duree, "markov")
      incProgress(1)
    })
    ajouter_prevalence(df)
  })

  output$markov_plot <- renderPlot({
    req(markov_results())
    grid.arrange(grobs = plots_markov(markov_results()), ncol = 2)
  })

  output$markov_download <- downloadHandler(
    filename = function() nom_export("markov"),
    content = function(file) write.csv(markov_results(), file, row.names = FALSE)
  )

  # ---------------------------------------------------------------------------
  # SIMULATION AVEC INTERVENTION
  # ---------------------------------------------------------------------------

  interv_results <- eventReactive(input$interv_simulate, {
    n <- input$interv_n_parcelles
    params <- params_defaut(
      n, delta = input$interv_delta, r0 = r0_scen(), kappa = input$interv_kappa,
      t0_intervention = input$interv_t0 * 365,
      tau_intervention = input$interv_tau * 365,
      reduction_r0 = input$interv_reduction_r0 / 100,
      reduction_beta = input$interv_reduction_beta / 100,
      augmentation_muF = input$interv_aug_muF / 100
    )
    prev0 <- input$interv_prev0 / 100
    y0 <- c(rep(1000, n), 50, 10, 50000 * (1 - prev0), 50000 * prev0)

    withProgress(message = "Simulation intervention...", value = 0, {
      df <- simuler_intervention(params, y0, input$interv_duree)
      incProgress(1)
    })
    df
  })

  output$interv_plot <- renderPlot({
    req(interv_results())
    grid.arrange(grobs = plots_intervention(interv_results(), input$interv_t0), ncol = 2)
  })

  output$interv_download <- downloadHandler(
    filename = function() nom_export("intervention"),
    content = function(file) write.csv(interv_results(), file, row.names = FALSE)
  )

  # ---------------------------------------------------------------------------
  # COMPARAISON DES MODÈLES
  # ---------------------------------------------------------------------------

  comp_results <- eventReactive(input$comp_simulate, {
    simuler_comparaison(input$comp_duree, input$comp_C0, input$comp_H0,
                        delta = delta_scen(), r0 = r0_scen(), gamma_B = gamma_scen())
  })

  output$comp_plot <- renderPlot({
    req(comp_results())
    plot_comparaison(comp_results())
  })
}

# =============================================================================
# LANCEMENT DE L'APPLICATION
# =============================================================================

shinyApp(ui = ui, server = server)
