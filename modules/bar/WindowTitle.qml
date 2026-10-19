import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

// Title of the focused window, shown only on the monitor it lives on
Text {
    id: root

    property ShellScreen screen
    property real maxWidth: 400
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property HyprlandToplevel toplevel: Hyprland.activeToplevel

    width: Math.min(implicitWidth, maxWidth)
    text: toplevel && toplevel.workspace === monitor?.activeWorkspace ? toplevel.title : ""
    elide: Text.ElideRight
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    color: Theme.c.on_surface_variant
}
