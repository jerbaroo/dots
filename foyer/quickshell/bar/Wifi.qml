pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar

// WiFi state via NetworkManager (nmcli). Hidden entirely when the machine
// has no wifi device.
Singleton {
    id: root

    property bool hasDevice: false
    property bool enabled: false
    property string ssid: ""
    // Dropdown options: { label, value (ssid), active }.
    property var networks: []

    function connectTo(ssid) {
        Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", ssid]);
    }

    function refresh() {
        if (!status.running)
            status.running = true;
    }

    function setEnabled(on) {
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
        enabled = on;
    }

    function _parse(out) {
        const lines = out.trim().split("\n");
        enabled = lines[0].trim() === "enabled";
        ssid = "";
        const seen = {};
        const found = [];
        for (const line of lines.slice(1)) {
            const [active, name, signal] = line.split(":");
            if (!name || seen[name])
                continue;
            seen[name] = true;
            if (active === "yes")
                ssid = name;
            found.push({
                label: `${name} (${signal}%)`,
                value: name,
                active: active === "yes"
            });
        }
        networks = found;
    }

    Process {
        id: detect
        command: ["sh", "-c", "nmcli -t -f TYPE device | grep -q wifi && echo yes || echo no"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.hasDevice = text.trim() === "yes"
        }
    }

    Process {
        id: status
        command: ["sh", "-c", "nmcli radio wifi; nmcli -t --rescan no -f ACTIVE,SSID,SIGNAL dev wifi"]

        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    Timer {
        interval: Style.wifiPollMs
        repeat: true
        running: root.hasDevice
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
