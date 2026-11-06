import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

// Popups in the top-right of the focused monitor. The server and history live in
// NotificationService; timed-out popups stay in the notification center on the bar.
Scope {
    id: root

    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: NotificationService.popups.length > 0 && !NotificationService.centerOpen
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "foonshell:notifications"
        exclusionMode: ExclusionMode.Normal

        anchors {
            top: true
            right: true
        }
        margins {
            top: Theme.gap
            right: Theme.gap
        }

        implicitWidth: 380
        implicitHeight: column.implicitHeight

        Column {
            id: column
            width: parent.width
            spacing: Theme.gap

            Repeater {
                model: NotificationService.popups

                NotificationCard {
                    width: column.width
                }
            }
        }
    }
}
