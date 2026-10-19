import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

// Picker for the default output and input device
BarPopup {
    id: root

    readonly property var devices: Pipewire.nodes.values.filter(n => n.audio && !n.isStream)

    component SectionTitle: Text {
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.bold: true
        color: Theme.c.on_surface
    }

    component DeviceRow: MouseArea {
        id: row

        required property PwNode modelData
        property bool current

        width: parent.width
        implicitHeight: 32
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius - 4
            color: row.containsMouse ? Theme.c.surface_container_highest : "transparent"
        }

        Text {
            id: icon
            anchors {
                left: parent.left
                leftMargin: 8
                verticalCenter: parent.verticalCenter
            }
            text: AudioService.icon(row.modelData)
            font.family: Theme.font
            font.pixelSize: Theme.iconSize
            color: row.current ? Theme.c.primary : Theme.c.on_surface_variant
        }

        Text {
            anchors {
                left: icon.right
                leftMargin: 10
                right: check.left
                rightMargin: 6
                verticalCenter: parent.verticalCenter
            }
            elide: Text.ElideRight
            text: row.modelData.description || row.modelData.nickname || row.modelData.name
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            color: row.current ? Theme.c.on_surface : Theme.c.on_surface_variant
        }

        Text {
            id: check
            anchors {
                right: parent.right
                rightMargin: 8
                verticalCenter: parent.verticalCenter
            }
            text: row.current ? "󰄬" : ""
            font.family: Theme.font
            font.pixelSize: Theme.iconSize
            color: Theme.c.primary
        }
    }

    SectionTitle {
        text: "Output"
    }

    Repeater {
        model: root.devices.filter(n => n.isSink)

        DeviceRow {
            current: modelData === Pipewire.defaultAudioSink
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }

    SectionTitle {
        text: "Input"
    }

    Repeater {
        model: root.devices.filter(n => !n.isSink)

        DeviceRow {
            current: modelData === Pipewire.defaultAudioSource
            onClicked: Pipewire.preferredDefaultAudioSource = modelData
        }
    }
}
