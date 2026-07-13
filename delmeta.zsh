#!/usr/bin/env zsh
# delmeta — чистит метаданные из файлов: exiftool (внутри) + xattr (macOS-атрибуты).
#
# Подключение (обычно из ~/.zshrc):
#     source /путь/к/delmeta.zsh
# Или запуск напрямую:
#     zsh delmeta.zsh файл.jpg

delmeta() {
    [ -n "$ZSH_VERSION" ] && emulate -L zsh

    if [ "$#" -eq 0 ]; then
        print -u2 -- "Использование: delmeta <файл> [ещё файлы...]"
        return 1
    fi

    local rc=0 f out remaining msg
    for f in "$@"; do
        msg=""
        if [ ! -e "$f" ]; then
            print -u2 -- "✗ $f — файл не найден"; rc=1; continue
        fi
        if [ ! -f "$f" ]; then
            print -u2 -- "✗ $f — это не файл"; rc=1; continue
        fi

        # 1) macOS extended attributes: quarantine, "откуда скачан"
        #    (kMDItemWhereFroms), Finder-теги и комментарии.
        #    com.apple.provenance пропускаем: он есть на каждом файле,
        #    не удаляется и не содержит инфы об источнике.
        if command -v xattr >/dev/null 2>&1; then
            remaining=$(xattr "$f" 2>/dev/null | grep -v '^com\.apple\.provenance$')
            if [ -n "$remaining" ]; then
                xattr -c -- "$f"
                msg="macOS-атрибуты"
            fi
        fi

        # 2) встроенные метаданные: EXIF/GPS/IPTC/XMP, PDF, видео, аудио.
        #    -all= удалить всё,  -overwrite_original без копии *_original
        if command -v exiftool >/dev/null 2>&1; then
            out=$(exiftool -all= -overwrite_original -- "$f" 2>&1)
            if [ $? -eq 0 ]; then
                [ -n "$msg" ] && msg="$msg, встроенные" || msg="встроенные"
            elif print -r -- "$out" | grep -qiE 'not yet supported|unknown file type|format error'; then
                : # формат без встроенных метаданных (txt и пр.) — это не ошибка
            else
                print -u2 -- "⚠ $f — exiftool: $out"; rc=1
            fi
        else
            print -u2 -- "delmeta: exiftool не установлен → brew install exiftool"
        fi

        if [ -n "$msg" ]; then
            print -- "✓ $f — очищено: $msg"
        else
            print -- "• $f — метаданных не найдено"
        fi
    done
    return $rc
}

# Запуск напрямую (zsh delmeta.zsh ...), а не через source.
if [ -n "$ZSH_VERSION" ] && [ "$ZSH_EVAL_CONTEXT" = "toplevel" ]; then
    delmeta "$@"
fi
