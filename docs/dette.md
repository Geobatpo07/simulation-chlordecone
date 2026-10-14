# Dette du preprint

Failles relevées dans *Modélisation de l'exposition humaine au chlordécone* (Laguerre, 1er février 2026, DOI 10.13140/RG.2.2.36238.01607), à corriger lors d'une prochaine version.

L'implémentation de ce dépôt ne reproduit pas ces erreurs : elle suit la version correcte à chaque fois (voir la dernière section et [corrections_math.md](corrections_math.md), qui détaille les formes corrigées). Les numéros de section et de page renvoient au PDF.

**Gravité** : 🔴 invalide un résultat ou une conclusion annoncés · 🟠 raisonnement incomplet ou incohérent · 🟡 notation, unité ou rédaction.

---

## 1. Résultats mathématiques

### 🔴 1.1 Le « régime périodique stable » est vide (résumé, §1, §6.7)

- Le résumé et les contributions annoncent un régime périodique stable et des « dynamiques saisonnières persistantes ».
- La fonction $V = \sum_i C_i + E + F$ vérifie $\dfrac{dV}{dt} \leq -\varepsilon V$ (§6.6) : $C$, $E$ et $F$ tendent vers 0. Dès lors $\lambda(F) \to 0$ et $(H_s, H_i)$ converge vers $\left(\dfrac{\Lambda_h}{d_h},\, 0\right)$.
- La seule solution périodique est donc l'équilibre $E_0$ lui-même (constante, donc $T$-périodique). Aucune saisonnalité ne persiste.
- Contradictions directes :
  - §6.7.5 : « la population humaine suit une dynamique périodique forcée par la saisonnalité résiduelle ». Faux : il n'y a pas de saisonnalité résiduelle quand $C = E = F = 0$.
  - §6.7.7 : « quand $A \to 0$, $y^*(t)$ dégénère vers $E_0$ ». Elle est déjà égale à $E_0$ pour tout $A$.
  - §6.7.6 décrit des « pics saisonniers » qui ne sont que du transitoire.
- À faire : reformuler comme « convergence globale vers $E_0$ quelle que soit la saisonnalité » et retirer l'argument de régime périodique, ou ajouter une source continue qui rende le régime non trivial.

### 🔴 1.2 Le Théorème 5 est mal énoncé et mal appliqué (§6.7.3 à §6.7.4)

- Le théorème affirme qu'un système $T$-périodique, dissipatif au sens « $\dfrac{dV}{dt} \leq -\varepsilon V$ », admet une solution périodique **asymptotiquement stable au sens orbital**.
- L'existence d'une solution périodique pour un système dissipatif est un résultat classique, mais la stabilité asymptotique n'en découle pas. La Remarque 1 reconnaît d'ailleurs que l'unicité n'est pas garantie, ce qui contredit la stabilité affirmée.
- La fonction $V$ du §6.7.4 ne dépend pas de $(H_s, H_i)$. Elle ne peut donc pas servir de fonction de Lyapunov du système complet. La dissipativité sur toutes les variables vient d'un autre argument (borne sur $H$), qui n'est pas relié à $V$.
- À faire : citer un théorème précis (Massera, Yoshizawa ou autre) avec ses hypothèses, ou démontrer directement la convergence vers $E_0$ par cascade ($C$, $E$, $F$ puis $H$).

### 🟠 1.3 Théorème 1 (bornes a priori, §6.1) : démonstration non rigoureuse

- La borne sur $E$ utilise une « approximation quasi-stationnaire ($E$ rapide) ». Ce n'est pas une preuve. Une borne rigoureuse s'obtient par comparaison :

$$
E' \leq r_{\max}\, g_{\max}\, C_{tot}(0)\, e^{-\delta_{\min} t} - \mu_{tot} E .
$$

- La borne sur $F$ : « $\dfrac{dF}{dt} \leq \kappa E$, donc $F$ borné » est insuffisante, car l'intégration de $\kappa E$ donne une croissance linéaire. Il faut conserver le terme $-\mu_F F$.
- La borne sur $H$ : $\dfrac{dH}{dt} = \Lambda_h - d_h H$ donne $H \leq \max\!\left(H(0),\, \dfrac{\Lambda_h}{d_h}\right)$, et non $H \leq \dfrac{\Lambda_h}{d_h}$ sans condition.

### 🟠 1.4 Théorème 3 (positivité, §6.3) : raisonnement circulaire et conclusion trop forte

