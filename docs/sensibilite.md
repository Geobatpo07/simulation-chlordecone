# Analyse de sensibilité du modèle de base

Ce document présente les résultats de l'analyse de sensibilité du modèle de base (module [app/R/sensibilite.R](../app/R/sensibilite.R), onglet « Sensibilité » de l'application, script [scripts/sensibilite.R](../scripts/sensibilite.R)). Il remplace par des valeurs calculées les affirmations non démontrées du §8.1 du preprint (voir [dette.md](dette.md), 2.3).

**Les valeurs de référence des paramètres sont illustratives** (le preprint n'en donne pas) : les conclusions valent pour ces valeurs et pour le domaine exploré, pas pour le chlordécone réel.

---

## 1. Méthode

**Paramètres étudiés (9).** $\delta$, $r^0$, $\alpha$, $\mu_E$, $\kappa$, $\mu_F$, $\beta$, $\rho$, $F_{\max}$.

**Sorties (3).** Prévalence maximale $P_{\max} = \max_t H_I/H$, prévalence à 5 ans $P_5 = H_I(5\,\text{ans})/H$, pic de la ressource $F_{pic} = \max_t F$.

**Configuration.** 3 parcelles de 1 000 kg, $E(0) = 50$ kg, $F(0) = 10$ kg, $H_0 = 50\,000$, prévalence initiale $20\ \%$ (§8.2.1), horizon 20 ans. Sorties échantillonnées tous les 5 jours (écart inférieur à $1\ \%$ avec un pas d'un jour, vérifié par test).

**Analyse locale (un paramètre à la fois).** Chaque paramètre $\theta_i$ est multiplié par $0{,}5$ puis par $2$, les autres restant à leur référence. L'élasticité mesure la variation relative de la sortie pour une variation relative du paramètre :

$$
\varepsilon_i = \frac{y(1{,}1\,\theta_i) - y(0{,}9\,\theta_i)}{0{,}2\;y_{réf}} .
$$

Une élasticité de $0{,}5$ signifie qu'une hausse de $10\ \%$ du paramètre augmente la sortie d'environ $5\ \%$.

**Analyse globale (indices de Sobol).** Les 9 paramètres varient simultanément entre la moitié et le double de leur référence (tirage uniforme sur le logarithme). Pour une sortie $Y$ :

$$
S_i = \frac{\operatorname{Var}\bigl(\mathbb{E}[Y \mid \theta_i]\bigr)}{\operatorname{Var}(Y)},
\qquad
S_{T_i} = 1 - \frac{\operatorname{Var}\bigl(\mathbb{E}[Y \mid \theta_{\sim i}]\bigr)}{\operatorname{Var}(Y)} ,
$$

estimés par les formules de Saltelli (2010) pour $S_i$ et de Jansen pour $S_{T_i}$ :

$$
\hat{V}_i = \frac{1}{N}\sum_{j=1}^{N} f(B)_j\,\bigl(f(A_B^{(i)})_j - f(A)_j\bigr),
\qquad
\hat{V}_{T_i} = \frac{1}{2N}\sum_{j=1}^{N} \bigl(f(A)_j - f(A_B^{(i)})_j\bigr)^2 ,
$$

où $A$ et $B$ sont deux échantillons indépendants et $A_B^{(i)}$ est $A$ dont la colonne $i$ est remplacée par celle de $B$. $N = 1024$, soit $N(k+2) = 11\,264$ simulations par scénario ($k = 9$). Les sorties sont centrées avant calcul de $S_i$ (sinon l'estimateur est instable quand la moyenne est grande devant l'écart-type). Les intervalles de confiance sont obtenus par bootstrap (200 rééchantillonnages).

- $S_i$ : part de la variance due au seul paramètre $i$.
- $S_{T_i}$ : part de la variance due au paramètre $i$ seul et à ses interactions. $S_{T_i} > S_i$ indique des interactions.
- $\sum_i S_i \approx 1$ : modèle quasi additif ; $\sum_i S_{T_i} > 1$ : interactions.

L'estimateur est validé sur la fonction d'Ishigami (indices connus analytiquement) dans [tests/test_sensibilite.R](../tests/test_sensibilite.R).

---

## 2. Scénario « Preprint » ($\delta = 10^{-3}$, $r^0 = 10^{-2}$ j$^{-1}$)

La contamination disparaît en quelques mois (demi-vie du sol : 59 jours) : un pic d'exposition court, puis une décroissance.

#### Prévalence maximale $P_{\max}$ (%)

| Paramètre | × 0,5 | Référence | × 2 | Élasticité | $S_1$ [IC 95 %] | $S_T$ [IC 95 %] |
|---|---|---|---|---|---|---|
| $\rho$ | 97,5 | 95,2 | 90,9 | −0,05 | 0,30 [0,25 ; 0,35] | 0,37 [0,33 ; 0,41] |
| $\beta$ | 90,8 | 95,2 | 97,5 | 0,05 | 0,31 [0,27 ; 0,36] | 0,37 [0,33 ; 0,41] |
| $F_{\max}$ | 90,8 | 95,2 | 97,5 | 0,05 | 0,29 [0,24 ; 0,34] | 0,36 [0,32 ; 0,41] |
| $\kappa$ | 95,2 | 95,2 | 95,2 | 0,00 | 0,00 [−0,01 ; 0,01] | 0,01 [0,00 ; 0,01] |
| $\mu_F$ | 95,2 | 95,2 | 95,2 | 0,00 | 0,01 [0,00 ; 0,01] | 0,01 [0,00 ; 0,01] |
| $r^0$ | 95,2 | 95,2 | 95,2 | 0,00 | 0,00 [−0,01 ; 0,00] | 0,01 [0,00 ; 0,01] |
| $\mu_E$ | 95,2 | 95,2 | 95,2 | 0,00 | 0,00 [−0,01 ; 0,00] | 0,00 [0,00 ; 0,01] |
| $\alpha$ | 95,2 | 95,2 | 95,2 | 0,00 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| $\delta$ | 95,2 | 95,2 | 95,2 | 0,00 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| *Somme* | | | | | 0,9 | 1,1 |

#### Prévalence à 5 ans $P_5$ (%)

| Paramètre | × 0,5 | Référence | × 2 | Élasticité | $S_1$ [IC 95 %] | $S_T$ [IC 95 %] |
|---|---|---|---|---|---|---|
| $\rho$ | 3,32 | 0,13 | 0,000418 | −6,79 | 0,67 [0,58 ; 0,77] | 0,84 [0,67 ; 1,05] |
| $r^0$ | 0,993 | 0,13 | 0,0552 | −2,04 | 0,12 [0,07 ; 0,20] | 0,22 [0,18 ; 0,29] |
| $\mu_F$ | 0,452 | 0,13 | 0,0771 | −1,03 | 0,05 [0,03 ; 0,08] | 0,11 [0,08 ; 0,15] |
| $\beta$ | 0,0964 | 0,13 | 0,175 | 0,43 | −0,01 [−0,02 ; 0,00] | 0,03 [0,02 ; 0,04] |
| $\delta$ | 0,146 | 0,13 | 0,107 | −0,22 | 0,00 [−0,01 ; 0,01] | 0,02 [0,01 ; 0,03] |
| $\mu_E$ | 0,158 | 0,13 | 0,103 | −0,32 | 0,00 [0,00 ; 0,01] | 0,01 [0,01 ; 0,01] |
| $\kappa$ | 0,107 | 0,13 | 0,15 | 0,24 | 0,00 [−0,01 ; 0,01] | 0,01 [0,01 ; 0,01] |
| $\alpha$ | 0,141 | 0,13 | 0,112 | −0,16 | 0,00 [−0,01 ; 0,00] | 0,00 [0,00 ; 0,00] |
| $F_{\max}$ | 0,13 | 0,13 | 0,13 | 0,00 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| *Somme* | | | | | 0,84 | 1,3 |

#### Pic de la ressource $F_{pic}$ (kg)

| Paramètre | × 0,5 | Référence | × 2 | Élasticité | $S_1$ [IC 95 %] | $S_T$ [IC 95 %] |
|---|---|---|---|---|---|---|
| $\kappa$ | 177 | 289 | 425 | 0,64 | 0,27 [0,22 ; 0,32] | 0,31 [0,28 ; 0,33] |
| $\mu_F$ | 423 | 289 | 181 | −0,62 | 0,23 [0,19 ; 0,27] | 0,29 [0,26 ; 0,32] |
| $r^0$ | 185 | 289 | 416 | 0,59 | 0,21 [0,17 ; 0,25] | 0,25 [0,23 ; 0,28] |
| $\mu_E$ | 409 | 289 | 182 | −0,59 | 0,21 [0,17 ; 0,24] | 0,24 [0,21 ; 0,26] |
| $\alpha$ | 281 | 289 | 306 | 0,06 | 0,00 [0,00 ; 0,01] | 0,00 [0,00 ; 0,00] |
| $\delta$ | 295 | 289 | 280 | −0,04 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| $F_{\max}$ | 289 | 289 | 289 | 0,00 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| $\beta$ | 289 | 289 | 289 | 0,00 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| $\rho$ | 289 | 289 | 289 | 0,00 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| *Somme* | | | | | 0,92 | 1,1 |

**Lecture.**

- **Pic de prévalence ($P_{\max} = 95{,}2\ \%$)** : seuls $\beta$, $F_{\max}$ et $\rho$ comptent, avec des poids voisins ($S_T \approx 0{,}37$ chacun). Les six paramètres environnementaux ($\delta$, $r^0$, $\alpha$, $\mu_E$, $\kappa$, $\mu_F$) ont une influence quasi nulle ($S_T < 0{,}01$). Raison : $F$ dépasse $F_{\max}$ (pic de $289$ kg pour $F_{\max} = 100$), donc $\lambda = \beta\,F_{\max}$ : l'exposition est saturée et ne dépend plus du niveau de contamination. $\beta$ et $F_{\max}$ jouent des rôles **identiques** (mêmes valeurs à $\times 0{,}5$ et $\times 2$), car seul leur produit intervient.
- **Prévalence à 5 ans ($P_5 = 0{,}13\ \%$)** : dominée par $\rho$ ($S_1 = 0{,}67$, élasticité $-6{,}8$). Une fois le pic passé, la prévalence résiduelle décroît au rythme de la dépuration. La réponse est très non linéaire (somme des $S_{T_i} = 1{,}25$ ; $\rho/2$ donne $3{,}3\ \%$, soit 25 fois la référence) : les indices sont moins précis, avec une sortie à queue lourde. $r^0$ et $\mu_F$ interviennent par la vitesse d'épuisement du pic.
- **Pic de la ressource ($F_{pic} = 289$ kg)** : déterminé par la chaîne de transfert, avec quatre paramètres d'influence comparable : $\kappa$, $\mu_F$, $r^0$, $\mu_E$ (élasticités d'environ $\pm 0{,}6$). $\beta$, $\rho$ et $F_{\max}$ n'ont aucun effet (pas de rétroaction de la population sur $F$).

---

## 3. Scénario « Persistance longue » ($\delta = 5 \times 10^{-5}$, $r^0 = 4 \times 10^{-5}$ j$^{-1}$)

Demi-vie du sol d'environ 20 ans : l'exposition dure des décennies et $F$ reste bien sous $F_{\max}$ (pas de saturation).

#### Prévalence maximale $P_{\max}$ (%)

| Paramètre | × 0,5 | Référence | × 2 | Élasticité | $S_1$ [IC 95 %] | $S_T$ [IC 95 %] |
|---|---|---|---|---|---|---|
| $\beta$ | 43,8 | 61,7 | 79,2 | 0,44 | 0,50 [0,45 ; 0,56] | 0,52 [0,48 ; 0,56] |
| $\mu_F$ | 72,5 | 61,7 | 48,5 | −0,29 | 0,24 [0,20 ; 0,28] | 0,23 [0,21 ; 0,25] |
| $\rho$ | 69,4 | 61,7 | 52,1 | −0,20 | 0,12 [0,09 ; 0,15] | 0,12 [0,12 ; 0,14] |
| $\kappa$ | 53,2 | 61,7 | 69,2 | 0,20 | 0,09 [0,06 ; 0,12] | 0,10 [0,09 ; 0,11] |
| $\mu_E$ | 68,4 | 61,7 | 53,8 | −0,18 | 0,06 [0,04 ; 0,09] | 0,07 [0,06 ; 0,08] |
| $r^0$ | 60,5 | 61,7 | 64,2 | 0,04 | 0,00 [0,00 ; 0,01] | 0,01 [0,00 ; 0,01] |
| $\alpha$ | 61,6 | 61,7 | 61,9 | 0,00 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| $\delta$ | 61,7 | 61,7 | 61,7 | 0,00 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| $F_{\max}$ | 61,7 | 61,7 | 61,7 | 0,00 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| *Somme* | | | | | 1 | 1 |

#### Prévalence à 5 ans $P_5$ (%)

| Paramètre | × 0,5 | Référence | × 2 | Élasticité | $S_1$ [IC 95 %] | $S_T$ [IC 95 %] |
|---|---|---|---|---|---|---|
| $\mu_F$ | 45,3 | 29,2 | 17,1 | −0,71 | 0,23 [0,19 ; 0,27] | 0,24 [0,21 ; 0,26] |
| $\rho$ | 45,3 | 29,2 | 17 | −0,72 | 0,23 [0,20 ; 0,28] | 0,23 [0,21 ; 0,26] |
| $\beta$ | 17,2 | 29,2 | 45,1 | 0,70 | 0,20 [0,17 ; 0,24] | 0,22 [0,20 ; 0,24] |
| $r^0$ | 17,7 | 29,2 | 43,3 | 0,65 | 0,17 [0,14 ; 0,21] | 0,19 [0,17 ; 0,21] |
| $\kappa$ | 20,3 | 29,2 | 37,4 | 0,44 | 0,07 [0,05 ; 0,10] | 0,09 [0,08 ; 0,10] |
| $\mu_E$ | 37,5 | 29,2 | 20,3 | −0,44 | 0,07 [0,05 ; 0,09] | 0,08 [0,07 ; 0,09] |
| $\delta$ | 30 | 29,2 | 27,6 | −0,06 | 0,00 [0,00 ; 0,01] | 0,00 [0,00 ; 0,00] |
| $\alpha$ | 28,5 | 29,2 | 30,5 | 0,05 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| $F_{\max}$ | 29,2 | 29,2 | 29,2 | 0,00 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| *Somme* | | | | | 0,99 | 1,1 |

#### Pic de la ressource $F_{pic}$ (kg)

| Paramètre | × 0,5 | Référence | × 2 | Élasticité | $S_1$ [IC 95 %] | $S_T$ [IC 95 %] |
|---|---|---|---|---|---|---|
| $\kappa$ | 13,6 | 18,8 | 26,2 | 0,49 | 0,67 [0,60 ; 0,73] | 0,69 [0,65 ; 0,74] |
| $\mu_F$ | 22,2 | 18,8 | 15,1 | −0,29 | 0,20 [0,16 ; 0,23] | 0,23 [0,20 ; 0,25] |
| $\mu_E$ | 21,9 | 18,8 | 15,8 | −0,26 | 0,15 [0,12 ; 0,18] | 0,17 [0,15 ; 0,19] |
| $r^0$ | 18,6 | 18,8 | 19,3 | 0,02 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| $\alpha$ | 18,8 | 18,8 | 18,9 | 0,00 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| $\delta$ | 18,8 | 18,8 | 18,8 | 0,00 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| $\beta$ | 18,8 | 18,8 | 18,8 | 0,00 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| $\rho$ | 18,8 | 18,8 | 18,8 | 0,00 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| $F_{\max}$ | 18,8 | 18,8 | 18,8 | 0,00 | 0,00 [0,00 ; 0,00] | 0,00 [0,00 ; 0,00] |
| *Somme* | | | | | 1 | 1,1 |

**Lecture.**

- **Pic de prévalence ($P_{\max} = 61{,}7\ \%$)** : dominé par $\beta$ ($S_1 = 0{,}50$, élasticité $0{,}44$), puis $\mu_F$ ($0{,}24$), $\rho$ ($0{,}12$), $\kappa$ ($0{,}09$) et $\mu_E$ ($0{,}06$). Le modèle est quasi additif ($\sum S_i = 1{,}01$).
- **Prévalence à 5 ans ($P_5 = 29{,}2\ \%$)** : quatre paramètres d'influence voisine, $\rho$, $\mu_F$, $\beta$ et $r^0$ ($S_T$ entre $0{,}19$ et $0{,}24$, élasticités d'environ $\pm 0{,}7$), puis $\kappa$ et $\mu_E$ ($\approx 0{,}08$). Contrairement au pic, $r^0$ compte à 5 ans : il fixe l'intensité du flux de contamination qui entretient l'exposition.
- **Pic de la ressource ($F_{pic} = 18{,}8$ kg)** : dominé par $\kappa$ ($S_1 = 0{,}67$), puis $\mu_F$ et $\mu_E$. $r^0$ n'a aucun effet ici : ce pic est le **transitoire des conditions initiales** ($E(0) = 50$ kg), et non le régime persistant (où $F \approx 2$ kg).
- $\delta$, $\alpha$ et $F_{\max}$ sont sans effet sur les trois sorties ($S_T \leq 0{,}002$).

