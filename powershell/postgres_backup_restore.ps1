function Read-Required($message) {
    do {
        $value = Read-Host $message

        if ([string]::IsNullOrWhiteSpace($value)) {
            Write-Host "⚠️ Campo obligatorio."
        }

    } while ([string]::IsNullOrWhiteSpace($value))

    return $value
}

Write-Host "====================================="
Write-Host " PostgreSQL Backup / Restore Tool"
Write-Host "====================================="

$action = Read-Required "Elegí una opción: [B] Backup | [R] Restore"

$hostDb = Read-Host "Host (Enter = localhost)"
if ([string]::IsNullOrWhiteSpace($hostDb)) {
    $hostDb = "localhost"
}

$port = Read-Host "Puerto (Enter = 5432)"
if ([string]::IsNullOrWhiteSpace($port)) {
    $port = "5432"
}

$dbName = Read-Required "Base de datos"
$dbUser = Read-Required "Usuario"
$dbPass = Read-Required "Password"

$env:PGPASSWORD = $dbPass
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if ($action -eq "B" -or $action -eq "b") {

    $baseName = "$dbName-backup_$timestamp"
    $sqlFile = "$baseName.sql"
    $zipFile = "$baseName.zip"

    Write-Host ""
    Write-Host "Generando backup SQL..."

    pg_dump `
        -h $hostDb `
        -p $port `
        -U $dbUser `
        -d $dbName `
        -f $sqlFile

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error al generar backup."
        $env:PGPASSWORD = ""
        exit
    }

    Write-Host "Comprimiendo ZIP..."

    Compress-Archive `
        -Path $sqlFile `
        -DestinationPath $zipFile `
        -Force

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error al comprimir."
        $env:PGPASSWORD = ""
        exit
    }

    Remove-Item $sqlFile

    Write-Host ""
    Write-Host "✅ Backup generado correctamente:"
    Write-Host $zipFile
}
elseif ($action -eq "R" -or $action -eq "r") {

    $inputFile = Read-Required "Ruta del archivo (.sql o .zip)"

    if (-Not (Test-Path $inputFile)) {
        Write-Host "❌ El archivo no existe."
        $env:PGPASSWORD = ""
        exit
    }

    $extension = [System.IO.Path]::GetExtension($inputFile).ToLower()
    $sqlFile = $null
    $tempFolder = $null

    if ($extension -eq ".zip") {

        Write-Host "Descomprimiendo ZIP..."

        $tempFolder = Join-Path $env:TEMP ("pg_restore_" + $timestamp)

        New-Item `
            -ItemType Directory `
            -Path $tempFolder `
            -Force | Out-Null

        Expand-Archive `
            -Path $inputFile `
            -DestinationPath $tempFolder `
            -Force

        $foundSql = Get-ChildItem `
            -Path $tempFolder `
            -Filter *.sql `
            -Recurse | Select-Object -First 1

        if (-Not $foundSql) {
            Write-Host "❌ No se encontró archivo .sql dentro del ZIP."
            $env:PGPASSWORD = ""
            exit
        }

        $sqlFile = $foundSql.FullName
    }
    elseif ($extension -eq ".sql") {
        $sqlFile = $inputFile
    }
    else {
        Write-Host "❌ Formato no soportado. Usá .sql o .zip."
        $env:PGPASSWORD = ""
        exit
    }

    Write-Host ""
    Write-Host "Restaurando base de datos..."

    psql `
        -h $hostDb `
        -p $port `
        -U $dbUser `
        -d $dbName `
        -f $sqlFile

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error durante la restauración."
        $env:PGPASSWORD = ""
        exit
    }

    if ($tempFolder -and (Test-Path $tempFolder)) {
        Remove-Item `
            -Path $tempFolder `
            -Recurse `
            -Force
    }

    Write-Host ""
    Write-Host "✅ Restauración completada correctamente."
}
else {
    Write-Host "❌ Opción inválida. Usá B o R."
}

$env:PGPASSWORD = ""