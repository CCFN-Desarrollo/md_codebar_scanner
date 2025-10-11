# 📱 Barcode Scanner App

Una aplicación Flutter para escanear códigos de barras, gestionar productos y generar recibos de impresión.

## 📋 Características

- 🔐 Autenticación con contraseña
- ⚙️ Configuración persistente de sucursal y servidor
- 📸 Escáner de códigos de barras (simulado)
- 🔍 Búsqueda de productos
- 🖨️ Vista previa de impresión de recibos
- 🎨 Diseño minimalista con colores corporativos

## 🚀 Instalación y Configuración

### Prerequisitos

- **Flutter SDK**: 3.0 o superior
- **Dart SDK**: 3.0 o superior
- **Android Studio** o **VS Code** con extensiones de Flutter
- **Git**

### Verificar instalación de Flutter

```bash
flutter doctor
```

### Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd barcode-scanner-app
```

### Instalar dependencias

```bash
flutter pub get
```

### Arquitectura 
Conserve esta organizacion 
proyecto-flutter/
├── android/                    # Código nativo Android
├── ios/                       # Código nativo iOS  
├── lib/                       # ← AQUÍ va todo tu código Dart
│   ├── main.dart             # Punto de entrada
│   ├── screens/              # ← Pantallas aquí
│   │   ├── main_screen.dart
│   │   ├── password_screen.dart
│   │   ├── scanner_screen.dart
│   │   └── product_detail_screen.dart
│   ├── widgets/              # Widgets reutilizables
│   ├── services/             # Lógica de negocio
│   ├── models/               # Modelos de datos
│   ├── utils/                # Utilidades y constantes
│   └── theme/                # Configuración del tema
├── test/                      # Tests unitarios
├── assets/                    # Imágenes, fuentes, etc.
├── pubspec.yaml              # Dependencias del proyecto
├── .gitignore
└── README.md

## 🛠️ Comandos de Desarrollo

### 🔧 Desarrollo y Debug

#### Ejecutar en modo debug
```bash
# Ejecutar en dispositivo conectado
flutter run

# Ejecutar en un dispositivo específico
flutter devices
flutter run -d <device-id>

# Ejecutar en modo debug con hot reload habilitado
flutter run --debug
```

#### Debug avanzado
```bash
# Ejecutar con verbose para más información
flutter run --verbose

# Debug con inspector de widgets
flutter run --debug --enable-software-rendering

# Ejecutar con perfil de rendimiento
flutter run --profile
```

### 📱 Plataformas Específicas

#### Android
```bash
# Ejecutar en Android
flutter run -d android

# Ejecutar en emulador Android específico
flutter emulators
flutter emulators --launch <emulator-name>
flutter run
```

#### iOS (solo en macOS)
```bash
# Ejecutar en iOS
flutter run -d ios

# Ejecutar en simulador iOS
open -a Simulator
flutter run
```

#### Web
```bash
# Ejecutar en navegador web
flutter run -d web-server --web-port 8080
# o simplemente
flutter run -d chrome
```

### 🔨 Build y Release

#### Android APK
```bash
# Build APK debug
flutter build apk --debug

# Build APK release
flutter build apk --release

# Build APK con split por ABI (archivos más pequeños)
flutter build apk --split-per-abi --release
```

#### Android App Bundle (recomendado para Play Store)
```bash
# Build AAB release
flutter build appbundle --release
```

#### iOS (solo en macOS)
```bash
# Build iOS release
flutter build ios --release

# Build IPA
flutter build ipa --release
```

#### Web
```bash
# Build web release
flutter build web --release
```

## 🧪 Testing

### Ejecutar tests
```bash
# Ejecutar todos los tests
flutter test

# Ejecutar tests con coverage
flutter test --coverage

# Ejecutar tests específicos
flutter test test/widget_test.dart

# Tests de integración
flutter drive --target=test_driver/app.dart
```

### Tests de rendimiento
```bash
# Análisis de rendimiento
flutter run --profile --trace-startup --verbose
```

## 🔍 Análisis de Código

### Análisis estático
```bash
# Analizar código
flutter analyze

# Formatear código
flutter format .

# Formatear con línea específica
flutter format --line-length 80 .
```

### Verificar dependencias
```bash
# Verificar dependencias obsoletas
flutter pub outdated

# Actualizar dependencias
flutter pub upgrade

# Limpiar dependencias
flutter clean
flutter pub get
```

## 📊 Monitoreo y Debugging

### Herramientas de desarrollo
```bash
# Abrir DevTools en navegador
flutter pub global activate devtools
flutter pub global run devtools

