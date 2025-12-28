import QtQml
import QtQml.Models
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root

    function hide() {
        visible = false 
        searchInput.text = ""
        list.visible = false
    }

    IpcHandler {
        target: "launcher"
        function show() { 
            visible = true 
            list.visible = true
        }
        function hide() {
            root.hide()
        }
        function toggle() { visible ? hide() : show() }
    }
    
    implicitWidth: 800
    exclusiveZone: 0
    focusable: true
    anchors {
        right: true
        top: true
        bottom: true
    }
    margins {
        top: {
            if (ToplevelManager.activeToplevel?.fullscreen) {
                return 0
            }
            return 36;
        }
    }
    readonly property int radius: 20
    readonly property var font: {
        family: "comfortaa"
    }
    readonly property int entry_height: 100
    color: "transparent"
    Item {
        anchors.fill: parent
        Keys.onPressed: (event) => {
            switch (event.key) {
                case Qt.Key_Down:
                    list.incrementCurrentIndex()
                    break;
                case Qt.Key_Up:
                    list.decrementCurrentIndex()
                    break;
                case Qt.Key_Escape:
                    root.visible = false
                    break;
                case Qt.Key_Return:
                    list.currentItem.execute()
                    root.hide()
            }
        }

        ListView {
            id: list
            spacing: 6
            anchors.fill: parent
            layer.enabled: true
            highlightMoveDuration: 150
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: 120
            preferredHighlightEnd: this.height/2 + 200
            property var currentApps: {
                let apps = Array.from(DesktopEntries.applications.values);
                apps.sort((a, b) => a.name.localeCompare(b.name));
                if (searchInput.text.length === 0) {
                    return apps;
                }
                return apps.filter(app => {
                    return app.name.toLowerCase().search(searchInput.text.toLowerCase()) != -1
                });
            }


            model: currentApps
            delegate: Item {
                height: entry_height
                width: root.width + 10
                property var leftMargin: (Math.pow(Math.abs(this.y - list.contentY - root.height/2), 1.8) / 1400)
                anchors {
                    left: parent?.left
                    leftMargin: leftMargin + selectedOffset
                }
                z: -index
                property real selectedOffset: ListView.isCurrentItem ? 16 : 64
                function execute() { modelData.execute() }
                Behavior on selectedOffset {
                    NumberAnimation {duration: 500; easing.type: Easing.OutQuint}
                }
                Button {
                    id: button
                    anchors {
                        fill: parent
                        // left: parent.left
                        // right: parent.right
                        // verticalCenter: parent.verticalCenter
                    }
                    onClicked: modelData.execute()
                    Component.onCompleted: {
                    }

                    // Calculate background color based on average color of icon
                    Canvas {
                        id: canvas
                        width: icon.width
                        height: icon.height
                        visible: false
                        onImageLoaded: {
                            console.log("loaded");
                            requestPaint();
                        }
                        Component.onCompleted: loadImage(button.iconPath)
                    }
                    property color color: {
                        if (!canvas.available) {
                            return null
                        }
                        const ctx = canvas.getContext("2d");
                        ctx.drawImage(button.iconPath, 0, 0, canvas.width, canvas.height)
                        const pixels = ctx.getImageData(0, 0, 100, 100).data;
                        let avg = [0, 0, 0, 0];
                        let count = 0;
                        for (let i = 0; i < pixels.length; i += 4) {
                            avg[0] += pixels[i+0];
                            avg[1] += pixels[i+1];
                            avg[2] += pixels[i+2];
                            count += pixels[i+3];
                        }
                        return Qt.rgba(avg[0]/count, avg[1]/count, avg[2]/count, 1);
                    }
                    property var iconPath: Quickshell.iconPath(modelData.icon)

                    // Background gradient
                    Rectangle {
                        anchors.fill: parent
                        radius: root.radius
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                color: Qt.darker(button.color, 16)
                                position: 0
                            }
                            GradientStop {
                                color: Qt.darker(button.color, 4)
                                position: 1
                            }
                        }
                    }

                    // Triangles
                    Item {
                        id: triangles
                        anchors.fill: parent
                        clip: true
                        layer.enabled: true
                        Instantiator {
                            model: 6
                            delegate: Shape {
                                id: tri
                                property real x_size: Math.random() * button.width/12 + button.width/10
                                property real y_size: x_size * Math.SQRT1_2

                                property real y_anim: 0
                                property real y_off: Math.random() * entry_height
                                x: Math.random() * (button.width + x_size*2) - x_size
                                y: (y_anim + y_off) % (entry_height + y_size) - y_size
                                ShapePath {
                                    strokeWidth: 2
                                    strokeColor: Qt.darker(button.color, 3)
                                    fillColor: "transparent"

                                    startX: tri.x_size/2
                                    startY: 0
                                    PathLine {x: 0; y: tri.y_size}
                                    PathLine {x: tri.x_size; y: tri.y_size}
                                    PathLine {x: tri.x_size/2; y: 0}
                                }
                                PropertyAnimation on y_anim {
                                    from: entry_height + tri.y_size
                                    to: 0
                                    duration: Math.random() * 12000 + 3500
                                    loops: Animation.Infinite
                                }
                            }
                            onObjectAdded: (index, obj) => obj.parent = triangles
                        }
                    }

                    Item {
                        anchors.fill: parent
                        clip: true
                        Image {
                            id: icon
                            source: button.iconPath
                            width: 80
                            height: width
                            anchors {
                                right: parent.right
                                rightMargin: 140
                                verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    // App name/description
                    Column {
                        anchors {
                            leftMargin: 12
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 4
                        Text {
                            text: modelData.name
                            font.family: root.font
                            font.pixelSize: 16
                            font.bold: true
                            color: "white"
                        }
                        Text {
                            visible: modelData.comment.length > 0
                            width: parent.parent.width - icon.anchors.rightMargin-icon.width - 20
                            text: modelData.comment
                            font.family: root.font
                            color: "white"
                            elide: Text.ElideRight
                        }
                    }

                    // Drop shadow
                    background: RectangularShadow {
                        anchors.fill: parent
                        radius: root.radius
                        blur: 8
                        spread: 4
                        opacity: 0.6
                    }
                }
            }
        }

        Item {
            id: searchBox
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                topMargin: 12
                rightMargin: 12
            }
            height: 80

            TextInput {
                z: 5
                id: searchInput
                font.family: root.font
                font.pixelSize: 16
                font.bold: true
                focus: true
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: 45
                }
                color: "white"
                onActiveFocusChanged: focus = true;
            }
            Rectangle {
                color: "#333"
                radius: root.radius
                anchors {
                    fill: parent
                    leftMargin: 35
                }
                Rectangle {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: parent.width - 60
                    radius: root.radius
                    color: "#222"
                }
                transform: [Shear {
                    xFactor: -0.15
                }]
                RectangularShadow {
                    z: -1
                    anchors.fill: parent
                    radius: root.radius
                    blur: 8
                    spread: 4
                    opacity: 0.6
                }
            }
            Image {
                source: Quickshell.iconPath("search")
                anchors {
                    right: searchBox.right
                    verticalCenter: searchBox.verticalCenter
                    rightMargin: 26
                }
                width: 24
                height: 24
            }
            Text {
                text: "Search apps..."
                anchors.fill: searchInput
                font: searchInput.font
                color: "#888"
                visible: searchInput.text.length === 0
            }
        }

    }
}
