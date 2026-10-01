# Changelog

Todos los cambios notables de este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Versionado Semántico](https://semver.org/lang/es/).

---

## [2.0.0] - 2026-10-01

### 🎉 Agregado
- **Impresión en lote** para re-etiquetación masiva (#14)
  - Nuevo botón **Impresión en Lote** en la pantalla principal (visible para todos los perfiles)
  - Escaneo continuo: la cámara no se cierra; cada código se agrega al instante y el producto se consulta en segundo plano. También acepta captura manual o lector de hardware
  - Re-escanear un producto suma +1 impresión (tope 10); otro código de barras del mismo artículo se fusiona
  - Pantalla **Revisar Lote**: frente e impresiones editables por producto (1 por defecto, máximo 10), **Aplicar a todos**, quitar productos y reintentar los no encontrados
  - Un solo botón imprime todo con progreso *x de N*; en Bluetooth se conecta una sola vez y en el servicio Zebra se envían bloques de 10 productos por request
  - Si la impresión falla a medias, se quitan de la lista los productos ya impresos para reintentar solo los pendientes
  - La lista se guarda en el dispositivo y se conserva al cerrar la app; botón **Eliminar lista** con confirmación
  - Selector **Cámara | Lector / Teclado** (se recuerda por dispositivo): en modo cámara no se muestra el campo de texto ni el teclado; en modo lector se oculta la cámara y el lector óptico escribe sin abrir el teclado en pantalla (botón para mostrarlo y capturar a mano)
  - Lector óptico: el código se agrega solo, sin tocar botones, tanto si el lector manda Enter/Tab como si no manda sufijo (se detecta el fin de la ráfaga de teclas)
  - Beep al detectar un código y tono de error cuando el producto no existe o se alcanza el máximo de impresiones (suena aunque el teléfono esté en silencio)

### 🔧 Cambiado
- Toolchain Android actualizado para Flutter 3.47: Gradle 8.14, Android Gradle Plugin 8.11.1, Kotlin 2.2.20
- `material_symbols_icons` 4.2960.0 (la versión anterior no compila con Flutter 3.47)

## [1.2.0] - 2026-09-24

### 🎉 Agregado
- **Impresión por servicio (Scanner Agent / Zebra)** (#12)
  - Nuevo tipo de impresora "Servicio": envía la etiqueta en ZPL a `POST http://<ip-pc>:8100/print/zebra`
  - Botón **Verificar** que consulta `GET /status` y valida que el agente tenga `agent_role` `zebra` o `all`
  - Botón **Probar** que imprime una etiqueta de prueba en la Zebra
  - URL del servicio configurable por dispositivo (una PC por tienda); se rechaza `localhost`
  - Diseño de etiqueta ZPL para ZD421 (203 dpi) ajustado a la etiqueta preimpresa "Precio SuperChivas": precio grande, descripción en dos líneas cortando por palabra, Code128 ancho y centrado, frente y fecha
  - Pruebas unitarias del generador ZPL y del cliente HTTP

### 🔧 Cambiado
- La configuración de impresora ahora permite elegir **Bluetooth** o **Servicio** (componente `PrinterSettingsCard` compartido por las dos pantallas de configuración)
- `PrinterService.printLabel` decide el tipo de impresión; la pantalla de detalle ya no maneja la conexión Bluetooth directamente

## [1.1.0] - 2024-10-14

### 🎉 Agregado
- **Sistema de Autenticación completo**
  - Pantalla de login con validación de email y contraseña
  - Integración con API de autenticación (endpoint `/Account/Login`)
  - Gestión de sesiones con SharedPreferences
  - Tokens JWT para seguridad
  - Splash screen con verificación automática de sesión
  - Botón de logout en pantalla principal
  - Asignación automática de sucursal desde login (warehouseCode)

- **Sistema de Control de Versiones**
  - Detección automática de actualizaciones disponibles
  - Descarga e instalación de APK desde servidor
  - Comparación inteligente de versiones (semántico)
  - Notificaciones al usuario sobre actualizaciones
  - Manejo de permisos para instalación

- **Mejoras en Configuración**
  - Campo de sucursal inteligente (bloqueado si viene del login)
  - Indicador visual cuando la sucursal no es modificable
  - Validaciones mejoradas
  - Mensajes de ayuda contextuales

### 🔧 Cambiado
- Campo de sucursal convertido de dropdown a TextField
- Servidor API ahora se configura desde constants (no editable por usuario)
- Versión de la app ahora se lee dinámicamente desde pubspec.yaml
- Mejorado el flujo de navegación con manejo de estados

### 🐛 Corregido
- Eliminada duplicación de versión en constants.dart
- Sincronización de sucursal entre login y configuración

### 📚 Documentación
- Agregada guía completa de versionado (VERSIONADO_GUIA.md)
- Agregada guía de manejo de imágenes (IMAGENES_GUIA.md)
- Documentación de estructura de carpetas assets

---

## [1.0.0] - 2024-10-XX

### 🎉 Agregado
- Versión inicial de la aplicación
- Escaneo de códigos de barras con cámara
- Integración con impresoras Bluetooth
- Pantalla de configuración
- Gestión de productos
- Impresión de etiquetas

---

## Tipos de Cambios

- `🎉 Agregado` - Nuevas funcionalidades
- `🔧 Cambiado` - Cambios en funcionalidades existentes
- `❌ Deprecado` - Funcionalidades que serán removidas
- `🗑️ Removido` - Funcionalidades removidas
- `🐛 Corregido` - Corrección de bugs
- `🔒 Seguridad` - Mejoras de seguridad
- `📚 Documentación` - Cambios solo en documentación

---

## Guía de Versionado

### Formato: MAJOR.MINOR.PATCH

**MAJOR (X.0.0)** - Cambios incompatibles
- Cambios que rompen compatibilidad con versiones anteriores
- Reestructuración completa
- Eliminación de funcionalidades

**MINOR (1.X.0)** - Nuevas funcionalidades
- Nuevas características compatibles
- Mejoras significativas
- Agregado de funcionalidades

**PATCH (1.0.X)** - Correcciones
- Corrección de bugs
- Mejoras de rendimiento
- Fixes menores

---

## Próximas Versiones (Planeadas)

### [1.2.0] - Próximamente
- [ ] Endpoint dinámico para lista de sucursales
- [ ] Soporte para múltiples idiomas
- [ ] Modo offline
- [ ] Sincronización automática

### [1.1.1] - Próximamente
- [ ] Optimizaciones de rendimiento
- [ ] Mejoras en manejo de errores
- [ ] Correcciones de UI

---

## Contacto

Para reportar bugs o sugerir mejoras, contacta al equipo de desarrollo.
