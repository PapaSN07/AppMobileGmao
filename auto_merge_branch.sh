#!/bin/bash

# Nom des branches (adaptez selon vos noms réels)
BACKEND_BRANCH="backend"
ANGULAR_BRANCH="frontend_web"
FLUTTER_BRANCH="frontend_mobile"

# Aller sur main
git checkout main

# Fonction pour merger une branche dans un dossier
merge_to_subdirectory() {
    local branch=$1
    local folder=$2
    
    echo "Merging $branch into $folder/..."
    
    git merge -s ours --no-commit --allow-unrelated-histories $branch
    git read-tree --prefix=$folder/ -u $branch
    git commit -m "merge: integrate $branch into $folder/ folder"
    
    echo "✓ $branch merged successfully"
}

# Merger chaque branche
merge_to_subdirectory $BACKEND_BRANCH "backend"
merge_to_subdirectory $ANGULAR_BRANCH "frontend_web"
merge_to_subdirectory $FLUTTER_BRANCH "frontend_mobile"

echo "✓ All branches merged successfully!"
echo "Don't forget to push: git push origin main"