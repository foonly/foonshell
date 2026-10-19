import QtQuick
import Quickshell
import Quickshell.Networking
import qs

// Left click: network popup. Right click: nmtui. Hover: connection details.
BarIcon {
    id: root

    readonly property var device: {
        const devices = Networking.devices.values.filter(d => d.connected);
        return devices.find(d => d.type === DeviceType.Wired) ?? devices.find(d => d.type === DeviceType.Wifi) ?? null;
    }
    readonly property var wifi: device?.type === DeviceType.Wifi
        ? device.networks.values.find(n => n.connected) ?? null
        : null

    icon: {
        if (!device)
            return Networking.wifiEnabled ? "󰤮" : "󰖪";
        if (device.type === DeviceType.Wired)
            return Networking.connectivity === NetworkConnectivity.Full ? "󰈀" : "󰈂";
        const strength = wifi?.signalStrength ?? 0;
        return ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][Math.min(4, Math.floor(strength * 5))];
    }
    dimmed: !device
    hoverEnabled: true

    readonly property string connectivityText: {
        switch (Networking.connectivity) {
        case NetworkConnectivity.Portal:
            return "Sign-in required";
        case NetworkConnectivity.Limited:
            return "Limited connectivity";
        case NetworkConnectivity.None:
            return "No internet";
        default:
            return "";
        }
    }

    onLeftClicked: popup.toggle()
    onRightClicked: Quickshell.execDetached(["uwsm", "app", "--", "alacritty", "-e", "nmtui"])

    NetworkPopup {
        id: popup
        anchor.item: root
    }

    BarTooltip {
        anchor.item: root
        shown: root.containsMouse && !popup.visible

        Row {
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.icon
                font.family: Theme.font
                font.pixelSize: Theme.iconSize
                color: root.device ? Theme.c.primary : Theme.c.outline
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: !root.device ? (Networking.wifiEnabled ? "Not connected" : "Wi-Fi off")
                    : root.device.type === DeviceType.Wired ? "Ethernet"
                    : root.wifi?.name ?? "Wi-Fi"
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: root.device ? Theme.c.on_surface : Theme.c.outline
            }

            Text {
                visible: text !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: root.device?.type === DeviceType.Wired
                    ? (root.device.linkSpeed > 0 ? `${root.device.linkSpeed} Mb/s` : "")
                    : root.wifi ? `${Math.round(root.wifi.signalStrength * 100)}%` : ""
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Theme.c.outline
            }
        }

        // Only worth mentioning when something's off
        Text {
            visible: root.device !== null && root.connectivityText !== ""
            text: root.connectivityText
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            color: Theme.c.error
        }
    }
}