- La positivité de $H_s$ utilise « $+\rho H_i \geq 0$ », donc $H_i \geq 0$. Celle de $H_i$ utilise $\lambda(F) H_s \geq 0$, donc $H_s \geq 0$. Chacune suppose l'autre. Il faut un argument de système coopératif (quasi-positivité), ou une preuve par premier instant de sortie de $\Omega$.
- Les minorations par Gronwall donnent $y_i(t) > 0$ seulement si $y_i(0) > 0$. L'énoncé « toutes les variables restent positives » est faux pour $y_i(0) = 0$ (par exemple $E(0) = 0$ ou $H_i(0) = 0$) : seule la non-négativité est garantie.

### 🟠 1.5 Théorème 4 et §6.5 : stabilité locale

- Le Théorème 4 dit « par le théorème 1, l'existence de cet équilibre est garantie ». Le Théorème 1 donne des bornes, pas l'existence d'un équilibre. La phrase est un non-sequitur ($E_0$ est trivialement un équilibre).
- La matrice $J_{cont}$ est dite « triangulaire supérieure par blocs » alors que celle écrite est triangulaire **inférieure**.
- Les sous-systèmes sont dits « découplés ». Ils sont en cascade : la jacobienne complète a un bloc de couplage $F \to (H_s, H_i)$, de terme $-\beta\,\dfrac{\Lambda_h}{d_h}$. La conclusion (valeurs propres des blocs diagonaux) reste valide, mais l'énoncé est inexact.
- L'analyse suppose $R$ constant (§6.4) alors que le système est non autonome (§6.7). La stabilité locale pour $R(t)$ n'est pas traitée.

### 🟠 1.6 §5.2.1 : le « semi-flot » ne s'applique pas à un système non autonome

