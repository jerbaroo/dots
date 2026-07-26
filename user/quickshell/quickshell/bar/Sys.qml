pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar

// CPU / memory / temperature stats, polled from /proc and friends.
Singleton {
    id: root

    property real cpuPercent: 0
    property string loadInfo: ""
    property string tempInfo: ""
    property var topCpu: []
    property real memPercent: 0
    property string memInfo: ""
    property var topMem: []
    property var _prevStat: null

    // "Key: value" with the key padded so the values line up across the lines
    // of a popup (the panel font is monospaced).
    function _kv(key, value) {
        var k = key + ":";
        while (k.length < 5)
            k += " ";
        return k + " " + value;
    }

    function _cap(s) {
        return s.length > 0 ? s.charAt(0).toUpperCase() + s.slice(1) : s;
    }

    // Pad `s` to width `n` with spaces (prepended when `left`, else appended).
    function _pad(s, n, left) {
        while (s.length < n)
            s = left ? " " + s : s + " ";
        return s;
    }

    // Format the top processes as rows with the names left-aligned and the
    // percentages right-aligned into a column (the panel font is monospaced,
    // so equal-width columns line up).
    function _formatTop(procs) {
        var nameW = 0;
        var pctW = 0;
        for (const p of procs) {
            nameW = Math.max(nameW, p.comm.length);
            pctW = Math.max(pctW, p.pct.length);
        }
        return procs.map(p => _pad(p.comm, nameW, false) + " " + _pad(p.pct, pctW, true));
    }

    function _parse(out) {
        const cpu = [];
        const mem = [];
        for (const line of out.trim().split("\n")) {
            const parts = line.trim().split(/\s+/);
            const fields = parts.slice(1);
            switch (parts[0]) {
            case "s":
                {
                    // user nice system idle iowait irq softirq steal.
                    const stat = fields.slice(1).map(Number);
                    if (_prevStat !== null) {
                        const total = i => stat[i] - _prevStat[i];
                        let totalD = 0;
                        for (let i = 0; i < 8; i++)
                            totalD += total(i);
                        const idleD = total(3) + total(4);
                        if (totalD > 0)
                            cpuPercent = 100 * (totalD - idleD) / totalD;
                    }
                    _prevStat = stat;
                    break;
                }
            case "l":
                loadInfo = _kv("Load", `${fields[0]} · ${fields[1]} cores`);
                break;
            case "m":
                {
                    const totalKib = Number(fields[0]);
                    const availKib = Number(fields[1]);
                    const usedGib = (totalKib - availKib) / 1024 / 1024;
                    memPercent = 100 * (totalKib - availKib) / totalKib;
                    memInfo = _kv("Used", `${usedGib.toFixed(0)} / ${(totalKib / 1024 / 1024).toFixed(0)} GiB`);
                    break;
                }
            case "t":
                tempInfo = fields[0] ? _kv("Temp", `${Math.round(Number(fields[0]) / 1000)}°C`) : "";
                break;
            case "c":
                // comm may contain spaces; the percentage is the last field.
                cpu.push({
                    comm: _cap(fields.slice(0, -1).join(" ")),
                    pct: Math.round(Number(fields[fields.length - 1])) + "%"
                });
                break;
            case "M":
                mem.push({
                    comm: _cap(fields.slice(0, -1).join(" ")),
                    pct: Math.round(Number(fields[fields.length - 1])) + "%"
                });
                break;
            }
        }
        topCpu = _formatTop(cpu);
        topMem = _formatTop(mem);
    }

    Timer {
        interval: Style.pollMs
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }

    Process {
        id: poll
        command: ["sh", "-c", `
            echo s $(head -1 /proc/stat)
            echo l $(cut -d' ' -f1 /proc/loadavg) $(nproc)
            echo m $(awk '/MemTotal|MemAvailable/ {print $2}' /proc/meminfo | tr '\\n' ' ')
            echo t $(cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | sort -nr | head -1)
            ps -eo comm,%cpu --sort=-%cpu --no-headers | head -3 | sed 's/^/c /'
            ps -eo comm,%mem --sort=-%mem --no-headers | head -3 | sed 's/^/M /'
        `]

        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }
}
