# Lancement de l'application Shiny - Modélisation de l'exposition au chlordécone
#
# Utilisation (depuis n'importe quel dossier) :
#   Rscript app/run.R          # depuis la racine du dépôt
#   source("app/run.R")        # depuis une console R ouverte à la racine
#   app\launch.bat             # double-clic ou terminal Windows
#
# Pour retrouver exactement les versions de packages du projet, utiliser renv :
#   renv::restore()

packages <- c("shiny", "shinydashboard", "deSolve", "ggplot2", "gridExtra", "reshape2")

manquants <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(manquants) > 0) {
  cat("Installation des packages manquants :", paste(manquants, collapse = ", "), "\n")
  install.packages(manquants, repos = "https://cloud.r-project.org/")
}

# Dossier de l'application : celui de ce script, quelle que soit la façon de le lancer
dossier_script <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  fichier <- sub("^--file=", "", args[grepl("^--file=", args)])
  if (length(fichier) == 1) return(dirname(normalizePath(fichier)))                 # Rscript
  ofile <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
  if (!is.null(ofile)) return(dirname(normalizePath(ofile)))                        # source()
  if (file.exists("app.R")) return(getwd())                                         # console dans app/
  if (file.exists(file.path("app", "app.R"))) return(normalizePath("app"))          # console à la racine
  stop("Impossible de localiser app.R : lancez le script depuis la racine du dépôt ou le dossier app/.")
}

app_dir <- dossier_script()
cat("Application :", app_dir, "\n")
cat("Elle s'ouvrira dans votre navigateur. Pour l'arreter : Ctrl+C (ou Echap dans RStudio).\n\n")

shiny::runApp(appDir = app_dir, launch.browser = TRUE)
