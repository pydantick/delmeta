#!/usr/bin/env sh
# Установщик delmeta. Основная версия — zsh, fish ставится дополнительно.
# Работает и из клона репозитория, и через  curl | sh.
set -e

REPO_RAW="https://raw.githubusercontent.com/pydantick/delmeta/main"

info() { printf '\033[32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[33m !\033[0m %s\n' "$1" >&2; }
err()  { printf '\033[31m x\033[0m %s\n' "$1" >&2; exit 1; }

download() { # url dest
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$1" -o "$2"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$2" "$1"
    else
        err "нет ни curl, ни wget — не могу скачать $1"
    fi
}

# откуда брать файлы: рядом со скриптом (клон) или качать
SRC_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)"
fetch() { # basename dest
    if [ -n "$SRC_DIR" ] && [ -f "$SRC_DIR/$1" ]; then
        cp "$SRC_DIR/$1" "$2"
    else
        download "$REPO_RAW/$1" "$2"
    fi
}

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

# 2. ОСНОВНАЯ версия — zsh
ZSH_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/delmeta"
mkdir -p "$ZSH_DIR"
fetch delmeta.zsh "$ZSH_DIR/delmeta.zsh"

ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
if [ -f "$ZSHRC" ] && grep -qF "delmeta.zsh" "$ZSHRC"; then
    info "delmeta уже подключён в $ZSHRC"
else
    printf '\n# delmeta\nsource "%s/delmeta.zsh"\n' "$ZSH_DIR" >> "$ZSHRC"
    info "zsh-версия установлена, подключение добавлено в $ZSHRC"
fi

# 3. ДОПОЛНИТЕЛЬНО — fish (если установлен)
if command -v fish >/dev/null 2>&1; then
    FISH_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fish/functions"
    mkdir -p "$FISH_DIR"
    fetch delmeta.fish "$FISH_DIR/delmeta.fish"
    info "fish-версия тоже установлена (~/.config/fish/functions)"
fi

echo
info "готово! перезапусти терминал или выполни:  source \"$ZSHRC\""
info "использование:  delmeta файл.jpg"
