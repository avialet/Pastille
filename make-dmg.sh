#!/bin/bash
set -e

APP_NAME="Lucarne"
VERSION="${1:-1.0.0}"
BUILD_DIR="build"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ $APP_BUNDLE introuvable. Lance build.sh d'abord."
    exit 1
fi

echo "📦 Création du DMG..."

# Répertoire temporaire pour le contenu du DMG
DMG_TEMP="$BUILD_DIR/dmg_temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

cp -R "$APP_BUNDLE" "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"

# Créer le DMG
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

rm -rf "$DMG_TEMP"

echo "✅ DMG créé : $DMG_PATH"
ls -lh "$DMG_PATH"
