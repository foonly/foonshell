import QtQuick
import Quickshell
import qs

// Small panel shown under a bar item while it's hovered.
// Set anchor.item to the item and bind `shown` to its hover state.
PopupWindow {
    id: root

    default property alias content: column.data
    property bool shown

    anchor.rect.y: anchor.item ? anchor.item.height + Theme.gap * 2 : 0
    anchor.rect.x: anchor.item ? anchor.item.width / 2 : 0
    anchor.gravity: Edges.Bottom
    implicitWidth: column.implicitWidth + Theme.pillPadding * 2
    implicitHeight: column.implicitHeight + Theme.pillPadding * 2
    color: "transparent"
    visible: false

    onShownChanged: shown ? delay.restart() : (delay.stop(), visible = false)

    // Don't flash open when the pointer just passes over the bar
    Timer {
        id: delay
        interval: 300
        onTriggered: root.visible = true
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.c.surface_container
        border.color: Theme.c.outline_variant

        Column {
            id: column
            anchors.centerIn: parent
            spacing: 4
        }
    }
}
