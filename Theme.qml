pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Colors come from ~/.local/state/foonshell/colors.json, which matugen regenerates on wallpaper change.
// The file is watched, so the bar recolors without a restart.
Singleton {
    id: root

    readonly property var c: adapter

    readonly property string font: Config.font
    readonly property int fontSize: Config.fontSize
    readonly property int iconSize: Config.iconSize
    readonly property string displayFont: Config.displayFont
    readonly property int displayFontSize: Config.displayFontSize

    readonly property int barHeight: Config.barHeight
    readonly property int gap: Config.gap
    readonly property int radius: Config.radius
    readonly property int pillPadding: Config.pillPadding
    // Scales the fixed corner radii of individual widgets with the radius setting,
    // so they keep their designed look at the default 10 and follow a smaller one
    function round(r: real): real {
        return r * Config.radius / 10;
    }
    readonly property bool outlined: Config.outlined
    readonly property bool iconTint: Config.iconTint
    // Text colors on the bar itself; popups and tooltips use the palette directly
    readonly property color text: Config.accentText ? c.primary : c.on_surface
    readonly property color textVariant: Config.accentText ? c.primary : c.on_surface_variant
    // Status icons and the current workspace; colors.json may give a stronger color than primary
    readonly property color accent: c.highlight || c.primary
    readonly property color onAccent: c.highlight ? (c.on_highlight || c.on_primary) : c.on_primary

    FileView {
        path: `${Config.stateDir}/colors.json`
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
            // Optional, empty means primary
            property string highlight: ""
            property string on_highlight: ""
            property string secondary: "#e6bad7"
            property string tertiary: "#dcbaf0"
            property string error: "#ffb4ab"
        }
    }
}
