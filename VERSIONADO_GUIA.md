# 📱 Guía de Versionado y Actualización de la App

## 🎯 Fuente Única de Verdad: `pubspec.yaml`

La versión de tu aplicación se define **ÚNICAMENTE** en `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

### Formato de Versión:
```
MAJOR.MINOR.PATCH+BUILD_NUMBER
  1  .  0  .  0  +  1

- MAJOR (1): Cambios incompatibles con versiones anteriores
- MINOR (0): Nuevas funcionalidades compatibles
- PATCH (0): Correcciones de bugs
- BUILD_NUMBER (+1): Número de compilación (incrementa en cada build)
```

---

## 📊 Sistema de Versiones

### ✅ **CORRECTO** - Una sola fuente
```yaml
# pubspec.yaml
version: 1.0.0+1
```

### ❌ **INCORRECTO** - Duplicar en constants
```dart
// NO hagas esto - causa confusión
static const String appVersion = '1.0.0';
```

---

## 🔄 Cómo Leer la Versión en el Código

### Usar `package_info_plus`:

```dart
import 'package:package_info_plus/package_info_plus.dart';

// Obtener información de la app
PackageInfo packageInfo = await PackageInfo.fromPlatform();

String appName = packageInfo.appName;        // "md_codebar_scanner"
String version = packageInfo.version;        // "1.0.0"
String buildNumber = packageInfo.buildNumber; // "1"
```

---

## 🚀 Proceso de Actualización de Versión

### **Paso 1: Actualizar `pubspec.yaml`**

```yaml
# Antes
version: 1.0.0+1

# Después (nueva versión)
version: 1.0.1+2
```

**Reglas para incrementar:**
- Bug fix: `1.0.0+1` → `1.0.1+2`
- Nueva feature: `1.0.0+1` → `1.1.0+2`
- Breaking change: `1.0.0+1` → `2.0.0+2`

**IMPORTANTE:** Siempre incrementa el BUILD_NUMBER (+2, +3, +4, etc.)

---

### **Paso 2: Construir el APK**

```bash
# Construir APK de release
flutter build apk --release

# O construir para arquitecturas específicas
flutter build apk --release --split-per-abi

# Ver información del build
flutter build apk --release --verbose
```

**El APK resultante estará en:**
```
build/app/outputs/flutter-apk/app-release.apk
```

---

### **Paso 3: Actualizar archivo de versión en servidor**

Actualiza el archivo `.text` en tu servidor:

**Ubicación:**
```
http://192.168.101.20:5000/sap10/MD_CODEBAR_SCANNER_VERSION.text
```

**Contenido del archivo:**
```
1.0.1
```

**IMPORTANTE:** 
- Solo el número de versión (sin +buildNumber)
- Sin espacios extras
- Sin saltos de línea al final

---

## 🔍 Sistema de Detección de Actualizaciones

### Cómo Funciona:

```dart
// 1. Lee versión actual de la app instalada
PackageInfo packageInfo = await PackageInfo.fromPlatform();
String currentVersion = packageInfo.version; // "1.0.0"

// 2. Descarga versión del servidor
final response = await http.get(Uri.parse(versionCheckUrl));
String latestVersion = response.body.trim(); // "1.0.1"

// 3. Compara versiones
if (_isNewVersionAvailable(currentVersion, latestVersion)) {
  // Mostrar diálogo de actualización
}
```

### Ejemplos de Comparación:

| Versión Instalada | Versión Servidor | ¿Actualizar? |
|-------------------|------------------|--------------|
| 1.0.0 | 1.0.1 | ✅ SÍ |
| 1.0.0 | 1.1.0 | ✅ SÍ |
| 1.0.0 | 2.0.0 | ✅ SÍ |
| 1.0.1 | 1.0.0 | ❌ NO |
| 1.0.0 | 1.0.0 | ❌ NO |

---

## 📝 Workflow Completo de Release

### 1. **Desarrollo y Testing**
```bash
flutter run --debug
# Probar la app
```

### 2. **Incrementar Versión**
```yaml
# pubspec.yaml
version: 1.0.1+2
```

### 3. **Construir Release**
```bash
# Limpiar builds anteriores
flutter clean

