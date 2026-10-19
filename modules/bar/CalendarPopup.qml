import QtQuick
import QtQuick.Controls
import Quickshell
import qs

// Month calendar shown under the clock, with events from CalendarService.
// Scroll or use the arrows to change month, click a day to see its events,
// click the title to jump back to today.
BarPopup {
    id: root

    property date today: new Date()
    property int month: today.getMonth()
    property int year: today.getFullYear()
    property date selected: today
    readonly property var selectedEvents: CalendarService.eventsOn(selected)

    // Centered under the clock instead of right aligned
    anchor.rect.x: anchor.item ? anchor.item.width / 2 : 0
    anchor.gravity: Edges.Bottom
    implicitWidth: 280

    // Always open on the current month
    onVisibleChanged: if (visible) {
        goToday();
        CalendarService.refreshIfStale();
    }

    function goToday() {
        today = new Date();
        selected = today;
        month = today.getMonth();
        year = today.getFullYear();
    }

    function sameDay(a: date, b: date): bool {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    function eventColor(event): color {
        return event.color || Theme.c.primary;
    }

    // "09:00 – 10:30", "All day", or "Until 12:00" on the last day of a multi day event
    function timeText(event): string {
        if (event.allDay)
            return "All day";
        const start = new Date(event.start);
        const end = new Date(event.end);
        const startsToday = sameDay(start, selected);
        const endsToday = sameDay(new Date(end - 1), selected);
        if (startsToday && endsToday)
            return `${Qt.formatTime(start, "HH:mm")} – ${Qt.formatTime(end, "HH:mm")}`;
        if (startsToday)
            return `From ${Qt.formatTime(start, "HH:mm")}`;
        if (endsToday)
            return `Until ${Qt.formatTime(end, "HH:mm")}`;
        return "All day";
    }

    function shift(months: int) {
        const d = new Date(year, month + months, 1);
        month = d.getMonth();
        year = d.getFullYear();
    }

    component NavButton: MouseArea {
        id: button

        property string icon

        implicitWidth: 24
        implicitHeight: 24
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: button.containsMouse ? Theme.c.surface_container_highest : "transparent"
        }

        Text {
            anchors.centerIn: parent
            text: button.icon
            font.family: Theme.font
            font.pixelSize: Theme.iconSize
            color: Theme.c.on_surface_variant
        }
    }

    Item {
        width: parent.width
        implicitHeight: 24

        NavButton {
            anchors.left: parent.left
            icon: "󰅁"
            onClicked: root.shift(-1)
        }

        MouseArea {
            anchors.centerIn: parent
            implicitWidth: title.implicitWidth
            implicitHeight: title.implicitHeight
            cursorShape: Qt.PointingHandCursor
            onClicked: root.goToday()

            Text {
                id: title
                text: Qt.locale().standaloneMonthName(root.month) + " " + root.year
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.bold: true
                font.capitalization: Font.Capitalize
                color: Theme.c.on_surface
            }
        }

        NavButton {
            anchors.right: parent.right
            icon: "󰅂"
            onClicked: root.shift(1)
        }
    }

    Item {
        width: parent.width
        implicitHeight: grid.implicitHeight + days.implicitHeight

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => root.shift(event.angleDelta.y > 0 ? -1 : 1)
        }

        WeekNumberColumn {
            id: weeks
            anchors {
                left: parent.left
                top: grid.top
                bottom: grid.bottom
            }
            implicitWidth: 24
            month: root.month
            year: root.year

            delegate: Text {
                required property int weekNumber
                text: weekNumber
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
                color: Theme.c.outline
            }
        }

        DayOfWeekRow {
            id: days
            anchors {
                left: weeks.right
                right: parent.right
            }

            delegate: Text {
                required property string shortName
                text: shortName.slice(0, 2)
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
                font.capitalization: Font.Capitalize
                color: Theme.c.outline
            }
        }

        MonthGrid {
            id: grid
            anchors {
                left: weeks.right
                right: parent.right
                top: days.bottom
            }
            month: root.month
            year: root.year
            spacing: 2

            delegate: MouseArea {
                id: day

                required property var model
                readonly property bool isToday: model.today
                readonly property bool inMonth: model.month === root.month
                readonly property bool isSelected: root.sameDay(model.date, root.selected)
                readonly property var events: CalendarService.eventsOn(model.date)

                implicitWidth: 30
                implicitHeight: 32
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selected = model.date

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 1
                    width: 26
                    height: 26
                    radius: height / 2
                    color: day.isToday ? Theme.c.primary
                        : day.containsMouse ? Theme.c.surface_container_highest
                        : "transparent"
                    border.width: day.isSelected && !day.isToday ? 1 : 0
                    border.color: Theme.c.primary
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 1
                    height: 26
                    verticalAlignment: Text.AlignVCenter
                    text: day.model.day
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    font.bold: day.isToday
                    color: day.isToday ? Theme.c.on_primary
                        : day.inMonth ? Theme.c.on_surface
                        : Theme.c.outline_variant
                }

                // One dot per calendar with events that day
                Row {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                    }
                    spacing: 2

                    Repeater {
                        model: [...new Set(day.events.map(e => root.eventColor(e).toString()))].slice(0, 3)

                        Rectangle {
                            required property string modelData
                            width: 4
                            height: 4
                            radius: 2
                            color: modelData
                            opacity: day.inMonth ? 1 : 0.4
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.c.outline_variant
    }

    Item {
        width: parent.width
        implicitHeight: agendaTitle.implicitHeight

        Text {
            id: agendaTitle
            text: root.sameDay(root.selected, root.today) ? "Today"
                : Qt.locale().toString(root.selected, "dddd d MMMM")
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.bold: true
            font.capitalization: Font.Capitalize
            color: Theme.c.on_surface
        }

        Text {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            visible: CalendarService.syncing || CalendarService.errors.length > 0
            text: CalendarService.syncing ? "Syncing…" : "Sync failed"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 2
            color: CalendarService.syncing ? Theme.c.outline : Theme.c.error
        }
    }

    Text {
        visible: root.selectedEvents.length === 0
        width: parent.width
        wrapMode: Text.Wrap
        text: CalendarService.configured ? "No events"
            : "Add iCal links to calendars.json to see events here"
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
        color: Theme.c.outline
    }

    ListView {
        visible: root.selectedEvents.length > 0
        width: parent.width
        implicitHeight: Math.min(contentHeight, 220)
        clip: true
        spacing: 6
        model: root.selectedEvents

        delegate: Item {
            id: event

            required property var modelData

            width: ListView.view.width
            implicitHeight: details.implicitHeight

            Rectangle {
                id: bar
                width: 3
                height: parent.height
                radius: 1.5
                color: root.eventColor(event.modelData)
            }

            Column {
                id: details
                anchors {
                    left: bar.right
                    leftMargin: 8
                    right: parent.right
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: event.modelData.title
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    color: Theme.c.on_surface
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.timeText(event.modelData) + (event.modelData.location ? ` · ${event.modelData.location}` : "")
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                    color: Theme.c.outline
                }
            }
        }
    }
}
