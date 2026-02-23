# Application Shiny - Modélisation de l'exposition au chlordécone

## Description

Application interactive pour explorer différentes approches de modélisation de l'exposition humaine au chlordécone aux Antilles françaises.

## Installation

### Prérequis

Installer les packages R nécessaires :

```r
install.packages(c("shiny", "shinydashboard", "deSolve", "ggplot2", "gridExtra", "DT", "reshape2"))
```

## Lancement de l'application

### Depuis RStudio

1. Ouvrir le fichier `app.R` dans RStudio
2. Cliquer sur "Run App" en haut à droite de l'éditeur

### Depuis la console R

```r
library(shiny)
runApp("path/to/simulation/app")
```

### Depuis le terminal

```bash
R -e "shiny::runApp('simulation/app')"
```

## Structure de l'application

### 🏠 Accueil
- Vue d'ensemble de l'application
- Description des modèles disponibles
- Instructions d'utilisation

### 📊 Modèles disponibles

#### 1. Modèle de base (CC1)
**Description** : Modèle compartimental à 6 compartiments
- Parcelles agricoles (C)
- Environnement aquatique (E)
- Ressource alimentaire (F)
- Population à faible charge (H_S)
- Population à charge élevée (H_I)
- Forçage pluviométrique (R)

**Paramètres ajustables** :
- Nombre de parcelles
- Stocks initiaux
- Taux de dégradation (δ)
- Ruissellement de base (r₀)
- Amplification pluviométrique (α)
- Transferts environnementaux (μ_E, κ, μ_F)
- Taux d'exposition (β)
- Taux de dépuration (ρ)

**Sorties** :
- Évolution des stocks parcellaires
- Contamination environnementale et ressource
- Dynamique des populations
- Prévalence de charge élevée

---

#### 2. Variable de charge corporelle B(t)
**Description** : Extension du modèle de base avec biomarqueur sanguin

**Nouveautés** :
- Variable B(t) : concentration sanguine moyenne (µg/L)
- Dynamique : dB/dt = γ·F/H - μ_B·B
- Transition probabiliste basée sur B via fonction sigmoïde

**Paramètres supplémentaires** :
- γ : coefficient d'absorption
- μ_B : taux d'élimination corporelle
- B* : seuil de charge
- k : raideur de la sigmoïde

**Avantages** :
- Lien direct avec données de biosurveillance
- Modélisation de délais physiologiques
- Transitions graduelles entre états

---

#### 3. Spatialisation (multi-bassins)
**Description** : Modèle avec réseau hydrographique

**Structure** :
- Plusieurs bassins versants interconnectés
- Attribution des parcelles aux bassins
- Transferts inter-bassins
- Ressources alimentaires par bassin

**Paramètres spécifiques** :
- Nombre de bassins versants (2-4)
- Taux de transfert inter-bassins (w)
- Répartition parcelles → bassins

**Utilité** :
- Ciblage géographique des interventions
- Identification de bassins prioritaires
- Modélisation réaliste du transfert hydrique

---

#### 4. Chaîne de Markov (4 classes de charge)
**Description** : Discrétisation de la charge en classes avec transitions stochastiques

**Classes** :
1. **Classe 1** : Charge nulle (B < 0.2 µg/L)
2. **Classe 2** : Charge faible (0.2 ≤ B < 0.5 µg/L)
3. **Classe 3** : Charge modérée (0.5 ≤ B < 1.0 µg/L)
4. **Classe 4** : Charge élevée (B ≥ 1.0 µg/L)

**Transitions** :
- Progression : Classes 1→2→3→4 (exposition via β_i·F)
- Régression : Classes 4→3→2→1 (dépuration via ρ_i)

**Sorties** :
- Distribution de la population par classe
- Prévalence multi-niveaux
- Proportions finales

**Avantages** :
- Capture de l'hétérogénéité
- Temps de séjour par classe
- Calibration via données longitudinales

---

#### 5. Intervention (politiques publiques)
**Description** : Simulation de mesures de réduction de l'exposition

**Interventions modélisées** :
1. **Aménagements hydrauliques** : réduction de r₀ (bassins de rétention)
2. **Sensibilisation alimentaire** : réduction de β (diversification)
3. **Mise en place progressive** : fonction sigmoïde φ(t)

**Paramètres** :
- t₀ : début de l'intervention (années)
- τ : durée de transition (années)
- Réductions (%) pour r₀ et β

**Sorties** :
- Comparaison avant/après intervention
- Impact sur prévalence, ressources, populations
- Visualisation de la progression de l'intervention

---

#### 6. Comparaison des modèles
**Description** : Analyse comparative des prédictions

