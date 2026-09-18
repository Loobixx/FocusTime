#!/bin/bash

TARGET_FILE="lib/models/city_network.dart"
COMMIT_MSG=${1:-"Mise à jour"}

echo "🚀 Préparation du push..."

# Remplacement ciblant le mot-clé indépendamment des espaces ou caractères invisibles
perl -i -pe 's/isDevMode\s*=\s*true/isDevMode = false/g' "$TARGET_FILE"

# Vérification
if grep -q "isDevMode = false;" "$TARGET_FILE"; then
  echo "✅ isDevMode est bien passé à false."
else
  echo "❌ Échec du remplacement dans $TARGET_FILE !"
  exit 1
fi

# Git workflow
git add .
git commit -m "$COMMIT_MSG"
git push

# Rétablissement pour le travail local
perl -i -pe 's/isDevMode\s*=\s*false/isDevMode = true/g' "$TARGET_FILE"
echo "✅ isDevMode réactivé localement !"