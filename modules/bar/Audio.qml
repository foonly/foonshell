import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

// Left click: device picker. Right click: mute. Scroll: volume. Hover: output and input.
BarIcon {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? true

    // Node properties are only populated while the node is tracked
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    function isMuted(node: PwNode): bool {
        return node?.audio?.muted ?? true;
    }

    function nodeName(node: PwNode): string {
        return node?.description || node?.nickname || "None";
    }

    function levelText(node: PwNode): string {
        return isMuted(node) ? "Muted" : `${Math.round((node?.audio?.volume ?? 0) * 100)}%`;
    }

    // Speakers show the volume level, other devices (headphones, ...) their own icon
    icon: muted ? "󰝟" : AudioService.kind(sink) !== "speaker" ? AudioService.icon(sink) : volume < 0.34 ? "󰕿" : volume < 0.67 ? "󰖀" : "󰕾"
    label: `${Math.round(volume * 100)}%`
    dimmed: muted
    hoverEnabled: true

    onLeftClicked: popup.toggle()
    onRightClicked: if (sink?.audio) sink.audio.muted = !sink.audio.muted
    onScrolled: delta => {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(1, volume + (delta > 0 ? 0.02 : -0.02)));
    }

    AudioPopup {
        id: popup
        anchor.item: root
    }

    BarTooltip {
        anchor.item: root
        shown: root.containsMouse && !popup.visible

        Grid {
            columns: 3
            columnSpacing: 8
            rowSpacing: 4
            verticalItemAlignment: Grid.AlignVCenter

            Text {
                text: root.isMuted(root.sink) ? "󰝟" : AudioService.icon(root.sink)
                font.family: Theme.font
                font.pixelSize: Theme.iconSize
                color: root.isMuted(root.sink) ? Theme.c.outline : Theme.c.primary
            }

            Text {
                text: root.nodeName(root.sink)
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Theme.c.on_surface
            }

            Text {
                text: root.levelText(root.sink)
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Theme.c.outline
            }

            Text {
                text: root.isMuted(root.source) ? "󰍭" : AudioService.icon(root.source)
                font.family: Theme.font
                font.pixelSize: Theme.iconSize
                color: root.isMuted(root.source) ? Theme.c.outline : Theme.c.primary
            }

            Text {
                text: root.nodeName(root.source)
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Theme.c.on_surface
            }

            Text {
                text: root.levelText(root.source)
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Theme.c.outline
            }
        }
    }
}
