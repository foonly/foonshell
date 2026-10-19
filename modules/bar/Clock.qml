import QtQuick
import Quickshell
import qs

// Left click: calendar
Pill {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        text: Qt.formatDateTime(clock.date, Config.dateFormat)
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        color: Theme.c.on_surface_variant
    }

    Text {
        text: Qt.formatDateTime(clock.date, Config.timeFormat)
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.bold: true
        color: Theme.c.on_surface
    }

    MouseArea {
        parent: root
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: calendar.toggle()
    }

    CalendarPopup {
        id: calendar
        anchor.item: root
    }
}
