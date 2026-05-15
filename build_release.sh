#!/bin/bash
# Build release APK with obfuscation
# Prerequisites:
#   1. Create a keystore: keytool -genkey -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
#   2. Create android/key.properties with:
#      storePassword=<password>
#      keyPassword=<password>
#      keyAlias=upload
#      storeFile=../upload-keystore.jks
#   3. Configure signing in android/app/build.gradle.kts (see Flutter docs)

flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# Also build appbundle for Play Store
# flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info

echo "APK built at build/app/outputs/flutter-apk/app-release.apk"
