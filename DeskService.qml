pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Standing desk state from the `desk` CLI, shared by every bar so that only one
// bluetooth connection to the desk is open at a time.
Singleton {
    id: root

    // [{ name, height, raw }] from `desk list`
    property var positions: []
    property string height
    property int raw: -1
    // The last status call reached the desk
    property bool found
    readonly property bool moving: move.running || pending !== ""
    // Position to move to once the status call in flight has finished
    property string pending
    readonly property bool available: found && positions.length > 0

    // `desk` prints "116.0 cm (raw 2318)", or "raw 2318" before calibration
    function parse(text: string): var {
        const cm = text.match(/([\d.]+) cm/);
        const raw = text.match(/raw (\d+)/);
        return {
            height: cm ? `${Math.round(parseFloat(cm[1]))} cm` : raw ? `raw ${raw[1]}` : "",
            raw: raw ? parseInt(raw[1]) : -1
        };
    }

    function refresh() {
        if (!moving)
            status.running = true;
    }

    // Only one bluetooth connection at a time, so wait for a status call instead of killing it
    function goTo(name: string) {
        if (moving)
            return;
        pending = name;
        if (!status.running)
            startMove();
    }

    function startMove() {
        move.command = ["desk", pending];
        pending = "";
        move.running = true;
    }

    function stop() {
        pending = "";
        if (move.running)
            move.signal(15);
    }

    // The list only reads the config file, so it is cheap to rerun whenever that changes
    Process {
        id: list
        command: ["desk", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.positions = text.split("\n").filter(l => l.trim() !== "").map(l => {
                const name = l.trim().split(/\s+/)[0];
                return Object.assign({ name }, root.parse(l));
            })
        }
        onExited: code => {
            if (code !== 0)
                root.positions = [];
        }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/desk/config.json"
        watchChanges: true
        onFileChanged: list.running = true
    }

    // Each status call opens a bluetooth connection (a few seconds), so poll slowly
    Process {
        id: status
        command: ["desk", "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = root.parse(text);
                if (p.raw >= 0) {
                    root.height = p.height;
                    root.raw = p.raw;
                }
            }
        }
        onExited: code => {
            root.found = code === 0;
            if (root.pending !== "")
                root.startMove();
        }
    }

    Timer {
        interval: 60000
        running: root.positions.length > 0
        repeat: true
        onTriggered: root.refresh()
    }

    // Prints the live position while moving, each update ending in a carriage return
    Process {
        id: move
        stdout: SplitParser {
            splitMarker: "\r"
            onRead: data => {
                const p = root.parse(data);
                if (p.raw >= 0) {
                    root.height = p.height;
                    root.raw = p.raw;
                    root.found = true;
                }
            }
        }
    }
}
