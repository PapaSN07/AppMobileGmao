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

cleanup_prefix() {
  local folder="$1"
  
  echo "🧹 Cleaning up $folder/ completely..."
  
  # 1. Annuler tout merge en cours pour ce préfixe
  git reset HEAD "$folder" 2>/dev/null || true
  
  # 2. Supprimer du working tree
  if [ -d "$folder" ]; then
    rm -rf "$folder"
    echo "   ✓ Removed from working tree"
  fi
  
  # 3. Supprimer de l'index (toutes les entrées)
  if git ls-files | grep -qE "^${folder}/"; then
    git rm -rf --cached --ignore-unmatch "$folder/" 2>/dev/null || true
    echo "   ✓ Removed from index"
  fi
  
  # 4. Vérifier que c'est bien nettoyé
  if git ls-files | grep -qE "^${folder}/"; then
    echo "   ⚠️  Warning: Some index entries still remain, forcing cleanup..."
    git ls-files | grep -E "^${folder}/" | xargs -r git rm --cached --force --ignore-unmatch || true
  fi
  
  echo "   ✓ Cleanup complete"
}

merge_to_subdirectory() {
  local branch="$1"
  local folder="$2"

  echo ""
  echo "🔀 Merging $branch into $folder/..."
  
  # Vérifier si backup nécessaire
  local need_backup=false
  if has_changes "$folder" "$branch"; then
    need_backup=true
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local bak="${BACKUP_DIR}/${folder}_${timestamp}.bak"
    echo "📦 Backup $folder -> $bak (changes detected)"
    mkdir -p "$(dirname "$bak")"
    cp -r "$folder" "$bak"
  else
    echo "ℹ️  No changes detected for $folder, skipping backup"
  fi
  
  # Nettoyer complètement le préfixe (working tree + index)
  cleanup_prefix "$folder"
  
  # Merge strategy "ours" pour conserver l'historique
  echo "📝 Creating merge commit..."
  git merge -s ours --no-commit --allow-unrelated-histories "$branch" 2>/dev/null || true
  
  # Injecter l'arbre de la branche distante sous le préfixe
  echo "📥 Injecting $branch tree into $folder/"
  git read-tree --prefix="${folder}/" -u "$branch"
  
  if [ $? -ne 0 ]; then
    echo "❌ Failed to inject tree for $folder"
    echo "   Attempting recovery..."
    git read-tree --reset HEAD
    cleanup_prefix "$folder"
    git read-tree --prefix="${folder}/" -u "$branch"
  fi

  # Ajouter et committer
  git add "$folder"
  
  if git diff --cached --quiet; then
    echo "ℹ️  No changes to commit for $folder"
  else
    git commit -m "merge: integrate $branch into $folder/ folder" || echo "⚠️  Commit failed for $folder"
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
echo "   3. Clean old backups: ls -la $BACKUP_DIR/ && rm -rf $BACKUP_DIR/*.bak"