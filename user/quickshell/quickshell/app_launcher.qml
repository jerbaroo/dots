import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

import "config.js" as Config
import Theme 0.1

Scope {
    id: root

    property bool appLauncherOpen: false

    // Start each launcher session with a fresh query.
    onAppLauncherOpenChanged: {
        if (appLauncherOpen)
            searchInput.text = "";
    }

    ListModel {
        id: resultsModel
    }

    IpcHandler {
        target: "app-launcher"
        function toggle(): void {
            root.appLauncherOpen = !root.appLauncherOpen;
        }
    }

    // Ask Rust server for apps.
    function fetchApps(query) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            try {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        resultsModel.clear();
                        resultsList.currentIndex = 0;
                        var apps = JSON.parse(xhr.responseText);
                        for (var i = 0; i < apps.length; i++) {
                            resultsModel.append({
                                "name": apps[i].name,
                                "exec": apps[i].exec,
                                "comment": apps[i].comment !== null ? apps[i].comment : "",
                                "icon": apps[i].icon || "application-x-executable"
                            });
                            console.log(`${apps[i].name}: ${apps[i].icon}`);
                        }
                    }
                }
            } catch (exception) {
                console.log("HTTP exception: ", exception);
            }
        };
        var url = "http://localhost:1235/apps/search/" + encodeURIComponent(query);
        xhr.open("GET", url, true);
        xhr.send();
    }

    Process {
        id: appProcess
    }

    function launchApp(exec) {
        var cleanExec = exec.replace(/%[UufFieGgckvw]/g, "").trim();
        console.log("Launching app: ", cleanExec);
        appProcess.command = ["sh", "-c", cleanExec];
        appProcess.startDetached();
        root.appLauncherOpen = false;
    }

    PanelWindow {
        id: window

        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }
        color: "transparent"
        focusable: true
        visible: root.appLauncherOpen

        MouseArea {
            anchors.fill: parent
            onClicked: root.appLauncherOpen = false
        }

        Rectangle {
            anchors.centerIn: parent
            color: Theme.crust
            // Responsive: a fraction of the screen, capped on large monitors.
            implicitHeight: Math.min(Config.launcher.maxHeight, window.height * Config.launcher.heightFraction)
            implicitWidth: Math.min(Config.launcher.maxWidth, window.width * Config.launcher.widthFraction)
            radius: Config.launcher.radius

            // Trap mouse clicks, to avoid bubbling up to the dismiss layer.
            MouseArea {
                anchors.fill: parent
            }

            Column {
                anchors.fill: parent

                // Search bar container.
                Item {
                    width: parent.width
                    height: Config.launcher.searchHeight

                    // The Visual Search Box Layout
                    Rectangle {
                        id: searchBoxContainer

                        anchors.fill: parent
                        anchors.margins: Config.launcher.padding // Padding around the search box
                        color: Theme.base
                        radius: Config.launcher.radius

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Config.launcher.padding
                            anchors.rightMargin: Config.launcher.padding
                            spacing: Config.launcher.padding // Between search icon and input.

                            // Search Glass System Icon
                            IconImage {
                                id: searchIcon

                                anchors.verticalCenter: parent.verticalCenter
                                asynchronous: true
                                implicitSize: Config.launcher.iconSize
                                source: "image://icon/edit-find"
                            }

                            // The Input Text Layer
                            TextField {
                                id: searchInput

                                anchors.verticalCenter: parent.verticalCenter
                                background: null
                                color: Theme.text
                                focus: true
                                font.family: Config.font.family
                                font.pixelSize: Config.font.pixelSize.xlarge
                                placeholderText: "Search apps..."
                                placeholderTextColor: Theme.text

                                onTextChanged: {
                                    resultsModel.clear();
                                    if (text.trim() !== "") {
                                        fetchApps(text);
                                    }
                                }

                                Keys.onPressed: event => {
                                    var isCtrl = (event.modifiers & Qt.ControlModifier);
                                    if (event.key === Qt.Key_Down || (isCtrl && event.key === Qt.Key_J)) {
                                        resultsList.currentIndex = Math.min(resultsList.count - 1, resultsList.currentIndex + 1);
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Up || (isCtrl && event.key === Qt.Key_K)) {
                                        resultsList.currentIndex = Math.max(0, resultsList.currentIndex - 1);
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        if (resultsList.count > 0 && resultsList.currentIndex >= 0) {
                                            launchApp(resultsModel.get(resultsList.currentIndex).exec);
                                        }
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Escape) {
                                        root.appLauncherOpen = false;
                                    }
                                }
                            }
                        }
                    }
                }

                // List of apps
                ListView {
                    id: resultsList

                    clip: true
                    leftMargin: Config.launcher.padding
                    model: resultsModel
                    rightMargin: Config.launcher.padding
                    height: parent.height - Config.launcher.searchHeight
                    width: parent.width
                    spacing: Config.launcher.padding // Vertical height between results.

                    // Explicitly transparent canvas for empty list areas
                    Rectangle {
                        color: "transparent"
                    }

                    delegate: ItemDelegate {
                        id: delegateItem

                        required property int index
                        required property var modelData

                        height: Config.launcher.rowHeight
                        width: resultsList.width - resultsList.leftMargin - resultsList.rightMargin

                        background: Rectangle {
                            readonly property bool isCurrent: resultsList.currentIndex === delegateItem.index
                            color: delegateItem.hovered ? Theme.base : "transparent"
                            border.color: isCurrent ? Theme.accent : "transparent"
                            border.width: isCurrent ? 1 : 0
                            radius: Config.launcher.radius
                        }

                        contentItem: Row {
                            anchors.fill: parent
                            anchors.leftMargin: Config.launcher.padding
                            anchors.rightMargin: Config.launcher.padding
                            spacing: Config.launcher.padding

                            IconImage {
                                id: appIcon

                                anchors.verticalCenter: parent.verticalCenter
                                asynchronous: true
                                implicitSize: Config.launcher.iconSize
                                source: Quickshell.iconPath(modelData.icon)
                                visible: modelData.icon !== ""
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Config.launcher.textSpacing

                                Text {
                                    color: Theme.text
                                    font.bold: true
                                    font.family: Config.font.family
                                    font.pixelSize: Config.font.pixelSize.large
                                    text: modelData.name
                                }

                                Text {
                                    color: Theme.accent
                                    font.family: Config.font.family
                                    font.pixelSize: Config.font.pixelSize.medium
                                    text: modelData.comment
                                    visible: text !== ""
                                }
                            }
                        }
                        onClicked: launchApp(modelData.exec)
                    }
                }
            }
        }
    }
}
