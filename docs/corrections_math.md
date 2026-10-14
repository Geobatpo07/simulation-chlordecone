# Corrections mathématiques reprises dans le code

Ce document recense les écarts entre le preprint (*Modélisation de l'exposition humaine au chlordécone*, Laguerre, 2026) et le code, pour lesquels **le code applique la forme corrigée**. Chaque entrée donne le problème, la forme retenue, l'endroit du code et la vérification.

Les failles du preprint elles-mêmes (à corriger dans le texte) sont dans [dette.md](dette.md). Les nombres ci-dessous sont calculés avec les paramètres par défaut de l'application (illustratifs, le preprint n'en donne pas).

**Notation.** $H = H_S + H_I$ (population), $d = d_H = \dfrac{1}{70 \times 365}\ \text{j}^{-1}$, $g(R)$ l'amplification pluviométrique.

---

## 1. Équilibre démographique : $\Lambda_H = H_0\, d_H$

**Problème.** Le preprint donne l'équilibre sans contamination $H_s^* = \Lambda_h / d_h$ (§6.4.1). En sommant les deux équations de population, les flux entre $H_s$ et $H_i$ s'annulent et

$$
\frac{dH}{dt} = \Lambda_h - d_h H
\quad\Longrightarrow\quad
H(t) = \frac{\Lambda_h}{d_h} + \left(H(0) - \frac{\Lambda_h}{d_h}\right) e^{-d_h t}.
$$

Le code utilisait $\Lambda_h = 10$ pers./j, soit $\Lambda_h / d_h = 10 \times 25\,550 = 255\,500$ pour une population initiale de $50\,000$. La population dérivait vers $255\,500$ : $64\,167$ à 5 ans et $101\,071$ à 20 ans.

**Forme retenue.**

$$
\Lambda_H = H_0\, d_H \approx 1{,}96 \ \text{pers./j}\quad(H_0 = 50\,000),
\qquad\text{de sorte que}\quad H(t) \equiv H_0 .
$$

**Code.** `params_defaut()` dans [app/R/simulation.R](../app/R/simulation.R) (`Lambda_H = H0 * D_H`). Le curseur « Population initiale » de l'onglet de base et celui de la comparaison fixent $H_0$.

**Vérification.** `tests/smoke.R` : après 20 ans, $H = 50\,000$ (tolérance 50).

---

## 2. Transfert inter-bassins : conservation de la masse

**Forme du preprint (§10.1.2).** Pour le bassin $j$ :

$$
\frac{dE_j}{dt} = \sum_{i \in P_j} r_i^0\, g(R)\, C_i \;-\; (\mu_E + \kappa)\, E_j \;-\; \sum_{k} w_{jk} E_j \;+\; \sum_{k} w_{kj} E_k .
$$

Les termes de transfert se compensent en sommant sur $j$ : le stock total n'évolue que par les apports (ruissellement) et les pertes ($\mu_E$, $\kappa$).

**Problème dans le code d'origine.** Le terme reçu de l'amont, `dE[j+1] <- dE[j+1] + w*E[j]`, était écrasé à l'itération suivante par `dE[j] <- apports - pertes`. La masse sortant du bassin $j$ n'arrivait jamais dans le bassin $j+1$ : le transfert était une perte.

**Forme retenue.** Chaîne amont $\to$ aval ($w_{j,j+1} = w$, les autres $w_{jk}$ nuls), avec accumulation :

$$
\frac{dE_j}{dt} = \sum_{i \in P_j} r_i^0\, g\, C_i \;-\; \bigl(\mu_E + \kappa + w\,\mathbf{1}_{j<m}\bigr)\, E_j \;+\; w\, E_{j-1}\,\mathbf{1}_{j>1}.
$$

Le dernier bassin $m$ n'a pas de sortie par transfert, et

$$
\sum_{j=1}^{m} \frac{dE_j}{dt} = \sum_i r_i^0\, g\, C_i - (\mu_E + \kappa) \sum_{j} E_j .
$$

