import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs

// Left click: device popup. Right click: toggle power. Hover: connected devices.
BarIcon {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)

    icon: !enabled ? "󰂲" : connected.length > 0 ? "󰂱" : "󰂯"
    dimmed: !enabled
    hoverEnabled: true

    onLeftClicked: popup.toggle()
    onRightClicked: if (adapter) adapter.enabled = !adapter.enabled

    BluetoothPopup {
        id: popup
        anchor.item: root
        adapter: root.adapter
    }

    BarTooltip {
        anchor.item: root
        shown: root.containsMouse && !popup.visible

        Text {
            visible: root.connected.length === 0
            text: root.enabled ? "No devices connected" : "Bluetooth off"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            color: Theme.c.outline
        }

        Repeater {
            model: root.connected

            Row {
                required property BluetoothDevice modelData
                spacing: 8

                Text {
                    text: parent.modelData.name
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    color: Theme.c.on_surface
                }

                Text {
                    visible: parent.modelData.batteryAvailable
                    text: `${Math.round(parent.modelData.battery * 100)}%`
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    color: Theme.c.outline
                }
            }
        }
    }
}