---

## 4. Ce que cela dit des affirmations du §8.1 du preprint

| Affirmation du preprint | Résultat (valeurs illustratives, horizon 20 ans) |
|---|---|
| $\delta$ « contrôle la vitesse d'élimination » ; paramètre clé (§8.1.1) | **Non retrouvé** : $S_T \leq 0{,}002$ en persistance longue et $S_T \leq 0{,}02$ dans le scénario du preprint (effet maximal sur $P_5$). $\delta$ n'agit que sur la décroissance du stock du sol, trop lente (demi-vie de 20 ans) ou trop dominée par le ruissellement (demi-vie de 59 jours) pour peser sur des sorties à 5 ou 20 ans. L'intensité de l'exposition est portée par le flux $r^0 g C$, pas par $\delta$. |
| $\alpha$ « paramètre critique » (§8.1.2) | **Non retrouvé** : $S_T \leq 0{,}004$ sur toutes les sorties. Avec $R_{moy} = 6 \ll R_h = 50$, $g(R)$ ne varie que de $1{,}05$ à $1{,}12$. Le résultat dépend de $R_h$ et $R_{moy}$, non donnés par le preprint. |
| $\kappa$ « déterminant pour l'exposition humaine » (§8.1.3) | **Confirmé pour $F$** (élasticité $0{,}5$ à $0{,}6$, $S_1 = 0{,}67$ pour $F_{pic}$ en persistance) et **modéré pour la prévalence** (persistance : $S_T \approx 0{,}09$ à $0{,}10$). Sans effet sur $P_{\max}$ dans le scénario saturé. $\kappa/2$ réduit $F_{pic}$ de $28\ \%$ (persistance) à $39\ \%$ (preprint). |
| $\beta$ « directement proportionnel » aux nouveaux cas (§8.1.4) | **Non proportionnel** : élasticité de $P_{\max}$ à $\beta$ égale à $0{,}44$ (persistance) et $0{,}05$ (preprint, saturation). Elle monte à $0{,}70$ pour $P_5$ en persistance. |
| Leviers du §8.2.1 : $r^0$, $\beta$, $\mu_F$ | **Comparables** pour $P_5$ en persistance : élasticités $+0{,}65$, $+0{,}70$ et $-0{,}71$. Pour $P_{\max}$, $\beta$ domine et $r^0$ est sans effet. Dans le scénario du preprint, ils n'agissent que sur la dynamique après le pic. |

