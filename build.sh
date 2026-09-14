#!/bin/bash

# 1. Netlify télécharge la version stable de Flutter
git clone https://github.com/flutter/flutter.git -b stable

# 2. On indique à Netlify où se trouve Flutter pour qu'il puisse l'utiliser
export PATH="$PATH:`pwd`/flutter/bin"

# 3. On télécharge les paquets de ton projet et on lance la construction web
flutter pub get
flutter build web