pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon state shared by the popups and the notification center.
// Every notification stays tracked after its popup times out, so it lives on in the
// center (with working actions) until it is dismissed or pushed off the history.
Singleton {
    id: root

    // How many non-persistent notifications the center keeps. Beyond that the
    // lowest-priority, oldest ones are dropped first.
    readonly property int historyLimit: Config.notificationHistory

    readonly property var all: server.trackedNotifications.values

    // Ids shown as popups right now
    property var popupIds: []
    // id -> arrival time in ms, for ordering and the timestamp on each card
    property var arrived: ({})
    // Notifications that came in since the center was last opened
    property int unread: 0
    property bool centerOpen: false

    readonly property var popups: all.filter(n => popupIds.includes(n.id))
    // Persistent first, then by urgency, newest first within each tier
    readonly property var history: all.slice().sort((a, b) => rank(b) - rank(a) || arrivedAt(b) - arrivedAt(a))
    readonly property bool hasCritical: all.some(n => n.urgency === NotificationUrgency.Critical)

    // Critical notifications and those the app asked to keep (no expiry, or resident)
    function isPersistent(n: Notification): bool {
        return n.urgency === NotificationUrgency.Critical || n.expireTimeout === 0 || n.resident;
    }

    function rank(n: Notification): int {
        if (n.urgency === NotificationUrgency.Critical)
            return 4;
        if (isPersistent(n))
            return 3;
        return n.urgency === NotificationUrgency.Low ? 0 : 1;
    }

    function arrivedAt(n: Notification): real {
        return arrived[n.id] ?? 0;
    }

    // Popup timed out: the notification moves to the center only
    function hidePopup(n: Notification) {
        popupIds = popupIds.filter(id => id !== n.id);
        // Transient notifications ask not to be kept around
        if (n.transient)
            n.expire();
        trim();
    }

    function clearAll() {
        all.slice().forEach(n => n.dismiss());
    }

    // Push the lowest-priority, oldest notifications off the end of the history,
    // never touching persistent ones or ones still on screen as a popup
    function trim() {
        const evictable = history.filter(n => !isPersistent(n) && !popupIds.includes(n.id));
        for (let i = historyLimit; i < evictable.length; i++)
            evictable[i].dismiss();
    }

    onCenterOpenChanged: if (centerOpen) {
        // Everything is visible in the center, so the popups have done their job
        const shown = popups;
        popupIds = [];
        unread = 0;
        shown.filter(n => n.transient).forEach(n => n.expire());
        trim();
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;
            const id = notification.id;
            root.arrived = Object.assign({}, root.arrived, {
                [id]: Date.now()
            });
            if (!root.centerOpen) {
                root.popupIds = root.popupIds.filter(i => i !== id).concat([id]);
                root.unread++;
            }
            notification.closed.connect(() => {
                root.popupIds = root.popupIds.filter(i => i !== id);
                const rest = Object.assign({}, root.arrived);
                delete rest[id];
                root.arrived = rest;
            });
            root.trim();
        }
    }
}
