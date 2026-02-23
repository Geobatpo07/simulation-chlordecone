# Guide de démarrage rapide

# Application Shiny - Modélisation chlordécone

## 🚀 Lancement en 3 étapes

### Étape 1 : Ouvrir RStudio

Double-cliquez sur le fichier `app.R` pour l'ouvrir dans RStudio

### Étape 2 : Installer les dépendances (première fois seulement)

Dans la console R, exécutez :

``` r
source("run.R")
```

OU exécutez manuellement :

``` r
install.packages(c("shiny", "shinydashboard", "deSolve", 
                   "ggplot2", "gridExtra", "DT", "reshape2"))
```

### Étape 3 : Lancer l'application

-   **Option A** : Cliquez sur le bouton "Run App" en haut à droite dans RStudio
-   **Option B** : Dans la console R :

``` r
shiny::runApp()
```

## 📱 Navigation dans l'application

### Menu principal (barre latérale gauche)

1.  **🏠 Accueil** : Vue d'ensemble et instructions
2.  **📈 Modèle de base** : Modèle CC1 (6 compartiments)
3.  **💓 Variable charge B(t)** : Extension avec biomarqueur
4.  **🗺️ Spatialisation** : Multi-bassins versants
5.  **🎲 Chaîne de Markov** : 4 classes de charge
6.  **💉 Intervention** : Politiques publiques
7.  **⚖️ Comparaison** : Comparaison multi-modèles
8.  **ℹ️ À propos** : Informations et références

## 🎯 Exemple d'utilisation : Modèle de base

### 1. Cliquez sur "Modèle de base" dans le menu

### 2. Ajustez les paramètres (panneau de gauche)

-   **Parcelles** : Nombre de parcelles = 3
-   **Stock initial** : 1000 kg
-   **Taux de dégradation** : 0.001 j⁻¹ (demi-vie \~2 ans)
-   **Ruissellement** : 0.01 j⁻¹
-   **Amplification pluie** : 0.8
-   **Durée de simulation** : 20 ans

### 3. Cliquez sur "Simuler" (bouton vert)

### 4. Explorez les résultats (panneau de droite)

-   **Graphique 1** : Contamination parcellaire (échelle log)
-   **Graphique 2** : Environnement et ressource alimentaire
-   **Graphique 3** : Dynamique des populations (H_S, H_I)
-   **Graphique 4** : Prévalence de charge élevée (%)

### 5. Téléchargez les résultats (optionnel)

Cliquez sur "Télécharger les résultats" pour obtenir un fichier CSV

## 🧪 Scénarios suggérés

### Scénario 1 : Impact de la dégradation

-   Varier δ de 0.0005 à 0.002
-   Observer l'effet sur la décroissance de C et la prévalence finale

### Scénario 2 : Rôle de la pluviométrie

-   Varier α de 0 (pas d'effet) à 2 (fort effet)
-   Comparer les fluctuations saisonnières de E et F

### Scénario 3 : Efficacité d'une intervention

-   Aller dans l'onglet "Intervention"
-   Définir t₀ = 5 ans
-   Réduction r₀ = 40%, réduction β = 40%
-   Comparer prévalence avant/après

### Scénario 4 : Comparaison des modèles

-   Aller dans l'onglet "Comparaison"
-   Lancer la simulation comparative
-   Observer les différences de prédictions

## 💡 Conseils pratiques

### ✅ Bonnes pratiques

-   Commencer avec les paramètres par défaut
-   Modifier un paramètre à la fois pour comprendre son effet
-   Utiliser des durées de 10-20 ans pour observer les dynamiques long terme
-   Télécharger les résultats pour analyses approfondies

### ⚠️ À éviter

-   Paramètres physiquement impossibles (négatifs)
-   Durées trop longues (\>50 ans) sans justification
-   Valeurs extrêmes sans calibration

### 🐛 En cas de problème

1.  Vérifier que tous les packages sont installés
2.  Redémarrer la session R (Session → Restart R)
3.  Vérifier les messages d'erreur dans la console
4.  Consulter le README.md pour plus de détails

## 📊 Interprétation des résultats

### Prévalence de charge élevée

-   **\< 5%** : Exposition faible
-   **5-15%** : Exposition modérée
-   **\> 15%** : Exposition préoccupante

### Décroissance de C (parcelles)

-   Suit une exponentielle décroissante
-   Pente dépend de δ (dégradation) et r₀ (ruissellement)

### Dynamique de E (environnement)

-   Phase transitoire : accumulation initiale
-   Quasi-équilibre : balance flux entrants/sortants
-   Fluctuations saisonnières dues à R(t)

### Évolution de H_I (population exposée)

-   Augmentation progressive (effet cumulatif)
-   Peut atteindre un plateau si F se stabilise

## 🔧 Personnalisation avancée

### Modifier les conditions initiales

Éditer directement dans `app.R` les lignes :

``` r
C0 <- rep(input$base_C0, input$base_n_parcelles)
E0 <- 50  # Modifier ici
F0 <- 10  # Modifier ici
```

### Ajouter de nouveaux graphiques

Utiliser ggplot2 dans la section `output$..._plot`

### Changer la période de forçage

Modifier `T_periode = 365` pour d'autres cycles

## 📚 Ressources supplémentaires

-   **README.md** : Documentation complète
-   **app.R** : Code source commenté
-   **Présentation CC2** : Contexte scientifique (presentation_cc2_chlordecone_final.qmd)
-   **Rapport CC1** : Fondements mathématiques (cc_chlordecone.Rmd)

## 🎓 Pour aller plus loin

### Calibration avec données réelles

1.  Collecter données empiriques (sols, biote, biomarqueurs)
2.  Définir fonction objectif (distance modèle-données)
3.  Optimisation (optim, GA, DEoptim)

### Analyse de sensibilité

``` r
library(sensitivity)
# Définir plage de variation des paramètres
# Méthode de Morris ou Sobol
```

### Export pour publications

``` r
# Sauvegarder graphiques haute résolution
ggsave("figure.pdf", width = 10, height = 6, dpi = 300)
```

## ✉️ Contact et support

**Questions** : lgeobatpo98\@gmail.com\
**Bugs** : Créer une issue sur GitHub\
**Documentation** : Voir README.md

------------------------------------------------------------------------

**Version** : 1.0\
**Date** : Janvier 2026\
**Auteur** : Geovany LAGUERRE