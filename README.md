# bash_scripts_and_others

Repositorio con scripts y utilidades para automatizar tareas simples de desarrollo, soporte y mantenimiento.

---

# PostgreSQL Backup & Restore Scripts

Scripts para realizar backups y restauraciones de bases de datos PostgreSQL tanto en Windows (PowerShell) como en Linux (Bash).

---

# Scripts disponibles

| Script | Sistema Operativo | Descripción |
|---|---|---|
| `postgres_backup_restore.ps1` | Windows / PowerShell | Backup y restore PostgreSQL |
| `postgres_backup_restore.sh` | Linux / Bash | Backup y restore PostgreSQL |

---

# Funcionalidades

Los scripts permiten:

- generar backups PostgreSQL
- restaurar bases de datos
- comprimir backups en `.zip`
- restaurar desde `.sql` o `.zip`
- generar nombres automáticos con fecha y hora
- validar campos obligatorios
- limpiar archivos temporales automáticamente

---

# Formato de backups

Los backups se generan automáticamente con el siguiente formato:

```text
nombreBase-backup_YYYYMMDD_HHMMSS.zip
```

Ejemplo:

```text
vodb-backup_20260507_145530.zip
```

---

# Requisitos

## PostgreSQL Client

Los scripts requieren:

- `pg_dump`
- `psql`

---

# Windows

Verificar instalación:

```powershell
pg_dump --version
psql --version
```

Si PostgreSQL no está en el PATH del sistema, agregar:

```text
C:\Program Files\PostgreSQL\<VERSION>\bin
```

---

# Linux

Instalar dependencias:

## Ubuntu / Debian

```bash
sudo apt install postgresql-client zip unzip
```

## RHEL / CentOS

```bash
sudo dnf install postgresql zip unzip
```

---

# Uso en Windows (PowerShell)

## Configuración previa

Habilitar ejecución temporal de scripts:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

---

## Ejecutar script

```powershell
.\postgres_backup_restore.ps1
```

---

# Uso en Linux

## Dar permisos de ejecución

```bash
chmod +x postgres_backup_restore.sh
```

---

## Ejecutar script

```bash
./postgres_backup_restore.sh
```

---

# Flujo de uso

Al ejecutar el script se solicitarán los siguientes datos:

```text
Elegí una opción: [B] Backup | [R] Restore
Host
Puerto
Base de datos
Usuario
Password
```

---

# Backup

Si se elige la opción `B`:

1. se genera un archivo `.sql`
2. se comprime automáticamente en `.zip`
3. se elimina el `.sql` temporal

Resultado:

```text
vodb-backup_20260507_145530.zip
```

---

# Restore

Si se elige la opción `R`:

El script permite restaurar:

- archivos `.sql`
- archivos `.zip`

Si el archivo es `.zip`:

1. se descomprime automáticamente
2. se restaura la base de datos
3. se eliminan archivos temporales

---

# Ejemplo de uso

```text
Elegí una opción: [B] Backup | [R] Restore : B
Host: localhost
Puerto: 5432
Base de datos: vodb
Usuario: vouser
Password: *****
```

---

# Notas

- Los backups se generan en la carpeta actual.
- El password se utiliza únicamente durante la ejecución.
- Compatible con entornos locales, QA y desarrollo.
- Los scripts no eliminan ni recrean la base de datos automáticamente.
- Para restaurar, la base de datos debe existir previamente.

---

# Recomendaciones

- Mantener backups históricos.
- No subir backups reales a repositorios Git.
- Agregar `.zip` y `.sql` al `.gitignore`.

Ejemplo:

```gitignore
*.sql
*.zip
```