- La propriété de semi-groupe $\Phi_{t+s} = \Phi_t \circ \Phi_s$ est fausse pour $f(t, y)$ dépendant de $t$. Il faut un processus d'évolution $\Phi(t, s)$ (ou l'application de Poincaré sur une période, ou un semi-flot sur le produit $\mathbb{R}/T\mathbb{Z} \times \Omega$).
- $f$ est déclaré défini sur $\mathbb{R}_+ \times \mathbb{R}^{n+4}$ (§5.1.1), alors qu'il n'est défini que sur $\Omega$ ($\lambda(F)$ n'est pas défini pour $F < 0$). $\Phi_0 = \mathrm{Id}$ est écrit « sur $\mathbb{R}^{n+4}$ » alors que l'espace est $\mathbb{R}_+^{n+4}$.

### 🟠 1.7 §6.4.2 : l'équilibre « endémique » n'existe pas

- La section annonce une source persistante, puis suppose $C = E = F = 0$ et $H_i^* = 0$. Elle conclut que l'équilibre est $E_0$, ce qui ne dit rien de l'état endémique annoncé.
- $r = r_1^0\, g(R_{moy})$ et $\delta = \delta_1$ sont définis et jamais utilisés.
- À faire : soit introduire un terme source constant et calculer l'équilibre endémique (avec saturation $F_{\max}$), soit renommer la section.

---

## 2. Modélisation et cohérence scientifique

### 🔴 2.1 La persistance annoncée contredit les paramètres retenus (§1, §8.1.1)

- L'introduction présente le chlordécone comme « extrêmement persistant », présent « plusieurs décennies » après l'arrêt de son usage.
- Le modèle (stock fini, décroissance exponentielle) prédit l'élimination. Avec $\delta \approx 10^{-3}\ \text{j}^{-1}$, la demi-vie annoncée est d'environ 2 ans. Le §8.1.1 écrit pourtant que cela « explique la contamination à long terme », ce qui est faux : 2 ans ne correspond pas à des décennies.
- Le taux réel de perte du sol est $\delta + r^0 g(R)$, pas $\delta$ seul. Avec un ruissellement de base de l'ordre de $10^{-2}\ \text{j}^{-1}$ (valeur non donnée) et $g(R) \approx 1{,}08$, la demi-vie effective tombe à environ 2 mois (59 jours) :

$$
T_{1/2} = \frac{\ln 2}{\delta + r^0 \bar{g}} = \frac{\ln 2}{0{,}001 + 0{,}01 \times 1{,}085} \approx 59\ \text{jours}.
$$

- Les limites du §1 (« pas de remobilisation ni de relargage ») excluent le mécanisme qui produit la persistance observée (réservoir sol/sédiments à libération lente).
- À faire : choisir entre un modèle fidèle à la persistance (réservoir lent, $\delta$ et $r^0$ beaucoup plus petits, remobilisation des sédiments) et un modèle d'élimination, puis aligner introduction, résumé, valeurs de paramètres et conclusion.

### 🔴 2.2 Aucune valeur de paramètre ni condition initiale, et aucun résultat numérique

- Absents : $r^0$, $\alpha$, $R_h$, $R_{moy}$, $A$, $F_{\max}$, $\beta$, $\kappa$, $\mu_E$, $\mu_F$, $\rho$, $\Lambda_h$, $d_h$, $C_i(0)$, $E(0)$, $F(0)$, $H_s(0)$, $H_i(0)$. Seuls $\delta$, $\mu_B$ et $B^*$ sont mentionnés.
- Le Tableau 2 omet $\alpha$, $R_h$, $F_{\max}$, $R_{moy}$, $A$ et $T$.
- L'annexe renvoie à une application en ligne mais ne montre aucune simulation (aucune figure ni valeur). Rien ne permet de reproduire le §8.2.1 ni de vérifier les sensibilités du §8.1.
- À faire : ajouter un tableau de valeurs de référence avec leur source (ou « hypothèse »), les conditions initiales, et au moins une figure de simulation.

### 🔴 2.3 Les affirmations quantitatives du §8 sont fausses ou non démontrées

- **« $\alpha$ de 0,5 à 1,0 peut doubler le flux » (§8.1.2)** : $g = 1 + \alpha x$ avec $x = \dfrac{R}{R_h + R} < 1$. Le rapport vaut

$$
\frac{g(\alpha = 1)}{g(\alpha = 0{,}5)} = \frac{1 + x}{1 + 0{,}5\,x} < \frac{4}{3},
$$

  donc le flux ne peut pas doubler.
- **« $+10\ \%$ sur $\delta$ réduit la demi-vie de $10\ \%$ » (§8.1.1)** : la demi-vie vaut $\dfrac{\ln 2}{\delta}$, donc elle baisse de $\dfrac{1}{1{,}1} - 1 = -9{,}1\ \%$. Et si le taux effectif est $\delta + r^0 g$, l'effet est encore plus faible.
- **« $\beta$ $-30\ \%$ réduit proportionnellement les nouveaux cas » (§8.1.4)** : $\lambda$ baisse bien de $30\ \%$, mais le flux de nouveaux cas $\lambda H_s$ n'est proportionnel à $\beta$ qu'à l'instant initial. $H_s$ évolue ensuite (retour par $\rho$, déplétion). À préciser.
- **« $\kappa$ $-50\ \%$ réduit significativement $F$ » (§8.1.3)** : $F$ n'est pas proportionnel à $\kappa$ ($\kappa$ intervient aussi dans la perte $-\kappa E$ de $E$). L'effet est à calculer, pas à affirmer.
- Aucune de ces « sensibilités » n'est calculée dans le preprint (pas d'analyse de sensibilité locale ou globale). Elles sont maintenant calculées dans [sensibilite.md](sensibilite.md) (avec des valeurs illustratives) : $\delta$ et $\alpha$ ne sont pas retrouvés comme paramètres clés, $\beta$ n'est pas proportionnel, $\kappa$ est confirmé pour $F$.

### 🟠 2.4 Prédiction du §8.2.1 non démontrée

- « Cette intervention devrait réduire $H_i/H$ de $\sim 20\ \%$ à $\sim 10\ \%$ en 5 ans » : aucune simulation, aucune valeur de paramètre, et la prévalence initiale de $20\ \%$ n'est définie nulle part (condition initiale).
- Les trois actions sont listées ($r^0$, $\beta$, $\mu_F$), mais seules deux formules sont données. La formule de $\mu_F(t)$ manque.
- $\sigma(t) = \dfrac{1}{2}\left(1 + \tanh\dfrac{t - t_0}{\tau}\right)$ n'est pas nulle à $t = 0$ : l'intervention est déjà partiellement active, avec

$$
\sigma(0) = \frac{1}{2}\left(1 - \tanh\frac{t_0}{\tau}\right) > 0 .
$$

