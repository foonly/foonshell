import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

PanelWindow {
    id: window

    required property ShellScreen modelData
    required property var manager

    screen: modelData
    color: "transparent"
    visible: manager.active || manager.animProgress > 0

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "foonshell:logout"
    exclusionMode: ExclusionMode.Ignore

    readonly property bool isFocusedScreen: {
        const mon = Hyprland.focusedMonitor;
        if (mon && mon.name)
            return modelData.name === mon.name;
        return modelData === Quickshell.screens[0];
    }

    WlrLayershell.keyboardFocus: (manager.active && isFocusedScreen) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onVisibleChanged: {
        if (visible && isFocusedScreen) {
            focusScope.forceActiveFocus();
        }
    }

    // Keyboard navigation focus scope
    Item {
        id: focusScope
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                manager.close();
                event.accepted = true;
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                manager.selectNext();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                manager.selectPrevious();
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                if (manager.selectedIndex >= 0 && manager.selectedIndex < manager.actions.length) {
                    manager.triggerAction(manager.actions[manager.selectedIndex]);
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_L) {
                manager.triggerActionById("lock");
                event.accepted = true;
            } else if (event.key === Qt.Key_E) {
                manager.triggerActionById("logout");
                event.accepted = true;
            } else if (event.key === Qt.Key_U) {
                manager.triggerActionById("suspend");
                event.accepted = true;
            } else if (event.key === Qt.Key_R) {
                manager.triggerActionById("reboot");
                event.accepted = true;
            } else if (event.key === Qt.Key_S || event.key === Qt.Key_P) {
                manager.triggerActionById("shutdown");
                event.accepted = true;
            }
        }
    }

    // Backdrop overlay: click to cancel
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.04, 0.03, 0.05, 0.82)
        opacity: manager.animProgress

        MouseArea {
            anchors.fill: parent
            onClicked: manager.close()
        }
    }

    // Centered Content
    Item {
        anchors.centerIn: parent
        width: contentColumn.implicitWidth
        height: contentColumn.implicitHeight
        opacity: manager.animProgress
        scale: 0.94 + 0.06 * manager.animProgress

        Column {
            id: contentColumn
            anchors.centerIn: parent
            spacing: 28

            // Header
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Power Menu"
                    font.family: Theme.font
                    font.pixelSize: 22
                    font.bold: true
                    color: Theme.c.on_surface
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: `${Quickshell.env("USER") || "user"}${manager.hostname ? "@" + manager.hostname : ""}`
                    font.family: Theme.font
                    font.pixelSize: 13
                    color: Theme.c.outline
                }
            }

            // Row of Action Cards
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Repeater {
                    model: manager.actions

                    LogoutButton {
                        required property var modelData
                        required property int index

                        actionId: modelData.id
                        label: modelData.label
                        icon: modelData.icon
                        keyHint: modelData.keyHint
                        accentColor: modelData.accentColor
                        isSelected: manager.selectedIndex === index

                        onTriggered: manager.triggerAction(modelData)
                        onHovered: manager.selectedIndex = index
                    }
                }
            }

            // Footer hint
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                height: 28
                radius: 14
                color: Theme.c.surface_container
                border.width: 1
                border.color: Theme.c.outline_variant
                implicitWidth: hintText.implicitWidth + 24

                Text {
                    id: hintText
                    anchors.centerIn: parent
                    text: "Esc Cancel  •  Tab / ← → Navigate  •  Enter Select  •  [L] [E] [U] [R] [S] Hotkeys"
                    font.family: Theme.font
                    font.pixelSize: 11
                    color: Theme.c.outline
                }
            }
        }
    }
}
