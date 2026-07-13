# delmeta

Чистит метаданные из файла одной командой: `delmeta file`.

Убирает **два слоя** за раз:

- **встроенные** метаданные — EXIF/GPS/IPTC/XMP, а также PDF, видео, аудио (через `exiftool`);
- **macOS extended attributes** — `quarantine`, «откуда скачан» (`kMDItemWhereFroms`), Finder-теги и комментарии.

## Установка

```sh
brew install exiftool
cp delmeta.fish ~/.config/fish/functions/
```

Fish подхватит функцию автоматически, перезапуск не нужен.

## Использование

```sh
delmeta photo.jpg
delmeta a.pdf b.png c.mp4    # можно несколько файлов сразу
```

- Пишет в тот же файл, без копий `*_original`.
- `com.apple.provenance` не трогается — это системный атрибут, есть на каждом файле и не содержит инфы об источнике.

## Вывод

- `✓ file — очищено: ...` — метаданные удалены
- `• file — метаданных не найдено` — чистить было нечего
- `✗ / ⚠ file — ...` — файл не найден или битый
