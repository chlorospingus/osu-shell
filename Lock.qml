import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

WlSessionLock {
    id: lock
    readonly property string bgPath: "assets/lockbg.jpg"
    readonly property string logoPath: "assets/logo.svg"
    function open() {
        locked = true
    }
    function close() {
        locked = false
    }
    locked: false
    surface: WlSessionLockSurface {
        id: surface
        color: "transparent"
        Item {
            id: content
            visible: true
            layer.enabled: true
            anchors.fill: parent
            Image {
                visible: false
                source: lock.bgPath
                anchors {
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }
                width: surface.width
                height: surface.height
                fillMode: Image.PreserveAspectCrop
            }
            Item {
                id: logo
                anchors {
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }
                width: Math.min(surface.width, surface.height) * 0.6 + borderWidth*2
                height: width

                readonly property real borderWidth: 24

                // Background
                Shape {
                    id: circleBg
                    layer.enabled: true
                    anchors.fill: parent
                    containsMode: Shape.FillContains
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        fillGradient: LinearGradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0; color: "#FB64A8" }
                            GradientStop { position: 1; color: "#CA5289" }
                        }
                        strokeWidth: 0
                        PathAngleArc {
                            moveToStart: true
                            centerX: logo.width/2
                            centerY: logo.height/2
                            radiusX: surface.height * 0.3 + logo.borderWidth/2
                            radiusY: radiusX
                            startAngle: 0
                            sweepAngle: 360
                        }
                    }
                }
                Item {
                    id: triangles
                    visible: false
                    anchors.fill: parent
                    clip: true
                    layer.enabled: true
                    Instantiator {
                        model: 24
                        delegate: Shape {
                            id: tri
                            property real x_size: Math.random() * logo.width + logo.width/8
                            property real y_size: x_size * 0.8

                            property real y_anim: 0
                            property real y_off: Math.random() * logo.height
                            x: Math.random() * (logo.width + x_size*2) - x_size
                            y: (y_anim + y_off) % (logo.height + y_size) - y_size
                            ShapePath {
                                strokeWidth: 2
                                strokeColor: "#9A4272"
                                fillColor: "transparent"

                                startX: tri.x_size/2
                                startY: 0
                                PathLine {x: 0; y: tri.y_size}
                                PathLine {x: tri.x_size; y: tri.y_size}
                                PathLine {x: tri.x_size/2; y: 0}
                            }
                            PropertyAnimation on y_anim {
                                from: logo.height + tri.y_size
                                running: lock.secure
                                to: 0
                                duration: Math.random() * 15000 + 12000
                                loops: Animation.Infinite
                            }
                        }
                        onObjectAdded: (index, obj) => obj.parent = triangles
                    }
                }
                ShaderEffect {
                    anchors.fill: parent
                    property var src: triangles
                    property var mask: circleBg
                    property bool fadeDirection: true
                    vertexShader: "default.vert.qsb"
                    fragmentShader: "trifade.frag.qsb"
                }

                // Group border and logo to shadow together
                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    // Circle border
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: "white"
                            strokeWidth: logo.borderWidth
                            PathAngleArc {
                                moveToStart: true
                                centerX: logo.width/2
                                centerY: logo.height/2
                                radiusX: surface.height * 0.3
                                radiusY: radiusX
                                startAngle: 0
                                sweepAngle: 360
                            }
                        }
                    }
                    // Logo
                    Image {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            horizontalCenter: parent.horizontalCenter
                            verticalCenterOffset: logo.height * 0.05 * -1
                        }
                        width: logo.width * 0.65
                        height: width
                        source: lock.logoPath
                        sourceSize {
                            width: width
                            height: height
                        }
                    }
                    layer.effect: MultiEffect {
                        anchors.fill: parent
                        blurMax: 48
                        shadowEnabled: true
                        shadowOpacity: 0.4
                        shadowVerticalOffset: logo.height * 0.015
                    }
                }
            }

            Rectangle {
                id: flash
                color: "white"
                anchors.fill: parent
                PropertyAnimation on opacity {
                    running: lock.secure
                    from: 1

                    to: 0
                    duration: 800
                }
            }
            Button {
                text: "unlock"
                onClicked: lock.locked = false
            }
            layer.effect: MultiEffect {
                anchors.fill: parent
                maskEnabled: true
                maskSource: contentMask
            }
        }

        Item {
            id: contentMask
            layer.enabled: true
            anchors.fill: parent
            visible: false
            Rectangle {
                x: 0
                y: surface.height/2 * (1 - progress)
                width: surface.width
                height: surface.height * progress
                property real progress: 0
                PropertyAnimation on progress {
                    running: lock.secure
                    from: 0
                    to: 1
                    duration: 800
                    easing.type: Easing.OutQuint
                }
            }
        }
    }
}
