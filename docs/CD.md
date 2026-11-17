# Despliegue continuo (CD)

Publicar una versión = **crear un tag `vX.Y.Z` sobre `master`**. GitHub Actions
(`.github/workflows/release.yml`) compila, firma, prueba y sube el APK al servidor
de auto-update; los equipos se actualizan solos al abrir la app.

## Publicar una versión

1. En la rama de trabajo:
   - Subir `version:` en `pubspec.yaml` (por ejemplo `2.0.3+4`; el `+N` siempre aumenta).
   - Agregar la sección `## [2.0.3] - AAAA-MM-DD` en `CHANGELOG.md`.
2. PR a `develop`, y después `develop` → `master`.
3. Crear el tag sobre `master`:

   ```bash
   git checkout master && git pull
   git tag v2.0.3
   git push origin v2.0.3
   ```

4. Revisar la ejecución en **Actions → Release**.

## Qué hace el pipeline

| Paso | Falla si… |
|---|---|
| Validar tag | el tag no coincide con `pubspec.yaml`, falta el `+N`, el commit no está en `master` o falta la sección en `CHANGELOG.md` |
| `flutter test` | alguna prueba falla |
| Firmar y compilar | falta el secret del keystore |
| Verificar firma | el APK no quedó firmado con el certificado `4de67283…c290` (el de los equipos instalados) |
| Publicar en `sap10` | primero el APK y **después** `MD_CODEBAR_SCANNER_VERSION.text` |
| Comprobar versión | la URL pública no responde la nueva versión |
| GitHub Release | crea el release con el APK y las notas del CHANGELOG |

El APK también queda como artefacto del workflow durante 30 días.

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

## Configuración del servidor (una sola vez)

La llave de despliegue **solo** puede ejecutar `deploy/md-scanner-recibir`, que
acepta `apk` o `version` por stdin y escribe únicamente esos dos archivos en `sap10`
(con archivo temporal + `mv` atómico). Es el mismo esquema que el piloto de WMSAPP.

```bash
# En el EC2, como ec2-user
mkdir -p ~/bin
nano ~/bin/md-scanner-recibir          # pegar el contenido de deploy/md-scanner-recibir
chmod 755 ~/bin/md-scanner-recibir

# ec2-user debe poder escribir en sap10
test -w /var/www/html/CCFNCRM/public/sap10 && echo OK

# Autorizar la llave restringida (una sola línea)
echo 'restrict,command="/home/ec2-user/bin/md-scanner-recibir" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRiYK1AGGAkQH9ebx31+x98esHy9zCJCSN79jDxgTcF md-scanner-deploy' >> ~/.ssh/authorized_keys
```

Prueba desde esta PC (no publica nada; debe responder `uso: apk | version`):

```bash
ssh -i C:/Users/DESARROLLO/keys/md-scanner/md-scanner-deploy ec2-user@13.52.132.84 prueba
```

Para revocar la llave: borrar esa línea de `~/.ssh/authorized_keys`.

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
