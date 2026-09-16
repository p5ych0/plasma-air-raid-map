// SPDX-License-Identifier: MIT
import QtQuick
import org.kde.plasma.plasmoid

WallpaperItem {
    AlertMap {
        anchors.fill: parent
        // Plasma supplies screen-local coordinates and updates them when panels move.
        availableRect: Containment.availableScreenRect
        onUpdateCountChanged: {
            if (updateCount === 1)
                console.info("Air Raid Map (native): first valid alert snapshot received; available desktop "
                             + availableRect);
        }
        onThreatsUpdateCountChanged: {
            if (threatsUpdateCount === 1)
                console.info("Air Raid Map (native): first valid threat snapshot received ("
                             + source.threats.count + " reports)");
        }
    }
}
