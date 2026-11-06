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
    // Generated files such as colors.json go here, not into the config dir
    readonly property string stateDir: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/foonshell`

    property var data: ({})

    readonly property string font: data.font ?? "MonaspiceNe NFP"
    readonly property int fontSize: data.fontSize ?? 13
    readonly property int iconSize: data.iconSize ?? 15
    // For the clock and workspace numbers; the body font if unset
    readonly property string displayFont: data.displayFont ?? font
    readonly property int displayFontSize: data.displayFontSize ?? fontSize

    readonly property int barHeight: data.barHeight ?? 34
    readonly property int gap: data.gap ?? 6
    readonly property int radius: data.radius ?? 10
    readonly property int pillPadding: data.pillPadding ?? 10
    // Pills and popups as thin outlines on the bar color instead of filled boxes
    readonly property bool outlined: data.outlined ?? false
    // App and tray icons in a single theme color instead of their own
    readonly property bool iconTint: data.iconTint ?? false
    // Text on the bar in the primary color instead of the neutral text colors
    readonly property bool accentText: data.accentText ?? false

    readonly property string dateFormat: data.clock?.dateFormat ?? "ddd d MMM"
    readonly property string timeFormat: data.clock?.timeFormat ?? "HH:mm"

    readonly property var barLeft: data.bar?.left ?? ["workspaces", "windowTitle"]
    readonly property var barCenter: data.bar?.center ?? ["clock"]
    readonly property var barRight: data.bar?.right ?? ["media", "tray", "status", "notifications"]
    readonly property var barStatus: data.bar?.status ?? ["bluetooth", "network", "audio", "desk", "battery"]

    // Where the battery stops charging unless a full charge is unlocked from the bar
    readonly property int chargeLimit: data.battery?.chargeLimit ?? 80

    // Non-persistent notifications kept in the notification center before the
    // lowest-priority, oldest ones are pushed off
    readonly property int notificationHistory: data.notifications?.history ?? 30

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