**Code.** `modele_spatialise()` dans [app/R/models.R](../app/R/models.R) (`dE[j] <- dE[j] + ...`).

**Vérification.** `tests/smoke.R` : avec $\delta = \mu_E = \kappa = 0$, la somme (parcelles + bassins) reste égale à $3\,000$ kg.

---

## 3. Charge corporelle $B(t)$ : unités, équilibre et lien avec $H_S$, $H_I$

### 3.1 Équation et unités

Forme du preprint (§9.1), conservée :

$$
\frac{dB}{dt} = \gamma\,\frac{F}{H} - \mu_B\, B .
$$

**Correction d'unités.** $F/H$ est en kg/pers. et $dB/dt$ en $\mu\text{g}\cdot\text{L}^{-1}\cdot\text{j}^{-1}$, donc

$$
[\gamma] = \mu\text{g}\cdot\text{L}^{-1}\cdot\text{j}^{-1}\cdot\text{kg}^{-1}\cdot\text{pers.}
$$

Le preprint écrit $\mu\text{g}\cdot\text{L}^{-1}\cdot\text{kg}^{-1}\cdot\text{pers.}$ : il manque $\text{j}^{-1}$.

À $F$ et $H$ constants :

$$
B_{eq} = \frac{\gamma\, F}{H\, \mu_B},
\qquad
T_{1/2} = \frac{\ln 2}{\mu_B} = 139 \ \text{jours}\quad(\mu_B = 0{,}005\ \text{j}^{-1}),
$$

à comparer à la demi-vie d'environ 150 jours du preprint.

### 3.2 Choix de $\gamma$

$\gamma$ est fixé pour que $B_{eq}$ approche le seuil $B^* = 1\ \mu\text{g/L}$ :

$$
\gamma = \frac{B^*\, \mu_B\, H}{F}.
$$

- Scénario du preprint (pic $F \approx 100$ kg) : $\gamma = \dfrac{1 \times 0{,}005 \times 50\,000}{100} = \mathbf{2{,}5}$.
- Persistance longue ($F \approx 2{,}4$ kg pour 3 parcelles, $5{,}7$ kg pour 7) : $\gamma = \mathbf{60}$.

Avec $\gamma = 60$ en persistance longue : $B$ atteint $1{,}22\ \mu\text{g/L}$ pour 3 parcelles ($0{,}83$ à 1 an, $0{,}50$ à 5 ans) et $1{,}50\ \mu\text{g/L}$ pour 7 parcelles ($1{,}42$ à 1 an, $1{,}17$ à 5 ans).

### 3.3 Lien $B \to (H_S, H_I)$

Le preprint décrit les mêmes compartiments de deux façons incompatibles : des EDO avec $\lambda(F)$ et $\rho$ (§4), et la fermeture algébrique $H_i = H\, p_i(B)$ (§9.2.2). Cette fermeture n'est donc pas imposée : le code couple les deux par un **flux de relaxation** de vitesse $k_{trans}$ :

$$
\phi_{S \to I} = k_{trans}\, p(B)\, H_S,
\qquad
\phi_{I \to S} = k_{trans}\, \bigl(1 - p(B)\bigr)\, H_I,
\qquad
p(B) = \frac{1}{1 + e^{-k\,(B - B^*)}} .
$$

Leur bilan net est

$$
\phi_{S \to I} - \phi_{I \to S} = k_{trans}\,\bigl(H\, p(B) - H_I\bigr),
$$

donc $H_I$ **relaxe vers $H\, p(B)$** à la vitesse $k_{trans}$, ce qui redonne la fermeture du preprint quand $k_{trans} \to \infty$. L'exposition directe $\lambda(F)\, H_S$ reste en parallèle. Dans le modèle $B(t)$, $\rho$ n'intervient pas (le retour vers $H_S$ est porté par le flux).

La dérivée de la fermeture est

$$
\frac{d(H\, p)}{dt} = H' \, p + H\, p'(B)\, B',
$$

