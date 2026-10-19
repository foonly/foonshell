pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// What kind of device each audio node is (speaker, headphones, ...). Quickshell only sees
// node properties, but the form factor and active port live on the PipeWire device, so they
// are read through `pactl` and refreshed whenever pulse reports a device change.
Singleton {
    id: root

    // node.name -> { port, formFactor, bus }
    property var info: ({})

    // "speaker", "headphones", "headset", "tv", "webcam" or "mic"
    function kind(node: PwNode): string {
        const i = info[node?.name] ?? {};
        const byPort = {
            speaker: "speaker",
            headphones: "headphones",
            headset: "headset",
            handset: "headset",
            earpiece: "headset",
            hdmi: "tv",
            tv: "tv"
        };
        const byFormFactor = {
            headphone: "headphones",
            headset: "headset",
            "hands-free": "headset",
            handset: "headset",
            speaker: "speaker",
            hifi: "speaker",
            portable: "speaker",
            tv: "tv",
            webcam: "webcam",
            microphone: "mic"
        };
        let k = byPort[i.port] ?? byFormFactor[i.formFactor] ?? (i.bus === "bluetooth" ? "headphones" : "");
        // Inputs are the microphone part of the device, so headphones with a mic are a headset
        if (!node?.isSink && k !== "webcam")
            k = k === "headphones" || k === "headset" ? "headset" : "mic";
        return k || "speaker";
    }

    function icon(node: PwNode): string {
        return {
            speaker: "󰓃",
            headphones: "󰋋",
            headset: "󰋎",
            tv: "󰔂",
            webcam: "󰖠",
            mic: "󰍬"
        }[kind(node)];
    }

    function refresh() {
        if (!list.running)
            list.running = true;
    }

    Component.onCompleted: refresh()

    // One JSON array per line: sinks, then sources
    Process {
        id: list
        command: ["sh", "-c", "pactl -f json list sinks; echo; pactl -f json list sources"]
        stdout: StdioCollector {
            onStreamFinished: {
                const info = {};
                for (const line of text.split("\n")) {
                    if (!line.trim())
                        continue;
                    try {
                        for (const d of JSON.parse(line)) {
                            const p = d.properties ?? {};
                            const port = (d.ports ?? []).find(port => port.name === d.active_port);
                            info[d.name] = {
                                port: (port?.type ?? "").toLowerCase(),
                                formFactor: p["device.form_factor"] ?? "",
                                bus: p["device.bus"] ?? ""
                            };
                        }
                    } catch (e) {
                        console.warn("audio: unreadable pactl output", e);
                    }
                }
                root.info = info;
            }
        }
    }

    // Port switches and jack plugs show up as card changes, new devices as new sinks/sources.
    // Plain sink changes are skipped since every volume step sends one (bluetooth volume
    // still changes the card, hence the debounce).
    Process {
        id: subscribe
        running: true
        command: ["pactl", "subscribe"]
        // Exits when PipeWire restarts
        onExited: resubscribe.start()
        stdout: SplitParser {
            onRead: line => {
                if (/on card|'(new|remove)' on (sink|source)/.test(line))
                    debounce.restart();
            }
        }
    }

    Timer {
        id: debounce
        interval: 300
        onTriggered: root.refresh()
    }

    Timer {
        id: resubscribe
        interval: 2000
        onTriggered: {
            subscribe.running = true;
            root.refresh();
        }
    }
}
