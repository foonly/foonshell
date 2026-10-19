import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs

// Cover art, artist and title of the playing media, hidden while nothing plays.
// Left click: now playing card with controls.
MouseArea {
    id: root

    property real maxWidth: 400
    readonly property MprisPlayer playing: Mpris.players.values.find(p => p.isPlaying) ?? null
    // Kept after pausing so the card doesn't lose its player
    property MprisPlayer player
    readonly property bool hasArt: art.status === Image.Ready

    readonly property bool shown: (playing !== null || popup.visible) && player !== null

    onPlayingChanged: if (playing)
        player = playing
    Component.onCompleted: player = playing

    visible: shown
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()

    Row {
        id: row
        spacing: 6

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20

            ClippingRectangle {
                anchors.fill: parent
                radius: 4
                color: "transparent"
                visible: root.hasArt

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    sourceSize: Qt.size(40, 40)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            // No art from the player, or it hasn't loaded
            Text {
                anchors.centerIn: parent
                visible: !root.hasArt
                text: "󰝚"
                font.family: Theme.font
                font.pixelSize: Theme.iconSize
                color: Theme.c.primary
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.maxWidth - 20 - row.spacing)
            text: root.player ? [root.player.trackArtist, root.player.trackTitle].filter(s => s).join(" – ") : ""
            elide: Text.ElideRight
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            color: Theme.c.on_surface_variant
        }
    }

    MediaPopup {
        id: popup
        anchor.item: root
        player: root.player
    }
}
