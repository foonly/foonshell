import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs

Pill {
    id: root

    required property PanelWindow bar
    readonly property bool shown: SystemTray.items.values.length > 0

    visible: shown
    spacing: 8

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item

            required property SystemTrayItem modelData

            implicitWidth: Theme.iconSize + 2
            implicitHeight: Theme.iconSize + 2
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor

            onClicked: event => {
                if (event.button === Qt.MiddleButton) {
                    modelData.secondaryActivate();
                } else if (event.button === Qt.RightButton || modelData.onlyMenu) {
                    if (modelData.hasMenu) {
                        const pos = mapToItem(root.bar.contentItem, 0, height);
                        modelData.display(root.bar, pos.x, pos.y + Theme.gap);
                    }
                } else {
                    modelData.activate();
                }
            }

            onWheel: event => modelData.scroll(event.angleDelta.y, false)

            IconImage {
                anchors.fill: parent
                source: {
                    // Some apps (Electron, Steam) send "name?path=/dir" instead of an icon name
                    const icon = item.modelData.icon;
                    if (!icon.includes("?path="))
                        return icon;
                    const [name, path] = icon.split("?path=");
                    return `file://${path}/${name.slice(name.lastIndexOf("/") + 1)}`;
                }
            }
        }
    }
}
