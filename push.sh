#!/bin/bash

TARGET_FILE="lib/models/city_network.dart"
COMMIT_MSG="$1"

# 🛑 Vérifie qu'un message de commit non vide a bien été fourni
if [ -z "$COMMIT_MSG" ]; then
  echo "❌ Erreur : Tu dois obligatoirement renseigner un message de commit !"
  echo "👉 Exemple : ./push.sh \"Mon message de commit\""
  exit 1
fi

# 🛑 Vérifie que le fichier cible existe bien
if [ ! -f "$TARGET_FILE" ]; then
  echo "❌ Erreur : Le fichier $TARGET_FILE est introuvable depuis ce dossier !"
  exit 1
fi

echo "🚀 Préparation du push..."

# Remplacement avec sed (plus stable sur Git Bash) qui gère les espaces variables
sed -i 's/isDevMode *= *true/isDevMode = false/g' "$TARGET_FILE"

# Vérification plus souple (sans le point-virgule)
if grep -q "isDevMode = false" "$TARGET_FILE"; then
  echo "✅ isDevMode est bien passé à false."
else
  echo "❌ Échec du remplacement dans $TARGET_FILE !"
  echo "💡 Astuce : Vérifie que ton fichier contient bien 'isDevMode = true' (et pas déjà false ou un autre nom de variable)."
  exit 1
fi

# Git workflow
git add .
git commit -m "$COMMIT_MSG"
git push

# Rétablissement pour le travail local
sed -i 's/isDevMode *= *false/isDevMode = true/g' "$TARGET_FILE"
echo "✅ isDevMode réactivé localement !"