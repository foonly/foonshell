import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs

// Only shown on machines with a laptop battery. Left click: toggle time remaining.
// Right click: unlock a full charge past the charge limit (relocks on unplug or when full). Hover: details.
BarIcon {
    id: root

    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property real percentage: battery?.percentage ?? 0
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging || battery?.state === UPowerDeviceState.FullyCharged || battery?.state === UPowerDeviceState.PendingCharge
    readonly property real seconds: charging ? battery?.timeToFull ?? 0 : battery?.timeToEmpty ?? 0
    property bool showTime
    hoverEnabled: true

    // The display device is a virtual aggregate; health and sysfs info live on the real one
    readonly property UPowerDevice cell: UPower.devices.values.find(d => d.isLaptopBattery) ?? null

    function duration(seconds: real): string {
        const minutes = Math.round(seconds / 60);
        return `${Math.floor(minutes / 60)}h ${String(minutes % 60).padStart(2, "0")}m`;
    }

    readonly property string stateText: {
        switch (battery?.state) {
        case UPowerDeviceState.Charging:
            return seconds > 0 ? `${duration(seconds)} until full` : "Charging";
        case UPowerDeviceState.Discharging:
            return seconds > 0 ? `${duration(seconds)} left` : "On battery";
        case UPowerDeviceState.FullyCharged:
            return "Fully charged";
        case UPowerDeviceState.PendingCharge:
            return "Plugged in, not charging";
        case UPowerDeviceState.PendingDischarge:
            return "Plugged in, discharging";
        default:
            return "";
        }
    }

    // Charge cycles aren't exposed by UPower, so read them straight from sysfs
    FileView {
        id: cycles
        path: root.cell ? `/sys/class/power_supply/${root.cell.nativePath}/cycle_count` : ""
    }

    // Charge limit set in firmware, explains sitting at e.g. 80% while plugged in
    FileView {
        id: chargeLimit
        path: root.cell ? `/sys/class/power_supply/${root.cell.nativePath}/charge_control_end_threshold` : ""
    }

    // FileView doesn't watch sysfs, so refresh whenever the tooltip opens
    function refreshFiles() {
        cycles.reload();
        chargeLimit.reload();
    }

    // Charge limit toggle. Locked, the battery stops at Config.chargeLimit and only starts again
    // five points below it; unlocked, it charges to 100%. The thresholds are written straight to
    // sysfs, which needs the udev rule in extras/ for write access. The firmware keeps them across
    // reboots. UPower's EnableChargeThreshold isn't used: on ThinkPads it doesn't restore the limit.
    readonly property string sysfsDir: cell ? `/sys/class/power_supply/${cell.nativePath}` : ""
    readonly property int limitEnd: parseInt(chargeLimit.text())
    readonly property bool limitSupported: limitEnd > 0
    // 0 is how some drivers report "no limit"
    readonly property bool unlocked: limitSupported && (limitEnd >= 100 || limitEnd === 0)
    property string limitError

    function setLimit(locked: bool) {
        if (!sysfsDir || setLimitProc.running)
            return;
        const start = `${sysfsDir}/charge_control_start_threshold`;
        const end = `${sysfsDir}/charge_control_end_threshold`;
        // Start must stay below end, so the order of the two writes depends on the direction
        const script = locked
            ? `{ [ ! -e ${start} ] || echo ${Config.chargeLimit - 5} > ${start}; } && echo ${Config.chargeLimit} > ${end}`
            : `echo 100 > ${end} && { [ ! -e ${start} ] || echo 0 > ${start}; }`;
        setLimitProc.command = ["sh", "-c", script];
        setLimitProc.running = true;
    }

    // Relock once the full charge has been used: unplugged, or done charging
    function relockIfDone() {
        if (unlocked && (UPower.onBattery || battery?.state === UPowerDeviceState.FullyCharged || (charging && percentage >= 0.995)))
            setLimit(true);
    }

    // Re-read the limit as the battery changes, in case something else set it
    onPercentageChanged: {
        chargeLimit.reload();
        relockIfDone();
    }
    onChargingChanged: {
        chargeLimit.reload();
        relockIfDone();
    }
    onUnlockedChanged: relockIfDone()

    Connections {
        target: UPower

        function onOnBatteryChanged() {
            root.relockIfDone();
        }
    }

    Process {
        id: setLimitProc
        stderr: StdioCollector {
            id: setLimitErr
        }
        onExited: code => {
            root.limitError = code === 0 ? "" : "No write access, see README";
            if (code !== 0)
                console.warn("battery: setting the charge limit failed:", setLimitErr.text.trim());
            chargeLimit.reload();
        }
    }

    readonly property bool shown: UPower.devices.values.some(d => d.isLaptopBattery)

    visible: shown

    icon: {
        const level = Math.min(10, Math.round(percentage * 10));
        return charging ? ["󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"][level] : ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][level];
    }
    label: {
        const text = showTime && seconds > 0 ? duration(seconds) : `${Math.round(percentage * 100)}%`;
        return unlocked ? `${text} 󰌿` : text;
    }
    alert: !charging && percentage <= 0.15

    onLeftClicked: showTime = !showTime
    onRightClicked: if (limitSupported)
        setLimit(unlocked)

    onContainsMouseChanged: if (containsMouse)
        refreshFiles()

    BarTooltip {
        anchor.item: root
        shown: root.containsMouse

        Text {
            text: `${Math.round(root.percentage * 100)}%` + (root.stateText ? ` · ${root.stateText}` : "")
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.bold: true
            color: root.alert ? Theme.c.error : Theme.c.on_surface
        }

        Grid {
            columns: 2
            columnSpacing: 12
            rowSpacing: 2

            Repeater {
                model: {
                    // Label, value, label, value, … for the two column grid
                    const rows = [];
                    const b = root.battery;
                    if (b && Math.abs(b.changeRate) > 0.05)
                        rows.push(root.charging ? "Charging at" : "Drawing", `${Math.abs(b.changeRate).toFixed(1)} W`);
                    if (b && b.energyCapacity > 0)
                        rows.push("Energy", `${b.energy.toFixed(1)} / ${b.energyCapacity.toFixed(1)} Wh`);
                    if (root.cell?.healthSupported)
                        rows.push("Health", `${Math.round(root.cell.healthPercentage)}%`);
                    const cycleCount = parseInt(cycles.text());
                    if (cycleCount > 0)
                        rows.push("Cycles", `${cycleCount}`);
                    if (root.limitError)
                        rows.push("Charge limit", root.limitError);
                    else if (root.unlocked)
                        rows.push("Charge limit", "Unlocked until full or unplugged");
                    else if (root.limitSupported)
                        rows.push("Charge limit", `${root.limitEnd}%`);
                    rows.push("Profile", PowerProfile.toString(PowerProfiles.profile));
                    return rows;
                }

                Text {
                    required property string modelData
                    required property int index
                    text: modelData
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    color: index % 2 === 0 ? Theme.c.outline : Theme.c.on_surface
                }
            }
        }
    }
}
