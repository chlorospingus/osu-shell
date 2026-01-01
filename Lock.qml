import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

WlSessionLock {
    id: lock
    readonly property string bgPath: "assets/lockbg.jpg"
    readonly property string logoPath: "assets/logo.svg"

    function open() {
        locked = true
    }
    function close() {
        exitAnimation.start()
    }
    locked: false

    component OutQuint300: Behavior {
        enabled: lock.secure
        PropertyAnimation {
            duration: 500
            easing.type: Easing.OutQuint
        }
    }

    surface: WlSessionLockSurface {
        id: surface
        color: "transparent"
        Item {
            id: content
            anchors.fill: parent
            layer.enabled: true
            readonly property real angle: -1 * Math.tan(10 * Math.PI/180) // 10 degrees
            property bool idle: true
            Keys.onReturnPressed: {
                idle = false
                if (!pam.active) {
                    pam.start()
                }
            }
            Image {
                source: lock.bgPath
                anchors {
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }
                width: surface.width
                height: surface.height
                fillMode: Image.PreserveAspectCrop
                PropertyAnimation on opacity {
                    running: exitAnimation.running
                    from: 1
                    to: 0
                    duration: 800
                    easing.type: Easing.Linear
                }
            }

            Item {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                height: logo.height * 0.3
                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    height: parent.height * !content.idle
                    opacity: !content.idle
                    OutQuint300 on height {}
                    OutQuint300 on opacity {}
                    color: "#323232"
                    RectangularShadow {
                        anchors {
                            fill: parent
                            leftMargin: -blur
                            rightMargin: -blur
                        }
                        z: -1
                        blur: 12
                        opacity: 0.6
                    }
                }
                Item { 
                    anchors.fill: parent
                    clip: true
                    Rectangle {
                        antialiasing: true
                        anchors {
                            top: inputBox.top
                            left: inputBox.right
                            bottom: inputBox.bottom
                        }
                        width: !content.idle * surface.width * 0.05
                        color: "#EEAA00"
                        transform: Shear { xFactor: content.angle }
                        ColorAnimation on color {
                            onStarted: lockIcon.source = "assets/unlocked.svg"
                            running: exitAnimation.running
                            from: Qt.lighter("#A5CE00", 2.5)
                            to: "#A5CE00"
                            duration: 400
                        }
                        SequentialAnimation on color {
                            id: failAnimation
                            running: false
                            ColorAnimation {
                                from: Qt.lighter("#CC3378", 2.5)
                                to: "#CC3378"
                                duration: 400
                            }
                            ColorAnimation { duration: 1500 }
                            ColorAnimation {
                                to: "#EEAA00"
                                duration: 600
                                easing.type: Easing.InOutQuint
                            }
                        }
                        Image {
                            id: lockIcon
                            anchors {
                                verticalCenter: parent.verticalCenter
                                horizontalCenter: parent.horizontalCenter
                                horizontalCenterOffset: content.angle * height * 0.5
                            }
                            width: parent.width/2
                            height: parent.width/2
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                blurMax: 4
                                shadowEnabled: true
                                shadowOpacity: 0.4
                                shadowVerticalOffset: height * 0.04
                            }
                            source: "assets/locked.svg"
                            fillMode: Image.Pad
                            sourceSize {
                                width: width
                                height: height
                            }
                            transform: Shear { xFactor: content.angle * -1 }
                        }
                    }
                    RectangularShadow {
                        anchors {
                            top: inputBox.top
                            right: inputBox.right
                            bottom: inputBox.bottom
                            topMargin: -blur
                            bottomMargin: -blur
                        }
                        blur: 16
                        width: blur
                        opacity: 0.8
                        transform: Shear { xFactor: content.angle }
                    }
                    Rectangle {
                        id: inputBox
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                        }
                        antialiasing: true
                        x: surface.width/3 + (surface.width/4) * content.idle
                        width: (surface.width/3) * !content.idle
                        OutQuint300 on x {}
                        OutQuint300 on width {}
                        color: "#5F46BB"
                        transform: Shear { xFactor: content.angle }
                    }
                    Column {
                        anchors {
                            verticalCenter: inputBox.verticalCenter
                            verticalCenterOffset: pamMessage.height * 1/3
                            left: inputBox.right
                            leftMargin: surface.width/3 * -1 + logo.width * 0.29
                        }
                        width: inputBox.width
                        clip: true
                        spacing: 10
                        Text {
                            id: prompt
                            anchors.left: parent.left
                            anchors.leftMargin: passInputBg.height * 0.15/2
                            text: "o shit waddup!"
                            color: "white"
                            font {
                                family: "comfortaa"
                                pixelSize: 20
                            }
                        }
                        Rectangle {
                            id: passInputBg
                            anchors.left: parent.left
                            anchors.leftMargin: height * 0.15
                            radius: 12
                            color: Qt.darker(inputBox.color, 1.5)
                            height: prompt.font.pixelSize + 20
                            width: surface.width * 0.18
                            transform: Shear { xFactor: content.angle }
                            TextInput {
                                id: passInput
                                anchors.fill: passInputBg
                                anchors.margins: 10
                                focus: !pam.active
                                font: prompt.font
                                color: "white"
                                echoMode: TextInput.Password
                                transform: Shear { xFactor: content.angle * -1 }
                                onTextChanged: content.idle = !text.length
                            }
                        }
                        Text {
                            id: pamMessage
                            text: pam.responseRequired ? "" : pam.message
                            height: 20
                            width: 1
                            color: "white"
                            font: {
                                family: prompt.family
                                pixelSize: 12
                            }
                        }
                    }
                }
            }

            Item {
                id: logo
                anchors {
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }
                width: Math.min(surface.width, surface.height) * 0.6 
                height: width
                layer.enabled: true
                layer.smooth: true

                readonly property real borderWidth: width * 0.04

                transform: [
                    Scale {
                        origin {x: logo.width/2; y: logo.height/2 }
                        xScale: (content.idle ? 1.0 : 0.5)
                        yScale: xScale
                        OutQuint300 on xScale {}
                    },
                    Translate {
                        x: content.idle ? 0 : (surface.width/6 * -1)
                        OutQuint300 on x {}
                    }
                ]

                // Background
                Shape {
                    id: circleBg
                    layer.enabled: true
                    anchors.fill: parent
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
                            radiusX: logo.width * 0.45 + logo.borderWidth/2
                            radiusY: radiusX
                            startAngle: 0
                            sweepAngle: 360
                        }
                    }
                }
                Item {
                    id: triangles
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
                                strokeWidth: content.idle ? 2 : 4
                                strokeColor: "#9A4272"
                                fillColor: "transparent"
                                capStyle: ShapePath.FlatCap
                                joinStyle: ShapePath.MiterJoin

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
                    layer.effect: ShaderEffect {
                        property var src: triangles
                        property var mask: circleBg
                        property bool fadeDirection: true
                        vertexShader: "default.vert.qsb"
                        fragmentShader: "trifade.frag.qsb"
                    }
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
                                radiusX: logo.height * 0.45
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
                            verticalCenterOffset: logo.height * 0.065 * -1
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
                    from: 1
                    to: 0
                    easing.type: Easing.Linear
                    duration: 800
                }
            }
            layer.effect: MultiEffect {
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
                PropertyAnimation on progress {
                    id: exitAnimation
                    duration: 800
                    running: false
                    from: 1
                    to: 0
                    easing.type: Easing.OutQuart
                    onStopped: lock.locked = false
                }
            }
        }
        PamContext {
            id: pam
            config: "pam.conf"
            configDirectory: "."
            onPamMessage: if (this.responseRequired) this.respond(passInput.text)
            onCompleted: result => { switch (result) {
                case PamResult.Success:
                    exitAnimation.start();
                    break;
                case PamResult.Failed:
                case PamResult.Error:
                case PamResult.MaxTries:
                    passInput.text = "";
                    content.idle = false;
                    failAnimation.start();
                    break;
            }}
        }
    }
}
