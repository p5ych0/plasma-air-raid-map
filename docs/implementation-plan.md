# Display-only air-raid map wallpaper

## Scope

Show a dynamically updated Ukraine alert map on KDE Plasma 6 without map
interaction. Publish `p5ych0/plasma-air-raid-map` publicly and prominently
credit FullyRealist/LivelyAirRaidAlert for the original idea.

## Implementation and checks

- [x] Render district/oblast boundaries with Qt Quick Canvas.Image.
- [x] Fetch NEPTUN's documented boundary and alert endpoints, polling alerts
  every 30 seconds with a 15-second request timeout.
- [x] Validate snapshots before replacing state. Unknown regions and malformed
  responses must not clear active alerts. Mark data stale on failure or after
  90 seconds without a successful response.
- [x] Include provider attribution and the official-alert notice on the map.
- [x] Test snapshot replacement, key matching, severity, malformed responses,
  multipolygon geometry, and stale-data detection.
- [x] Verify repeated live API updates and visually inspect a software-rendered
  preview before installing the native plugin.
- [x] Validate the package, install it, and verify Plasma remains healthy.
- [x] Create the public repository with the original-idea credit.

## Threat overlay (v0.2)

- [x] Poll NEPTUN's separate threat feed independently of regional alerts.
- [x] Draw all eight published threat types with small transparent silhouettes.
- [x] Preserve provider fields and distinguish advisory reports with blue symbols.
- [x] Display area-only reports in a list rather than at an invented location.
- [x] Replace full snapshots; hide markers on failure or stale data.
- [x] Check parsing, replacement, independent freshness, and all symbol types.
- [x] Check final live rendering, package upgrade, and Plasma health.

Release packaging: `python3 scripts/package.py` creates the installable ZIP
and checksum for publication with the repository's tagged release.

Corner text uses Plasma's screen-local `Containment.availableScreenRect`,
with 20 pixels of additional clearance and a minimum 64-pixel inset on each edge.
The visual preview's `--panels` option checks panels on all four sides.

## Rendering decision

Use native Qt Quick 2D drawing and JSON requests. This keeps browser engines
and WebGL contexts out of Plasma and avoids changes to the desktop's graphics
configuration. The map uses the provider's regional alert API instead of
embedding its interactive web application.

## Files

- `package/metadata.json`: Plasma package identity.
- `package/contents/ui/main.qml`: native wallpaper entry point.
- `package/contents/ui/AlertMap.qml`: map drawing and status/attribution labels.
- `package/contents/ui/AlertSource.qml`: network requests, retry, freshness.
- `package/contents/ui/MapData.js`: geometry and alert-response validation.
- `package/contents/ui/ThreatSymbols.js`: native threat silhouettes at reported positions.
- `tests/tst_alertdata.qml`: data-contract tests with synthetic fixtures.
- `tests/tst_threatdata.qml`, `tests/tst_threatsource.qml`: threat parsing and freshness checks.
- `tests/preview-threats.qml`: offline symbol and outage visual fixtures.
- `tests/preview.qml`: live-provider rendering and update check.
- `README.md`, `LICENSE`: installation, original-idea attribution, and license.