# Inspector de widgets
flutter inspector

# Perfilador de rendimiento
flutter run --profile
# Luego ir a DevTools -> Performance
```

### Logs y debugging
```bash
# Ver logs en tiempo real
flutter logs

# Logs específicos de Android
adb logcat

# Logs específicos de iOS
idevicesyslog
```

## 🚀 Despliegue

### Android
1. **Configurar signing en `android/app/build.gradle`**
2. **Generar keystore**:
   ```bash
   keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
   ```
3. **Build release**:
   ```bash
   flutter build appbundle --release
   ```

### iOS
1. **Configurar certificados en Xcode**
2. **Build release**:
   ```bash
   flutter build ipa --release
   ```

### Web
1. **Build web**:
   ```bash
   flutter build web --release
   ```
2. **Desplegar** en servidor web o servicio como Firebase Hosting

## ⚙️ Configuración del Proyecto

### Estructura de archivos importante
```
lib/
├── main.dart                    # Punto de entrada
├── screens/                     # Pantallas principales
├── widgets/                     # Widgets reutilizables
├── services/                    # Lógica de negocio
├── models/                      # Modelos de datos
├── utils/                       # Utilidades y constantes
└── theme/                       # Configuración del tema
```

### Dependencias principales
```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2    # Persistencia local
  # Para escáner real (opcional):
  # barcode_scan2: ^4.2.3
```

## 🔧 Configuración de la App

### Credenciales por defecto
- **Contraseña de configuración**: `password?facil`

### SKUs de prueba
- `12345` - Producto Ejemplo 1 ($29.99)
- `67890` - Producto Ejemplo 2 ($45.50)  
- `11111` - Producto Ejemplo 3 ($15.75)
- `22222` - Producto Ejemplo 4 ($99.99)
- `33333` - Producto Ejemplo 5 ($8.25)

## 🐛 Troubleshooting

### Problemas comunes

#### Error de dependencias
```bash
flutter clean
flutter pub get
```

#### Error de build Android
```bash
cd android
./gradlew clean
cd ..
flutter build apk
```

#### Error de build iOS
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter build ios
```

#### Error de hot reload
```bash
# Reiniciar completamente
flutter run --hot
# Presionar 'r' en terminal para hot reload
# Presionar 'R' en terminal para hot restart
```

### Comandos útiles de limpieza
```bash
# Limpieza completa del proyecto
flutter clean
flutter pub get

# Limpiar cache de Flutter
flutter pub cache clean

# Reparar instalación de Flutter
flutter doctor --android-licenses
flutter config --enable-web
```

## 📚 Recursos Adicionales

- [Documentación oficial de Flutter](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Material Design Guidelines](https://material.io/design)

## 🤝 Contribución

1. Fork el proyecto
2. Crear una rama feature (`git checkout -b feature/nueva-caracteristica`)
3. Commit los cambios (`git commit -m 'Agregar nueva característica'`)
4. Push a la rama (`git push origin feature/nueva-caracteristica`)
5. Abrir un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 👥 Autores

- **Tu Nombre** - *Desarrollo inicial* - [TuUsuario](https://github.com/tuusuario)

## 🆘 Soporte

Si tienes preguntas o problemas:
1. Revisa la sección de [Troubleshooting](#-troubleshooting)
2. Busca en [Issues existentes](../../issues)
3. Crea un [nuevo Issue](../../issues/new) si no encuentras solución

## 📄NOTAS
 - Intente usar flutter_blue_plus pero no pude encontrar la impresora con la que estoy trabajando al parecer es porque la impresora TSC usa otro puerto Bluetooth Serial Port Profile (SPP). Se modifico el servicio par apoder utilizar el package flutter_bluetooth_serial pero al ser un paquete viejo y sin mantenimiento(4 anos sin actualizacion) tenemos que modificar dos archivos: build.gradle y AndroidManifest.xml directamente de donde se instalo el paquete.
 En mi caso:
 ´´´
 c
 ´´´
```bash
# C:\Users\DESARROLLO\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_bluetooth_serial-0.4.0\android\build.gradle

android {
    namespace "com.shinow.qrscan.flutter_bluetooth_serial"
    compileSdkVersion 33

    defaultConfig {
        minSdkVersion 21
    }
}

```
```bash
# C:\Users\DESARROLLO\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_bluetooth_serial-0.4.0\android\build.gradle

<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="io.github.edufolly.flutterbluetoothserial">

# Dejar asi:
<manifest xmlns:android="http://schemas.android.com/apk/res/android">


```

