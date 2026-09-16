// SPDX-License-Identifier: MIT
import QtQuick
import org.kde.plasma.plasmoid

WallpaperItem {
    AlertMap {
        anchors.fill: parent
        onUpdateCountChanged: {
            if (updateCount === 1)
                console.info("Air Raid Map (native): first valid alert snapshot received");
        }
        onThreatsUpdateCountChanged: {
            if (threatsUpdateCount === 1)
                console.info("Air Raid Map (native): first valid threat snapshot received ("
                             + source.threats.count + " reports)");
        }
    }
}
