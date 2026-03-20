#!/bin/bash
set -e

APP_NAME="Lucarne"
VERSION="${1:-1.0.0}"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "🔨 Building $APP_NAME v$VERSION..."

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RESOURCES"

# Trouver tous les fichiers Swift
SOURCES=$(find Lucarne -name "*.swift" | tr '\n' ' ')

echo "   Sources: $(echo "$SOURCES" | wc -w | tr -d ' ') fichiers"

# Compilation
swiftc \
    $SOURCES \
    -o "$MACOS/$APP_NAME" \
    -target arm64-apple-macosx13.0 \
    -framework AppKit \
    -framework SwiftUI \
    -framework CoreGraphics \
    -framework Carbon \
    -Osize \
    -whole-module-optimization

# Copier les ressources
cp Resources/Info.plist "$CONTENTS/"

# Mettre à jour la version dans Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS/Info.plist"

# Nettoyer les attributs étendus (resource forks) avant signature
xattr -cr "$APP_BUNDLE"

# Signer avec les entitlements
if [ -f Resources/Lucarne.entitlements ]; then
    codesign --force --sign - --entitlements Resources/Lucarne.entitlements "$APP_BUNDLE"
else
    codesign --force --sign - "$APP_BUNDLE"
fi

echo "✅ Built $APP_BUNDLE"
echo "   Version: $VERSION"
ls -lh "$MACOS/$APP_NAME"