alors que le §9.2.2 du preprint oublie le terme $H' p$.

**Code.** `modele_avec_charge()` ([app/R/models.R](../app/R/models.R)) ; $\gamma$ par scénario dans le serveur (`gamma_scen`).

---

## 4. Fonction d'exposition : $\lambda(F) = \beta \min(F,\, F_{\max})$

La forme par morceaux du §4.3

$$
\lambda(F) =
\begin{cases}
\beta F & \text{si } F < F_{\max} \\
\beta F_{\max} & \text{si } F \geq F_{\max}
\end{cases}
$$

s'écrit sans test : $\lambda(F) = \beta \min(F, F_{\max})$. Le code utilise `pmin` (à la place de `ifelse`), fonction identique mais sans branchement. Dans le modèle spatialisé, la saturation s'applique au stock agrégé $F_{tot} = \sum_j F_j$.

**Code.** `taux_exposition()` dans [app/R/models.R](../app/R/models.R).

---

## 5. Amplification pluviométrique : ordre de grandeur réel

$$
g(R) = 1 + \frac{\alpha R}{R_h + R},
\qquad R(t) = R_{moy}\left(1 + A \sin\frac{2\pi t}{T}\right).
$$

La borne $g \leq 1 + \alpha$ (§4.2) est correcte mais pas atteinte. Pour les paramètres de l'application ($R_{moy} = 6$, $R_h = 50$, $\alpha = 0{,}8$, $A = 0{,}5$), $x = \dfrac{R}{R_h + R} \approx 0{,}1$ et $g(R(t))$ varie entre $1{,}045$ et $1{,}122$ (moyenne $1{,}085$), loin de $1{,}8$.

Conséquence sur une affirmation du §8.1.2 (« $\alpha$ de 0,5 à 1,0 peut doubler le flux ») : avec $x = \dfrac{R}{R_h + R} < 1$,

$$
\frac{g(\alpha = 1)}{g(\alpha = 0{,}5)} = \frac{1 + x}{1 + 0{,}5\,x} < \frac{4}{3},
$$

et ici $\dfrac{1{,}107}{1{,}054} = \mathbf{+5\ \%}$.

**Code.** `amplification_pluie()` dans [app/R/models.R](../app/R/models.R).

---

## 6. Taux effectif de perte du sol et demi-vie

Le sol perd du chlordécone à la fois par dégradation ($\delta$) et par ruissellement ($r^0 g$), donc le taux effectif est

$$
k_{eff} = \delta + r^0\, \bar{g},
\qquad
T_{1/2} = \frac{\ln 2}{k_{eff}},
$$

et non $\delta$ seul comme le suppose le §8.1.1 (demi-vie $\approx$ 2 ans pour $\delta = 0{,}001\ \text{j}^{-1}$).

| Scénario | $\delta$ ($\text{j}^{-1}$) | $r^0$ ($\text{j}^{-1}$) | $k_{eff}$ ($\text{j}^{-1}$) | Demi-vie du sol |
|---|---|---|---|---|
| Preprint | $10^{-3}$ | $10^{-2}$ | $1{,}18 \times 10^{-2}$ | **59 jours** |
| Persistance longue | $5 \times 10^{-5}$ | $4 \times 10^{-5}$ | $9{,}3 \times 10^{-5}$ | **20,3 ans** |

Vérifié par simulation : $C_1$ passe sous 500 kg (moitié de 1 000 kg) à $t = 0{,}2$ an dans le scénario du preprint, et à $t = 20{,}3$ ans en persistance longue.

À l'équilibre quasi-stationnaire :

$$
E^* = \frac{r^0\, \bar{g}\, C_{tot}}{\mu_E + \kappa},
\qquad
F^* = \frac{\kappa\, E^*}{\mu_F}.
$$

Persistance longue, 3 parcelles de 1 000 kg : $E^* = 1{,}63$ kg et $F^* = 2{,}44$ kg (la simulation donne $F = 2{,}34$ kg à 1 an).

