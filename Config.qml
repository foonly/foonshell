pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// User settings from ~/.config/foonshell/config.json.
// Every setting has a fallback so the config file is optional.
Singleton {
    id: root

    readonly property string configDir: `${Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"}/foonshell`
    readonly property string configPath: `${configDir}/config.json`

    property var data: ({})

    readonly property string font: data.font ?? "MonaspiceNe NFP"
    readonly property int fontSize: data.fontSize ?? 13
    readonly property int iconSize: data.iconSize ?? 15

    readonly property int barHeight: data.barHeight ?? 34
    readonly property int gap: data.gap ?? 6
    readonly property int radius: data.radius ?? 10
    readonly property int pillPadding: data.pillPadding ?? 10

    readonly property string dateFormat: data.clock?.dateFormat ?? "ddd d MMM"
    readonly property string timeFormat: data.clock?.timeFormat ?? "HH:mm"

    readonly property var barLeft: data.bar?.left ?? ["workspaces", "windowTitle"]
    readonly property var barCenter: data.bar?.center ?? ["clock"]
    readonly property var barRight: data.bar?.right ?? ["media", "tray", "status"]
    readonly property var barStatus: data.bar?.status ?? ["bluetooth", "network", "audio", "desk", "battery"]

    FileView {
        path: root.configPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.data = JSON.parse(text());
            } catch (e) {
                console.warn("config: unreadable config.json", e);
            }
        }
    }
}
