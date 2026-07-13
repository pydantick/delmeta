function delmeta --description "Чистит метаданные файла: exiftool (внутри) + xattr (macOS-атрибуты)"
    if test (count $argv) -eq 0
        echo "Использование: delmeta <файл> [ещё файлы...]" >&2
        return 1
    end

    set -l rc 0
    for f in $argv
        if not test -e "$f"
            printf "✗ %s — файл не найден\n" "$f" >&2
            set rc 1
            continue
        end
        if not test -f "$f"
            printf "✗ %s — это не файл\n" "$f" >&2
            set rc 1
            continue
        end

        set -l cleaned

        # 1) macOS-метаданные: quarantine, "откуда скачан" (kMDItemWhereFroms),
        #    Finder-теги и комментарии, Spotlight-данные. exiftool это не трогает.
        #    com.apple.provenance исключаем: он есть на КАЖДОМ файле в системе,
        #    не удаляется (переставляется ядром) и не содержит инфы об источнике.
        set -l xa (xattr -- "$f" 2>/dev/null | string match -v -- com.apple.provenance)
        if test (count $xa) -gt 0
            xattr -c -- "$f"
            set -a cleaned "macOS-атрибуты"
        end

        # 2) Встроенные метаданные: EXIF/GPS/IPTC/XMP/Comment и т.п.
        #    -all=  удалить всё,  -overwrite_original  без копии *_original
        if command -q exiftool
            set -l out (exiftool -all= -overwrite_original -- "$f" 2>&1)
            if test $status -eq 0
                set -a cleaned "встроенные"
            else if string match -q -- "*not yet supported*" $out
                # формат без встроенных метаданных (txt и пр.) — это не ошибка
            else if string match -q -- "*format*" $out; or string match -q -- "*Unknown file type*" $out
                # тоже не пишем метаданные в этот формат — не ошибка
            else
                printf "⚠ %s — exiftool: %s\n" "$f" "$out" >&2
                set rc 1
            end
        else
            echo "delmeta: exiftool не установлен (встроенные метаданные не чищу) → brew install exiftool" >&2
        end

        if test (count $cleaned) -gt 0
            printf "✓ %s — очищено: %s\n" "$f" (string join ", " $cleaned)
        else
            printf "• %s — метаданных не найдено\n" "$f"
        end
    end
    return $rc
end