**Code.** Scénarios `delta_scen()` et `r0_scen()` dans [app/app.R](../app/app.R).

---

## 7. Chaîne de Markov : générateur, équilibre et conservation

**Forme.** Avec $\mathbf{H} = (H_1, \dots, H_4)^\top$ et $Q(F)$ le générateur du §10.3.2 :

$$
\frac{d\mathbf{H}}{dt} = \Lambda_h\, \mathbf{e}_1 + Q(F)^\top \mathbf{H} - d_h\, \mathbf{H},
\qquad
Q(F) =
\begin{pmatrix}
-q_{12} & q_{12} & 0 & 0 \\
\rho_1 & -(\rho_1 + q_{23}) & q_{23} & 0 \\
0 & \rho_2 & -(\rho_2 + q_{34}) & q_{34} \\
0 & 0 & \rho_3 & -\rho_3
\end{pmatrix},
\qquad q_{i,i+1} = \beta_i F .
$$

Les taux de régression $\rho_1, \rho_2, \rho_3$ sont des **paramètres libres** (§10.3.2), alors que le code d'origine les fixait à $0{,}5\rho$, $0{,}7\rho$ et $\rho$. Les défauts actuels ($0{,}0025$, $0{,}0035$, $0{,}005$) donnent les anciennes valeurs.

**Conservation.** Les lignes de $Q$ somment à 0, donc

$$
\frac{d}{dt}\sum_{i=1}^{4} H_i = \Lambda_h - d_h \sum_{i=1}^{4} H_i,
$$

et la population totale vaut $H_0$ pour $\Lambda_h = H_0\, d_h$ (vérifié : $50\,000$ sur 20 ans).

**Équilibre à $F = 0$.** Le preprint écrit « $q_{ij} = 0$ » et conclut que la population se concentre en classe 1. C'est vrai, mais à cause des $\rho_i$ **non nuls** qui ramènent tout le monde vers la classe 1. L'équilibre est

$$
\mathbf{H}^* = \left(\frac{\Lambda_h}{d_h},\, 0,\, 0,\, 0\right).
$$

À $F$ constant, l'équilibre du système ouvert est

$$
\mathbf{H}^* = \Lambda_h \,\bigl(d_h I - Q^\top\bigr)^{-1} \mathbf{e}_1,
$$

et non la solution de $Q^\top \pi = 0$ du §10.3.3 (valable pour une chaîne fermée).

**Code.** `modele_markov()` ([app/R/models.R](../app/R/models.R)) et curseurs `markov_rho_1` à `markov_rho_3` ([app/app.R](../app/app.R)).

---

## 8. Intervention : complétion de la définition et scénario de référence

**Forme du preprint (§8.2.1).**

$$
r^0(t) = r^0\,\bigl(1 - a\,\sigma(t)\bigr),
\qquad
\beta(t) = \beta\,\bigl(1 - b\,\sigma(t)\bigr),
\qquad
\sigma(t) = \frac{1}{2}\left(1 + \tanh\frac{t - t_0}{\tau}\right).
$$

**Ajouts dans le code.**

- L'action sur $\mu_F$, citée au §8.2.1 mais sans formule :

$$
\mu_F(t) = \mu_F\,\bigl(1 + c\,\sigma(t)\bigr).
$$

- Un **scénario de référence** ($a = b = c = 0$, mêmes paramètres et conditions initiales), pour mesurer l'effet de l'intervention. La réduction relative à 5 ans vaut

$$
R_5 = 1 - \frac{P_{int}(5\ \text{ans})}{P_{réf}(5\ \text{ans})},
\qquad P = \frac{H_I}{H}.
$$

- La prévalence initiale (20 % au §8.2.1) est un paramètre (curseur).

**Code.** `modele_intervention()` et `progression_intervention()` ([app/R/models.R](../app/R/models.R)), `simuler_intervention()` ([app/R/simulation.R](../app/R/simulation.R)).

