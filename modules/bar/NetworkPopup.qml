import QtQuick
import Quickshell
import Quickshell.Networking
import qs

// Wifi network list shown under the network indicator. Scans while open.
BarPopup {
    id: root

    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property bool enabled: Networking.wifiEnabled

    // Network waiting for a password typed into its row
    property var passwordFor
    // Last failure, shown on the row of the network it belongs to
    property var failedNetwork
    property string failedReason

    readonly property var visibleNetworks: (wifiDevice?.networks.values ?? []).filter(n => n.name !== "")
    // Connected first, then saved, then by signal strength
    readonly property var sortedNetworks: visibleNetworks.slice()
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))
    // Order snapshot taken while a password prompt is open, so its row doesn't move
    property var frozenOrder: null
    readonly property var networks: {
        const order = frozenOrder;
        if (!order)
            return sortedNetworks;
        // Networks that appeared after the snapshot go at the end
        const rank = n => {
            const i = order.indexOf(n);
            return i < 0 ? order.length : i;
        };
        return visibleNetworks.slice().sort((a, b) => rank(a) - rank(b));
    }

    onPasswordForChanged: frozenOrder = passwordFor ? sortedNetworks : null

    onVisibleChanged: {
        if (wifiDevice)
            wifiDevice.scannerEnabled = visible && enabled;
        if (!visible) {
            passwordFor = null;
            failedNetwork = null;
        }
    }

    function signalIcon(strength: real): string {
        return ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][Math.min(4, Math.floor(strength * 5))];
    }

    function secured(network): bool {
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe;
    }

    function activate(network) {
        failedNetwork = null;
        if (network.connected) {
            network.disconnect();
        } else if (network.known || !secured(network)) {
            passwordFor = null;
            network.connect();
        } else {
            passwordFor = passwordFor === network ? null : network;
        }
    }

    function submitPassword(network, psk: string) {
        if (psk === "")
            return;
        passwordFor = null;
        failedNetwork = null;
        network.connectWithPsk(psk);
    }

    function failText(reason): string {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
        case ConnectionFailReason.WifiAuthTimeout:
            return "Wrong password?";
        case ConnectionFailReason.WifiNetworkLost:
            return "Network lost";
        default:
            return "Couldn't connect";
        }
    }

    Item {
        width: parent.width
        implicitHeight: toggle.implicitHeight

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.wifiDevice?.scannerEnabled ? "Wi-Fi · scanning…" : "Wi-Fi"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.bold: true
            color: Theme.c.on_surface
        }

        // Radio switch
        Rectangle {
            id: toggle
            anchors.right: parent.right
            implicitWidth: 36
            implicitHeight: 20
            radius: height / 2
            color: root.enabled ? Theme.c.primary : Theme.c.surface_container_highest
            opacity: Networking.wifiHardwareEnabled ? 1 : 0.4

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
                enabled: Networking.wifiHardwareEnabled
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Networking.wifiEnabled = !root.enabled;
                    if (root.wifiDevice)
                        root.wifiDevice.scannerEnabled = Networking.wifiEnabled;
                }
            }
        }
    }

    // Ethernet, only when a cable is plugged in
    MouseArea {
        id: wired

        readonly property var network: root.wiredDevice?.network ?? null

        visible: root.wiredDevice?.hasLink ?? false
        width: parent.width
        implicitHeight: 36
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: network?.connected ? network.disconnect() : network?.connect()

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius - 4
            color: wired.containsMouse ? Theme.c.surface_container_highest : "transparent"
        }

        Text {
            id: wiredIcon
            anchors {
                left: parent.left
                leftMargin: 8
                verticalCenter: parent.verticalCenter
            }
            text: "󰈀"
            font.family: Theme.font
            font.pixelSize: Theme.iconSize
            color: wired.network?.connected ? Theme.c.primary : Theme.c.on_surface_variant
        }

        Column {
            anchors {
                left: wiredIcon.right
                leftMargin: 10
                right: parent.right
                rightMargin: 8
                verticalCenter: parent.verticalCenter
            }

            Text {
                text: "Ethernet"
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Theme.c.on_surface
            }

            Text {
                text: {
                    if (wired.network?.stateChanging)
                        return wired.network.state === ConnectionState.Disconnecting ? "Disconnecting…" : "Connecting…";
                    if (wired.network?.connected)
                        return root.wiredDevice.linkSpeed > 0 ? `Connected · ${root.wiredDevice.linkSpeed} Mb/s` : "Connected";
                    return "Click to connect";
                }
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
                color: wired.network?.stateChanging ? Theme.c.secondary : Theme.c.outline
            }
        }
    }

    Text {
        visible: !root.enabled || root.networks.length === 0
        text: !root.wifiDevice ? "No wifi adapter found"
            : !Networking.wifiHardwareEnabled ? "Blocked by hardware switch"
            : !root.enabled ? "Turned off"
            : "No networks found"
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        color: Theme.c.outline
    }

    ListView {
        visible: root.enabled
        width: parent.width
        implicitHeight: Math.min(contentHeight, 360)
        clip: true
        spacing: 2
        // ScriptModel diffs updates instead of resetting, so delegates (and the
        // password being typed) survive the frequent signal strength refreshes
        model: ScriptModel {
            values: root.enabled ? root.networks : []
        }

        delegate: Column {
            id: row

            required property var modelData
            readonly property bool asking: root.passwordFor === modelData
            readonly property bool failed: root.failedNetwork === modelData

            width: ListView.view.width
            spacing: 4

            Connections {
                target: row.modelData

                function onConnectionFailed(reason) {
                    root.failedNetwork = row.modelData;
                    root.failedReason = reason;
                    // Saved password no longer works: ask for a new one
                    if (reason === ConnectionFailReason.NoSecrets && root.secured(row.modelData))
                        root.passwordFor = row.modelData;
                }
            }

            MouseArea {
                id: item
                width: parent.width
                implicitHeight: 36
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activate(row.modelData)

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius - 4
                    color: item.containsMouse || row.asking ? Theme.c.surface_container_highest : "transparent"
                }

                Text {
                    id: icon
                    anchors {
                        left: parent.left
                        leftMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.signalIcon(row.modelData.signalStrength)
                    font.family: Theme.font
                    font.pixelSize: Theme.iconSize
                    color: row.modelData.connected ? Theme.c.primary : Theme.c.on_surface_variant
                }

                Column {
                    anchors {
                        left: icon.right
                        leftMargin: 10
                        right: actions.left
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
                            const n = row.modelData;
                            if (n.stateChanging)
                                return n.state === ConnectionState.Disconnecting ? "Disconnecting…" : "Connecting…";
                            if (row.failed)
                                return root.failText(root.failedReason);
                            if (n.connected)
                                return "Connected";
                            return n.known ? "Saved" : "";
                        }
                        visible: status !== ""
                        text: status
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 2
                        color: row.failed ? Theme.c.error
                            : row.modelData.stateChanging ? Theme.c.secondary
                            : Theme.c.outline
                    }
                }

                Row {
                    id: actions
                    anchors {
                        right: parent.right
                        rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 8

                    // Forget a saved network
                    MouseArea {
                        id: forget
                        visible: row.modelData.known && item.containsMouse
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

                    Text {
                        visible: root.secured(row.modelData)
                        text: "󰌾"
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        color: Theme.c.outline
                    }
                }
            }

            // Password prompt for a secured network we don't know yet
            Rectangle {
                visible: row.asking
                width: parent.width
                implicitHeight: 32
                radius: Theme.radius - 4
                color: Theme.c.surface_container_high
                border.color: password.activeFocus ? Theme.c.primary : Theme.c.outline_variant

                TextInput {
                    id: password
                    anchors {
                        left: parent.left
                        right: show.left
                        leftMargin: 10
                        rightMargin: 6
                        verticalCenter: parent.verticalCenter
                    }
                    echoMode: show.revealed ? TextInput.Normal : TextInput.Password
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    color: Theme.c.on_surface
                    selectionColor: Theme.c.primary
                    selectedTextColor: Theme.c.on_primary
                    clip: true

                    onVisibleChanged: {
                        text = "";
                        if (visible)
                            forceActiveFocus();
                    }
                    onAccepted: root.submitPassword(row.modelData, text)
                    Keys.onEscapePressed: root.passwordFor = null

                    Text {
                        visible: password.text === ""
                        text: "Password"
                        font: password.font
                        color: Theme.c.outline
                    }
                }

                // Toggle password visibility
                MouseArea {
                    id: show

                    property bool revealed

                    anchors {
                        right: parent.right
                        rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    implicitWidth: showIcon.implicitWidth
                    implicitHeight: showIcon.implicitHeight
                    cursorShape: Qt.PointingHandCursor
                    onClicked: revealed = !revealed

                    Text {
                        id: showIcon
                        text: show.revealed ? "󰈉" : "󰈈"
                        font.family: Theme.font
                        font.pixelSize: Theme.iconSize
                        color: Theme.c.outline
                    }
                }
            }
        }
    }
}
