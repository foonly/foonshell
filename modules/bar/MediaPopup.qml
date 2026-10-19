import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs

// Now playing card: cover art, track info, progress and playback controls
BarPopup {
    id: root

    property MprisPlayer player
    readonly property bool hasArt: art.status === Image.Ready

    implicitWidth: 340

    function time(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        const h = Math.floor(s / 3600);
        const m = Math.floor(s / 60) % 60;
        const pad = n => String(n).padStart(2, "0");
        return h > 0 ? `${h}:${pad(m)}:${pad(s % 60)}` : `${m}:${pad(s % 60)}`;
    }

    // Position isn't pushed by players, so poll it while it can change and be seen
    Timer {
        running: root.visible && (root.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player?.positionChanged()
    }

    component ControlButton: MouseArea {
        id: button

        property string icon
        property int size: 32

        implicitWidth: size
        implicitHeight: size
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: button.containsMouse && button.enabled ? Theme.c.surface_container_highest : "transparent"
        }

        Text {
            anchors.centerIn: parent
            text: button.icon
            font.family: Theme.font
            font.pixelSize: button.size * 0.6
            color: button.enabled ? Theme.c.on_surface : Theme.c.outline
        }
    }

    Row {
        width: parent.width
        spacing: 12

        Item {
            width: 120
            height: 120

            ClippingRectangle {
                anchors.fill: parent
                radius: Theme.radius - 4
                color: "transparent"
                visible: root.hasArt

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    sourceSize: Qt.size(240, 240)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius - 4
                visible: !root.hasArt
                color: Theme.c.surface_container_highest

                Text {
                    anchors.centerIn: parent
                    text: "󰝚"
                    font.family: Theme.font
                    font.pixelSize: 48
                    color: Theme.c.primary
                }
            }
        }

        Column {
            width: parent.width - 120 - parent.spacing
            height: 120
            spacing: 4

            Text {
                width: parent.width
                text: root.player?.trackTitle || "Unknown title"
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1
                font.bold: true
                color: Theme.c.on_surface
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.player?.trackArtist ?? ""
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Theme.c.on_surface_variant
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.player?.trackAlbum ?? ""
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Theme.c.outline
            }

            Text {
                width: parent.width
                text: root.player?.identity ?? ""
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
                color: Theme.c.outline
            }
        }
    }

    // Progress, click to seek
    Column {
        width: parent.width
        spacing: 2
        visible: (root.player?.lengthSupported ?? false) && root.player.length > 0

        MouseArea {
            id: seek
            width: parent.width
            height: 12
            enabled: root.player?.canSeek ?? false
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: event => root.player.position = root.player.length * event.x / width

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Theme.c.surface_container_highest

                Rectangle {
                    width: parent.width * Math.min(1, (root.player?.position ?? 0) / (root.player?.length || 1))
                    height: parent.height
                    radius: 2
                    color: Theme.c.primary
                }
            }
        }

        Item {
            width: parent.width
            height: position.implicitHeight

            Text {
                id: position
                text: root.time(root.player?.position ?? 0)
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
                color: Theme.c.outline
            }

            Text {
                anchors.right: parent.right
                text: root.time(root.player?.length ?? 0)
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
                color: Theme.c.outline
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        ControlButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "󰒮"
            enabled: root.player?.canGoPrevious ?? false
            onClicked: root.player.previous()
        }

        ControlButton {
            anchors.verticalCenter: parent.verticalCenter
            size: 40
            icon: root.player?.isPlaying ? "󰏤" : "󰐊"
            enabled: root.player?.canTogglePlaying ?? false
            onClicked: root.player.togglePlaying()
        }

        ControlButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "󰒭"
            enabled: root.player?.canGoNext ?? false
            onClicked: root.player.next()
        }
    }
}
