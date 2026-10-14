#!/usr/bin/env bash
# Lancement de l'application Shiny (Linux, macOS, Git Bash sous Windows).
# Usage : ./app/launch.sh   (depuis n'importe quel dossier)

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

echo "============================================"
echo "Application Shiny - Modelisation Chlordecone"
echo "============================================"
echo

# 1) Rscript dans le PATH, 2) sinon les emplacements habituels
RSCRIPT="$(command -v Rscript || true)"

if [ -z "$RSCRIPT" ]; then
    candidats=(
        "/usr/local/bin/Rscript"
        "/opt/homebrew/bin/Rscript"
        "/Library/Frameworks/R.framework/Resources/bin/Rscript"
        "/usr/lib/R/bin/Rscript"
    )
    # Windows (Git Bash) : la version de R la plus récente dans Program Files
    if [ -d "/c/Program Files/R" ]; then
        while IFS= read -r d; do candidats+=("$d/bin/Rscript.exe"); done \
            < <(ls -d "/c/Program Files/R"/R-* 2>/dev/null | sort -rV)
    fi
    for c in "${candidats[@]}"; do
        if [ -x "$c" ]; then RSCRIPT="$c"; break; fi
    done
fi

if [ -z "$RSCRIPT" ]; then
    echo "ERREUR: R n'a pas ete trouve sur votre systeme." >&2
    echo "Installez R depuis https://cran.r-project.org/ ou ajoutez Rscript au PATH." >&2
    exit 1
fi

echo "R trouve: $RSCRIPT"
echo
echo "Lancement de l'application (Ctrl+C pour arreter)..."
echo

exec "$RSCRIPT" --vanilla run.R
