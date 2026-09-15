// SPDX-License-Identifier: MIT
import QtQuick
import "MapData.js" as Data

Item {
    id: root
    visible: false
    property string apiBase: "https://neptun.in.ua"
    property int pollInterval: 30000
    property bool autoRefresh: true
    property var oblasts: null
    property var raions: null
    property var snapshot: null
    property double lastSuccess: 0
    property double now: Date.now()
    property string error: ""
    property var currentRequest: null
    property int updateCount: 0
    readonly property bool stale: Data.isStale(lastSuccess, now, error !== "")

    function acceptSnapshot(payload) {
        const next = Data.parseSnapshot(payload, oblasts, raions);
        snapshot = next;
        lastSuccess = Date.now();
        now = lastSuccess;
        error = "";
        ++updateCount;
    }

    function getJson(path, accept) {
        const xhr = new XMLHttpRequest();
        currentRequest = xhr;
        timeout.restart();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || root.currentRequest !== xhr) return;
            root.currentRequest = null;
            timeout.stop();
            if (xhr.status !== 200) { root.error = "HTTP " + xhr.status; return; }
            try { accept(JSON.parse(xhr.responseText)); }
            catch (e) { root.error = String(e); }
        };
        xhr.open("GET", apiBase + path);
        xhr.send();
    }

    function refresh() {
        if (currentRequest !== null) return;
        if (oblasts === null) {
            getJson("/oblasts.geojson", function(data) {
                root.oblasts = Data.prepareGeometry(data); root.refresh();
            });
        } else if (raions === null) {
            getJson("/raions.geojson", function(data) {
                root.raions = Data.prepareGeometry(data); root.refresh();
            });
        } else {
            getJson("/api/v1/alerts", function(data) { root.acceptSnapshot(data); });
        }
    }

    Timer {
        id: timeout
        interval: 15000
        onTriggered: {
            const xhr = root.currentRequest;
            root.currentRequest = null;
            root.error = "Network timeout";
            if (xhr !== null) xhr.abort();
        }
    }
    Timer {
        interval: root.pollInterval
        repeat: true
        running: root.autoRefresh
        onTriggered: root.refresh()
    }
    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = Date.now()
    }
    Component.onCompleted: if (autoRefresh) refresh()
    Component.onDestruction: {
        if (currentRequest !== null) {
            currentRequest.onreadystatechange = function() {};
            currentRequest.abort();
        }
    }
}
