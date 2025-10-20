#!/bin/bash
set -euo pipefail

# --- Usage ---
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <decompiled-apk-dir> <final-signed-apk-name> [sanitize-resources]"
    echo "Example: $0 myapp_dec myapp_signed.apk 1"
    exit 1
fi

# --- Arguments ---
APK_DIR="$1"
SIGNED_APK="$2"
SANITIZE_RESOURCES="${3:-0}"  # optional, default 0

# --- Configuration ---
KEYSTORE="debug.jks"
STOREPASS="android"
ALIAS="labkey"
PATCHED_APK="patched.apk"
ALIGNED_APK="aligned.apk"

# --- Cleanup previous files ---
rm -f "$KEYSTORE" "$PATCHED_APK" "$ALIGNED_APK" "$SIGNED_APK"

# --- Step 1: Generate keystore ---
keytool -genkeypair \
    -alias "$ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -keystore "$KEYSTORE" \
    -storepass "$STOREPASS" \
    -dname "CN=Lab, O=You"

# --- Step 2-3: Optional sanitization ---
if [[ "$SANITIZE_RESOURCES" -eq 1 ]]; then
    echo "🔧 Sanitizing \$-prefixed resource filenames in $APK_DIR/res..."
    find "$APK_DIR/res" -type f -name '\$*' | while read -r f; do
        newf="$(dirname "$f")/$(basename "$f" | tr -d '$')"
        mv "$f" "$newf"
    done

    echo "🔧 Updating XML references..."
    grep -rl '@drawable/\$' "$APK_DIR/res" | while read -r file; do
        sed -i 's/@drawable\/\$/@drawable\//g' "$file"
    done
fi

# --- Step 4: Build APK ---
apktool b "$APK_DIR" -o "$PATCHED_APK"
apktool b "$APK_DIR" --use-aapt2 -o "$PATCHED_APK"

# --- Step 5: Align APK ---
zipalign -p -f 4 "$PATCHED_APK" "$ALIGNED_APK"

# --- Step 6: Sign APK ---
apksigner sign \
    --ks "$KEYSTORE" \
    --ks-pass pass:"$STOREPASS" \
    --key-pass pass:"$STOREPASS" \
    --out "$SIGNED_APK" \
    "$ALIGNED_APK"

echo "✅ APK successfully patched, aligned, and signed: $SIGNED_APK"
