import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs

// Device list shown under the bluetooth indicator. Scans while open.
BarPopup {
    id: root

    property BluetoothAdapter adapter
    readonly property bool enabled: adapter?.enabled ?? false

    // Device we just paired and still want to connect once pairing finishes
    property BluetoothDevice pendingConnect

    // Connected first, then paired, then nearby devices that advertise a name
    readonly property var devices: Bluetooth.devices.values
        .filter(d => d.paired || d.deviceName !== "")
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))

    onVisibleChanged: if (adapter && enabled) adapter.discovering = visible

    function activate(device: BluetoothDevice) {
        if (device.connected) {
            device.disconnect();
        } else if (device.paired) {
            device.connect();
        } else {
            device.trusted = true;
            pendingConnect = device;
            device.pair();
        }
    }

    function deviceIcon(icon: string): string {
        if (icon.startsWith("audio-head"))
            return "󰋋";
        if (icon.startsWith("audio"))
            return "󰓃";
        if (icon === "input-mouse")
            return "󰍽";
        if (icon === "input-keyboard")
            return "󰌌";
        if (icon === "input-gaming")
            return "󰊴";
        if (icon === "phone")
            return "󰏲";
        if (icon === "computer")
            return "󰌢";
        return "󰂯";
    }

    Connections {
        target: root.pendingConnect

        function onPairedChanged() {
            if (root.pendingConnect.paired)
                root.pendingConnect.connect();
            root.pendingConnect = null;
        }

        function onPairingChanged() {
            // Pairing ended without success (cancelled, rejected, timed out)
            if (!root.pendingConnect.pairing && !root.pendingConnect.paired)
                root.pendingConnect = null;
        }
    }

    Item {
        width: parent.width
        implicitHeight: toggle.implicitHeight

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.adapter?.discovering ? "Bluetooth · scanning…" : "Bluetooth"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.bold: true
            color: Theme.c.on_surface
        }

        // Power switch
        Rectangle {
            id: toggle
            anchors.right: parent.right
            implicitWidth: 36
            implicitHeight: 20
            radius: height / 2
            color: root.enabled ? Theme.c.primary : Theme.c.surface_container_highest

            Rectangle {
                width: 14
                height: 14
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                x: root.enabled ? parent.width - width - 3 : 3
                color: root.enabled ? Theme.c.on_primary : Theme.c.outline

                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!root.adapter)
                        return;
                    root.adapter.enabled = !root.enabled;
                    if (root.adapter.enabled)
                        root.adapter.discovering = true;
                }
            }
        }
    }

    Text {
        visible: !root.enabled || root.devices.length === 0
        text: !root.adapter ? "No adapter found" : !root.enabled ? "Turned off" : "No devices found"
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        color: Theme.c.outline
    }

    ListView {
        visible: root.enabled
        width: parent.width
        implicitHeight: Math.min(contentHeight, 320)
        clip: true
        spacing: 2
        model: root.enabled ? root.devices : []

        delegate: MouseArea {
            id: row

            required property BluetoothDevice modelData
            readonly property bool busy: modelData.pairing
                || modelData.state === BluetoothDeviceState.Connecting
                || modelData.state === BluetoothDeviceState.Disconnecting

            width: ListView.view.width
            implicitHeight: 36
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activate(modelData)

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
                text: root.deviceIcon(row.modelData.icon)
                font.family: Theme.font
                font.pixelSize: Theme.iconSize
                color: row.modelData.connected ? Theme.c.primary : Theme.c.on_surface_variant
            }

            Column {
                anchors {
                    left: icon.right
                    leftMargin: 10
                    right: forget.left
                    rightMargin: 6
                    verticalCenter: parent.verticalCenter
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: row.modelData.name
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    color: Theme.c.on_surface
                }

                Text {
                    readonly property string status: {
                        const d = row.modelData;
                        if (d.pairing)
                            return "Pairing…";
                        if (d.state === BluetoothDeviceState.Connecting)
                            return "Connecting…";
                        if (d.state === BluetoothDeviceState.Disconnecting)
                            return "Disconnecting…";
                        if (d.connected)
                            return d.batteryAvailable ? `Connected · ${Math.round(d.battery * 100)}%` : "Connected";
                        return d.paired ? "" : "Click to pair";
                    }
                    visible: status !== ""
                    text: status
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                    color: row.busy ? Theme.c.secondary : Theme.c.outline
                }
            }

            // Forget a paired device
            MouseArea {
                id: forget
                visible: row.modelData.paired && row.containsMouse
                anchors {
                    right: parent.right
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                implicitWidth: forgetIcon.implicitWidth
                implicitHeight: forgetIcon.implicitHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: row.modelData.forget()

                Text {
                    id: forgetIcon
                    text: "󰆴"
                    font.family: Theme.font
                    font.pixelSize: Theme.iconSize
                    color: forget.containsMouse ? Theme.c.error : Theme.c.outline
                }
            }
        }
    }
}
