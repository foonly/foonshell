import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs

Scope {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real sinkVolume: (sink && sink.audio) ? sink.audio.volume : 0
    readonly property bool sinkMuted: (sink && sink.audio) ? sink.audio.muted : false
    readonly property real sourceVolume: (source && source.audio) ? source.audio.volume : 0
    readonly property bool sourceMuted: (source && source.audio) ? source.audio.muted : false

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    property bool initialized: false
    property real lastSinkVolume: -1
    property bool lastSinkMuted: false
    property string lastSinkName: ""

    property real lastSourceVolume: -1
    property bool lastSourceMuted: false
    property string lastSourceName: ""

    property bool shown: false
    property bool isInput: false
    property string eventType: "volume" // "volume", "mute", "device"

    readonly property PwNode currentNode: isInput ? source : sink
    readonly property real currentVolume: isInput ? sourceVolume : sinkVolume
    readonly property bool isCurrentMuted: isInput ? sourceMuted : sinkMuted
    readonly property color accentColor: isInput ? Theme.c.secondary : Theme.c.primary

    readonly property string headerTitle: {
        if (eventType === "device")
            return isInput ? "Default Input" : "Default Output";
        return isInput ? "Microphone" : "Volume";
    }

    readonly property string deviceName: {
        const n = currentNode;
        if (n && (n.description || n.nickname))
            return n.description || n.nickname;
        return isInput ? "Input Device" : "Output Device";
    }

    readonly property string currentIcon: {
        if (isInput) {
            return isCurrentMuted ? "󰍭" : AudioService.icon(source) || "󰍬";
        }
        if (isCurrentMuted)
            return "󰝟";
        if (AudioService.kind(sink) !== "speaker")
            return AudioService.icon(sink);
        if (currentVolume < 0.34)
            return "󰕿";
        if (currentVolume < 0.67)
            return "󰖀";
        return "󰕾";
    }

    Timer {
        id: hideTimer
        interval: 1600
        repeat: false
        onTriggered: root.shown = false
    }

    Timer {
        id: initTimer
        interval: 1000
        running: true
        repeat: false
        onTriggered: {
            root.lastSinkVolume = root.sinkVolume;
            root.lastSinkMuted = root.sinkMuted;
            root.lastSinkName = (root.sink && (root.sink.description || root.sink.nickname || root.sink.name)) ? (root.sink.description || root.sink.nickname || root.sink.name) : "";

            root.lastSourceVolume = root.sourceVolume;
            root.lastSourceMuted = root.sourceMuted;
            root.lastSourceName = (root.source && (root.source.description || root.source.nickname || root.source.name)) ? (root.source.description || root.source.nickname || root.source.name) : "";

            root.initialized = true;
        }
    }

    function trigger(input: bool, type: string) {
        if (!initialized)
            return;
        isInput = input;
        eventType = type;
        shown = true;
        hideTimer.restart();
    }

    function checkSinkChange(type: string) {
        if (!initialized)
            return;

        const currentName = (sink && (sink.description || sink.nickname || sink.name)) ? (sink.description || sink.nickname || sink.name) : "";
        const currentVol = sinkVolume;
        const currentMute = sinkMuted;

        if (type === "device") {
            if (currentName !== lastSinkName) {
                lastSinkName = currentName;
                lastSinkVolume = currentVol;
                lastSinkMuted = currentMute;
                trigger(false, "device");
                return;
            }
        }

        if (type === "mute" || currentMute !== lastSinkMuted) {
            lastSinkMuted = currentMute;
            lastSinkVolume = currentVol;
            trigger(false, "mute");
            return;
        }

        if (Math.abs(currentVol - lastSinkVolume) >= 0.005) {
            lastSinkVolume = currentVol;
            trigger(false, "volume");
        }
    }

    function checkSourceChange(type: string) {
        if (!initialized)
            return;

        const currentName = (source && (source.description || source.nickname || source.name)) ? (source.description || source.nickname || source.name) : "";
        const currentVol = sourceVolume;
        const currentMute = sourceMuted;

        if (type === "device") {
            if (currentName !== lastSourceName) {
                lastSourceName = currentName;
                lastSourceVolume = currentVol;
                lastSourceMuted = currentMute;
                trigger(true, "device");
                return;
            }
        }

        if (type === "mute" || currentMute !== lastSourceMuted) {
            lastSourceMuted = currentMute;
            lastSourceVolume = currentVol;
            trigger(true, "mute");
            return;
        }

        if (Math.abs(currentVol - lastSourceVolume) >= 0.005) {
            lastSourceVolume = currentVol;
            trigger(true, "volume");
        }
    }

    Connections {
        target: (root.sink && root.sink.audio) ? root.sink.audio : null
        function onVolumesChanged() {
            root.checkSinkChange("volume");
        }
        function onMutedChanged() {
            root.checkSinkChange("mute");
        }
    }

    Connections {
        target: (root.source && root.source.audio) ? root.source.audio : null
        function onVolumesChanged() {
            root.checkSourceChange("volume");
        }
        function onMutedChanged() {
            root.checkSourceChange("mute");
        }
    }

    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() {
            root.checkSinkChange("device");
        }
        function onDefaultAudioSourceChanged() {
            root.checkSourceChange("device");
        }
    }

    IpcHandler {
        target: "volume"

        function show() {
            root.trigger(false, "volume");
        }

        function showInput() {
            root.trigger(true, "volume");
        }

        function increase() {
            if (root.sink && root.sink.audio) {
                root.sink.audio.volume = Math.min(1.5, root.sinkVolume + 0.05);
            }
        }

        function decrease() {
            if (root.sink && root.sink.audio) {
                root.sink.audio.volume = Math.max(0, root.sinkVolume - 0.05);
            }
        }

        function toggleMute() {
            if (root.sink && root.sink.audio) {
                root.sink.audio.muted = !root.sink.audio.muted;
            }
        }

        function toggleMicMute() {
            if (root.source && root.source.audio) {
                root.source.audio.muted = !root.source.audio.muted;
            }
        }
    }

    PanelWindow {
        id: osdWindow

        screen: {
            const mon = Hyprland.focusedMonitor;
            if (mon && mon.name) {
                const s = Quickshell.screens.find(scr => scr.name === mon.name);
                if (s)
                    return s;
            }
            return Quickshell.screens[0];
        }

        color: "transparent"
        visible: root.shown || card.opacity > 0.01

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "foonshell:osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}

        anchors {
            bottom: true
        }

        margins {
            bottom: Math.round(screen.height * 0.28)
        }

        implicitWidth: 320
        implicitHeight: card.implicitHeight

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            implicitHeight: column.implicitHeight + 24
            radius: 18
            color: Qt.rgba(Theme.c.surface_container.r, Theme.c.surface_container.g, Theme.c.surface_container.b, 0.85)
            border.width: 1.5
            border.color: root.isCurrentMuted ? Theme.c.outline_variant : root.accentColor

            opacity: root.shown ? 1.0 : 0.0
            scale: root.shown ? 1.0 : 0.88

            Behavior on opacity {
                id: hideAnim
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: 150
                }
            }

            Column {
                id: column
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 14
                }
                spacing: 10

                Row {
                    width: parent.width
                    spacing: 12

                    Text {
                        text: root.currentIcon
                        font.family: Theme.font
                        font.pixelSize: 24
                        color: root.isCurrentMuted ? Theme.c.outline : root.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        width: parent.width - 24 - 12 - percentText.implicitWidth - 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            text: root.headerTitle
                            font.family: Theme.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.isCurrentMuted ? Theme.c.outline : root.accentColor
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: root.deviceName
                            font.family: Theme.font
                            font.pixelSize: 13
                            color: Theme.c.on_surface
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        id: percentText
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.isCurrentMuted ? "Muted" : `${Math.round(root.currentVolume * 100)}%`
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.bold: true
                        color: root.isCurrentMuted ? Theme.c.outline : Theme.c.on_surface
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Theme.c.surface_container_highest

                    Rectangle {
                        height: parent.height
                        radius: 3
                        width: parent.width * Math.min(1.0, Math.max(0.0, root.isCurrentMuted ? 0 : root.currentVolume))
                        color: root.isCurrentMuted ? Theme.c.outline : root.currentVolume > 1.0 ? Theme.c.error : root.accentColor

                        Behavior on width {
                            NumberAnimation {
                                duration: 80
                                easing.type: Easing.OutQuad
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }
                }
            }
        }
    }
}
