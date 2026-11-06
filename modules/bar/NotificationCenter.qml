import QtQuick
import Quickshell
import qs

// Bell with the unread count. Click: notification center.
Pill {
    id: root

    readonly property int count: NotificationService.all.length
    readonly property int unread: NotificationService.unread

    BarIcon {
        id: bell
        anchors.verticalCenter: parent.verticalCenter
        icon: root.unread > 0 ? "󰂞" : root.count > 0 ? "󰂚" : "󰂜"
        label: root.unread > 0 ? `${root.unread}` : ""
        dimmed: root.count === 0
        alert: NotificationService.hasCritical

        onLeftClicked: center.toggle()
    }

    // Make the whole pill clickable, not just the icon
    MouseArea {
        parent: root
        anchors.fill: parent
        z: -1
        cursorShape: Qt.PointingHandCursor
        onClicked: center.toggle()
    }

    NotificationCenterPopup {
        id: center
        anchor.item: root
        onVisibleChanged: NotificationService.centerOpen = visible
    }
}
