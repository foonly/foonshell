import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs

// Shows the workspaces that live on this bar's monitor
Pill {
    id: root

    property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    spacing: 4

    Repeater {
        model: Hyprland.workspaces.values.filter(ws => ws.id > 0 && ws.monitor === root.monitor)

        Rectangle {
            id: button

            required property HyprlandWorkspace modelData
            readonly property bool current: modelData.active
            readonly property bool occupied: modelData.toplevels.values.length > 0
            // One icon per app, so five terminals don't take up five slots
            readonly property var icons: {
                const seen = new Set();
                const result = [];
                for (const t of modelData.toplevels.values) {
                    const appId = t.wayland?.appId ?? t.lastIpcObject?.class ?? "";
                    if (!appId || seen.has(appId))
                        continue;
                    seen.add(appId);
                    const entry = DesktopEntries.heuristicLookup(appId);
                    result.push(Quickshell.iconPath(entry?.icon ?? appId, "application-x-executable"));
                }
                return result;
            }

            implicitWidth: Math.max(current ? 28 : 18, content.implicitWidth + 12)
            implicitHeight: 18
            radius: height / 2
            color: modelData.urgent ? Theme.c.error
                : current ? Theme.c.primary
                : mouse.containsMouse ? Theme.c.surface_container_highest
                : "transparent"

            Behavior on implicitWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                id: content
                anchors.centerIn: parent
                spacing: 3

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: button.modelData.name
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    font.bold: button.current
                    color: button.current ? Theme.c.on_primary
                        : button.occupied ? Theme.c.on_surface
                        : Theme.c.outline
                }

                Repeater {
                    model: button.icons

                    IconImage {
                        required property string modelData
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 12
                        source: modelData
                    }
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: button.modelData.activate()
            }
        }
    }

    // Scroll over the switcher to move between workspaces on this monitor
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const list = Hyprland.workspaces.values.filter(ws => ws.id > 0 && ws.monitor === root.monitor);
            const index = list.findIndex(ws => ws.active);
            const next = list[index + (event.angleDelta.y > 0 ? -1 : 1)];
            if (next)
                next.activate();
        }
    }
}
