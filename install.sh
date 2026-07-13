#!/usr/bin/env sh
# Установщик delmeta. Работает и при запуске из клона, и через curl | sh.
set -e

RAW_URL="https://raw.githubusercontent.com/pydantick/delmeta/main/delmeta.fish"

info() { printf '\033[32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[33m !\033[0m %s\n' "$1" >&2; }
err()  { printf '\033[31m x\033[0m %s\n' "$1" >&2; exit 1; }

# 1. exiftool — нужен для встроенных метаданных
if command -v exiftool >/dev/null 2>&1; then
    info "exiftool уже есть ($(exiftool -ver))"
else
    info "ставлю exiftool..."
    if command -v brew >/dev/null 2>&1; then
        brew install exiftool
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y libimage-exiftool-perl
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y perl-Image-ExifTool
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm perl-image-exiftool
    else
        warn "не нашёл пакетный менеджер — поставь exiftool вручную: https://exiftool.org"
    fi
fi

# 2. fish — delmeta это fish-функция
command -v fish >/dev/null 2>&1 || warn "fish не найден — установи fish, иначе функция не заработает"

FUNC_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fish/functions"
mkdir -p "$FUNC_DIR"

# 3. кладём delmeta.fish: из репозитория, если рядом, иначе качаем
SRC_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)"
if [ -n "$SRC_DIR" ] && [ -f "$SRC_DIR/delmeta.fish" ]; then
    cp "$SRC_DIR/delmeta.fish" "$FUNC_DIR/delmeta.fish"
    info "скопировал delmeta.fish из репозитория"
elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$RAW_URL" -o "$FUNC_DIR/delmeta.fish"
    info "скачал delmeta.fish"
elif command -v wget >/dev/null 2>&1; then
    wget -qO "$FUNC_DIR/delmeta.fish" "$RAW_URL"
    info "скачал delmeta.fish"
else
    err "нет ни curl, ни wget — не могу получить delmeta.fish"
fi

info "готово! использование:  delmeta файл.jpg"
info "fish подхватит функцию автоматически, перезапуск не нужен"
