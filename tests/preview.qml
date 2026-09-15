// Live-provider smoke test. Run with the offscreen software backend, outside Plasma.
import QtQuick
import QtQuick.Window
import "../package/contents/ui"

Window {
    width: 1280
    height: 720
    visible: true
    color: "#101820"

    AlertMap {
        id: map
        anchors.fill: parent
        pollInterval: 5000
    }

    Timer {
        interval: 20000
        running: true
        onTriggered: {
            if (map.stale || map.updateCount < 2) {
                console.error("Native map did not receive repeated updates: " + map.updateCount);
                Qt.exit(1);
                return;
            }
            map.grabToImage(function(result) {
                if (!result.saveToFile("/tmp/plasma-air-raid-map-preview.png")) {
                    Qt.exit(1);
                    return;
                }
                console.info("Saved native map preview after " + map.updateCount + " valid updates");
                Qt.quit();
            });
        }
    }
}
