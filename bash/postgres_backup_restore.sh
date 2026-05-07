#!/bin/bash

read_required() {
    local prompt="$1"
    local value=""

    while [[ -z "$value" ]]; do
        read -p "$prompt: " value

        if [[ -z "$value" ]]; then
            echo "⚠️ Campo obligatorio."
        fi
    done

    echo "$value"
}

read_password_required() {
    local prompt="$1"
    local value=""

    while [[ -z "$value" ]]; do
        read -s -p "$prompt: " value
        echo ""

        if [[ -z "$value" ]]; then
            echo "⚠️ Campo obligatorio."
        fi
    done

    echo "$value"
}

echo "====================================="
echo " PostgreSQL Backup / Restore Tool"
echo "====================================="

ACTION=$(read_required "Elegí una opción: [B] Backup | [R] Restore")

read -p "Host [localhost]: " HOST
HOST=${HOST:-localhost}

read -p "Puerto [5432]: " PORT
PORT=${PORT:-5432}

DB_NAME=$(read_required "Base de datos")
DB_USER=$(read_required "Usuario")
DB_PASS=$(read_password_required "Password")

export PGPASSWORD="$DB_PASS"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

if [[ "$ACTION" == "B" || "$ACTION" == "b" ]]; then

    BASE_NAME="${DB_NAME}-backup_${TIMESTAMP}"
    SQL_FILE="${BASE_NAME}.sql"
    ZIP_FILE="${BASE_NAME}.zip"

    echo ""
    echo "Generando backup SQL..."

    pg_dump \
        -h "$HOST" \
        -p "$PORT" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        -f "$SQL_FILE"

    if [[ $? -ne 0 ]]; then
        echo "❌ Error al generar backup."
        unset PGPASSWORD
        exit 1
    fi

    echo "Comprimiendo ZIP..."

    zip "$ZIP_FILE" "$SQL_FILE" > /dev/null

    if [[ $? -ne 0 ]]; then
        echo "❌ Error al comprimir."
        unset PGPASSWORD
        exit 1
    fi

    rm "$SQL_FILE"

    echo ""
    echo "✅ Backup generado correctamente:"
    echo "$ZIP_FILE"

elif [[ "$ACTION" == "R" || "$ACTION" == "r" ]]; then

    INPUT_FILE=$(read_required "Ruta del archivo (.sql o .zip)")

    if [[ ! -f "$INPUT_FILE" ]]; then
        echo "❌ El archivo no existe."
        unset PGPASSWORD
        exit 1
    fi

    EXTENSION="${INPUT_FILE##*.}"
    EXTENSION=$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')

    SQL_FILE=""
    TEMP_DIR=""

    if [[ "$EXTENSION" == "zip" ]]; then

        echo "Descomprimiendo ZIP..."

        TEMP_DIR="/tmp/pg_restore_${TIMESTAMP}"
        mkdir -p "$TEMP_DIR"

        unzip -o "$INPUT_FILE" -d "$TEMP_DIR" > /dev/null

        SQL_FILE=$(find "$TEMP_DIR" -name "*.sql" | head -n 1)

        if [[ -z "$SQL_FILE" ]]; then
            echo "❌ No se encontró archivo .sql dentro del ZIP."
            unset PGPASSWORD
            exit 1
        fi

    elif [[ "$EXTENSION" == "sql" ]]; then
        SQL_FILE="$INPUT_FILE"

    else
        echo "❌ Formato no soportado. Usá .sql o .zip."
        unset PGPASSWORD
        exit 1
    fi

    echo ""
    echo "Restaurando base de datos..."

    psql \
        -h "$HOST" \
        -p "$PORT" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        -f "$SQL_FILE"

    if [[ $? -ne 0 ]]; then
        echo "❌ Error durante la restauración."
        unset PGPASSWORD
        exit 1
    fi

    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi

    echo ""
    echo "✅ Restauración completada correctamente."

else
    echo "❌ Opción inválida. Usá B o R."
fi

unset PGPASSWORD