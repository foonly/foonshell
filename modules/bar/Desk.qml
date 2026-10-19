import QtQuick
import Quickshell
import qs

// Standing desk height via the `desk` CLI. Left click: named positions. Right click: stop.
// Hidden unless the CLI exists, has named positions and the desk answers.
BarIcon {
    id: root

    readonly property bool shown: DeskService.available

    visible: shown
    icon: "󱈹"
    label: DeskService.height
    dimmed: DeskService.moving

    onLeftClicked: popup.toggle()
    onRightClicked: DeskService.stop()

    BarPopup {
        id: popup
        anchor.item: root
        implicitWidth: 220

        onVisibleChanged: if (visible)
            DeskService.refresh()

        Text {
            text: DeskService.moving ? "Desk · moving… (right click stops)" : "Desk"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.bold: true
            color: Theme.c.on_surface
        }

        Repeater {
            model: DeskService.positions

            MouseArea {
                id: row

                required property var modelData
                // Raw units are about 0.02 cm, so this is "within a few millimetres"
                readonly property bool current: DeskService.raw >= 0 && Math.abs(DeskService.raw - modelData.raw) < 20

                width: parent.width
                implicitHeight: 32
                hoverEnabled: true
                cursorShape: DeskService.moving ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: DeskService.goTo(modelData.name)

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius - 4
                    color: row.containsMouse && !DeskService.moving ? Theme.c.surface_container_highest : "transparent"
                }

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    text: row.modelData.name
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    color: row.current ? Theme.c.primary : Theme.c.on_surface
                }

                Text {
                    anchors {
                        right: parent.right
                        rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    text: row.modelData.height
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    color: row.current ? Theme.c.primary : Theme.c.outline
                }
            }
        }
    }
}
