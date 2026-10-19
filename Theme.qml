pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Colors come from ~/.config/foonshell/colors.json, which matugen regenerates on wallpaper change.
// The file is watched, so the bar recolors without a restart.
Singleton {
    id: root

    readonly property var c: adapter

    readonly property string font: Config.font
    readonly property int fontSize: Config.fontSize
    readonly property int iconSize: Config.iconSize

    readonly property int barHeight: Config.barHeight
    readonly property int gap: Config.gap
    readonly property int radius: Config.radius
    readonly property int pillPadding: Config.pillPadding

    FileView {
        path: `${Config.configDir}/colors.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            // Fallbacks match the current DMS palette until matugen writes the file
            property string background: "#161219"
            property string surface: "#161219"
            property string surface_container: "#221e26"
            property string surface_container_high: "#2d2830"
            property string surface_container_highest: "#38333b"
            property string on_surface: "#e9e0eb"
            property string on_surface_variant: "#cec3d4"
            property string outline: "#978d9d"
            property string outline_variant: "#4b4452"
            property string primary: "#7cd7ba"
            property string on_primary: "#00382b"
            property string secondary: "#e6bad7"
            property string tertiary: "#dcbaf0"
            property string error: "#ffb4ab"
        }
    }
}
