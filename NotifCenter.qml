import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

PanelWindow {
    id: root
    anchors {
        top: true
        right: true
        bottom: true
    }
    visible: false
    exclusiveZone: 1
    implicitWidth: 500
    color: "transparent"

    function open() {
        root.visible = true;
    }
    function close() {
        exitAnim.start();
    }
    function toggle() {
        if (exitAnim.running) return;
        if (root.visible) close();
        else open();
    }

    required property var tracked

    Rectangle {
        color: "#222"
        anchors.fill: parent
        Text {
            id: title
            anchors {
                left: parent.left
                top: parent.top
                leftMargin: 12
                topMargin: 12
            }
            text: "Notifications"
            font.pixelSize: 20
            font.family: "Comfortaa"
            font.bold: true
            color: "white"
        }
        Button {
            anchors {
                top: parent.top
                right: parent.right
            }
            width: clearAllText.width + 32
            height: clearAllText.height + 30
            Text {
                id: clearAllText
                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    topMargin: 14
                    rightMargin: 16
                }
                color: "white"
                font.pixelSize: 16
                font.family: "Comfortaa"
                text: "Clear All"
            }
            onClicked: {while (root.tracked.values.length) {
                root.tracked.values[0].tracked = false;
            }}
            property var hover: HoverHandler { }
            background: Rectangle {
                anchors {
                    fill: parent
                    topMargin: 6
                    leftMargin: 8
                    bottomMargin: 6
                    rightMargin: 8
                }
                radius: 12
                color: parent.hover.hovered ? "#333" : "#222"
                Behavior on color { PropertyAnimation {
                    duration: 150
                }}
            }
        }
        ListView {
            anchors {
                fill: parent
                topMargin: 48
            }
            model: root.tracked
            spacing: 10
            delegate: Button {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: 12
                }
                height: notifContent.childrenRect.height + 32
                Image {
                    id: notifIcon
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: 12
                    }
                    width: 40
                    height: 40
                    source: Quickshell.iconPath(modelData.appIcon, true)
                }
                Column {
                    id: notifContent
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        topMargin: 16
                        leftMargin: 16 + (notifIcon.source == "" ? 0 : 44)
                        rightMargin: 16
                    }
                    spacing: 6
                    Text {
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        color: "white"
                        font.family: "Comfortaa"
                        font.pixelSize: 16
                        text: modelData.summary
                        elide: Text.ElideRight
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                    }
                    Text {
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        color: "white"
                        font.family: "Comfortaa"
                        font.pixelSize: 12
                        text: modelData.body
                        elide: Text.ElideRight
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                    }
                }
                background: Rectangle {
                    color: "#333"
                    radius: 12
                }
                onClicked: modelData.tracked = false
            }
        }
        transform: Translate {
            NumberAnimation on x {
                running: root.visible
                from: root.implicitWidth
                to: 0
                duration: 300
                easing.type: Easing.OutQuint
            }
            NumberAnimation on x {
                id: exitAnim
                to: root.implicitWidth
                duration: 300
                easing.type: Easing.InQuint
                onFinished: root.visible = false
            }
        }
    }
}
