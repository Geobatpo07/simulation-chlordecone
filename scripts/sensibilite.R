# Analyse de sensibilité hors application (parallélisée) : écrit des CSV dans results/.
#
# Usage (depuis la racine du dépôt) :
#   Rscript scripts/sensibilite.R [scenarios] [N] [annees] [prev0_pct] [coeurs]
# Exemple :
#   Rscript scripts/sensibilite.R preprint,persist 1024 20 20 8
#
# Sorties : results/sensibilite_<scenario>_oat.csv et results/sensibilite_<scenario>_sobol.csv

args <- commandArgs(trailingOnly = TRUE)
scenarios <- strsplit(if (length(args) >= 1) args[1] else "preprint,persist", ",")[[1]]
N <- if (length(args) >= 2) as.integer(args[2]) else 512L
annees <- if (length(args) >= 3) as.numeric(args[3]) else 20
prev0 <- (if (length(args) >= 4) as.numeric(args[4]) else 20) / 100
coeurs <- if (length(args) >= 5) as.integer(args[5]) else max(1L, parallel::detectCores() - 2L)

suppressMessages(library(deSolve))
fichiers <- file.path("app", "R", c("models.R", "simulation.R", "sensibilite.R"))
for (f in fichiers) source(f)

dir.create("results", showWarnings = FALSE)
# Les noeuds ne relisent pas .Rprofile (pas de second démarrage de renv) et reprennent les bibliothèques du maître
cl <- parallel::makeCluster(coeurs, rscript_args = "--no-init-file")
on.exit(parallel::stopCluster(cl), add = TRUE)
invisible(parallel::clusterCall(cl, function(chemins) .libPaths(chemins), .libPaths()))
parallel::clusterExport(cl, "fichiers")
invisible(parallel::clusterEvalQ(cl, {
  suppressMessages(library(deSolve))
  for (f in fichiers) source(f)
}))

# Fonction évaluée sur les noeuds : l'environnement local est envoyé avec la fermeture
f <- local({
  a <- annees
  p <- prev0
  function(valeurs) sorties_modele(valeurs, annees = a, prev0 = p)
}))
applique <- function(X, f) parallel::parLapply(cl, X, f)

for (sc in scenarios) {
  pars <- parametres_sensibilite(sc)
  ref <- setNames(pars$ref, pars$nom)
  cat(sprintf("== Scénario %s : %d simulations Sobol sur %d coeurs\n", sc, N * (length(ref) + 2), coeurs))

  t0 <- Sys.time()
  oat <- analyse_oat(f, ref)
  write.csv(oat, file.path("results", sprintf("sensibilite_%s_oat.csv", sc)), row.names = FALSE)

  sobol <- sobol_modele(ref, f, N = N, seed = 2026, applique = applique)
  write.csv(sobol, file.path("results", sprintf("sensibilite_%s_sobol.csv", sc)), row.names = FALSE)
  cat(sprintf("   terminé en %.0f s\n", as.numeric(Sys.time() - t0, units = "secs")))
}
