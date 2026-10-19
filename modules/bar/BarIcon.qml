import QtQuick
import qs

// Nerd font icon with optional label, used by the status indicators
MouseArea {
    id: root

    property string icon
    property string label
    property bool dimmed
    property bool alert

    signal leftClicked
    signal rightClicked
    signal scrolled(int delta)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: event => event.button === Qt.RightButton ? rightClicked() : leftClicked()
    onWheel: event => scrolled(event.angleDelta.y)

    Row {
        id: row
        spacing: 5

        Text {
            text: root.icon
            font.family: Theme.font
            font.pixelSize: Theme.iconSize
            color: root.alert ? Theme.c.error : root.dimmed ? Theme.c.outline : Theme.c.primary
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.label !== ""
            text: root.label
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            color: root.dimmed ? Theme.c.outline : Theme.c.on_surface
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
