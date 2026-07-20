import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland
import Cmds 0.1
import qs.bar

// The bar: transparent window, workspace chips left, module chips right.
// Everything below is ModuleChip configuration — no module has its own
// rendering or dispatch code.
PanelWindow {
    id: bar

    required property var notifications

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property var hyprMonitor: Hyprland.monitorFor(bar.screen)
    readonly property var battery: UPower.displayDevice
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property var perfModes: [
        {
            label: "Save",
            value: PowerProfile.PowerSaver,
            icon: "power-profile-power-saver-symbolic"
        },
        {
            label: "Balanced",
            value: PowerProfile.Balanced,
            icon: "power-profile-balanced-symbolic"
        },
        {
            label: "Performance",
            value: PowerProfile.Performance,
            icon: "power-profile-performance-symbolic"
        }
    ]
    readonly property int perfIndex: perfModes.findIndex(m => m.value === PowerProfiles.profile)

    function focusWorkspace(target) {
        if (target >= 1 && target <= 10)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = "${target}" })`);
    }

    function isoWeek(date) {
        const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
        const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
    }

    function pct(x) {
        return Math.round(100 * x);
    }

    // Right-align a 0..100 reading in a 3-char field (leading spaces) so the
    // chip width stays constant as the value crosses 10 and 100.
    function pad3(n) {
        var s = String(n);
        while (s.length < 3)
            s = " " + s;
        return s;
    }

    // Hyprglass applies the liquid glass effect by layer namespace (see the
    // layer_rule in hyprland.nix).
    WlrLayershell.namespace: "quickshell-bar"

    anchors {
        left: true
        right: true
        top: true
    }
    color: "transparent"
    implicitHeight: Style.barHeight

    // Track the default sink so its volume properties stay bound.
    PwObjectTracker {
        objects: bar.sink ? [bar.sink] : []
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // Workspaces (left): only open ones, plus a chip that creates a new one.
    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: Style.barPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.workspaceGap

        Repeater {
            model: Hyprland.workspaces

            ModuleChip {
                required property var modelData
                accent: modelData.focused
                bold: modelData.focused
                minWidth: Style.workspaceMinWidth
                value: modelData.name
                // Only workspaces on this bar's monitor.
                visible: modelData.monitor === bar.hyprMonitor
                // Hyprglass expects Lua dispatches, so avoid activate().
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = "${modelData.id}" })`)
                onScrolled: up => bar.focusWorkspace((Hyprland.focusedWorkspace?.id ?? 1) + (up ? 1 : -1))
            }
        }

        ModuleChip {
            dim: true
            minWidth: Style.workspaceMinWidth
            value: "+"
            onClicked: Hyprland.dispatch('hl.dsp.focus({ workspace = "empty" })')
            onScrolled: up => bar.focusWorkspace((Hyprland.focusedWorkspace?.id ?? 1) + (up ? 1 : -1))
        }
    }

    // Modules (right).
    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: Style.barPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.chipGap

        // System tray: app icons shown as-is, left-click activates,
				// right-click opens the app's own menu. Icons whose id match
				// Style.trayExclude are hidden (Row skips invisible children), e.g.
        // blueman's duplicate bluetooth icon.
        Repeater {
            model: SystemTray.items

            ModuleChip {
                id: trayChip

                required property var modelData

                visible: !Style.trayExclude.some(function (needle) {
                    return modelData.id && modelData.id.toLowerCase().indexOf(needle.toLowerCase()) >= 0;
                })

                iconSource: modelData.icon
                onClicked: modelData.activate()
                onRightClicked: {
                    if (modelData.hasMenu)
                        trayMenu.open();
                }

                QsMenuAnchor {
                    id: trayMenu
                    anchor.item: trayChip
                    anchor.rect.y: trayChip.height + Style.panelGap
                    menu: trayChip.modelData.menu
                }
            }
        }

        ModuleChip {
            dotIndex: bar.perfIndex
            icon: bar.perfModes[bar.perfIndex]?.icon ?? "power-profile-balanced-symbolic"
            panelControls: Component {
                Controls.ModeList {
                    current: PowerProfiles.profile
                    options: bar.perfModes
                    onSelected: value => PowerProfiles.profile = value
                }
            }
            panelState: bar.perfModes[bar.perfIndex]?.label ?? ""
            panelStateGood: true
            panelTitle: "Power mode"
            onClicked: PowerProfiles.profile = bar.perfModes[(bar.perfIndex + 1) % 3].value
            onScrolled: up => PowerProfiles.profile = bar.perfModes[(bar.perfIndex + (up ? 1 : 2)) % 3].value
        }

        ModuleChip {
            icon: "display-brightness-symbolic"
            panelControls: Component {
                Controls.SliderRow {
                    value: Brightness.value / 100
                    onMoved: value => Brightness.set(100 * value)
                }
            }
            panelState: Brightness.value + "%"
            panelTitle: "Brightness"
            value: bar.pad3(Brightness.value)
            visible: Brightness.available
            onScrolled: up => Brightness.adjust(up ? 5 : -5)
        }

        ModuleChip {
            readonly property bool muted: bar.sink?.audio.muted ?? false
            readonly property real volume: bar.sink?.audio.volume ?? 0
            dim: muted
            icon: muted ? "audio-volume-muted-symbolic" : volume < 0.34 ? "audio-volume-low-symbolic" : volume < 0.67 ? "audio-volume-medium-symbolic" : "audio-volume-high-symbolic"
            panelControls: Component {
                ColumnLayout {
                    spacing: Style.panelSpacing

                    Controls.SliderRow {
                        value: bar.sink?.audio.volume ?? 0
                        onMoved: value => {
                            if (bar.sink)
                                bar.sink.audio.volume = value;
                        }
                    }

                    Controls.Dropdown {
                        current: bar.sink?.description || ""
                        options: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio).map(n => ({
                                    label: n.description || n.name,
                                    value: n,
                                    active: n === bar.sink
                                }))
                        // Via wpctl: quickshell's preferredDefaultAudioSink
                        // does not reliably move the wireplumber default.
                        onSelected: value => Quickshell.execDetached(["wpctl", "set-default", String(value.id)])
                    }
                }
            }
            panelState: value === "" ? "" : value + "%"
            panelTitle: "Volume"
            rightClickApp: Cmds.audioGui
            value: bar.sink ? bar.pad3(bar.pct(bar.sink.audio.volume)) : ""
            visible: bar.sink !== null
            onClicked: {
                if (bar.sink)
                    bar.sink.audio.muted = !bar.sink.audio.muted;
            }
            onScrolled: up => {
                if (bar.sink)
                    bar.sink.audio.volume = Math.max(0, Math.min(1, bar.sink.audio.volume + (up ? 0.05 : -0.05)));
            }
        }

        ModuleChip {
            dim: !Wifi.enabled
            icon: "network-wireless-symbolic"
            panelControls: Component {
                ColumnLayout {
                    spacing: Style.panelSpacing

                    Controls.ToggleRow {
                        checked: Wifi.enabled
                        label: "WiFi"
                        onToggled: checked => Wifi.setEnabled(checked)
                    }

                    Controls.Dropdown {
                        current: Wifi.ssid || "not connected"
                        options: Wifi.networks
                        onSelected: value => Wifi.connectTo(value)
                    }
                }
            }
            panelState: Wifi.enabled ? "on" : "off"
            panelStateGood: Wifi.enabled
            panelTitle: "WiFi"
            rightClickApp: `quickshell -p ${Quickshell.shellDir}/nmtui.qml`
            visible: Wifi.hasDevice
            onClicked: Wifi.setEnabled(!Wifi.enabled)
            onPanelOpening: Wifi.refresh()
        }

        ModuleChip {
            readonly property bool btOn: bar.btAdapter?.enabled ?? false
            dim: !btOn
            icon: btOn ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic"
            panelControls: Component {
                ColumnLayout {
                    spacing: Style.panelSpacing

                    Controls.ToggleRow {
                        checked: bar.btAdapter?.enabled ?? false
                        label: "Bluetooth"
                        onToggled: checked => {
                            if (bar.btAdapter)
                                bar.btAdapter.enabled = checked;
                        }
                    }

                    Controls.Dropdown {
                        readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)
                        current: connected.length > 0 ? connected[0].name : "no device"
                        options: Bluetooth.devices.values.filter(d => d.bonded).map(d => ({
                                    label: d.name + (d.connected ? " ✓" : ""),
                                    value: d,
                                    active: d.connected
                                }))
                        onSelected: value => {
                            if (value.connected)
                                value.disconnect();
                            else
                                value.connect();
                        }
                    }
                }
            }
            panelState: btOn ? "on" : "off"
            panelStateGood: btOn
            panelTitle: "Bluetooth"
            rightClickApp: Cmds.bluetoothGui
            visible: bar.btAdapter !== null
            onClicked: {
                if (bar.btAdapter)
                    bar.btAdapter.enabled = !bar.btAdapter.enabled;
            }
        }

        ModuleChip {
            icon: "cpu-symbolic"
            panelControls: Component {
                Controls.InfoLines {
                    lines: [Sys.loadInfo, Sys.tempInfo, Sys.topCpu].filter(l => l !== "")
                }
            }
            panelState: value
            panelTitle: "CPU"
            rightClickApp: Cmds.btop
            value: bar.pad3(Math.round(Sys.cpuPercent)) + "%"
            onClicked: Launcher.app(Cmds.btop)
        }

        ModuleChip {
            icon: "memory-symbolic"
            panelControls: Component {
                Controls.InfoLines {
                    lines: [Sys.memInfo, Sys.topMem].filter(l => l !== "")
                }
            }
            panelState: value
            panelTitle: "Memory"
            rightClickApp: Cmds.btop
            value: bar.pad3(Math.round(Sys.memPercent)) + "%"
            onClicked: Launcher.app(Cmds.btop)
        }

        ModuleChip {
            id: batteryChip
            readonly property bool charging: bar.battery?.state === UPowerDeviceState.Charging
            readonly property int secondsLeft: charging ? (bar.battery?.timeToFull ?? 0) : (bar.battery?.timeToEmpty ?? 0)
            icon: bar.battery?.iconName || "battery-good-symbolic"
            panelControls: Component {
                Controls.InfoLines {
                    lines: [batteryChip.charging ? "charging" : "discharging", batteryChip.secondsLeft > 0 ? `${Math.floor(batteryChip.secondsLeft / 3600)}h ${Math.round(batteryChip.secondsLeft % 3600 / 60)}m remaining` : ""].filter(l => l !== "")
                }
            }
            panelState: value + "%"
            panelTitle: "Battery"
            value: bar.battery ? bar.pct(bar.battery.percentage) : ""
            visible: (bar.battery?.isLaptopBattery ?? false) && bar.battery.isPresent
        }

        ModuleChip {
            dim: bar.notifications.doNotDisturb
            icon: bar.notifications.doNotDisturb ? "notifications-disabled-symbolic" : "notifications-symbolic"
            panelControls: Component {
                Controls.ToggleRow {
                    checked: bar.notifications.doNotDisturb
                    label: "Do not disturb"
                    onToggled: checked => bar.notifications.doNotDisturb = checked
                }
            }
            panelState: bar.notifications.unreadCount + " unread"
            panelTitle: "Notifications"
            value: bar.notifications.unreadCount > 0 ? bar.notifications.unreadCount : ""
            onClicked: bar.notifications.centerOpen = !bar.notifications.centerOpen
            onRightClicked: bar.notifications.doNotDisturb = !bar.notifications.doNotDisturb
        }

        ModuleChip {
            bold: true
            panelControls: Component {
                Controls.InfoLines {
                    lines: [`${Qt.formatDate(clock.date, "ddd d MMMM yyyy")} · week ${bar.isoWeek(clock.date)}`]
                }
            }
            panelState: value
            panelTitle: "Clock"
            value: Qt.formatDateTime(clock.date, "HH:mm:ss")
        }

        ModuleChip {
            icon: "system-shutdown-symbolic"
            panelControls: Component {
                Controls.ModeList {
                    options: [
                        {
                            label: "Lock",
                            value: Cmds.lockScreen,
                            icon: "system-lock-screen-symbolic"
                        },
                        {
                            label: "Suspend",
                            value: "systemctl suspend",
                            icon: "system-suspend-symbolic"
                        },
                        {
                            label: "Reboot",
                            value: "systemctl reboot",
                            icon: "system-reboot-symbolic"
                        },
                        {
                            label: "Power off",
                            value: "systemctl poweroff",
                            icon: "system-shutdown-symbolic"
                        }
                    ]
                    onSelected: value => Launcher.app(value)
                }
            }
            panelTitle: "Power"
        }
    }
}
