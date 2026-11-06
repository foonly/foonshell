import QtQuick
import Quickshell
import qs
import qs.modules.notifications

// Notification history under the bell: persistent notifications first, then the rest
// by urgency, newest first. Scrolls once it outgrows the screen.
BarPopup {
    id: root

    implicitWidth: 400

    Item {
        width: parent.width
        implicitHeight: clear.implicitHeight

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.bold: true
            color: Theme.c.on_surface
        }

        Text {
            id: clear
            anchors.right: parent.right
            visible: NotificationService.all.length > 0
            text: "Clear all"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            color: clearMouse.containsMouse ? Theme.c.primary : Theme.c.outline

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationService.clearAll()
            }
        }
    }

    Text {
        visible: NotificationService.all.length === 0
        width: parent.width
        topPadding: Theme.gap * 2
        bottomPadding: Theme.gap * 2
        horizontalAlignment: Text.AlignHCenter
        text: "No notifications"
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        color: Theme.c.outline
    }

    Flickable {
        visible: NotificationService.all.length > 0
        width: parent.width
        height: Math.min(contentHeight, 640)
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list
            width: parent.width
            spacing: Theme.gap

            Repeater {
                model: NotificationService.history

                NotificationCard {
                    width: list.width
                    popup: false
                }
            }
        }
    }
}
