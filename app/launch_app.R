# Script de lancement simplifié pour l'application Shiny
# Double-cliquez sur ce fichier pour lancer l'application

cat("============================================\n")
cat("Application Shiny - Modélisation Chlordécone\n")
cat("============================================\n\n")

# Vérifier et installer les packages nécessaires
cat("Vérification des packages...\n")

packages <- c("shiny", "shinydashboard", "deSolve", "ggplot2", 
              "gridExtra", "DT", "reshape2")

manquants <- packages[!(packages %in% installed.packages()[,"Package"])]

if(length(manquants) > 0) {
  cat("Installation des packages manquants:", paste(manquants, collapse=", "), "\n")
  install.packages(manquants, repos = "https://cloud.r-project.org/")
}

cat("✓ Tous les packages sont disponibles\n\n")

# Charger shiny
library(shiny)

# Lancer l'application
cat("Lancement de l'application...\n")
cat("L'application s'ouvrira dans votre navigateur.\n")
cat("Pour arrêter, fermez cette fenêtre ou appuyez sur Ctrl+C\n\n")

runApp(launch.browser = TRUE)