**Autres enseignements.**

- Dans le scénario du preprint, la sortie est saturée : seul le produit $\beta F_{\max}$ et la dépuration $\rho$ comptent pour le pic. Les paramètres environnementaux n'ont d'effet que sur la **durée** de l'exposition, pas sur son niveau maximal.
- La dépuration $\rho$ est un des paramètres les plus influents sur la prévalence, alors qu'elle n'est pas un levier d'intervention du §8.2.1 et qu'elle n'est pas estimée dans le preprint. Elle devrait être priorisée dans une calibration.
- $F_{\max}$ n'a d'effet que lorsque $F$ le dépasse ; sa valeur n'est pas donnée par le preprint (voir [dette.md](dette.md), 2.2).

---

## 5. Limites

- **Plages arbitraires.** Chaque paramètre varie d'un facteur 2 vers le haut et le bas. Un autre domaine (par exemple $\delta$ et $r^0$ variant sur plusieurs ordres de grandeur) donnerait d'autres hiérarchies.
- **Valeurs de référence illustratives** : les indices dépendent du scénario (comparer les sections 2 et 3).
- **Sorties à un horizon donné.** À 50 ans, l'influence de $\delta$ pourrait être plus grande dans le scénario de persistance longue (non testé).
- **Précision.** Pour $P_5$ du scénario du preprint, la sortie est à queue lourde et les indices sont moins précis (intervalles larges, $\sum S_{T_i} = 1{,}25$). Pour augmenter la précision, relancer le script avec un $N$ plus grand.
- **Incertitude de structure non couverte** : la sensibilité est celle du modèle tel qu'il est écrit, y compris ses défauts (voir [dette.md](dette.md)).

---

## 6. Reproduire

Dans l'application : onglet « Sensibilité ». Hors application (parallélisé, résultats dans `results/`) :

```bash
Rscript scripts/sensibilite.R preprint,persist 1024 20 20 8
```

Arguments : scénarios, $N$, horizon (années), prévalence initiale (%), nombre de cœurs. Les tableaux ci-dessus ont été obtenus avec `1024 20 20` (graine 2026). Tests des estimateurs : `Rscript tests/test_sensibilite.R`.
