# Script de lancement de l'application Shiny
# Modélisation de l'exposition au chlordécone

# Installation des packages nécessaires (si non installés)
packages <- c("shiny", "shinydashboard", "deSolve", "ggplot2", 
              "gridExtra", "DT", "reshape2")

install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages) > 0) {
    cat("Installation des packages manquants:", paste(new_packages, collapse = ", "), "\n")
    install.packages(new_packages, dependencies = TRUE)
  } else {
    cat("Tous les packages sont déjà installés.\n")
  }
}

install_if_missing(packages)

# Chargement des packages
cat("\nChargement des packages...\n")
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(deSolve)
  library(ggplot2)
  library(gridExtra)
  library(DT)
  library(reshape2)
})

cat("✓ Packages chargés avec succès\n\n")

# Lancement de l'application
cat("Lancement de l'application Shiny...\n")
cat("L'application s'ouvrira dans votre navigateur par défaut.\n")
cat("Pour arrêter l'application, appuyez sur Ctrl+C ou Esc dans la console R.\n\n")

# Déterminer le chemin du dossier contenant ce script
app_dir <- dirname(sys.frame(1)$ofile)
if(length(app_dir) == 0 || app_dir == "") {
  # Si exécuté depuis RStudio ou interactivement
  app_dir <- getwd()
}

# Lancement
runApp(appDir = app_dir, launch.browser = TRUE)