- L'objectif (« réduire l'exposition de $50\ \%$ ») et la prédiction (« de $20\ \%$ à $10\ \%$ ») ne sont pas la même mesure (exposition vs prévalence).

### 🟠 2.5 Le §9 (charge corporelle) est incohérent avec le §4

- **Unité de $\gamma$** : $\dfrac{dB}{dt} = \gamma \dfrac{F}{H} - \mu_B B$ donne des $\mu\text{g}\cdot\text{L}^{-1}\cdot\text{j}^{-1}$. Avec $F/H$ en kg/pers., $\gamma$ doit s'exprimer en $\mu\text{g}\cdot\text{L}^{-1}\cdot\text{j}^{-1}\cdot\text{kg}^{-1}\cdot\text{pers.}$ L'unité écrite « $\mu\text{g}\cdot\text{L}^{-1}\cdot\text{kg}^{-1}\cdot\text{pers.}$ » omet le temps.
- **Stock et concentration** : $F$ est un stock (kg), et $F/H$ un stock par habitant. L'ingestion devrait dépendre de la concentration dans l'aliment ($F$ divisé par une biomasse) multipliée par la consommation, pas du stock total par habitant. Un stock plus grand dans une ressource plus abondante ne signifie pas une exposition plus forte.
- **Double description des mêmes compartiments** :
  - Le §4 définit $H_s$ et $H_i$ par des EDO ($\lambda(F)$, $\rho$).
  - Le §9.2.2 impose $H_i = H\, p_i(B)$, une fermeture algébrique instantanée.
  - Les deux ne peuvent pas être vraies en même temps. Avec la fermeture, $\lambda(F)$ et $\rho$ disparaissent.
- **Dérivée incomplète (§9.2.2)** :

$$
\frac{d(H\, p_i)}{dt} = H'\, p_i + H\, p_i'(B)\, B' ,
$$

  alors que l'équation donnée oublie le terme en $H'$.
- **Approche 1 (seuil déterministe)** : $B$ est une **moyenne** de population. Un seuil appliqué à la moyenne classe tout le monde au-dessus ou en dessous. La proportion de personnes au-dessus de $B^*$ dépend de la distribution de $B$ dans la population, pas de sa moyenne (inégalité de Jensen).
- **Pente de la sigmoïde** : l'unité de $k$ ($\text{L}/\mu\text{g}$) n'est pas donnée.
- **Seuils incohérents** : le §9.3 définit 3 niveaux ($0{,}5$ et $1$), le §10.3.2 définit 4 classes ($0{,}2$, $0{,}5$ et $1{,}0$).
- **$B^* \approx 1\ \mu\text{g/L}$ « seuil toxicologique » (§7.2)** et **la demi-vie de $\sim 150$ jours (§9.1)** ne sont pas sourcés.

### 🟠 2.6 L'exposition n'a pas de rétroaction sur la ressource, et la saturation mélange stock et flux

- La consommation humaine ne retire rien de $F$ : les humains n'apparaissent pas dans les bilans de masse. Le §2.1.1 énonce pourtant le principe de conservation de la masse comme guide.
- $F_{\max}$ est décrit comme « consommation maximale » (un flux) mais appliqué comme seuil sur un **stock** $F$ (§4.3).
- Le §7.1 liste $\mu_E E$ comme « élimination (dilution, sédimentation) ». La sédimentation est de la rétention et non de l'élimination, et c'est justement le réservoir qui expliquerait la persistance (voir 2.1).

### 🟠 2.7 §10.2 (modèle individu-centré)

- L'unité de $\gamma$ change (par rapport au §9.1) : « $\gamma\, c_k\, F/N$ » avec $c_k$ en kg/j.
- L'état $S_k$ (faible/élevé) est redondant avec $B_k$ : si la transition dépend de $B_k$, l'état est une fonction de $B_k$. Le modèle décrit deux variables pour une même information.
- Naissances : le texte dit « probabilité $\Lambda_h \Delta t$ », l'Algorithme 1 dit « $\text{Poisson}(\Lambda_h \Delta t)$ ».
- Aucune structure par âge n'existe, alors que $\rho_k$ « dépendant de l'âge » est mentionné.
- §10.2.3 : « le scénario 2 peut être plus efficace » : affirmation sans résultat.

### 🟡 2.8 §10.3 (chaîne de Markov)

