import QtQuick
import Quickshell
import qs

// Panel that drops down under a bar item and closes on outside clicks.
// Set anchor.item to the item it belongs to and call toggle() from its click handler.
PopupWindow {
    id: root

    default property alias content: column.data

    // The compositor dismisses the popup on an outside click before the item's click
    // handler runs, so a click on the item right after a dismissal must not reopen it
    property double closedAt: 0

    function toggle() {
        if (visible)
            visible = false;
        else if (Date.now() - closedAt > 200)
            visible = true;
    }

    anchor.rect.y: anchor.item ? anchor.item.height + Theme.gap * 2 : 0
    anchor.rect.x: anchor.item ? anchor.item.width : 0
    anchor.gravity: Edges.Bottom | Edges.Left
    implicitWidth: 300
    implicitHeight: column.implicitHeight + Theme.pillPadding * 2
    color: "transparent"
    visible: false
    grabFocus: true

    onVisibleChanged: if (!visible) closedAt = Date.now()

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.c.surface_container
        border.color: Theme.c.outline_variant

        Column {
            id: column
            anchors {
                fill: parent
                margins: Theme.pillPadding
            }
            spacing: Theme.gap
        }
    }
}
