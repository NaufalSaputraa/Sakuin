# Sakuin (索引) — Deployment & Release Pipeline

> Android Release Configuration, Build Automation, and Store Packaging.

---

## 1. Target Platforms & Environment Requirements

| Target | Requirement |
|--------|-------------|
| **Primary Platform** | Android (minSdk 26 / Android 8.0 Oreo, targetSdk 34) |
| **Flutter SDK** | Flutter 3.29.x / Dart 3.7.x |
| **Java / Gradle** | JDK 17, Gradle 8.x |
| **NDK** | Required for TFLite / on-device native libraries |

---

## 2. Release Build Steps

### 2.1 Code Quality & Pre-Build Checks
```bash
# 1. Clean build directory
flutter clean
flutter pub get

# 2. Re-generate Drift models
dart run build_runner build --delete-conflicting-outputs

# 3. Static analysis & test suite
flutter analyze
flutter test

# 4. AG-Kit verification checklist
python .agent/scripts/checklist.py .
```

### 2.2 Android App Bundle (AAB) Generation
```bash
# Build production Android App Bundle with tree-shaking
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### 2.3 Standalone APK for Direct Sideloading
```bash
flutter build apk --release --split-per-abi
```

---

## 3. Keystore Configuration & Signing

Configure `android/key.properties` (never commit to git):
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=sakuin_release
storeFile=../keystore/sakuin-release.jks
```

Reference in `android/app/build.gradle`:
```groovy
android {
    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties['keyAlias']
                keyPassword = keystoreProperties['keyPassword']
                storeFile = file(keystoreProperties['storeFile'])
                storePassword = keystoreProperties['storePassword']
            }
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```
