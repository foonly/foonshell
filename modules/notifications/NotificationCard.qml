import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs

// Left click runs the default action (or dismisses), right click dismisses.
// Hovering pauses the timeout.
Rectangle {
    id: root

    required property Notification modelData
    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
    readonly property string image: modelData.image || (modelData.appIcon ? Quickshell.iconPath(modelData.appIcon, true) : "")

    implicitHeight: content.implicitHeight + 24
    radius: Theme.radius
    color: Theme.c.surface_container
    border.width: 2
    border.color: critical ? Theme.c.error : Theme.c.outline_variant

    Timer {
        // Apps send -1 for "server default", 0 for "never expire"
        interval: root.modelData.expireTimeout > 0 ? root.modelData.expireTimeout : 6000
        running: !root.critical && root.modelData.expireTimeout !== 0 && !mouse.containsMouse
        onTriggered: root.modelData.expire()
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            const action = root.modelData.actions.find(a => a.identifier === "default");
            if (event.button === Qt.LeftButton && action)
                action.invoke();
            else
                root.modelData.dismiss();
        }
    }

    Row {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 12

        IconImage {
            visible: root.image !== ""
            source: root.image
            implicitSize: 40
        }

        Column {
            width: parent.width - (root.image !== "" ? 52 : 0)
            spacing: 4

            Text {
                width: parent.width
                text: root.modelData.appName
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
                color: Theme.c.primary
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.modelData.summary
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1
                font.bold: true
                color: Theme.c.on_surface
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.modelData.body
                textFormat: Text.StyledText
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Theme.c.on_surface_variant
                wrapMode: Text.Wrap
                maximumLineCount: 5
                elide: Text.ElideRight
            }

            Row {
                visible: actions.count > 0
                spacing: Theme.gap
                topPadding: 4

                Repeater {
                    id: actions
                    model: root.modelData.actions.filter(a => a.identifier !== "default")

                    Rectangle {
                        required property NotificationAction modelData

                        implicitWidth: label.implicitWidth + 20
                        implicitHeight: label.implicitHeight + 10
                        radius: Theme.radius / 2
                        color: actionMouse.containsMouse ? Theme.c.surface_container_highest : Theme.c.surface_container_high

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: parent.modelData.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            color: Theme.c.on_surface
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.modelData.invoke()
                        }
                    }
                }
            }
        }
    }
}
