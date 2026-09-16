# Air Raid Map for KDE Plasma

A native, display-only wallpaper showing air-raid alerts across Ukraine.
The map refreshes every 30 seconds. Desktop icons and mouse actions remain usable.

**Original idea:** [FullyRealist/LivelyAirRaidAlert](https://github.com/FullyRealist/LivelyAirRaidAlert)
brings live alert maps to Windows through Lively Wallpaper. This project adapts
that idea for Linux and KDE Plasma. Credit for the original wallpaper idea
belongs to FullyRealist. This implementation draws a native map using NEPTUN's
public alert, threat, and boundary data.

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
If Plasma continues showing the old version, log out and back in, or restart
only its desktop shell with `systemctl --user restart plasma-plasmashell.service`
on systems that manage Plasma through that user service.

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
- Small transparent symbols for drones, FPV drones, reconnaissance
  aircraft, cruise missiles, ballistic missiles, guided bombs (КАБ), MiG-31K
  aircraft, and unknown threats. Icons are 12–16 logical pixels, with no
  background or type labels. Groups show only a small **×2**, **×3**, etc.;
  single reports have no text. Each icon stays at its reported position.
  Directions are used only when supplied without the provider's
  presumed-course flag.
- Region-only reports appear in a separate list, never as invented point
  locations. Advisory icons are blue; advisory region-only reports are also
  labelled **Спостереження**.
- Separate times for the last successfully validated alert and threat responses.
- A prominent stale-data message after a failed request or 90 seconds without
  a successful response. Old alert colors are dimmed; old threat markers are
  hidden until recovery. A threat-feed failure does not stop regional updates.

The map is drawn with Qt Quick's CPU-backed 2D canvas. It repaints when alert
or threat state changes or the desktop is resized. It has no panning, zooming, sound,
WebGL, Chromium, or continuously running animation. A source-attribution link
is the only clickable element supplied by the plugin.

The plugin fetches `oblasts.geojson` and `raions.geojson` from NEPTUN once per
wallpaper instance, then independently polls `/api/v1/alerts` and
`/api/v1/threats` every 30 seconds. Requests time out after 15 seconds. Full valid
snapshots replace previous state; resolved or stale threat records disappear.
Malformed responses and unmatched region keys are treated as unavailable data,
not an all-clear. New, unrecognized threat types use the unknown symbol.
Each configured screen has its own polling instance.

Geometry is fetched at runtime and is not redistributed in this repository.
Markers show the provider's reported positions, refreshed at each poll; the
wallpaper does not predict motion between updates. Reports outside the fixed
map view are not plotted. A long region-only list shows an overflow count.
Availability and the accuracy of upstream data remain controlled by the provider.
Follow official air-raid alerts.

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

The preview uses software rendering, requires at least two valid updates from each API,
and saves `/tmp/plasma-air-raid-map-preview.png`. Its temporary five-second
polling interval follows the provider's documented minimum; the installed
wallpaper uses 30 seconds.

For an offline visual fixture covering every threat symbol, advisory and
region-only reports, and a threat-feed outage:

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  /usr/lib64/qt6/bin/qml tests/preview-threats.qml
```

It saves `/tmp/plasma-air-raid-threat-symbols.png` and
`/tmp/plasma-air-raid-threat-outage.png`. These contain clearly labelled synthetic
data; fixtures are not included in the installed wallpaper.

Build the installable release ZIP with `python3 scripts/package.py`.
The archive and its SHA-256 checksum are written to `dist/`.

## Credits and license

- Original live-wallpaper idea: [FullyRealist/LivelyAirRaidAlert](https://github.com/FullyRealist/LivelyAirRaidAlert).
- Alert, threat, and map-boundary data: [NEPTUN](https://neptun.in.ua/), under its provider terms.
- Original KDE implementation: MIT licensed; see [LICENSE](LICENSE).

This repository's MIT license does not relicense provider content or services.
