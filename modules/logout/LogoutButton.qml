import QtQuick
import qs

Rectangle {
    id: root

    property string actionId: ""
    property string label: ""
    property string icon: ""
    property string keyHint: ""
    property color accentColor: Theme.c.primary
    property bool isSelected: false

    signal triggered
    signal hovered

    implicitWidth: 140
    implicitHeight: 160
    radius: Theme.radius + 6

    readonly property bool isHovered: mouseArea.containsMouse
    readonly property bool isHighlighted: isHovered || isSelected

    color: isHighlighted ? Theme.c.surface_container_highest : Theme.c.surface_container
    border.width: isHighlighted ? 2 : 1.5
    border.color: isHighlighted ? accentColor : Theme.c.outline_variant
    scale: isHighlighted ? 1.05 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutBack
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: 120
        }
    }

    // Key hint badge in the top-right corner
    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            margins: 10
        }
        width: 24
        height: 22
        radius: 6
        color: root.isHighlighted ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22) : Theme.c.surface_container_high
        border.width: 1
        border.color: root.isHighlighted ? root.accentColor : Theme.c.outline_variant

        Text {
            anchors.centerIn: parent
            text: root.keyHint
            font.family: Theme.font
            font.pixelSize: 11
            font.bold: true
            color: root.isHighlighted ? root.accentColor : Theme.c.outline
        }
    }

    // Center icon & label
    Column {
        anchors.centerIn: parent
        spacing: 12

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            font.family: Theme.font
            font.pixelSize: 44
            color: root.isHighlighted ? root.accentColor : Theme.c.on_surface_variant

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            font.family: Theme.font
            font.pixelSize: 14
            font.bold: true
            color: root.isHighlighted ? Theme.c.on_surface : Theme.c.on_surface_variant

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
        onEntered: root.hovered()
    }
}
