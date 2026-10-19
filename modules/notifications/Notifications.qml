import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs

// Notification daemon with popups in the top-right of the focused monitor
Scope {
    id: root

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true

        onNotification: notification => notification.tracked = true
    }

    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: server.trackedNotifications.values.length > 0
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
                model: server.trackedNotifications

                NotificationCard {
                    width: column.width
                }
            }
        }
    }
}
