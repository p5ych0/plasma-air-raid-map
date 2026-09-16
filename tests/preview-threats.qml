// Synthetic fixtures for visual inspection of every symbol and provider flag.
import QtQuick
import QtQuick.Window
import "../package/contents/ui"
import "../package/contents/ui/MapData.js" as Data

Window {
    width: 1280
    height: 720
    visible: true
    AlertMap {
        id: map
        anchors.fill: parent
        source: AlertSource {
            autoRefresh: false
            Component.onCompleted: {
                oblasts = Data.prepareGeometry({type: "FeatureCollection", features: [{
                    properties: {key: "test", region: "SYNTHETIC TEST DATA"},
                    geometry: {type: "Polygon", coordinates: [[[22,44],[40,44],[40,52],[22,52],[22,44]]]}
                }]});
                raions = oblasts;
                acceptSnapshot({oblasts: [{key: "test"}], raions: []});
                const types = ["uav", "fpv", "recon", "missile", "ballistic", "kab", "mig31k", "unknown"];
                const entries = types.map(function(type, i) {
                    return {id: type, type: type, status: "active", lon: 25 + (i % 4) * 4,
                        lat: i < 4 ? 49 : 46, heading: i === 0 ? 90 : null,
                        count: i === 0 ? 3 : 0, advisory: type === "mig31k",
                        positionQuality: type === "fpv" ? "approx" : "confirmed"};
                });
                entries.push({id: "area", type: "missile", status: "active", areaOnly: true,
                    region: "Тестова область", heading: 180});
                entries.push({id: "advisory", type: "mig31k", status: "active", areaOnly: true,
                    region: "Інша область", advisory: true});
                acceptThreats({threats: entries});
            }
        }
    }
    Timer {
        interval: 1000
        running: true
        onTriggered: map.grabToImage(function(result) {
            if (!result.saveToFile("/tmp/plasma-air-raid-threat-symbols.png")) { Qt.exit(1); return; }
            map.source.threatsError = "Synthetic outage";
            staleCapture.start();
        })
    }
    Timer {
        id: staleCapture
        interval: 500
        onTriggered: map.grabToImage(function(result) {
            if (!result.saveToFile("/tmp/plasma-air-raid-threat-outage.png")) { Qt.exit(1); return; }
            Qt.quit();
        })
    }
}
