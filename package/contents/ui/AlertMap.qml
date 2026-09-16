// SPDX-License-Identifier: MIT
import QtQuick
import "ThreatSymbols.js" as Symbols

Item {
    id: root
    property alias apiBase: root.source.apiBase
    property alias pollInterval: root.source.pollInterval
    readonly property int updateCount: root.source.updateCount
    readonly property bool stale: root.source.stale
    readonly property int threatsUpdateCount: root.source.threatsUpdateCount
    readonly property bool threatsStale: root.source.threatsStale
    property AlertSource source: AlertSource {}

    Rectangle { anchors.fill: parent; color: "#0e1722" }

    Canvas {
        id: canvas
        anchors.fill: parent
        renderTarget: Canvas.Image
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);
            if (!root.source.oblasts) return;
            const b = root.source.oblasts.bounds;
            const padding = Math.max(24, Math.min(width, height) * 0.055);
            const scale = Math.min(Math.max(1, width - padding * 2) / (b[2] - b[0]),
                                   Math.max(1, height - padding * 2 - 100) / (b[3] - b[1]));
            const ox = (width - scale * (b[2] - b[0])) / 2;
            const oy = 65 + (height - 100 - scale * (b[3] - b[1])) / 2;

            function path(region) {
                ctx.beginPath();
                for (const polygon of region.polygons) {
                    for (const ring of polygon) {
                        for (let i = 0; i < ring.length; ++i) {
                            const x = ox + (ring[i][0] - b[0]) * scale;
                            const y = oy + (ring[i][1] - b[1]) * scale;
                            if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                        }
                        ctx.closePath();
                    }
                }
            }

            for (const region of root.source.oblasts.regions) {
                path(region); ctx.fillStyle = "#223448"; ctx.fill();
            }
            ctx.globalAlpha = root.source.stale ? 0.4 : 1;
            if (root.source.snapshot && root.source.raions) {
                // Red is painted last so overlapping yellow alerts cannot hide it.
                for (const level of ["yellow", "red"]) {
                    ctx.fillStyle = level === "red" ? "#cf4655" : "#c69235";
                    for (const kind of ["oblasts", "raions"]) {
                        const geometry = kind === "oblasts" ? root.source.oblasts : root.source.raions;
                        for (const region of geometry.regions) {
                            if (root.source.snapshot[kind]["@" + region.key] === level) {
                                path(region); ctx.fill();
                            }
                        }
                    }
                }
            }
            ctx.globalAlpha = 1;
            ctx.lineWidth = 0.5;
            ctx.strokeStyle = "#456078";
            if (root.source.raions) {
                for (const region of root.source.raions.regions) { path(region); ctx.stroke(); }
            }
            ctx.lineWidth = 1.2;
            ctx.strokeStyle = "#9ab1c6";
            for (const region of root.source.oblasts.regions) { path(region); ctx.stroke(); }

            const fontSize = Math.max(9, Math.min(17, width / 100));
            ctx.font = "600 " + fontSize + "px sans-serif";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.lineWidth = 3;
            for (const region of root.source.oblasts.regions) {
                if (region.key === "м. київ" || region.key === "севастополь") continue;
                const x = ox + (region.center[0] - b[0]) * scale;
                const y = oy + (region.center[1] - b[1]) * scale;
                ctx.strokeStyle = "#172431";
                ctx.strokeText(region.label, x, y);
                ctx.fillStyle = "#eef4fa";
                ctx.fillText(region.label, x, y);
            }

            if (root.source.threats && !root.source.threatsStale) {
                const size = Math.max(20, Math.min(30, width / 55));
                const reports = [];
                for (const threat of root.source.threats.points) {
                    const x = ox + (threat.point[0] - b[0]) * scale;
                    const y = oy + (threat.point[1] - b[1]) * scale;
                    // Do not clamp off-map reports to a false position at the edge.
                    if (x < 0 || x > width || y < 80 || y > height - 60) continue;
                    reports.push({threat: threat, x: x, y: y});
                }
                Symbols.markers(ctx, reports, size, width, height);
            }
        }
    }

    Connections {
        target: root.source
        function onOblastsChanged() { canvas.requestPaint(); }
        function onRaionsChanged() { canvas.requestPaint(); }
        function onSnapshotChanged() { canvas.requestPaint(); }
        function onStaleChanged() { canvas.requestPaint(); }
        function onThreatsChanged() { canvas.requestPaint(); }
        function onThreatsStaleChanged() { canvas.requestPaint(); }
    }

    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 28
        text: "ПОВІТРЯНІ ТРИВОГИ"
        color: "#e6edf5"
        font.pixelSize: Math.max(16, Math.min(26, root.width / 50))
        font.weight: Font.DemiBold
        font.letterSpacing: 2
    }
    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 28
        text: (root.source.stale ? (root.source.lastSuccess ? "ДАНІ ЗАСТАРІЛИ" : "ОЧІКУВАННЯ ДАНИХ")
                        : "Тривоги: " + Qt.formatTime(new Date(root.source.lastSuccess), "HH:mm:ss"))
            + "\n" + (root.source.threatsStale ? "Загрози: немає актуальних даних"
                        : "Загрози: " + Qt.formatTime(new Date(root.source.threatsLastSuccess), "HH:mm:ss")
                          + " · " + (root.source.threats ? root.source.threats.count : 0) + " повідомл.")
        horizontalAlignment: Text.AlignRight
        color: root.source.stale || root.source.threatsStale ? "#e5b45b" : "#a8bdcf"
        font.pixelSize: Math.max(11, Math.min(15, root.width / 85))
    }
    Text {
        anchors.centerIn: parent
        visible: root.source.stale
        text: root.source.oblasts ? "Немає актуальних даних тривог\nПовторна спроба автоматично" : "Завантаження мапи…"
        horizontalAlignment: Text.AlignHCenter
        color: "#f2c879"
        style: Text.Outline
        styleColor: "#0e1722"
        font.pixelSize: 22
        font.bold: true
    }
    Column {
        id: areaReports
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 28
        anchors.topMargin: 78
        width: Math.min(280, root.width * 0.24)
        spacing: 5
        readonly property int limit: Math.max(1, Math.floor((root.height - 210) / 64))
        visible: !root.source.threatsStale && root.source.threats !== null
                 && root.source.threats.areas.length > 0
        Text {
            text: "ЛИШЕ ОБЛАСТЬ · БЕЗ ТОЧНОЇ ПОЗИЦІЇ"
            color: "#a8bdcf"
            font.pixelSize: 10
        }
        Repeater {
            model: !root.source.threatsStale && root.source.threats
                   ? root.source.threats.areas.slice(0, areaReports.limit) : []
            delegate: Rectangle {
                required property var modelData
                width: parent.width
                height: areaLabel.implicitHeight + 12
                color: "#de152331"
                radius: 5
                Text {
                    id: areaLabel
                    anchors.fill: parent
                    anchors.margins: 6
                    text: parent.modelData.region + " · " + parent.modelData.label
                        + (parent.modelData.count > 0 ? " ×" + parent.modelData.count : "")
                        + (parent.modelData.advisory ? "\nСпостереження" : "")
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: parent.modelData.advisory ? "#9ad6f7" : "#eef4fa"
                    font.pixelSize: Math.max(10, Math.min(14, root.width / 95))
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }
        }
        Text {
            visible: root.source.threats !== null && root.source.threats.areas.length > areaReports.limit
            text: root.source.threats ? "Ще повідомлень: " + (root.source.threats.areas.length - areaReports.limit) : ""
            color: "#a8bdcf"
            font.pixelSize: 12
        }
    }
    Text {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 28
        text: '<font color="#cf4655">●</font> Червоний рівень   '
            + '<font color="#c69235">●</font> Жовтий рівень   '
            + '<font color="#7590a8">●</font> Без активної тривоги'
        textFormat: Text.RichText
        color: "#a8bdcf"
        font.pixelSize: Math.max(10, Math.min(13, root.width / 100))
    }
    Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        text: 'Дані: <a style="color:#8fc8ff" href="https://neptun.in.ua/">NEPTUN</a><br>'
            + 'Дотримуйтеся офіційних сигналів тривоги.'
        textFormat: Text.RichText
        horizontalAlignment: Text.AlignRight
        color: "#a8bdcf"
        linkColor: "#8fc8ff"
        font.pixelSize: Math.max(10, Math.min(13, root.width / 100))
        onLinkActivated: function(link) { Qt.openUrlExternally(link); }
    }
}
