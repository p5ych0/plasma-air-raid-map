# Air Raid Map for KDE Plasma

A native, display-only wallpaper showing air-raid alerts across Ukraine.
The map refreshes every 30 seconds. Desktop icons and mouse actions remain usable.

**Original idea:** [FullyRealist/LivelyAirRaidAlert](https://github.com/FullyRealist/LivelyAirRaidAlert)
brings live alert maps to Windows through Lively Wallpaper. This project adapts
that idea for Linux and KDE Plasma. Credit for the original wallpaper idea
belongs to FullyRealist. This implementation draws a native map using NEPTUN's
public alert and boundary data.

## Requirements

- KDE Plasma 6 on Linux.
- Internet access to `neptun.in.ua`.

The plugin uses the Qt Quick components included with Plasma. It does not
require Qt WebEngine, a browser, Node.js, API keys, or a background service.

## Install

From a checkout:

```sh
kpackagetool6 --type Plasma/Wallpaper --install package/
```

For subsequent updates, use `--upgrade` instead of `--install`.

Right-click the desktop, open **Configure Desktop and Wallpaper**, and choose
**Air Raid Map** as the wallpaper type. Configure each screen separately.

A release ZIP can be installed with the same command, replacing `package/`
with the ZIP's path.

To remove it, first select another wallpaper, then run:

```sh
kpackagetool6 --type Plasma/Wallpaper --remove io.github.p5ych0.airraidmap
```

## What it displays

- District and oblast alert areas, with Ukrainian labels.
- Red and yellow alert levels as supplied by NEPTUN.
- The time of the last successfully received and validated response.
- A prominent stale-data message after a failed request or 90 seconds without
  a successful response. Old alert colors are dimmed until recovery.

The map is drawn with Qt Quick's CPU-backed 2D canvas. It repaints when alert
state changes or the desktop is resized. It has no panning, zooming, sound,
WebGL, Chromium, or continuously running animation. A source-attribution link
is the only clickable element supplied by the plugin.

The plugin fetches `oblasts.geojson` and `raions.geojson` from NEPTUN once per
wallpaper instance, then polls `/api/v1/alerts` every 30 seconds. Requests time
out after 15 seconds. Full valid snapshots replace previous alert state;
malformed responses and unmatched region keys are treated as unavailable data,
not an all-clear. Each configured screen has its own polling instance.

Geometry is fetched at runtime and is not redistributed in this repository.
The map shows the provider's regional alerts; it does not reproduce NEPTUN's
estimated moving threat tracks. Availability and the accuracy of upstream data
remain controlled by the provider. Follow official air-raid alerts.

See [NEPTUN's API documentation](https://neptun.in.ua/developers) and
[terms](https://neptun.in.ua/api-terms). Visible attribution is included on the map.

## Development

No compilation is required. Tests use Qt Quick Test and `qmltestrunner`.
On Fedora the Qt tools are under `/usr/lib64/qt6/bin/`.

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  /usr/lib64/qt6/bin/qmltestrunner -input tests

/usr/lib64/qt6/bin/qmllint package/contents/ui/*.qml
```

For a live-provider smoke test, run the preview separately from Plasma:

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  /usr/lib64/qt6/bin/qml tests/preview.qml
```

The preview uses software rendering, requires at least two valid API updates,
and saves `/tmp/plasma-air-raid-map-preview.png`. Its temporary five-second
polling interval follows the provider's documented minimum; the installed
wallpaper uses 30 seconds.

Build the installable release ZIP with `python3 scripts/package.py`.
The archive and its SHA-256 checksum are written to `dist/`.

## Credits and license

- Original live-wallpaper idea: [FullyRealist/LivelyAirRaidAlert](https://github.com/FullyRealist/LivelyAirRaidAlert).
- Alert and map-boundary data: [NEPTUN](https://neptun.in.ua/), under its provider terms.
- Original KDE implementation: MIT licensed; see [LICENSE](LICENSE).

This repository's MIT license does not relicense provider content or services.
