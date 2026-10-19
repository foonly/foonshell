pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Events from the iCal feeds in calendars.json, fetched by scripts/calendar-sync.py
// into a cache file so they're there right away after a restart or while offline.
Singleton {
    id: root

    readonly property string configPath: `${Config.configDir}/calendars.json`
    readonly property string cachePath: `${Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache"}/foonshell/events.json`

    property var data: ({})
    readonly property var events: data.events ?? []
    readonly property bool configured: data.configured ?? false
    readonly property var errors: data.errors ?? []
    readonly property bool syncing: sync.running

    // Events grouped by day ("2026-10-14"), multi day events listed on every day they cover
    readonly property var byDay: {
        const days = {};
        for (const event of events) {
            const start = new Date(event.start.length === 10 ? event.start + "T00:00" : event.start);
            const end = new Date(event.end.length === 10 ? event.end + "T00:00" : event.end);
            // End is exclusive: an all day event ending on the 15th, or a timed one ending
            // at midnight, doesn't show on the 15th
            const last = end > start ? new Date(end - 1) : start;
            for (const d = new Date(start.getFullYear(), start.getMonth(), start.getDate()); d <= last; d.setDate(d.getDate() + 1)) {
                const key = dayKey(d);
                if (!days[key])
                    days[key] = [];
                days[key].push(event);
            }
        }
        return days;
    }

    function dayKey(d: date): string {
        return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
    }

    function eventsOn(d: date): var {
        return byDay[dayKey(d)] ?? [];
    }

    function refresh() {
        if (!sync.running)
            sync.running = true;
    }

    // Sync when the popup opens unless the cache is fresh
    function refreshIfStale() {
        const updated = data.updated ? new Date(data.updated) : null;
        if (!updated || Date.now() - updated > 5 * 60 * 1000)
            refresh();
    }

    // Not watched: the sync replaces the file, which a watch on the old one never sees.
    // Reloaded when a sync finishes instead.
    FileView {
        id: cache
        path: root.cachePath
        printErrors: false
        onLoaded: {
            try {
                root.data = JSON.parse(text());
            } catch (e) {
                console.warn("calendar: unreadable cache", e);
            }
        }
    }

    // Resync right away when the calendar list changes
    FileView {
        path: root.configPath
        watchChanges: true
        onFileChanged: root.refresh()
        printErrors: false
    }

    Process {
        id: sync
        command: ["python3", Quickshell.shellPath("scripts/calendar-sync.py"), root.configPath, root.cachePath]
        onExited: cache.reload()
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "")
                console.warn("calendar-sync:", text.trim())
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
