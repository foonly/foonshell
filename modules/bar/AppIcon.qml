import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs

// App or tray icon; with iconTint set it is recolored to the status icons' accent color
IconImage {
    id: root

    property color tint: Theme.c.primary

    layer.enabled: Theme.iconTint
    layer.effect: MultiEffect {
        colorization: 1.0
        colorizationColor: root.tint
    }
}
