import QtQuick
import qs

// Rounded container that groups related bar items
Rectangle {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing

    implicitWidth: row.implicitWidth + Theme.pillPadding * 2
    implicitHeight: Theme.barHeight - Theme.gap * 2
    radius: Theme.radius
    color: Theme.outlined ? "transparent" : Theme.c.surface_container_high
    border.width: Theme.outlined ? 1 : 0
    border.color: Theme.c.outline_variant

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10
    }
}
