# Despliegue continuo (CD)

Publicar una versión = **crear un tag `vX.Y.Z` sobre `master`**. GitHub Actions
(`.github/workflows/release.yml`) compila, firma, prueba y sube el APK al servidor
de auto-update; los equipos se actualizan solos al abrir la app.

**La versión sale del tag.** No hace falta editar `pubspec.yaml` ni el CHANGELOG
para publicar.

## Publicar una versión

1. Mergear los PRs a `develop` y después `develop` → `master`.
2. Crear y subir el tag sobre `master`:

   ```powershell
   git checkout master
   git pull
   git tag v2.0.3
   git push origin v2.0.3
   ```

3. Revisar la ejecución en **GitHub → Actions → Release**. Al terminar en verde, el
   servidor ya responde la nueva versión.

### Qué número poner

Mirar la versión publicada en
http://crm.ccfnweb.com.mx/sap10/MD_CODEBAR_SCANNER_VERSION.text o en
**GitHub → Releases**, y subir:

| Cambio | Ejemplo desde 2.0.3 |
|---|---|
| Solo correcciones (`fix:`) | `v2.0.4` |
| Funcionalidad nueva (`feat:`) | `v2.1.0` |
| Cambio grande / incompatible | `v3.0.0` |

El pipeline rechaza un tag igual o menor al publicado (la app solo instala versiones
mayores).

### Si el tag estuvo mal

Si el workflow falló **antes** de publicar, borrar el tag y volver a crearlo:

```powershell
git push origin :refs/tags/v2.0.3
git tag -d v2.0.3
```

Si ya publicó, no reutilizar el número: corregir y publicar la siguiente versión.

## Qué hace el pipeline

| Paso | Falla si… |
|---|---|
| Validar tag | no tiene formato `vX.Y.Z`, el commit no está en `master`, o la versión no es mayor a la publicada |
| `flutter test` | alguna prueba falla |
| Firmar y compilar | falta el secret del keystore |
| Verificar firma | el APK no quedó firmado con el certificado `4de67283…c290` (el de los equipos instalados) |
| Publicar en `sap10` | primero el APK y **después** `MD_CODEBAR_SCANNER_VERSION.text` |
| Comprobar versión | la URL pública no responde la nueva versión |
| GitHub Release | crea el release con el APK y notas generadas de los PRs mergeados |

Detalles:

- `--build-name` = versión del tag; `--build-number` (versionCode de Android) =
  **100 + número de ejecución del workflow**: siempre crece y supera a los builds
  manuales anteriores (el último fue `+3`). Mismo criterio que WMSAPP.
- La `version:` de `pubspec.yaml` solo aplica a builds locales (`flutter run`).
- El APK también queda como artefacto del workflow durante 30 días y adjunto al
  GitHub Release.

## Archivos en el servidor

Carpeta `/var/www/html/CCFNCRM/public/sap10` en `13.52.132.84`, que es lo que lee
`lib/services/app_update_service.dart`:

| Archivo | URL |
|---|---|
| `md_codebar_scanner.apk` | http://crm.ccfnweb.com.mx/sap10/md_codebar_scanner.apk |
| `MD_CODEBAR_SCANNER_VERSION.text` | http://crm.ccfnweb.com.mx/sap10/MD_CODEBAR_SCANNER_VERSION.text |
| `.md_codebar_scanner.apk.anterior` | respaldo del APK previo, para regresar de versión a mano (es el mismo APK que ya era público) |

## Secrets (Settings → Secrets and variables → Actions)

| Secret | Contenido |
|---|---|
| `SCANNER_KEYSTORE_B64` | `C:\Users\DESARROLLO\.android\debug.keystore` en base64 (contraseña estándar `android`) |
| `SCANNER_DEPLOY_KEY` | llave privada `C:\Users\DESARROLLO\keys\md-scanner\md-scanner-deploy` |

Para generar el base64 en PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\.android\debug.keystore")) | Set-Clipboard
```

**Respaldar el keystore y la llave fuera de esta máquina y nunca subirlos al repo.**
Si se pierde el keystore, los equipos no aceptan actualizaciones y hay que desinstalar
la app en cada uno.

## Configuración inicial (una sola vez)

### 1. Permiso para subir workflows

El token de `gh` necesita el scope `workflow` para hacer push de `.github/workflows/`:

```powershell
gh auth refresh -h github.com -s workflow
```

### 2. Servidor

La llave de despliegue **solo** puede ejecutar `deploy/md-scanner-recibir`, que
acepta `apk` o `version` por stdin y escribe únicamente esos dos archivos en `sap10`
(con archivo temporal + `mv` atómico). Es el mismo esquema que el piloto de WMSAPP.

Conectarse al EC2 como `ec2-user` (con la llave `.pem` de AWS):

```powershell
ssh -i "$env:USERPROFILE\Desktop\<llave>.pem" ec2-user@13.52.132.84
```

Con PuTTY: convertir el `.pem` a `.ppk` con PuTTYgen (Load → Save private key) y en
PuTTY usar Host `ec2-user@13.52.132.84` y *Connection → SSH → Auth → Credentials →
Private key file* = el `.ppk`.

Ya dentro:

```bash
mkdir -p ~/bin
nano ~/bin/md-scanner-recibir          # pegar el contenido de deploy/md-scanner-recibir
chmod 755 ~/bin/md-scanner-recibir

# ec2-user debe poder escribir en sap10
test -w /var/www/html/CCFNCRM/public/sap10 && echo OK

# Autorizar la llave restringida (una sola línea)
echo 'restrict,command="/home/ec2-user/bin/md-scanner-recibir" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRiYK1AGGAkQH9ebx31+x98esHy9zCJCSN79jDxgTcF md-scanner-deploy' >> ~/.ssh/authorized_keys
```

Prueba desde esta PC (no publica nada; debe responder `uso: apk | version`):

```powershell
ssh -i C:/Users/DESARROLLO/keys/md-scanner/md-scanner-deploy ec2-user@13.52.132.84 prueba
```

Para revocar la llave: borrar esa línea de `~/.ssh/authorized_keys`.

### 3. Workflow en `master`

GitHub solo ejecuta workflows que existen en el commit del tag: el primer release
requiere que `release.yml` ya esté mergeado en `master`.

## Aprobación manual (opcional)

El job usa el environment `production`. En **Settings → Environments → production →
Required reviewers** se puede exigir que alguien apruebe antes de publicar.

## Regresar a la versión anterior

En el servidor:

```bash
cd /var/www/html/CCFNCRM/public/sap10
cp -p .md_codebar_scanner.apk.anterior md_codebar_scanner.apk
```

Los equipos que ya actualizaron no bajan de versión solos (la app solo instala
versiones mayores): publicar una versión nueva con la corrección.
