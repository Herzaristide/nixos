import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root

    // ── Active player selection ──────────────────────────────────────────
    // Prefer the first player that is currently Playing, otherwise the first
    // available player. Re-evaluated reactively whenever the list or any
    // player's playbackState changes.
    property var player: {
        var list = Mpris.players ? Mpris.players.values : [];
        if (!list || list.length === 0) return null;
        for (var i = 0; i < list.length; ++i) {
            if (list[i].playbackState === MprisPlaybackState.Playing) return list[i];
        }
        return list[0];
    }

    readonly property bool hasPlayer: player !== null && player !== undefined
    readonly property bool isPlaying: hasPlayer && player.playbackState === MprisPlaybackState.Playing

    // ── Helpers ──────────────────────────────────────────────────────────
    function fmtTime(seconds) {
        if (!seconds || seconds < 0 || !isFinite(seconds)) return "0:00";
        var s = Math.floor(seconds);
        var m = Math.floor(s / 60);
        var r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
    }

    // Local position ticker — Mpris.position only updates on demand, so we
    // poll it gently while playing for a smooth progress bar.
    Timer {
        running: root.isPlaying
        interval: 500
        repeat: true
        onTriggered: if (root.hasPlayer) root.player.positionChanged()
    }

    // ── Layout ───────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 16

        // ── Album art card ───────────────────────────────────────────
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(parent.width - 24, 240)
            Layout.preferredHeight: width

            // Soft glow underneath the art
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.95
                height: parent.height * 0.95
                radius: 18
                color: Theme.accentColor
                opacity: root.isPlaying ? 0.18 : 0.08
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                SequentialAnimation on scale {
                    running: root.isPlaying
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.04; duration: 1800; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 1.04; to: 1.0; duration: 1800; easing.type: Easing.InOutQuad }
                }
            }

            Rectangle {
                id: artCard
                anchors.fill: parent
                radius: 14
                color: Theme.bgElevated
                clip: true
                border.width: 1
                border.color: Theme.dividerColor

                // Placeholder gradient when no art available
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    visible: !art.visible
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.accentDark }
                        GradientStop { position: 1.0; color: Theme.bgDeep }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "♪"
                        font.pixelSize: 64
                        color: Theme.iconColor
                        opacity: 0.35
                    }
                }

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.hasPlayer && root.player.trackArtUrl ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    cache: true
                    visible: status === Image.Ready

                    // Fade + zoom in on metadata change
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

                    onSourceChanged: {
                        scale = 1.06;
                        scaleAnim.restart();
                    }

                    NumberAnimation on scale {
                        id: scaleAnim
                        from: 1.06
                        to: 1.0
                        duration: 320
                        easing.type: Easing.OutCubic
                        running: false
                    }
                }
            }
        }

        // ── Title + Artist ───────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            // Marquee title
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: titleText.implicitHeight
                clip: true

                Text {
                    id: titleText
                    text: root.hasPlayer && root.player.trackTitle ? root.player.trackTitle : "Nothing playing"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    color: Theme.textPrimary
                    elide: Text.ElideNone
                    wrapMode: Text.NoWrap

                    property bool overflows: paintedWidth > parent.width

                    x: overflows ? marqueeX : (parent.width - paintedWidth) / 2
                    property real marqueeX: 0

                    SequentialAnimation on marqueeX {
                        running: titleText.overflows
                        loops: Animation.Infinite
                        PauseAnimation { duration: 1500 }
                        NumberAnimation {
                            from: 0
                            to: -(titleText.paintedWidth - titleText.parent.width + 8)
                            duration: Math.max(2000, titleText.paintedWidth * 18)
                            easing.type: Easing.InOutQuad
                        }
                        PauseAnimation { duration: 1500 }
                        NumberAnimation {
                            from: -(titleText.paintedWidth - titleText.parent.width + 8)
                            to: 0
                            duration: Math.max(2000, titleText.paintedWidth * 18)
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Behavior on opacity { NumberAnimation { duration: 250 } }
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.hasPlayer && root.player.trackArtist ? root.player.trackArtist : "—"
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                color: Theme.textSecondary
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.hasPlayer && root.player.trackAlbum ? root.player.trackAlbum : ""
                visible: text !== ""
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                color: Theme.textDim
                elide: Text.ElideRight
            }
        }

        // ── Progress bar ─────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            opacity: root.hasPlayer ? 1.0 : 0.4
            Behavior on opacity { NumberAnimation { duration: 250 } }

            Rectangle {
                id: progressTrack
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                radius: 2
                color: Theme.bgInput

                readonly property real ratio: {
                    if (!root.hasPlayer || !root.player.length || root.player.length <= 0) return 0;
                    return Math.max(0, Math.min(1, root.player.position / root.player.length));
                }

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * progressTrack.ratio
                    color: Theme.accentColor
                    Behavior on width { SmoothedAnimation { velocity: 200 } }
                }

                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: Theme.accentColor
                    border.width: 2
                    border.color: Theme.bgDeep
                    x: parent.width * progressTrack.ratio - width / 2
                    y: (parent.height - height) / 2
                    visible: seekArea.containsMouse || seekArea.pressed
                    Behavior on x { SmoothedAnimation { velocity: 200 } }
                }

                MouseArea {
                    id: seekArea
                    anchors.fill: parent
                    anchors.topMargin: -8
                    anchors.bottomMargin: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.hasPlayer && root.player && root.player.canSeek
                    onClicked: (mouse) => {
                        if (!enabled) return;
                        var ratio = Math.max(0, Math.min(1, mouse.x / width));
                        root.player.position = ratio * root.player.length;
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.hasPlayer ? root.fmtTime(root.player.position) : "0:00"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    color: Theme.textDim
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.hasPlayer ? root.fmtTime(root.player.length) : "0:00"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    color: Theme.textDim
                }
            }
        }

        // ── Transport controls ───────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 14

            // Previous
            TransportButton {
                glyph: "⏮"
                size: 36
                accent: false
                enabled: root.hasPlayer && root.player.canGoPrevious
                onActivated: if (root.hasPlayer) root.player.previous()
            }

            // Play / Pause (accented)
            TransportButton {
                glyph: root.isPlaying ? "⏸" : "▶"
                size: 48
                accent: true
                enabled: root.hasPlayer && (root.isPlaying ? root.player.canPause : root.player.canPlay)
                onActivated: if (root.hasPlayer) root.player.togglePlaying()
            }

            // Next
            TransportButton {
                glyph: "⏭"
                size: 36
                accent: false
                enabled: root.hasPlayer && root.player.canGoNext
                onActivated: if (root.hasPlayer) root.player.next()
            }
        }

        // Bottom spacer pushes everything up
        Item { Layout.fillHeight: true }
    }

    // ── Empty-state overlay (subtle) ─────────────────────────────────────
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        visible: !root.hasPlayer
        text: "No active media player"
        font.family: "JetBrains Mono"
        font.pixelSize: 11
        color: Theme.textDim
        opacity: 0.6
        SequentialAnimation on opacity {
            running: !root.hasPlayer
            loops: Animation.Infinite
            NumberAnimation { from: 0.4; to: 0.8; duration: 1400; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 0.8; to: 0.4; duration: 1400; easing.type: Easing.InOutQuad }
        }
    }

    // ── Reusable transport button ────────────────────────────────────────
    component TransportButton: Item {
        id: btn
        property string glyph: ""
        property real size: 36
        property bool accent: false
        signal activated()

        implicitWidth: size
        implicitHeight: size

        Rectangle {
            id: bg
            anchors.fill: parent
            radius: width / 2
            color: btn.accent
                   ? Theme.accentColor
                   : (ma.containsMouse ? Theme.hoverOverlay : Theme.bgElevated)
            opacity: btn.enabled ? 1.0 : 0.35
            border.width: btn.accent ? 0 : 1
            border.color: Theme.dividerColor

            scale: ma.pressed ? 0.92 : (ma.containsMouse ? 1.08 : 1.0)
            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on opacity { NumberAnimation { duration: 160 } }

            Text {
                anchors.centerIn: parent
                text: btn.glyph
                font.pixelSize: btn.size * 0.42
                color: btn.accent ? Theme.selectedTextColor : Theme.iconColor
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: btn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (btn.enabled) btn.activated()
        }
    }
}
