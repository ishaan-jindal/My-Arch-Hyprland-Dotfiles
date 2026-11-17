// sacred — dark Material You SDDM greeter, frosted right dock.
// Follows the wallpaper: theme.conf is rendered from theme.conf.template
// by wallpaper_switch.sh (matugen) on every switch. Do not edit theme.conf.

import QtQuick
import QtQuick.Layouts
// Controls is only imported for its layout-adjacent types; aliased so its
// Button never clashes with the SddmComponents Button used below.
import QtQuick.Controls as QQC
import QtQuick.Effects
import SddmComponents 2.0

Rectangle {
    id: root
    color: bgColor

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    // Single-session greeter: Hyprland only. SessionName wins when the
    // deployed theme.conf sets it, then autodetect, then lastIndex.
    property string sessionName: config.SessionName ? config.SessionName : "hyprland"
    // Single-user greeter: no username picker. FixedUser wins when the
    // deployed theme.conf sets it, then the last login name, then "sacred".
    property string fixedUser: config.FixedUser ? config.FixedUser : (userModel.lastUser ? userModel.lastUser : "sacred")
    property string avatarFile: config.AvatarFile ? config.AvatarFile : "avatar.jpg"
    property color mainColor: config.MainColor ? config.MainColor : "#e6e6e6"
    property color mutedColor: config.MutedColor ? config.MutedColor : "#8b8f98"
    property color accentColor: config.AccentColor ? config.AccentColor : "#ffffff"
    property color accentSoft: config.AccentSoft ? config.AccentSoft : "#8b8f98"
    property color bgColor: config.BackgroundColor ? config.BackgroundColor : "#0a0a0c"
    property color fieldColor: config.FieldColor ? config.FieldColor : "#0a0a0c"
    property color borderColor: config.BorderColor ? config.BorderColor : "#3a3f4b"
    property color criticalColor: config.CriticalColor ? config.CriticalColor : "#ff5f5f"
    property color loginTextColor: config.LoginTextColor ? config.LoginTextColor : "#0a0a0c"
    property string fontName: config.Font ? config.Font : "JetBrainsMono Nerd Font Mono"
    property int cornerRadius: config.Radius ? config.Radius : 10
    // Visible dock width, clamped HiDPI-safe; the dock body extends dockRadius
    // past the screen edge so the left corners get a matching radius and the
    // right stays flush.
    property real dockWidth: Math.min(420, Math.max(300, width - 32))
    property real dockX: width - dockWidth
    property int dockRadius: root.cornerRadius

    TextConstants {
        id: textConstants
    }

    function doLogin() {
        errorMessage.text = ""
        sddm.login(root.fixedUser, passField.text, root.resolveSessionIndex())
    }

    // Session roles are only readable inside a delegate, so a hidden
    // Instantiator mirrors Name/File per row for the lookup below.
    function resolveSessionIndex() {
        var want = root.sessionName.toLowerCase()
        for (var i = 0; i < sessionProbe.count; i++) {
            var o = sessionProbe.objectAt(i)
            if (o && ((o.probeName + " " + o.probeFile).toLowerCase().indexOf(want) !== -1)) {
                return i
            }
        }
        return sessionModel.lastIndex
    }

    function updateClock() {
        var d = new Date()
        clockText.text = Qt.formatTime(d, "hh:mm")
        dateText.text = Qt.formatDate(d, "dddd, d MMMM")
    }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            errorMessage.color = root.accentColor
            errorMessage.text = textConstants.loginSucceeded
        }
        function onLoginFailed() {
            passField.text = ""
            passField.focus = true
            errorMessage.color = root.criticalColor
            errorMessage.text = textConstants.loginFailed
        }
        function onInformationMessage(message) {
            errorMessage.color = root.criticalColor
            errorMessage.text = message
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateClock()
    }

    // Wallpaper stays sharp and full-bleed: 1.0x, async, cached, fallback.
    // The greeter runs as the sddm user, so this is the deployed
    // world-readable copy, not the file in $HOME.
    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        mipmap: true
        onStatusChanged: {
            if (status === Image.Error && source != config.defaultBackground) {
                source = config.defaultBackground
            }
        }
    }

    // Single clean edge: one narrow soft shadow cast by the dock onto the
    // wallpaper. The frosted panel itself carries the only hairline.
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: root.dockX - 28
        width: 28
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.0) }
            GradientStop { position: 0.6; color: Qt.rgba(0, 0, 0, 0.08) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.32) }
        }
    }

    // Right frosted-glass dock, full height. Blur is confined to this rect:
    // a live 1:1 ShaderEffectSource crop of the wallpaper region behind the
    // dock, blurred, tinted, hairlined. Never full-screen.
    Item {
        id: dock
        x: root.dockX
        width: root.dockWidth + root.dockRadius
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        opacity: 0
        transform: Translate { id: dockShift; x: 40 }

        // 1:1 crop of the visible dock region; identical size to sourceRect
        // so pixels map exactly on any resolution.
        ShaderEffectSource {
            id: dockCrop
            anchors.fill: parent
            anchors.rightMargin: root.dockRadius
            sourceItem: wallpaper
            sourceRect: Qt.rect(root.dockX, 0, root.dockWidth, root.height)
            live: true
            hideSource: false
        }

        MultiEffect {
            anchors.fill: dockCrop
            source: dockCrop
            blurEnabled: true
            blur: 0.55
            blurMax: 64
            saturation: 1.12
            // Same rounded shape as the tint/hairline below: without this
            // the square blur output pokes past the rounded dock corners.
            // autoPadding off so the mask maps 1:1 onto the dock rect;
            // layer on the mask makes it a valid texture provider.
            autoPaddingEnabled: false
            maskEnabled: true
            maskSource: Rectangle {
                width: dockCrop.width
                height: dockCrop.height
                radius: root.dockRadius
                color: "white"
                layer.enabled: true
                visible: false
            }
        }

        Rectangle {
            anchors.fill: parent
            color: root.bgColor
            opacity: 0.64
            radius: root.dockRadius
        }

        // The one hairline: outline_variant around the whole dock body.
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: root.borderColor
            border.width: 1
            opacity: 0.9
            radius: root.dockRadius
        }

        // Single inner top-light catch, inset past the corner curve so the
        // glass reads lit from above instead of sheened all over.
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.left: parent.left
            anchors.leftMargin: root.dockRadius
            anchors.right: parent.right
            anchors.rightMargin: root.dockRadius * 2
            height: 1
            color: Qt.rgba(1, 1, 1, 0.09)
        }

        ColumnLayout {
            id: dockCol
            anchors.fill: parent
            anchors.leftMargin: 36
            anchors.rightMargin: 36 + root.dockRadius
            anchors.topMargin: 32
            anchors.bottomMargin: 20
            spacing: 8

            Text {
                id: clockText
                Layout.topMargin: 2
                color: root.mainColor
                style: Text.Raised
                styleColor: Qt.rgba(0, 0, 0, 0.45)
                font.family: root.fontName
                font.weight: Font.Bold
                font.pointSize: 54
                font.letterSpacing: 1
            }

            Text {
                id: dateText
                color: root.mutedColor
                font.family: root.fontName
                font.weight: Font.Medium
                font.pointSize: 12
                font.letterSpacing: 1
            }

            Rectangle {
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                Layout.preferredWidth: 64
                Layout.preferredHeight: 1
                color: root.accentColor
                opacity: 0.45
            }

            RowLayout {
                spacing: 14

                Rectangle {
                    id: avatarBox
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 52
                    Layout.alignment: Qt.AlignVCenter
                    radius: 26
                    color: root.accentSoft

                    // Single load path: Canvas rasterizes the photo into a
                    // circle on any backend (MultiEffect/ShaderEffect silently
                    // render nothing for some source visibilities). The
                    // initial stays visible until the photo has painted.
                    property string avatarUrl: Qt.resolvedUrl(root.avatarFile)
                    property bool avatarPainted: false

                    Text {
                        anchors.centerIn: parent
                        color: root.loginTextColor
                        font.family: root.fontName
                        font.bold: true
                        font.pointSize: 19
                        visible: !avatarBox.avatarPainted
                        text: root.fixedUser.charAt(0).toUpperCase()
                    }

                    Canvas {
                        id: avatarCanvas
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.save()
                            ctx.beginPath()
                            ctx.arc(width / 2, height / 2, width / 2, 0, Math.PI * 2)
                            ctx.clip()
                            // Deploy guarantees a square 256px avatar.jpg, so
                            // a plain scale-fill matches PreserveAspectCrop.
                            ctx.drawImage(avatarBox.avatarUrl, 0, 0, width, height)
                            ctx.restore()
                        }
                        Component.onCompleted: loadImage(avatarBox.avatarUrl)
                        onImageLoaded: {
                            avatarBox.avatarPainted = true
                            requestPaint()
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        color: root.mutedColor
                        font.family: root.fontName
                        font.pointSize: 9
                        font.letterSpacing: 3
                        text: qsTr("welcome back")
                    }

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        color: root.mainColor
                        style: Text.Raised
                        styleColor: Qt.rgba(0, 0, 0, 0.45)
                        font.family: root.fontName
                        font.bold: true
                        font.pointSize: 17
                        text: root.fixedUser
                    }
                }
            }

            Text {
                id: errorMessage
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                Layout.topMargin: 4
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                color: root.criticalColor
                font.family: root.fontName
                font.pointSize: 10
            }

            Text {
                Layout.topMargin: 2
                color: root.mutedColor
                font.family: root.fontName
                font.pointSize: 9
                font.letterSpacing: 2
                text: textConstants.password
            }

            // One coherent password control: a single glass field in the
            // dock's radius language. The PasswordBox itself draws nothing —
            // fieldBox owns fill, hairline, and focus halo — and the
            // show/hide toggle is flat text behind a divider inside the
            // same control, never a second black box.
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 46

                Rectangle {
                    anchors.fill: fieldBox
                    anchors.margins: -4
                    radius: root.cornerRadius + 4
                    color: root.accentColor
                    opacity: passField.activeFocus ? 0.25 : 0
                    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }

                Rectangle {
                    id: fieldBox
                    anchors.fill: parent
                    radius: root.cornerRadius
                    color: Qt.rgba(root.fieldColor.r, root.fieldColor.g, root.fieldColor.b, 0.55)
                    border.color: passField.activeFocus ? root.accentColor : root.borderColor
                    border.width: passField.activeFocus ? 2 : 1

                    PasswordBox {
                        id: passField
                        anchors.fill: parent
                        anchors.leftMargin: 2
                        anchors.rightMargin: 66
                        color: "transparent"
                        borderColor: "transparent"
                        focusColor: "transparent"
                        hoverColor: "transparent"
                        textColor: root.mainColor
                        radius: root.cornerRadius
                        font.family: root.fontName
                        font.pointSize: 11
                        KeyNavigation.tab: loginButton
                        Keys.onPressed: function (event) {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.doLogin()
                                event.accepted = true
                            }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 58
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 20
                        color: root.borderColor
                        opacity: 0.7
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 58
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: root.fontName
                        font.pointSize: 10
                        font.letterSpacing: 1
                        font.bold: true
                        color: showHover.containsMouse ? root.mainColor : root.mutedColor
                        text: passField.echoMode === TextInput.Password ? "SHOW" : "HIDE"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: showHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                passField.echoMode = passField.echoMode === TextInput.Password ? TextInput.Normal : TextInput.Password
                            }
                        }
                    }
                }
            }

            Text {
                Layout.topMargin: 4
                color: root.mutedColor
                font.family: root.fontName
                font.pointSize: 9
                font.letterSpacing: 2
                text: textConstants.session
            }

            // Fixed session, stated plainly: a glass card in the same
            // language as the password field, so the pinned session reads
            // as a choice already made rather than a missing picker.
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                radius: root.cornerRadius
                color: Qt.rgba(root.fieldColor.r, root.fieldColor.g, root.fieldColor.b, 0.45)
                border.color: root.borderColor
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 8
                        Layout.preferredHeight: 8
                        Layout.alignment: Qt.AlignVCenter
                        radius: 4
                        color: root.accentColor
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            color: root.mainColor
                            font.family: root.fontName
                            font.bold: true
                            font.pointSize: 13
                            text: root.sessionName.charAt(0).toUpperCase() + root.sessionName.slice(1)
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            color: root.mutedColor
                            font.family: root.fontName
                            font.pointSize: 10
                            text: qsTr("Wayland · fixed session")
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        color: root.mutedColor
                        font.family: root.fontName
                        font.pointSize: 9
                        font.letterSpacing: 2
                        text: qsTr("FIXED")
                    }
                }
            }

            // Hidden role probe for resolveSessionIndex(): session Name/File
            // roles are unreadable from QML outside a delegate.
            Instantiator {
                id: sessionProbe
                model: sessionModel
                delegate: QtObject {
                    property string probeName: model.name
                    property string probeFile: model.file
                }
            }

            Rectangle {
                id: loginButton
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                Layout.topMargin: 10
                radius: 24
                activeFocusOnTab: true
                color: pillMouse.pressed ? Qt.darker(root.accentColor, 1.18) : ((pillMouse.containsMouse || activeFocus) ? Qt.lighter(root.accentColor, 1.08) : root.accentColor)
                border.color: root.mainColor
                border.width: activeFocus ? 2 : 0
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    color: root.loginTextColor
                    font.family: root.fontName
                    font.bold: true
                    font.pointSize: 12
                    text: textConstants.login
                }

                MouseArea {
                    id: pillMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.doLogin()
                }

                KeyNavigation.backtab: passField
                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        root.doLogin()
                        event.accepted = true
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: 8
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 6
                color: root.borderColor
                opacity: 0.6
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    visible: sddm.canSuspend
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 34
                    text: "☾"
                    color: "transparent"
                    activeColor: root.fieldColor
                    pressedColor: root.accentColor
                    textColor: root.mutedColor
                    font.family: root.fontName
                    font.pointSize: 13
                    onClicked: sddm.suspend()
                }

                Button {
                    visible: sddm.canReboot
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 34
                    text: "⟳"
                    color: "transparent"
                    activeColor: root.fieldColor
                    pressedColor: root.accentColor
                    textColor: root.mutedColor
                    font.family: root.fontName
                    font.pointSize: 13
                    onClicked: sddm.reboot()
                }

                Button {
                    visible: sddm.canPowerOff
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 34
                    text: "⏻"
                    color: "transparent"
                    activeColor: root.fieldColor
                    pressedColor: root.accentColor
                    textColor: root.mutedColor
                    font.family: root.fontName
                    font.pointSize: 13
                    onClicked: sddm.powerOff()
                }
            }
        }
    }

    SequentialAnimation {
        id: intro
        PauseAnimation { duration: 60 }
        ParallelAnimation {
            NumberAnimation { target: dock; property: "opacity"; to: 1; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: dockShift; property: "x"; to: 0; duration: 300; easing.type: Easing.OutCubic }
        }
    }

    Component.onCompleted: {
        root.updateClock()
        passField.focus = true
        intro.start()
    }
}