**Fonctionnalité** :
- Paramètres communs appliqués à tous les modèles
- Comparaison visuelle des prévalences
- Identification des différences entre approches

**Utilité** :
- Évaluation de l'impact des hypothèses
- Quantification de l'incertitude structurelle
- Aide au choix du modèle

---

## Utilisation typique

### Workflow recommandé

1. **Exploration initiale** : commencer avec le modèle de base
2. **Ajustement des paramètres** : calibrer sur ordres de grandeur connus
3. **Extensions** : tester modèles avec charge B(t) ou Markov
4. **Spatialisation** : si données géographiques disponibles
5. **Intervention** : évaluer l'efficacité de politiques
6. **Comparaison** : synthétiser les résultats

### Conseils pratiques

- **Durées de simulation** : 10-20 ans pour observer les dynamiques long terme
- **Pas de temps** : 1 jour (fixe, suffisant pour capturer saisonnalité)
- **Sensibilité** : tester plusieurs valeurs pour paramètres incertains
- **Téléchargement** : exporter CSV pour analyses post-hoc (R, Python, Excel)

---

## Paramètres par défaut (valeurs indicatives)

| Paramètre | Symbole | Valeur par défaut | Unité | Source/justification |
|-----------|---------|-------------------|-------|---------------------|
| Dégradation | δ | 0.001 | j⁻¹ | Demi-vie ≈ 2 ans (littérature) |
| Ruissellement | r₀ | 0.01 | j⁻¹ | Ordre de grandeur tropical |
| Amplification pluie | α | 0.8 | - | Effet modéré (saturation) |
| Élimination environnement | μ_E | 0.05 | j⁻¹ | Renouvellement rapide |
| Transfert E→F | κ | 0.03 | j⁻¹ | Bioaccumulation modérée |
| Renouvellement ressource | μ_F | 0.02 | j⁻¹ | Dynamique biologique |
| Taux exposition | β | 0.001 | j⁻¹·kg⁻¹ | Consommation locale |
| Taux dépuration | ρ | 0.005 | j⁻¹ | Métabolisme lent |
| Espérance de vie | 1/d_H | 70 | ans | Démographie |

**Note** : Ces valeurs sont **illustratives**. Une calibration rigoureuse nécessite des données empiriques.

---

## Téléchargement des résultats

Chaque onglet de modèle propose un bouton de téléchargement :
- Format : CSV (compatible Excel, R, Python)
- Contenu : toutes les variables à chaque pas de temps
- Utilisation : analyses statistiques, graphiques personnalisés

---

## Limitations et perspectives

### Limitations actuelles
- Paramètres déterministes (pas d'incertitude stochastique)
- Pas de validation formelle avec données réelles
- IBM (modèle individu-centré) non implémenté (coût computationnel)
- Pas de structure d'âge dans la population

### Extensions possibles
- Calibration bayésienne avec données KANNARI/HIBISCUS
- Analyse de sensibilité globale (méthodes de Sobol)
- Couplage avec SIG pour spatialisation détaillée
- Module d'optimisation (recherche de stratégies optimales)

---

## Références scientifiques

### Chlordécone aux Antilles
- ANSES (2020). Études sur le chlordécone
- INVS - Études épidémiologiques KANNARI

### Modélisation compartimentale
- Soetaert, K., Petzoldt, T., & Setzer, R. W. (2010). *Solving Differential Equations in R: Package deSolve*. Journal of Statistical Software, 33(9).
- Brauer, F., & Castillo-Chavez, C. (2012). *Mathematical Models in Population Biology and Epidemiology*. Springer.

### Applications environnement-santé
- Mackay, D. (2001). *Multimedia Environmental Models*. CRC Press.

---

## Support technique

### Problèmes courants

**1. Erreur au lancement**
```
Error in library(X) : there is no package called 'X'
```
→ Installer le package manquant : `install.packages("X")`

**2. Simulation trop longue**
→ Réduire la durée ou augmenter le pas de temps

**3. Résultats non physiques (négatifs)**
→ Vérifier cohérence des paramètres (ordres de grandeur)

### Contact
Pour signaler un bug ou suggérer une amélioration :
- Email : geovany.laguerre@example.com
- GitHub : [dépôt de l'application]

---

## Licence

Cette application est développée dans un cadre académique (Master 2 Mathématiques & Applications).
Libre d'utilisation pour des fins pédagogiques et de recherche.

---

## Auteur

**Geovany Batista Polo Laguerre**  
Master 2 Mathématiques & Applications  
Modélisation déterministe 2 - CC2  
Janvier 2026

---

## Changelog

### Version 1.0 (2026-01-22)
- Implémentation initiale
- 5 modèles disponibles
- Interface Shiny Dashboard
- Export CSV
- Comparaison multi-modèles
