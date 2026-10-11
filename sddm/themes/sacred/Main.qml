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
    property color accentSoft: config.AccentSoft ? config.AccentSoft : root.accentColor
    property color bgColor: config.BackgroundColor ? config.BackgroundColor : "#0a0a0c"
    property color fieldColor: config.FieldColor ? config.FieldColor : "#14161c"
    property color criticalColor: config.CriticalColor ? config.CriticalColor : "#ff5f5f"
    property color loginTextColor: config.LoginTextColor ? config.LoginTextColor : "#0a0a0c"
    property string fontName: config.Font ? config.Font : "JetBrainsMono Nerd Font"
    property int cornerRadius: config.Radius ? config.Radius : 14
    property real dimOverlay: config.DimOverlay ? config.DimOverlay : 0.45
    // Visible dock width, clamped HiDPI-safe; the dock body extends 26px past
    // the screen edge so the left corners get a 26 radius and the right stays flush.
    property real dockWidth: Math.min(420, Math.max(300, width - 32))
    property real dockX: width - dockWidth
    property int dockRadius: 26

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

    // Soft shadow cast by the dock onto the wallpaper — the only wallpaper
    // treatment besides the frosted panel itself.
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: root.dockX - 32
        width: 32
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.0) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.3) }
        }
    }

    // Right frosted-glass dock, full height. Blur is confined to this rect:
    // a live 1:1 ShaderEffectSource crop of the wallpaper region behind the
    // dock, blurred, tinted, sheened, hairlined. Never full-screen.
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
            saturation: 1.05
        }

        Rectangle {
            anchors.fill: parent
            color: root.bgColor
            opacity: 0.6
            radius: root.dockRadius
        }

        Rectangle {
            anchors.fill: parent
            radius: root.dockRadius
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.07) }
                GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.0) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.12) }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: root.accentColor
            border.width: 1
            opacity: 0.3
            radius: root.dockRadius
        }

        ColumnLayout {
            id: dockCol
            anchors.fill: parent
            anchors.leftMargin: 36
            anchors.rightMargin: 36 + root.dockRadius
            anchors.topMargin: 28
            anchors.bottomMargin: 24
            spacing: 7

            Text {
                color: root.accentColor
                font.family: root.fontName
                font.pointSize: 10
                font.letterSpacing: 6
                font.bold: true
                text: "s a c r e d"
            }

            Text {
                id: clockText
                Layout.topMargin: 2
                color: root.mainColor
                font.family: root.fontName
                font.weight: Font.Thin
                font.pointSize: 60
                font.letterSpacing: 2
            }

            Text {
                id: dateText
                color: root.mutedColor
                font.family: root.fontName
                font.pointSize: 12
                font.letterSpacing: 1
            }

            Rectangle {
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                Layout.preferredWidth: 64
                Layout.preferredHeight: 1
                color: root.accentColor
                opacity: 0.45
            }

            RowLayout {
                spacing: 12

                Rectangle {
                    id: avatarBox
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    Layout.alignment: Qt.AlignVCenter
                    radius: 24
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
                        font.pointSize: 18
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
                Layout.preferredHeight: 22
                Layout.topMargin: 2
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                color: root.criticalColor
                font.family: root.fontName
                font.pointSize: 10
            }

            Text {
                color: root.mutedColor
                font.family: root.fontName
                font.pointSize: 9
                text: textConstants.password
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 40

                Rectangle {
                    anchors.fill: passRow
                    anchors.margins: -4
                    radius: root.cornerRadius + 4
                    color: root.accentColor
                    opacity: passField.activeFocus ? 0.28 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                RowLayout {
                    id: passRow
                    anchors.fill: parent
                    spacing: 8

                    PasswordBox {
                        id: passField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        color: root.fieldColor
                        borderColor: root.mutedColor
                        focusColor: root.accentColor
                        hoverColor: root.accentColor
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

                    Button {
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 40
                        text: passField.echoMode === TextInput.Password ? "show" : "hide"
                        color: "transparent"
                        activeColor: root.fieldColor
                        pressedColor: root.accentColor
                        textColor: root.mutedColor
                        font.family: root.fontName
                        font.pointSize: 9
                        onClicked: {
                            passField.echoMode = passField.echoMode === TextInput.Password ? TextInput.Normal : TextInput.Password
                        }
                    }
                }
            }

            Text {
                color: root.mutedColor
                font.family: root.fontName
                font.pointSize: 9
                text: textConstants.session
            }

            // Fixed session: status-dot + name microcopy, no picker.
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 6
                    Layout.preferredHeight: 6
                    Layout.alignment: Qt.AlignVCenter
                    radius: 3
                    color: root.accentColor
                    opacity: 0.8
                }

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: root.mainColor
                    font.family: root.fontName
                    font.pointSize: 12
                    text: root.sessionName.charAt(0).toUpperCase() + root.sessionName.slice(1)
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
                Layout.preferredHeight: 46
                Layout.topMargin: 6
                radius: 23
                color: pillMouse.pressed ? root.mutedColor : root.accentColor
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
                Layout.minimumHeight: 0
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
        PauseAnimation { duration: 120 }
        ParallelAnimation {
            NumberAnimation { target: dock; property: "opacity"; to: 1; duration: 600; easing.type: Easing.OutCubic }
            NumberAnimation { target: dockShift; property: "x"; to: 0; duration: 600; easing.type: Easing.OutCubic }
        }
    }

    Component.onCompleted: {
        root.updateClock()
        passField.focus = true
        intro.start()
    }
}