**Vérification.** `tests/test_simulation.R` : avec $a = b = c = 0$, l'intervention est identique à la référence ; la référence ne dépend pas de $a$, $b$, $c$.

---

## 9. Prévalence et indexation des colonnes

**Définitions utilisées.**

- Modèles à deux classes (base, charge $B(t)$, spatialisé, intervention) :

$$
P = \frac{H_I}{H_S + H_I}.
$$

- Chaîne de Markov :

$$
P_{élevée} = \frac{H_4}{H},
\qquad
P_{modérée} = \frac{H_3 + H_4}{H}.
$$

  La comparaison utilise $P_{modérée}$.

**Bug corrigé.** L'onglet de comparaison indexait les colonnes de la solution par position et calculait $\dfrac{H_S}{F + H_S}$ (modèles de base et charge) au lieu de $\dfrac{H_I}{H_S + H_I}$, avec des colonnes décalées pour Markov. Les colonnes sont désormais nommées explicitement (`noms_colonnes()`), sans aucun accès par numéro.

**Vérification.** `tests/test_simulation.R` : à $t = 0$, les prévalences des trois modèles valent $2\ \%$, $2\ \%$ et $4\ \%$ ; la prévalence du modèle de base égale le calcul direct.

---

## 10. Nombre de parcelles

Les équations sont écrites pour $n$ parcelles quelconques (§4.4 : $i = 1, \dots, n$). Le code admet 1 à 7 parcelles (le preprint en utilise 7, §2.1.2) ; le code d'origine plafonnait à 5 (6 en spatial).

---

## Écarts du preprint conservés volontairement dans le code

Ces points sont des défauts du preprint (voir [dette.md](dette.md)), mais le code suit encore le preprint, à titre de repère :

| Point | Ce que fait le code | Conséquence |
|---|---|---|
| $\sigma(0) \neq 0$ (§8.2.1) | $\sigma(t) = \frac{1}{2}\bigl(1 + \tanh\frac{t - t_0}{\tau}\bigr)$ tel quel | Avec $t_0 = 0$ et $\tau = 1$ an, $\sigma(0) = 0{,}5$ : l'intervention est déjà à demi active au départ. Les chiffres « 13,3 % contre 29,2 % à 5 ans » (réduction de 54 %) en tiennent compte. Avec $t_0 = 0{,}5$ an, $\sigma(0) = 0{,}27$. |
| Ingestion proportionnelle au stock par habitant $F/H$ (§9.1) | $\dfrac{dB}{dt} = \gamma \dfrac{F}{H} - \mu_B B$ | Le stock total n'est pas une concentration dans l'aliment (voir dette.md, 2.5). |
| Sigmoïde sur la moyenne $B$ (§9.2.2) | $p(B)$ appliqué à $B$ moyen | Effet de Jensen non traité (dette.md, 2.5). |
| Consommation sans effet sur $F$ (§2.1.1) | $F$ n'est pas diminué par l'ingestion | Simplification du preprint. |
| Seuil $F_{\max}$ appliqué à un stock (§4.3) | $\lambda = \beta \min(F, F_{\max})$ | Mélange stock et flux (dette.md, 2.6). |

Pour corriger le premier point, on pourrait normaliser

$$
\tilde{\sigma}(t) = \frac{\sigma(t) - \sigma(0)}{1 - \sigma(0)},
$$

qui vaut 0 à $t = 0$ et tend vers 1.

---

## Tests qui verrouillent ces corrections

| Test | Correction protégée |
|---|---|
| `tests/smoke.R` : $H = 50\,000$ après 20 ans | 1 (démographie) |
| `tests/smoke.R` : masse conservée en spatial | 2 (transferts) |
| `tests/test_simulation.R` : prévalences initiales 2 / 2 / 4 % | 9 (comparaison) |
| `tests/test_simulation.R` : comparaison = calcul direct | 9 |
| `tests/test_simulation.R` : intervention neutre = référence | 8 |
| `tests/test_simulation.R` : population de Markov conservée | 7 |
