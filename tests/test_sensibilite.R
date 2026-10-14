# Tests du module de sensibilité (R/sensibilite.R) :
# estimateurs de Sobol validés sur la fonction d'Ishigami (indices connus analytiquement),
# élasticités validées sur des fonctions simples, et cohérence des sorties du modèle.
# Usage (depuis la racine du dépôt) : Rscript tests/test_sensibilite.R

suppressMessages(library(deSolve))
source("app/R/models.R")
source("app/R/simulation.R")
source("app/R/sensibilite.R")

ok <- function(nom) cat("OK ", nom, "\n")

# 1. Sobol sur Ishigami : f = sin(x1) + 7 sin(x2)^2 + 0,1 x3^4 sin(x1), x_i ~ U(-pi, pi)
#    Valeurs exactes : S1 = (0,3139, 0,4424, 0) ; ST = (0,5576, 0,4424, 0,2437)
ishigami <- function(x) c(y = sin(x[["x1"]]) + 7 * sin(x[["x2"]])^2 + 0.1 * x[["x3"]]^4 * sin(x[["x1"]]))
bas <- c(x1 = -pi, x2 = -pi, x3 = -pi)
haut <- c(x1 = pi, x2 = pi, x3 = pi)
res <- indices_sobol(ishigami, bas, haut, N = 20000, seed = 42, echelle_log = FALSE, B = 50)
S1_exact <- c(x1 = 0.3139, x2 = 0.4424, x3 = 0)
ST_exact <- c(x1 = 0.5576, x2 = 0.4424, x3 = 0.2437)
stopifnot(all(abs(res$S1 - S1_exact[res$parametre]) < 0.03),
          all(abs(res$ST - ST_exact[res$parametre]) < 0.03))
# Les intervalles bootstrap contiennent l'estimation ponctuelle
stopifnot(all(res$S1_inf <= res$S1 + 1e-9), all(res$S1 <= res$S1_sup + 1e-9),
          all(res$ST_inf <= res$ST + 1e-9), all(res$ST <= res$ST_sup + 1e-9))
ok("Sobol sur Ishigami (S1 et ST à 0,03 près)")

# 1b. Invariance par décalage : ajouter une grande constante à la sortie ne change pas les indices
decale <- function(x) ishigami(x) + 1000
res2 <- indices_sobol(decale, bas, haut, N = 20000, seed = 42, echelle_log = FALSE, B = 10)
stopifnot(max(abs(res2$S1 - res$S1)) < 1e-6, max(abs(res2$ST - res$ST)) < 1e-6)
ok("Sobol invariant par décalage de la sortie (centrage)")

# 2. Sobol sur une fonction additive : S1 = ST = part de variance, pas d'interaction
additive <- function(x) c(y = 2 * x[["a"]] + x[["b"]])
r <- indices_sobol(additive, c(a = 0, b = 0), c(a = 1, b = 1), N = 20000, seed = 7, echelle_log = FALSE, B = 20)
# Var(2a) = 4/12, Var(b) = 1/12 -> parts 0,8 et 0,2
stopifnot(abs(r$S1[r$parametre == "a"] - 0.8) < 0.03, abs(r$ST[r$parametre == "a"] - 0.8) < 0.03,
          abs(r$S1[r$parametre == "b"] - 0.2) < 0.03)
ok("Sobol sur fonction additive (0,8 / 0,2)")

# 3. OAT : élasticité d'une loi de puissance y = a^2 * b est 2 pour a et 1 pour b
puissance <- function(x) c(y = x[["a"]]^2 * x[["b"]])
o <- analyse_oat(puissance, c(a = 2, b = 3))
stopifnot(abs(o$elasticite[o$parametre == "a"] - 2) < 0.05,
          abs(o$elasticite[o$parametre == "b"] - 1) < 1e-6,
          all.equal(o$y_bas[o$parametre == "a"], 1^2 * 3),   # a x 0,5
          all.equal(o$y_haut[o$parametre == "b"], 4 * 6))    # b x 2
ok("OAT : élasticités 2 et 1, effets x0,5 et x2")

# 4. Sorties du modèle : finies, prévalence initiale respectée, F_pic cohérent
pars <- parametres_sensibilite("preprint")
ref <- setNames(pars$ref, pars$nom)
s <- sorties_modele(ref)
stopifnot(identical(names(s), names(SORTIES_SENSIBILITE)), all(is.finite(s)),
          s[["prevalence_max"]] >= 20 - 1e-6, s[["F_pic"]] > 10)
# Le pas de 5 jours reproduit le pas d'un jour à moins de 1 % près
params <- params_defaut(3, ref[["delta"]], ref[["r0"]])
d1 <- resoudre_edo(modele_base, c(rep(1000, 3), 50, 10, 40000, 10000), params, 20, "base", pas_jours = 1)
stopifnot(abs(max(d1$F) - s[["F_pic"]]) / max(d1$F) < 0.01,
          abs(max(d1$H_I / (d1$H_S + d1$H_I) * 100) - s[["prevalence_max"]]) < 0.1)
ok("sorties_modele (pas de 5 jours = pas d'un jour à 1 %)")

# 5. Paramètres de référence des deux scénarios
pp <- parametres_sensibilite("persist")
stopifnot(pp$ref[pp$nom == "delta"] == 5e-5, pp$ref[pp$nom == "r0"] == 4e-5,
          pars$ref[pars$nom == "delta"] == 1e-3, nrow(pp) == 9)
ok("parametres_sensibilite")
