//@ pragma UseQApplication

import QtQuick
import Quickshell
import qs.modules.bar
import qs.modules.notifications
import qs.modules.logout
import qs.modules.osd

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Notifications {}

    Logout {}

    VolumeOsd {}
}
