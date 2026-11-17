# flutter_bluetooth_serial 0.4.0 (parchado)

Copia de https://pub.dev/packages/flutter_bluetooth_serial 0.4.0 (MIT, Eduardo Folly).
El paquete está abandonado y no compila con el Android Gradle Plugin actual, así que se
incluye en el repo con estos cambios (los mismos que se aplicaban a mano en el pub-cache):

- `android/build.gradle`: se agrega `namespace` (obligatorio desde AGP 8) y `compileSdkVersion 33`.
- `android/src/main/AndroidManifest.xml`: se quita el atributo `package=` (lo reemplaza `namespace`).

`pubspec.yaml` de la app lo usa con `path: packages/flutter_bluetooth_serial`.
