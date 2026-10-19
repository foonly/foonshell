import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
    id: root

    required property ShellScreen modelData

    screen: modelData
    color: "transparent"
    implicitHeight: Theme.barHeight
    WlrLayershell.namespace: "foonshell:bar"

    anchors {
        top: true
        left: true
        right: true
    }

    function componentFor(name: string): Component {
        switch (name) {
        case "workspaces":
            return workspacesComp;
        case "windowTitle":
            return windowTitleComp;
        case "clock":
            return clockComp;
        case "media":
            return mediaComp;
        case "tray":
            return trayComp;
        case "status":
            return statusComp;
        case "bluetooth":
            return bluetoothComp;
        case "network":
            return networkComp;
        case "audio":
            return audioComp;
        case "desk":
            return deskComp;
        case "battery":
            return batteryComp;
        default:
            console.warn("bar: unknown widget", name);
            return null;
        }
    }

    // Width available in a side row for elastic text items (windowTitle, media) before hitting center
    function availableElasticWidth(row: Row): real {
        let fixed = 0;
        for (let i = 0; i < row.children.length; i++) {
            const child = row.children[i];
            if (child && !child.elastic && child.visible && child.width > 0)
                fixed += child.width + row.spacing;
        }
        return Math.max(0, root.width / 2 - centerRow.width / 2 - fixed - Theme.gap * 3);
    }

    Component {
        id: workspacesComp
        Workspaces {
            screen: root.screen
        }
    }

    Component {
        id: windowTitleComp
        WindowTitle {
            property real availableWidth: 400
            screen: root.screen
            maxWidth: availableWidth
        }
    }

    Component {
        id: clockComp
        Clock {}
    }

    Component {
        id: mediaComp
        MediaTitle {
            property real availableWidth: 400
            maxWidth: availableWidth
        }
    }

    Component {
        id: trayComp
        Tray {
            bar: root
        }
    }

    Component {
        id: bluetoothComp
        Bluetooth {}
    }

    Component {
        id: networkComp
        Network {}
    }

    Component {
        id: audioComp
        Audio {}
    }

    Component {
        id: deskComp
        Desk {}
    }

    Component {
        id: batteryComp
        Battery {}
    }

    Component {
        id: statusComp
        Pill {
            readonly property bool shown: {
                for (let i = 0; i < statusRepeater.count; i++) {
                    const loader = statusRepeater.itemAt(i);
                    if (loader && loader.shown)
                        return true;
                }
                return false;
            }
            visible: shown

            Repeater {
                id: statusRepeater
                model: Config.barStatus

                Loader {
                    required property string modelData
                    readonly property bool shown: item ? (item.shown ?? true) : false
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: root.componentFor(modelData)
                    visible: shown
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.c.surface

        Row {
            id: leftRow
            anchors {
                left: parent.left
                leftMargin: Theme.gap
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.gap

            Repeater {
                model: Config.barLeft

                Loader {
                    required property string modelData
                    readonly property bool elastic: modelData === "windowTitle" || modelData === "media"
                    readonly property real elasticWidth: elastic ? root.availableElasticWidth(leftRow) : 0

                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: root.componentFor(modelData)
                    visible: item ? (item.shown ?? true) : false
                    onElasticWidthChanged: if (item && elastic)
                        item.availableWidth = elasticWidth
                    onLoaded: if (item && elastic)
                        item.availableWidth = elasticWidth
                }
            }
        }

        Row {
            id: centerRow
            anchors.centerIn: parent
            spacing: Theme.gap

            Repeater {
                model: Config.barCenter

                Loader {
                    required property string modelData
                    readonly property bool elastic: false

                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: root.componentFor(modelData)
                    visible: item ? (item.shown ?? true) : false
                }
            }
        }

        Row {
            id: rightRow
            anchors {
                right: parent.right
                rightMargin: Theme.gap
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.gap

            Repeater {
                model: Config.barRight

                Loader {
                    required property string modelData
                    readonly property bool elastic: modelData === "windowTitle" || modelData === "media"
                    readonly property real elasticWidth: elastic ? root.availableElasticWidth(rightRow) : 0

                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: root.componentFor(modelData)
                    visible: item ? (item.shown ?? true) : false
                    onElasticWidthChanged: if (item && elastic)
                        item.availableWidth = elasticWidth
                    onLoaded: if (item && elastic)
                        item.availableWidth = elasticWidth
                }
            }
        }
    }
}