# Obtener dependencias
flutter pub get

# Construir APK
flutter build apk --release
```

### 4. **Verificar el APK**
```bash
# Instalar en dispositivo de prueba
adb install build/app/outputs/flutter-apk/app-release.apk

# Verificar versión instalada
adb shell dumpsys package com.tuapp | grep versionName
```

### 5. **Subir a Servidor**
```bash
# Subir APK
http://crm.ccfnweb.com.mx/sap10/MD_CODEBAR_SCANNER.apk

# Actualizar archivo de versión
echo "1.0.1" > MD_CODEBAR_SCANNER_VERSION.text
# Subir MD_CODEBAR_SCANNER_VERSION.text
```

---

## 🔧 Comandos Útiles

### Ver información del proyecto:
```bash
flutter doctor -v
```

### Ver versión actual del código:
```bash
grep "^version:" pubspec.yaml
```

### Construir con nombre personalizado:
```bash
flutter build apk --release --build-name=1.0.1 --build-number=2
```

### Construir APKs por arquitectura (menor tamaño):
```bash
flutter build apk --release --split-per-abi
# Genera: app-armeabi-v7a-release.apk, app-arm64-v8a-release.apk, app-x86_64-release.apk
```

---

## 🎯 Mejores Prácticas

### ✅ **DO (Hacer):**
1. Incrementar versión en `pubspec.yaml` antes de cada build
2. Siempre incrementar el build number
3. Usar versionado semántico (MAJOR.MINOR.PATCH)
4. Mantener un changelog de cambios
5. Probar el APK en dispositivo real antes de distribuir
6. Actualizar el archivo de versión en servidor

### ❌ **DON'T (No hacer):**
1. NO duplicar versión en constants.dart
2. NO olvidar incrementar el build number
3. NO usar la misma versión para builds diferentes
4. NO subir APK sin probar
5. NO olvidar actualizar el archivo .text del servidor

---

## 📋 Checklist de Release

```markdown
- [ ] Incrementar versión en pubspec.yaml
- [ ] Ejecutar flutter clean
- [ ] Ejecutar flutter pub get
- [ ] Construir APK: flutter build apk --release
- [ ] Probar APK en dispositivo físico
- [ ] Verificar versión instalada
- [ ] Subir APK a servidor
- [ ] Actualizar archivo VERSION.text en servidor
- [ ] Notificar a usuarios
- [ ] Documentar cambios en changelog
```

---

## 🐛 Troubleshooting

### Problema: "La app no detecta actualizaciones"
```
✅ Verificar que VERSION.text tenga formato correcto
✅ Verificar que la URL del archivo sea accesible
✅ Verificar que no haya espacios o caracteres extras
✅ Incrementar la versión correctamente
```

### Problema: "Build number no incrementa"
```
✅ Verificar pubspec.yaml: version: x.x.x+BUILD
✅ Ejecutar flutter clean
✅ Ejecutar flutter pub get
```

### Problema: "APK muy grande"
```
✅ Usar --split-per-abi para generar APKs por arquitectura
✅ Habilitar obfuscación: flutter build apk --release --obfuscate
```

---

## 📚 Recursos

- [Documentación de Flutter - Build y Release](https://docs.flutter.dev/deployment/android)
- [Semantic Versioning](https://semver.org/)
- [Package Info Plus](https://pub.dev/packages/package_info_plus)

---

## ⚡ Quick Reference

```bash
# Ver versión actual
grep "^version:" pubspec.yaml

# Build release
flutter build apk --release

# Install APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Ver versión instalada
adb shell dumpsys package YOUR_PACKAGE_NAME | grep versionName
```

---

✅ **Ahora tu app usa una única fuente de verdad para la versión**
✅ **No hay duplicación en constants.dart**
✅ **La versión se lee dinámicamente con package_info_plus**
