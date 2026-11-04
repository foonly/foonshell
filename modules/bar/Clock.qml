import QtQuick
import Quickshell
import qs

// Left click: calendar
Pill {
    id: root

    SystemClock {
        id: clock
        precision: /s/.test(Config.timeFormat + Config.dateFormat) ? SystemClock.Seconds : SystemClock.Minutes
    }

    Text {
        text: Qt.formatDateTime(clock.date, Config.dateFormat)
        font.family: Theme.displayFont
        font.pixelSize: Theme.displayFontSize
        color: Theme.textVariant
    }

    Text {
        text: Qt.formatDateTime(clock.date, Config.timeFormat)
        font.family: Theme.displayFont
        font.pixelSize: Theme.displayFontSize
        font.bold: true
        color: Theme.text
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
