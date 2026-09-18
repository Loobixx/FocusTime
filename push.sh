#!/bin/bash

TARGET_FILE="lib/models/city_network.dart"
COMMIT_MSG=${1:-"Mise à jour"}

echo "🚀 Préparation du push..."

# 1. Désactive le devMode
sed -i 's/static const bool isDevMode = true;/static const bool isDevMode = false;/' "$TARGET_FILE"

# 2. Stage, commit et push
git add .
git commit -m "$COMMIT_MSG"
git push

# 3. Réactive le devMode localement après le push pour continuer à travailler
sed -i 's/static const bool isDevMode = false;/static const bool isDevMode = true;/' "$TARGET_FILE"
echo "✅ Push terminé et isDevMode réactivé localement !"