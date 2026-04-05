import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

FloatingWindow {
    id: root
    color: "transparent"
    height: 800
    width: 1000

    property var errorText: ""
    property var monitorLogs: []
    property var wifiModel: []
    property double wifiStartMs: 0 // Time since clicking "WiFi: ON"

    component MonoText: TextEdit {
        anchors.verticalCenter: parent.verticalCenter
        font.family: "monospace"
        color: "white"
        readOnly: true
        selectByMouse: true
    }

    onErrorTextChanged: {
        if (errorText !== "") {
            console.log("Error: ", errorText);
        }
    }

    Rectangle {
        color: "red"
        height: 30
        visible: root.errorText !== ""
        width: parent.width

        MonoText {
            anchors.centerIn: parent
            color: "white"
            font.bold: true
            text: "ERROR: " + root.errorText
        }
    }

    // Measure the width of a single monospace character.
    FontMetrics {
        id: fm
        font.family: "monospace"
    }
    // The width of one monospace character.
    property real charW: fm.advanceWidth("A")

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled
        if (Networking.wifiEnabled) {
            root.wifiStartMs = Date.now();
        } else {
            root.wifiModel = [];
            root.wifiStartMs = 0;
        }
    }

    Process {
        id: nmcliTask
        command: ["nmcli", "-t", "-e", "yes", "-f", "ACTIVE,SSID,BARS,SIGNAL,RATE,BSSID", "dev", "wifi", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                let wifiModel_ = [];
                for (let i = 0; i < lines.length; i++) {
                    const parts_ = lines[i].replace(/\\:/g, "__@@__").split(":");
                    const parts = parts_.map(x => x.replace(/__@@__/g, ":"));
                    if (parts.length >= 4) {
                        wifiModel_.push({
                            "active": parts[0] === "yes" || parts[0] === "*",
                            "ssid": parts[1] || "<Hidden>",
                            "bars": parts[2],
                            "signal": parts[3],
                            "rate": parts[4],
                            "bssid": parts.slice(5).join(":")
                        });
                        root.errorText = "";
                    } else if (Networking.wifiEnabled
                               && root.wifiStartMs > 0
                               && (Date.now() - root.wifiStartMs > 4000)) {
                        root.errorText = `Unexpected response from nmcli: ${parts}`;
                    }
                }
                root.wifiModel = wifiModel_;
            }
        }
    }

    // Ask NetworkManager for wifi networks every second.
    Timer {
        interval: 500
        onTriggered: if (!nmcliTask.running) nmcliTask.running = true
        running: true
        repeat: true
        triggeredOnStart: true
    }

    // Record the output of "nmcli monitor".
    Process {
        command: ["nmcli", "monitor"]
        id: monitorProcess
        running: true // Run immediately and forever.
        stdout: SplitParser {
            onRead: (data) => {
                const line = data.trim();
                if (line !== "") {
                    // .slice() copies the array so QML knows it needs to update the UI
                    let logs = root.monitorLogs.slice();
                    logs.push(line);
                    // Prevent memory leak.
                    if (logs.length > 1000) logs.shift();
                    root.monitorLogs = logs;
                }
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24

        Rectangle {
            border.color: "white"
            border.width: 2
            color: Qt.rgba(0, 0, 0, 0.2)
            height: 400
            radius: 8
            width: parent.width

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: root.charW

                // Column headers.
                Row {
                    spacing: 24
                    width: parent.width
                    component ColumnHeader: MonoText {
                        font.bold: true
                    }
                    ColumnHeader { text: "  Active"; width: root.charW * 10; }
                    ColumnHeader { text: "BSSID";  width: root.charW * 19; }
                    ColumnHeader { text: "SSID";   width: root.charW * 25; }
                    ColumnHeader { text: "Speed";  width: root.charW * 12; }
                    ColumnHeader { text: "Signal"; width: root.charW * 5; }
                    ColumnHeader { text: "Bars";   width: root.charW * 6; }
                }

                // Separator Line
                Rectangle {
                    height: 2
                    width: parent.width
                }

                ListView {
                    clip: true
                    focus: true // Required for key binds.
                    id: apList
                    height: parent.height - 40 // Avoid overflowing.
                    model: root.wifiModel
                    width: parent.width

                    // Up and down navigation.
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_J) {
                            apList.incrementCurrentIndex();
                        } else if (event.key === Qt.Key_K) {
                            apList.decrementCurrentIndex();
                        } else if (event.text === "G") {
                            apList.currentIndex = Math.max(0, apList.count - 1);
                        } else if (event.text === "g") {
                            apList.currentIndex = 0;
                        } else if (event.text === "q" || event.key === Qt.Key_Escape) {
                            Qt.quit()
                        } else if (event.key === Qt.Key_W) {
                            root.toggleWifi()
                        }
                    }

                    // Highlight the selected row.
                    highlight: Rectangle {
                        color: Qt.rgba(0, 0, 0, 0.5)
                        radius: 8
                        width: apList.width
                    }
                    highlightFollowsCurrentItem: true

                    delegate: Row {
                        height: 24
                        id: apRow
                        spacing: 24
                        width: apList.width

                        property color rowColour: {
                            let sig = parseInt(modelData.signal);
                            if (sig < 30) return "red";
                            if (sig < 55) return "orange";
                            if (sig < 80) return "yellow";
                            return "green";
                        }

                        component Cell: MonoText {
                            color: rowColour;
                        }
                        Cell { text: modelData.active ? "  Active" : ""; width: root.charW * 10; }
                        Cell { text: modelData.bssid;                  width: root.charW * 19; }
                        Cell { text: modelData.ssid;                   width: root.charW * 25; }
                        Cell { text: modelData.rate;                   width: root.charW * 12; }
                        Cell { text: modelData.signal + "%";           width: root.charW * 5; }
                        Cell { text: modelData.bars;                   width: root.charW * 6; }
                    }
                }
            }
        }

        // Keybinds legend.
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 24

            Row {
                spacing: 8
                MonoText { color: "blue"; font.bold: true; text: "j"; }
                MonoText { text: "up"; }
            }
            Row {
                spacing: 8
                MonoText { color: "blue"; font.bold: true; text: "k"; }
                MonoText { text: "down"; }
            }
            Row {
                spacing: 8
                MonoText { color: "blue"; font.bold: true; text: "g"; }
                MonoText { text: "top"; }
            }
            Row {
                spacing: 8
                MonoText { color: "blue"; font.bold: true; text: "G"; }
                MonoText { text: "bottom"; }
            }
            Row {
                spacing: 8
                MonoText { color: "blue"; font.bold: true; text: "w"; }
                MonoText { text: "toggle wifi"; }
            }
            Row {
                spacing: 8
                MonoText { color: "blue"; font.bold: true; text: "q/ESC"; }
                MonoText { text: "quit"; }
            }
        }

        // "nmcli monitor" box.
        Rectangle {
            border.color: "white"
            border.width: 2
            color: Qt.rgba(0, 0, 0, 0.2)
            radius: 8
            height: 150
            width: parent.width

            // Title for the box.
            Rectangle {
                id: monitorTitle
                height: 20
                topLeftRadius: 8
                width: 120
                MonoText {
                    anchors.centerIn: parent
                    color: "black"
                    font.bold: true
                    text: "LIVE MONITOR"
                }
            }

            ListView {
                clip: true
                id: monitorList
                anchors.fill: parent
                anchors.margins: 24
                anchors.topMargin: monitorTitle.height + 4 // Push text below the title.
                model: root.monitorLogs

                // Auto-scroll to the bottom when a new log arrives.
                onCountChanged: Qt.callLater(() => monitorList.positionViewAtEnd())

                // We use standard Text here instead of MonoText because
                // we don't want the verticalCenter anchors inside a ListView
                delegate: Text {
                    font.family: "monospace"
                    text: "> " + modelData
                    width: monitorList.width
                    wrapMode: Text.Wrap

                    color: {
                        const colorMap = {
                            "connecting": "yellow",
                            "limited": "yellow",
                            "disconnected": "red",
                            "failed": "red",
                            "unavailable": "grey",
                            "unmanaged": "grey",
                            "connected": "green",
                            "full": "green",
                            "running": "green",
                        };
                        let lowerLine = modelData.toLowerCase();
                        for (let word in colorMap) {
                            if (lowerLine.includes(word)) {
                                return colorMap[word]; // Found a match, return the color!
                            }
                        }
                        return "white";
                    }
                }
            }
        }
    }
}
