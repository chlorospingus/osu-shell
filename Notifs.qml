import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Effects

PanelWindow {
    id: root
    visible: false
    anchors {
        top: true
        right: true
    }
    color: "transparent"
    aboveWindows: true
    implicitWidth: 500
    implicitHeight: 200
    focusable: false

    property var font: { family: "Comfortaa" }

    Component {
        id: notifPopup
        Rectangle {
            id: notifRect
            required property var modelData

            y: {
                let res = 0;
                for (let i = 0; notifsList.children[i] && notifsList.children[i] != this; i++) {
                    if (!notifsList.children[i].exiting) res += notifsList.children[i].height + 10;
                }
                return res;
            }
            Behavior on y { NumberAnimation {
                duration: 300
                easing.type: Easing.InOutCubic
            }}
            property bool exiting: false
            width: parent?.width ?? 0
            height: notifContent.childrenRect.height + 32
            radius: 20
            color: "#181818"

            RectangularShadow {
                z: -1
                anchors.fill: parent
                blur: 12
                radius: parent.radius
            }
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
            NumberAnimation on x {
                running: root.visible
                from: root.width
                to: 0
                duration: 300
                easing.type: Easing.OutBack
                easing.overshoot: 0.8
            }
            NumberAnimation on x {
                id: exitAnim
                running: false
                to: parent.parent.width
                duration: 300 
                easing.type: Easing.InCubic
                onStarted: exiting = true
                onFinished: {
                    if (notifsList.children.length === 1) {
                        root.visible = false
                        root.implicitHeight = 200;
                    }
                    notifRect.destroy();
                }
            }
            Timer {
                running: true
                repeat: false
                interval: 5000
                onTriggered: exitAnim.start()
            }
            Component.onCompleted: {
                let sumHeight = 40;
                for (const notif of notifsList.children) {
                    sumHeight += notif.height + 6;
                }
                root.implicitHeight = Math.max(root.implicitHeight, sumHeight);
            }
        }
    }

    Item {
        id: notifsList
        anchors {
            fill: parent
            margins: 12
            leftMargin: 64
        }
    }

    function notify(notif) {
        if (notif.lastGeneration) return
        root.visible = true;
        notifPopup.createObject(notifsList, {modelData: notif});
    }
}
