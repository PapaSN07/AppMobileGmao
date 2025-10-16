#!/bin/bash
set -euo pipefail

# Branches à intégrer
BACKEND_BRANCH="origin/backend"
ANGULAR_BRANCH="origin/frontend_web"
FLUTTER_BRANCH="origin/frontend_mobile"

BACKUP_DIR="backup"

git checkout main
git fetch --all --prune

# Créer le dossier backup s'il n'existe pas
mkdir -p "$BACKUP_DIR"

# Fonction pour vérifier si des changements existent
has_changes() {
  local folder="$1"
  local branch="$2"
  
  # Si le dossier n'existe pas localement, pas besoin de backup
  [ ! -d "$folder" ] && return 1
  
  # Comparer l'arbre local avec la branche distante
  local diff_output=$(git diff --name-only "$branch" -- "$folder" 2>/dev/null || echo "diff")
  
  [ -n "$diff_output" ] && return 0 || return 1
}

backup_and_prepare_prefix() {
  local folder="$1"
  local branch="$2"
  
  # Vérifier si des changements existent
  if ! has_changes "$folder" "$branch"; then
    echo "ℹ️  No changes detected for $folder, skipping backup"
    # Même sans changements, on doit nettoyer le dossier pour éviter les conflits
    if [ -d "$folder" ]; then
      echo "🧹 Removing $folder/ to avoid conflicts"
      rm -rf "$folder"
    fi
    return 0
  fi
  
  # Si dossier présent et avec changements, le sauvegarder dans backup/
  if [ -d "$folder" ]; then
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local bak="${BACKUP_DIR}/${folder}_${timestamp}.bak"
    echo "📦 Backup $folder -> $bak (changes detected)"
    mkdir -p "$(dirname "$bak")"
    cp -r "$folder" "$bak"
    
    # IMPORTANT : Supprimer physiquement le dossier après backup
    echo "🗑️  Removing $folder/ from working tree"
    rm -rf "$folder"
  fi

  # Retirer les entrées du préfixe de l'index si elles existent encore
  if git ls-files | grep -qE "^${folder}/"; then
    echo "🧹 Removing index entries for ${folder}/"
    git ls-files | grep -E "^${folder}/" | xargs -r git rm --cached -r --ignore-unmatch || true
  fi
}

merge_to_subdirectory() {
  local branch="$1"
  local folder="$2"

  echo ""
  echo "🔀 Merging $branch into $folder/..."
  
  # Merge strategy "ours" pour conserver l'historique
  git merge -s ours --no-commit --allow-unrelated-histories "$branch" || true

  # Préparer le préfixe (backup conditionnel + nettoyage complet)
  backup_and_prepare_prefix "$folder" "$branch"

  # Injecter l'arbre de la branche distante sous le préfixe
  echo "📥 Injecting $branch tree into $folder/"
  git read-tree --prefix="${folder}/" -u "$branch"

  # Ajouter et committer
  git add "$folder"
  
  if git diff --cached --quiet; then
    echo "ℹ️  No changes to commit for $folder"
  else
    git commit -m "merge: integrate $branch into $folder/ folder"
    echo "✅ $branch merged successfully into $folder/"
  fi
}

# Merger chaque branche dans son dossier respectif
merge_to_subdirectory "$BACKEND_BRANCH" "backend"
merge_to_subdirectory "$ANGULAR_BRANCH" "frontend_web"
merge_to_subdirectory "$FLUTTER_BRANCH" "frontend_mobile"

echo ""
echo "✅ All branches merged successfully!"
echo "📁 Backups saved in: $BACKUP_DIR/"
echo ""
echo "💡 Next steps:"
echo "   1. Review changes: git status"
echo "   2. Push to remote: git push origin main"
echo "   3. Clean old backups if needed: rm -rf $BACKUP_DIR/*.bak"