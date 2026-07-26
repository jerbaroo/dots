import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets

import "../config.js" as Config
import "notifications.js" as Notifications

Scope {
    id: root

    property bool centerOpen: false
    property bool doNotDisturb: false
    readonly property int unreadCount: history.count

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
        // Card background. Opaque by default (floating popup toasts, which have
        // no blur behind them); the notification center overrides it to
        // transparent so its cards read as part of the frosted glass panel.
        property color background: Config.crust

        Layout.fillWidth: true
        implicitHeight: mainLayout.implicitHeight + 32
        border.color: urgency === NotificationUrgency.Critical ? Config.red : Config.accent
        border.width: borderEnabled ? Config.borderSize : 0
        color: background
        radius: Config.notification.radius

        Rectangle {
            color: Config.accent
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
                    color: card.urgency === NotificationUrgency.Critical ? Config.red : Config.accent
                    font.family: Config.font.family
                    font.pixelSize: Config.font.pixelSize.small
                    font.bold: true
                    text: card.appName
                }

                // Notification time.
                Text {
                    color: Config.accent
                    font.family: Config.font.family
                    font.pixelSize: Config.font.pixelSize.xsmall
                    text: card.time
                }

                // Close button.
                Rectangle {
                    color: closeMouseArea.containsMouse ? Config.red : "transparent"
                    height: 24
                    width: 24
                    radius: 12

                    Text {
                        anchors.centerIn: parent
                        color: closeMouseArea.containsMouse ? Config.crust : Config.accent
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
                        color: Config.yellow
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
                        color: Config.text
                        font.family: Config.font.family
                        font.pixelSize: Config.font.pixelSize.small
                        linkColor: Config.accent
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

                        color: actionMouseArea.containsMouse ? Config.accent : Config.surface0
                        implicitHeight: actionText.implicitHeight + 12
                        implicitWidth: actionText.implicitWidth + 24
                        radius: Config.notification.radius

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            color: actionMouseArea.containsMouse ? Config.crust : Config.text
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
        // Same blur namespace as the notification center, so the popup toasts
        // get the same liquid-glass blur (see hyprland.nix).
        WlrLayershell.namespace: "quickshell-notifications"

        anchors {
            right: true
            top: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitHeight: popupColumn.implicitHeight
        implicitWidth: 512
        margins {
            right: Config.notification.right
            // Clear the menu bar (see config.js), rather than overlapping it.
            top: Config.notification.top
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
                    // Frosted glass, matching the bar and notification center;
                    // the window's blur namespace shows through.
                    background: Config.glass
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
        // Own layer namespace so Hyprland's blur rule (see hyprland.nix) applies
        // the same liquid-glass blur as the menu bar and launcher.
        WlrLayershell.namespace: "quickshell-notifications"

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
                right: parent.right
                rightMargin: Config.notification.right
                top: parent.top
                // Clear the menu bar (see config.js), rather than overlapping it.
                topMargin: Config.notification.top
            }
            border.color: Config.accent
            border.width: Config.borderSize
            // Near-transparent glass, matching the bar and launcher, so the
            // Hyprland blur rule shows through. The full-screen dismiss layer
            // stays fully transparent so only this panel is blurred.
            color: Config.glass
            implicitHeight: centerColumn.implicitHeight + 32
            implicitWidth: 512
            radius: Config.notification.radius

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
                        color: Config.accent
                        font.bold: true
                        font.family: Config.font.family
                        font.pixelSize: Config.font.pixelSize.medium
                        text: "Notifications"
                    }

                    // Do not disturb toggle. Same icon as the bar's
                    // notifications module.
                    Rectangle {
                        color: dndToggleMouseArea.containsMouse ? Config.surface0 : "transparent"
                        implicitHeight: dndToggle.implicitHeight + 16
                        implicitWidth: dndToggle.implicitWidth + 16
                        radius: Config.notification.radius

                        IconImage {
                            id: dndToggle

                            anchors.centerIn: parent
                            implicitSize: Config.font.pixelSize.medium
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                brightness: 1
                                colorization: 1
                                colorizationColor: Config.text
                            }
                            source: Quickshell.iconPath(root.doNotDisturb ? "notifications-disabled-symbolic" : "notifications-symbolic")
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
                        color: clearAllMouseArea.containsMouse ? Config.red : "transparent"
                        implicitHeight: clearAllText.implicitHeight + 8
                        implicitWidth: clearAllText.implicitWidth + 16
                        radius: Config.notification.radius
                        visible: history.count > 0

                        Text {
                            id: clearAllText
                            anchors.centerIn: parent
                            color: clearAllMouseArea.containsMouse ? Config.crust : Config.accent
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
                        // Transparent so the card is part of the frosted glass
                        // panel rather than an opaque block on top of it.
                        background: "transparent"
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
                    color: Config.accent
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
