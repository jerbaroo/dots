import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

import "config.js" as Config
import "notifications.js" as Notifications
import Theme 0.1

Scope {
    id: root

    property bool centerOpen: false
    property bool doNotDisturb: false

    ListModel {
        id: history
    }

    // Re-usable notification card.
    component NotificationCard: Rectangle {
        id: card

        required property string appName
        required property bool borderEnabled
        required property string imageSource
        required property string body
        required property string summary
        required property string time
        required property int urgency
        property var dismissAction: function () {}
        // NotificationActions to show as buttons. Clicking a button invokes
        // the action and then dismisses the card.
        property var actions: []

        Layout.fillWidth: true
        implicitHeight: mainLayout.implicitHeight + 32
        border.color: urgency === NotificationUrgency.Critical ? Theme.red : Theme.base
        border.width: borderEnabled ? 2 : 0
        color: Theme.crust
        radius: 8

        Rectangle {
            color: Theme.accent
            height: 1
            opacity: 0.2
            visible: !card.borderEnabled
            width: parent.width
        }

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            // Notification header.
            RowLayout {
                Layout.fillWidth: true

                // App name.
                Text {
                    Layout.fillWidth: true
                    color: card.urgency === NotificationUrgency.Critical ? Theme.red : Theme.accent
                    font.family: Config.font.family
                    font.pixelSize: Config.font.pixelSize.small
                    font.bold: true
                    text: card.appName
                }

                // Notification time.
                Text {
                    color: Theme.accent
                    font.family: Config.font.family
                    font.pixelSize: Config.font.pixelSize.xsmall
                    text: card.time
                }

                // Close button.
                Rectangle {
                    color: closeMouseArea.containsMouse ? Theme.red : "transparent"
                    height: 24
                    width: 24
                    radius: 12

                    Text {
                        anchors.centerIn: parent
                        color: closeMouseArea.containsMouse ? Theme.crust : Theme.accent
                        font.family: Config.font.family
                        font.pixelSize: Config.font.pixelSize.small
                        font.bold: true
                        text: "X"
                    }

                    MouseArea {
                        id: closeMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: card.dismissAction()
                    }
                }
            }

            // Notification content.
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Image {
                    Layout.preferredHeight: 64
                    Layout.preferredWidth: 64
                    Layout.alignment: Qt.AlignTop
                    fillMode: Image.PreserveAspectFit
                    visible: card.imageSource !== ""
                    source: card.imageSource
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop

                    // Notification title.
                    Text {
                        Layout.fillWidth: true
                        color: Theme.yellow
                        font.bold: true
                        font.family: Config.font.family
                        font.pixelSize: Config.font.pixelSize.medium
                        text: card.summary
                        visible: text !== ""
                        wrapMode: Text.Wrap
                    }

                    // Notification body. May contain markup such as
                    // hyperlinks, per the freedesktop notification spec.
                    Text {
                        Layout.fillWidth: true
                        color: Theme.text
                        font.family: Config.font.family
                        font.pixelSize: Config.font.pixelSize.small
                        linkColor: Theme.accent
                        text: card.body
                        textFormat: Text.StyledText
                        visible: text !== ""
                        wrapMode: Text.Wrap
                        onLinkActivated: link => Qt.openUrlExternally(link)

                        HoverHandler {
                            cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }
                    }
                }
            }

            // Notification actions.
            Flow {
                Layout.fillWidth: true
                spacing: 8
                visible: card.actions.length > 0

                Repeater {
                    model: card.actions

                    delegate: Rectangle {
                        id: actionButton

                        required property var modelData

                        color: actionMouseArea.containsMouse ? Theme.accent : Theme.surface0
                        implicitHeight: actionText.implicitHeight + 12
                        implicitWidth: actionText.implicitWidth + 24
                        radius: 8

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            color: actionMouseArea.containsMouse ? Theme.crust : Theme.text
                            font.family: Config.font.family
                            font.pixelSize: Config.font.pixelSize.small
                            text: actionButton.modelData.text
                        }

                        MouseArea {
                            id: actionMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                actionButton.modelData.invoke();
                                card.dismissAction();
                            }
                        }
                    }
                }
            }
        }
    }

    // Receive notifications and push them to 'history'.
    NotificationServer {
        id: server

        actionsSupported: true
        bodySupported: true
        imageSupported: true
        onNotification: n => {
            const historyEntry = () => ({
                appName: n.appName || "Unknown",
                body: n.body || "",
                imageSource: n.image || n.appIcon || "",
                notificationId: n.id,
                summary: n.summary || "",
                time: Qt.formatDateTime(new Date(), "HH:mm"),
                urgency: n.urgency !== undefined ? n.urgency : 1
            });
            const historyIndex = () => {
                for (let i = 0; i < history.count; i++) {
                    if (history.get(i).notificationId === n.id) {
                        return i;
                    }
                }
                return -1;
            };
            const existing = historyIndex();
            if (existing >= 0) {
                history.set(existing, historyEntry());
            } else {
                history.insert(0, historyEntry());
            }
            // Notifications may be replaced in-place (same id, new content),
            // in which case the server updates 'n' rather than re-emitting.
            const updateHistory = () => {
                const i = historyIndex();
                if (i >= 0) {
                    history.set(i, historyEntry());
                }
            };
            n.appNameChanged.connect(updateHistory);
            n.summaryChanged.connect(updateHistory);
            n.bodyChanged.connect(updateHistory);
            n.imageChanged.connect(updateHistory);
            n.appIconChanged.connect(updateHistory);
            n.urgencyChanged.connect(updateHistory);
            n.tracked = true;
        }
    }

    IpcHandler {
        target: "notifications"
        function getCount(): int {
            return history.count;
        }
        function getDoNotDisturb(): bool {
            return root.doNotDisturb;
        }
        function setDoNotDisturbDisabled(): void {
            root.doNotDisturb = false;
        }
        function setDoNotDisturbEnabled(): void {
            root.doNotDisturb = true;
        }
        function setNotificationCenterClosed(): void {
            root.centerOpen = false;
        }
        function setNotificationCenterOpen(): void {
            root.centerOpen = true;
        }
        function toggleDoNotDisturb(): void {
            root.doNotDisturb = !root.doNotDisturb;
        }
        function toggleNotificationCenter(): void {
            root.centerOpen = !root.centerOpen;
        }
    }

    // List of notifications.
    PanelWindow {
        anchors {
            right: true
            top: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitHeight: popupColumn.implicitHeight
        implicitWidth: 512
        margins {
            right: 32
            top: 32
        }
        visible: !root.centerOpen && !root.doNotDisturb

        ColumnLayout {
            id: popupColumn
            width: parent.width
            spacing: 16

            Repeater {
                // Only notifications "currently" popping up on the screen.
                // Unlike 'history', which is our in-memory log.
                model: server.trackedNotifications

                delegate: NotificationCard {
                    id: popupCard

                    required property var modelData

                    appName: modelData.appName || "Unknown"
                    body: modelData.body || ""
                    borderEnabled: true
                    imageSource: modelData.image || modelData.appIcon || ""
                    summary: modelData.summary || ""
                    time: Qt.formatDateTime(new Date(), "HH:mm")
                    urgency: modelData.urgency || 1

                    // Dismissing from popup tells the server to close it
                    dismissAction: () => {
                        modelData.dismiss();
                    }

                    actions: Notifications.buttonActions(modelData)

                    Timer {
                        id: dismissTimer
                        running: urgency !== NotificationUrgency.Critical
                        interval: Notifications.timeout
                        onTriggered: dismissAction()
                    }

                    // Keep the popup around when it is replaced in-place.
                    Connections {
                        target: popupCard.modelData
                        function onSummaryChanged() {
                            popupCard.refresh();
                        }
                        function onBodyChanged() {
                            popupCard.refresh();
                        }
                    }

                    function refresh() {
                        time = Qt.formatDateTime(new Date(), "HH:mm");
                        dismissTimer.restart();
                    }
                }
            }
        }
    }

    // Notification center history view.
    PanelWindow {
        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: root.centerOpen // Required for the keyboard shortcut.
        visible: root.centerOpen

        MouseArea {
            anchors.fill: parent
            onClicked: root.centerOpen = false
        }

        Shortcut {
            enabled: root.centerOpen
            onActivated: {
                root.centerOpen = false;
            }
            sequence: "Escape"
        }

        Rectangle {
            anchors {
                margins: 16
                right: parent.right
                top: parent.top
            }
            border.color: Theme.accent
            border.width: 2
            color: Theme.crust
            implicitHeight: centerColumn.implicitHeight + 32
            implicitWidth: 512
            radius: 10

            // Trap mouse clicks, to avoid bubbling up to the dismiss layer.
            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: centerColumn
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true

                    // Notification center title.
                    Text {
                        Layout.fillWidth: true
                        color: Theme.accent
                        font.bold: true
                        font.family: Config.font.family
                        font.pixelSize: Config.font.pixelSize.medium
                        text: "Notifications"
                    }

                    // Do not disturb toggle.
                    Rectangle {
                        color: dndToggleMouseArea.containsMouse ? Theme.surface0 : "transparent"
                        implicitHeight: dndToggle.implicitHeight + 16
                        implicitWidth: dndToggle.implicitWidth + 16
                        radius: 8

                        Text {
                            id: dndToggle

                            anchors.centerIn: parent
                            font.family: Config.font.family
                            font.pixelSize: Config.font.pixelSize.medium
                            text: root.doNotDisturb ? "🔕" : "🔔"
                        }

                        MouseArea {
                            id: dndToggleMouseArea

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: () => {
                                root.doNotDisturb = !root.doNotDisturb;
                            }
                        }
                    }

                    // Clear all button.
                    Rectangle {
                        color: clearAllMouseArea.containsMouse ? Theme.red : "transparent"
                        implicitHeight: clearAllText.implicitHeight + 8
                        implicitWidth: clearAllText.implicitWidth + 16
                        radius: 8
                        visible: history.count > 0

                        Text {
                            id: clearAllText
                            anchors.centerIn: parent
                            color: clearAllMouseArea.containsMouse ? Theme.crust : Theme.accent
                            font.family: Config.font.family
                            font.pixelSize: Config.font.pixelSize.small
                            text: "Clear all"
                        }

                        MouseArea {
                            id: clearAllMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: () => {
                                history.clear();
                                // We need to also dismiss the tracked
                                // notifications, otherwise when we close the
                                // notification center the notifications will
                                // re-appear as floating.
                                while (server.trackedNotifications.values.length > 0) {
                                    server.trackedNotifications.values[0].dismiss();
                                }
                                root.centerOpen = false;
                            }
                        }
                    }
                }

                Repeater {
                    model: history

                    delegate: NotificationCard {
                        id: historyCard

                        required property int index
                        required property int notificationId

                        // The still-alive notification behind this history entry,
                        // or null once the server has closed it. Kept alive via
                        // 'n.tracked = true' so its actions remain invokable.
                        readonly property var trackedNotification: {
                            let values = server.trackedNotifications.values;
                            for (let i = 0; i < values.length; i++) {
                                if (values[i].id === notificationId) {
                                    return values[i];
                                }
                            }
                            return null;
                        }

                        borderEnabled: false
                        // Actions are only available while the notification is
                        // still tracked by the server.
                        actions: Notifications.buttonActions(historyCard.trackedNotification)
                        dismissAction: () => {
                            historyCard.trackedNotification?.dismiss();
                            // Update the state before the delegate is destroyed.
                            if (history.count <= 1) {
                                root.centerOpen = false;
                            }
                            history.remove(index);
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    color: Theme.accent
                    font.family: Config.font.family
                    font.pixelSize: Config.font.pixelSize.small
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 0.7
                    text: "No new notifications."
                    visible: history.count === 0
                }
            }
        }
    }
}
