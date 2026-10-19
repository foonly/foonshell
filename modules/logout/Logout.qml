import QtQuick
import Quickshell
import Quickshell.Io
import qs

Scope {
    id: root

    property bool active: false
    property real animProgress: 0.0
    property int selectedIndex: -1
    property string hostname: Quickshell.env("HOSTNAME") || Quickshell.env("HOST") || ""

    Process {
        id: hostProc
        command: ["uname", "-n"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const h = text.trim();
                if (h !== "") {
                    root.hostname = h;
                }
            }
        }
    }

    Behavior on animProgress {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: closeTimer
        interval: 180
        repeat: false
        onTriggered: {
            if (root.animProgress === 0.0) {
                root.active = false;
            }
        }
    }

    function open() {
        closeTimer.stop();
        selectedIndex = -1;
        active = true;
        animProgress = 1.0;
    }

    function close() {
        animProgress = 0.0;
        closeTimer.restart();
    }

    function toggle() {
        if (active && animProgress > 0.1) {
            close();
        } else {
            open();
        }
    }

    function selectNext() {
        if (selectedIndex < 0) {
            selectedIndex = 0;
        } else {
            selectedIndex = (selectedIndex + 1) % actions.length;
        }
    }

    function selectPrevious() {
        if (selectedIndex < 0) {
            selectedIndex = actions.length - 1;
        } else {
            selectedIndex = (selectedIndex - 1 + actions.length) % actions.length;
        }
    }

    Process {
        id: proc
    }

    function triggerAction(action) {
        close();
        proc.command = action.command;
        proc.running = true;
    }

    function triggerActionById(id) {
        for (let i = 0; i < actions.length; i++) {
            if (actions[i].id === id) {
                triggerAction(actions[i]);
                return;
            }
        }
    }

    readonly property var actions: [
        {
            id: "lock",
            label: "Lock",
            icon: "󰌾",
            keyHint: "L",
            accentColor: Theme.c.primary,
            command: ["loginctl", "lock-session"]
        },
        {
            id: "logout",
            label: "Logout",
            icon: "󰍃",
            keyHint: "E",
            accentColor: Theme.c.secondary,
            command: ["loginctl", "terminate-user", Quickshell.env("USER") || ""]
        },
        {
            id: "suspend",
            label: "Suspend",
            icon: "󰒲",
            keyHint: "U",
            accentColor: Theme.c.tertiary,
            command: ["systemctl", "suspend"]
        },
        {
            id: "reboot",
            label: "Reboot",
            icon: "󰜉",
            keyHint: "R",
            accentColor: Theme.c.primary,
            command: ["systemctl", "reboot"]
        },
        {
            id: "shutdown",
            label: "Shutdown",
            icon: "󰐥",
            keyHint: "S",
            accentColor: Theme.c.error,
            command: ["systemctl", "poweroff"]
        }
    ]

    // IPC handler for target "logout" (e.g. `qs ipc -c foonshell call logout toggle`)
    IpcHandler {
        target: "logout"

        function toggle() {
            root.toggle();
        }

        function open() {
            root.open();
        }

        function close() {
            root.close();
        }

        function lock() {
            root.triggerActionById("lock");
        }

        function logout() {
            root.triggerActionById("logout");
        }

        function suspend() {
            root.triggerActionById("suspend");
        }

        function reboot() {
            root.triggerActionById("reboot");
        }

        function shutdown() {
            root.triggerActionById("shutdown");
        }
    }

    // Secondary IPC handler for target "power" (e.g. `qs ipc -c foonshell call power toggle`)
    IpcHandler {
        target: "power"

        function toggle() {
            root.toggle();
        }

        function open() {
            root.open();
        }

        function close() {
            root.close();
        }
    }

    Variants {
        model: Quickshell.screens

        LogoutWindow {
            manager: root
        }
    }
}
