// SPDX-License-Identifier: MIT
import QtQuick

Item {
    id: root
    property alias apiBase: feed.apiBase
    property alias pollInterval: feed.pollInterval
    readonly property int updateCount: feed.updateCount
    readonly property bool stale: feed.stale

    AlertSource { id: feed }
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
            if (!feed.oblasts) return;
            const b = feed.oblasts.bounds;
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

            for (const region of feed.oblasts.regions) {
                path(region); ctx.fillStyle = "#223448"; ctx.fill();
            }
            ctx.globalAlpha = feed.stale ? 0.4 : 1;
            if (feed.snapshot && feed.raions) {
                // Red is painted last so overlapping yellow alerts cannot hide it.
                for (const level of ["yellow", "red"]) {
                    ctx.fillStyle = level === "red" ? "#cf4655" : "#c69235";
                    for (const kind of ["oblasts", "raions"]) {
                        const geometry = kind === "oblasts" ? feed.oblasts : feed.raions;
                        for (const region of geometry.regions) {
                            if (feed.snapshot[kind]["@" + region.key] === level) {
                                path(region); ctx.fill();
                            }
                        }
                    }
                }
            }
            ctx.globalAlpha = 1;
            ctx.lineWidth = 0.5;
            ctx.strokeStyle = "#456078";
            if (feed.raions) {
                for (const region of feed.raions.regions) { path(region); ctx.stroke(); }
            }
            ctx.lineWidth = 1.2;
            ctx.strokeStyle = "#9ab1c6";
            for (const region of feed.oblasts.regions) { path(region); ctx.stroke(); }

            const fontSize = Math.max(9, Math.min(17, width / 100));
            ctx.font = "600 " + fontSize + "px sans-serif";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.lineWidth = 3;
            for (const region of feed.oblasts.regions) {
                if (region.key === "м. київ" || region.key === "севастополь") continue;
                const x = ox + (region.center[0] - b[0]) * scale;
                const y = oy + (region.center[1] - b[1]) * scale;
                ctx.strokeStyle = "#172431";
                ctx.strokeText(region.label, x, y);
                ctx.fillStyle = "#eef4fa";
                ctx.fillText(region.label, x, y);
            }
        }
    }

    Connections {
        target: feed
        function onOblastsChanged() { canvas.requestPaint(); }
        function onRaionsChanged() { canvas.requestPaint(); }
        function onSnapshotChanged() { canvas.requestPaint(); }
        function onStaleChanged() { canvas.requestPaint(); }
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
        text: feed.stale ? (feed.lastSuccess ? "ДАНІ ЗАСТАРІЛИ" : "ОЧІКУВАННЯ ДАНИХ")
                        : "Оновлено " + Qt.formatTime(new Date(feed.lastSuccess), "HH:mm:ss")
        color: feed.stale ? "#e5b45b" : "#a8bdcf"
        font.pixelSize: Math.max(11, Math.min(15, root.width / 85))
    }
    Text {
        anchors.centerIn: parent
        visible: feed.stale
        text: feed.oblasts ? "Немає актуальних даних\nПовторна спроба автоматично" : "Завантаження мапи…"
        horizontalAlignment: Text.AlignHCenter
        color: "#f2c879"
        style: Text.Outline
        styleColor: "#0e1722"
        font.pixelSize: 22
        font.bold: true
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
