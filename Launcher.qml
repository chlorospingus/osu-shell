import QtQml
import QtQml.Models
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

PanelWindow {
    id: launcher

    function close() {
        visible = false 
        list.visible = false
        searchInput.text = ""
    }
    function open() { 
        visible = true 
        list.visible = true
    }

    implicitWidth: 800
    exclusiveZone: 0
    focusable: true
    anchors {
        right: true
        top: true
        bottom: true
    }
    visible: false

    readonly property int radius: 20
    readonly property int entry_height: 100
    property var currentApps: {
        let apps = Array.from(DesktopEntries.applications.values);
        if (searchInput.text.length === 0) {
            apps.sort((a, b) => a.name.localeCompare(b.name));
            return apps;
        }
        apps = apps.filter(app => 
            app.name.toLowerCase().search(searchInput.text.toLowerCase()) !== -1
        );
        return apps
    }
    property string lastLaunched: ""

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
                    launcher.visible = false
                    break;
                case Qt.Key_Return:
                    list.currentItem.execute()
            }
        }

        ListView {
            id: list
            spacing: 6
            anchors.fill: parent
            highlightMoveDuration: 150
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: 120
            preferredHighlightEnd: this.height/2

            model: ScriptModel { values: currentApps; objectProp: "id" }
            delegate: Button {
                height: entry_height
                width: launcher.width + 10
                property var leftMargin: (Math.pow(Math.abs(this.y - list.contentY - launcher.height/2), 1.8) / 1400)
                anchors {
                    left: parent?.left
                    leftMargin: leftMargin + selectedOffset
                }
                z: -index
                property real selectedOffset: ListView.isCurrentItem ? 16 : 64
                function execute() {
                    modelData.execute() 
                    launcher.lastLaunched = modelData.id
                    launcher.close()
                }
                Behavior on selectedOffset {
                    NumberAnimation {duration: 500; easing.type: Easing.OutQuint}
                }
                id: button
                onClicked: execute()

                // Calculate background color based on average color of icon
                Canvas {
                    id: canvas
                    width: icon.width/2
                    height: icon.height/2
                    visible: false
                    onImageLoaded: {
                        requestPaint();
                    }
                    Component.onCompleted: loadImage(button.iconPath)
                }
                property var color: {
                    if (!canvas.available) {
                        return null
                    }
                    const ctx = canvas.getContext("2d");
                    ctx.drawImage(button.iconPath, 0, 0, canvas.width, canvas.height)
                    const pixels = ctx.getImageData(0, 0, 100, 100).data;
                    let avg = [0, 0, 0, 0];
                    let count = 0;
                    for (let i = 0; i < pixels.length; i += 4) {
                        let c_max = Math.max(pixels[i+0], pixels[i+1], pixels[i+2]);
                        let c_min = Math.min(pixels[i+0], pixels[i+1], pixels[i+2]);
                        let saturation = c_max === 0 ? 0 : (c_max - c_min) / c_max;
                        avg[0] += pixels[i+0] * saturation;
                        avg[1] += pixels[i+1] * saturation;
                        avg[2] += pixels[i+2] * saturation;
                        count += pixels[i+3] * saturation;
                    }
                    return Qt.rgba(avg[0]/count, avg[1]/count, avg[2]/count, 1);
                }
                property var iconPath: Quickshell.iconPath(modelData.icon)

                // Background gradient
                Rectangle {
                    anchors.fill: parent
                    radius: launcher.radius
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
                    visible: false
                    anchors.fill: parent
                    clip: true
                    layer.enabled: true
                    Instantiator {
                        model: 6
                        delegate: Shape {
                            id: tri
                            property real x_size: Math.random() * button.width/12 + button.width/10
                            property real y_size: x_size * 0.8

                            property real y_anim: 0
                            property real y_off: Math.random() * entry_height
                            x: Math.random() * (button.width + x_size*2) - x_size
                            y: (y_anim + y_off) % (entry_height + y_size) - y_size
                            ShapePath {
                                strokeWidth: 2
                                strokeColor: Qt.darker(button.color, 2.5)
                                fillColor: "transparent"

                                startX: tri.x_size/2
                                startY: 0
                                PathLine {x: 0; y: tri.y_size}
                                PathLine {x: tri.x_size; y: tri.y_size}
                                PathLine {x: tri.x_size/2; y: 0}
                            }
                            PropertyAnimation on y_anim {
                                from: entry_height + tri.y_size
                                running: launcher.visible
                                to: 0
                                duration: Math.random() * 12000 + 5000
                                loops: Animation.Infinite
                            }
                        }
                        onObjectAdded: (index, obj) => obj.parent = triangles
                    }
                }
                Rectangle {
                    id: triMask
                    x: triangles.x
                    y: triangles.y
                    width: triangles.width
                    height: triangles.height
                    visible: false
                    layer.enabled: true
                    radius: launcher.radius
                }
                ShaderEffect {
                    anchors.fill: triangles
                    property var src: triangles
                    property var mask: triMask
                    property bool fadeDirection: false
                    vertexShader: "default.vert.qsb"
                    fragmentShader: "trifade.frag.qsb"

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
                    radius: launcher.radius
                    blur: 8
                    spread: 4
                    opacity: 0.6
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
                radius: launcher.radius
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
                    radius: launcher.radius
                    color: "#222"
                }
                transform: [Shear {
                    xFactor: -0.15
                }]
                RectangularShadow {
                    z: -1
                    anchors.fill: parent
                    radius: launcher.radius
                    blur: 8
                    spread: 4
                    opacity: 0.6
                }
            }
            Text {
                text: "Search apps..."
                anchors.fill: searchInput
                font: searchInput.font
                color: "#888"
                visible: searchInput.text.length === 0
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
        }
    }
}
