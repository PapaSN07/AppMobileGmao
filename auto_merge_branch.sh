#!/bin/bash
set -euo pipefail

# Branches à intégrer (adapter si besoin)
BACKEND_BRANCH="origin/backend"
ANGULAR_BRANCH="origin/frontend_web"
FLUTTER_BRANCH="origin/frontend_mobile"

BACKUP_DIR="backup"

git checkout main
git fetch --all --prune

# Ensure backup dir exists and is not tracked
mkdir -p "$BACKUP_DIR"

backup_and_prepare_prefix() {
  local folder="$1"
  # si dossier présent dans l'arbre de travail, le déplacer dans backup
  if [ -d "$folder" ]; then
    local bak="${BACKUP_DIR}/${folder}.$(date +%Y%m%d%H%M%S).bak"
    echo "Backup existing $folder -> $bak"
    mkdir -p "$(dirname "$bak")"
    mv "$folder" "$bak"
  fi

  # retirer toute trace indexée du préfixe (ne supprime pas les fichiers locaux déjà déplacés)
  if git ls-files | grep -qE "^${folder}/"; then
    echo "Removing index entries for ${folder}/"
    git ls-files | grep -E "^${folder}/" | xargs -r git rm --cached -r --ignore-unmatch
  fi
}

merge_to_subdirectory() {
  local branch="$1"
  local folder="$2"

  echo "Merging $branch into $folder/..."
  # faire un merge "ours" pour conserver historique sans modifier fichiers
  git merge -s ours --no-commit --allow-unrelated-histories "$branch" || true

  # préparer préfixe (sauvegarde + nettoyage index) pour éviter overlaps
  backup_and_prepare_prefix "$folder"

  # injecter l'arbre sous le préfixe
  git read-tree --prefix="${folder}/" -u "$branch"

  # ajouter et committer l'intégration
  git add "$folder"
  git commit -m "merge: integrate $branch into $folder/ folder"

  echo "✓ $branch merged successfully"
}

merge_to_subdirectory "$BACKEND_BRANCH" "backend"
merge_to_subdirectory "$ANGULAR_BRANCH" "frontend_web"
merge_to_subdirectory "$FLUTTER_BRANCH" "frontend_mobile"

echo "✓ All branches merged successfully!"
echo "Don't forget to push: git push origin main"