- Le §10.3.3 dit que la distribution stationnaire résout $Q^\top \pi = 0$. C'est vrai pour une chaîne fermée à $F$ constant. Le système du §10.3.2 est ouvert ($\Lambda_h$, $d_h$), donc la distribution stationnaire n'est pas celle-ci.
- À $F = 0$, le texte dit « $q_{ij} = 0$ », alors que les taux de régression $\rho_i$ restent non nuls. C'est eux qui concentrent la population en classe 1.
- Collision de notation : $C_i$ désigne les parcelles (§2) et les classes (§10.3), $H_i$ désigne la population « élevée » (§2) et la classe $i$ (§10.3).

---

## 3. Rédaction, notation, références

- **Notation** : $\Lambda_H$ / $\Lambda_h$, $d_H$ / $d_h$, $H_S$ / $H_s$, $H_I$ / $H_i$, $E$ / $E_0$ utilisés indifféremment. Parcelles : $i = 1 \dots 7$ (§2.1.2, §4.4) ou $i = 1 \dots n$ (Tableau 1).
- **§2.1.2** : « 6 types de compartiments » compte $R(t)$ (variable exogène). Le modèle de base a $n + 4$ variables d'état.
- **Schéma §2.1.3** : l'étiquette « Charge élevée » est recouverte par $d_H$. Les flèches de dégradation et d'élimination sont placées avant le compartiment auquel elles s'appliquent.
- **Tableau 1** : $R(t)$ est listé comme variable d'état alors qu'il est exogène.
- **§4.3** : $\lambda$ est présentée « linéaire par morceaux » mais n'est pas dérivable en $F_{\max}$. L'effet sur la jacobienne n'est pas discuté.
- **Références** : aucune citation dans le corps du texte (les quatre références ne sont citées nulle part). Des faits précis ne sont sourcés nulle part : demi-vie de 2 ans, demi-vie de 150 jours, $B^* \approx 1\ \mu\text{g/L}$, pluviométrie $> 2000$ mm/an. Les références (Multigner 2016, Cabidoche 2009) sont à vérifier (volume et pages).
- **Orthographe** : « chlordécone » et « chlordecone » mélangés dans le texte et le titre courant.
- **§6.2** : le « théorème de prolongement » est cité sans énoncé. Citer la version utilisée.

---

## 4. Choix faits dans l'implémentation (déjà traités, sans attendre la correction)

| Faille | Choix dans le code |
|---|---|
| 1.1 / 2.1 Persistance vs élimination | Sélecteur de scénario : « Preprint » ($\delta = 10^{-3}$, $r^0 = 10^{-2}$, demi-vie du sol de 59 jours) et « Persistance longue » ($\delta = 5 \times 10^{-5}$, $r^0 = 4 \times 10^{-5}$, demi-vie du sol de 20 ans). Valeurs illustratives. |
| 2.2 Valeurs absentes | Valeurs par défaut documentées dans `app/app.R` et le README, marquées « illustratives ». Pas de calibration. |
| 2.4 Prédiction §8.2.1 | Scénario de référence sans intervention, curseur de prévalence initiale ($20\ \%$), réduction relative à 5 ans affichée. Le gain de $\sim 54\ \%$ n'est obtenu que dans le scénario « Persistance longue », et avec $\sigma(0) = 0{,}5$ (voir [corrections_math.md](corrections_math.md)). |
| 2.4 $\mu_F$ manquant | Action $\mu_F$ ajoutée à l'intervention : $\mu_F(t) = \mu_F\,(1 + c\,\sigma(t))$ (curseur, $c = 0$ par défaut). |
| 2.5 $B(t)$ | Forme du preprint ($\gamma F/H - \mu_B B$) conservée. Le lien avec $H_s$, $H_i$ se fait par un flux $S \leftrightarrow I$ de vitesse $k_{trans}$, pas par la fermeture $H_i = H\, p_i(B)$ (voir 2.5, double description). $\gamma$ ajusté par scénario ($2{,}5$ ou $60$). |
| 2.8 Markov | $\rho_1$, $\rho_2$, $\rho_3$ libres (le preprint les traite comme des paramètres). |
| Démographie | $\Lambda_H = H_0\, d_H$ (équilibre cohérent avec le §6.4.1), au lieu d'une valeur fixe qui faisait doubler la population. |
| Nombre de parcelles | Jusqu'à 7 parcelles, comme dans le §2.1.2 (le code en limitait 5 ou 6). |

*Document tenu à jour au fil des corrections du preprint.*
