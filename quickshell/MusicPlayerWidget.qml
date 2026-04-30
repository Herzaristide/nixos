import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
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

    // ── Real-time audio spectrum from cava (9 bars, 0–100) ─────────────
    property var eqLevels: [0,0,0,0,0,0,0,0,0]

    Process {
        id: cavaProc
        running: root.isPlaying
        command: [
            "sh", "-c",
            "mkdir -p /tmp/qs-music && cat > /tmp/qs-music/cava.conf <<'EOF'\n" +
            "[general]\nbars = 9\nframerate = 60\n" +
            "[input]\nmethod = pulse\nsource = auto\n" +
            "[output]\nmethod = raw\ndata_format = ascii\nascii_max_range = 100\nchannels = mono\n" +
            "[smoothing]\nnoise_reduction = 35\n" +
            "EOF\nexec cava -p /tmp/qs-music/cava.conf"
        ]
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.trim().split(';');
                var arr = [];
                for (var i = 0; i < 9; i++) {
                    var v = parseInt(parts[i]);
                    arr.push(isNaN(v) ? 0 : v);
                }
                root.eqLevels = arr;
            }
        }
        // Reset bars when audio stops streaming
        onRunningChanged: if (!running) root.eqLevels = [0,0,0,0,0,0,0,0,0]
    }

    // ── Vinyl disc rotation (25 fps) ──────────────────────────────────
    property real vinylRotation: 0

    Timer {
        running: root.isPlaying
        interval: 40
        repeat: true
        onTriggered: root.vinylRotation = (root.vinylRotation + 0.8) % 360
    }

    // ── Track-change accent flash ──────────────────────────────────────
    property string currentTrackId: hasPlayer
        ? ((player.trackTitle || "") + "|" + (player.trackArtist || ""))
        : ""
    onCurrentTrackIdChanged: flashAnim.restart()

    SequentialAnimation {
        id: flashAnim
        NumberAnimation { target: trackFlash; property: "opacity"; to: 0.25; duration: 100 }
        NumberAnimation { target: trackFlash; property: "opacity"; to: 0.0; duration: 600; easing.type: Easing.OutCubic }
    }

    // ── Lyrics ───────────────────────────────────────────────────────────
    property bool   showLyrics:    false
    property string lyricsText:    ""
    property bool   lyricsLoading: false

    // Animated height for the collapsible lyrics panel
    property real lyricsH: 0
    Behavior on lyricsH { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    onShowLyricsChanged: {
        lyricsH = showLyrics ? 200 : 0;
        if (showLyrics && lyricsText.length === 0 && !lyricsLoading
                && hasPlayer && player.trackTitle && player.trackArtist) {
            lyricsLoading = true;
            lyricsFetcher.pendingArtist = player.trackArtist;
            lyricsFetcher.pendingTitle  = player.trackTitle;
            Qt.callLater(function() { lyricsFetcher.running = true; });
        }
    }

    // Re-fetch when the track changes (only if the panel is open)
    property string trackId: hasPlayer && player.trackTitle
                             ? (player.trackArtist + "|||" + player.trackTitle) : ""
    onTrackIdChanged: {
        lyricsText    = "";
        lyricsLoading = false;
        lyricsFetcher.running = false;
        if (showLyrics && hasPlayer && player.trackTitle && player.trackArtist) {
            lyricsLoading = true;
            lyricsFetcher.pendingArtist = player.trackArtist;
            lyricsFetcher.pendingTitle  = player.trackTitle;
            Qt.callLater(function() { lyricsFetcher.running = true; });
        }
    }

    // Fetches lyrics from api.lyrics.ovh; artist/title are passed as
    // positional shell arguments ($1/$2) to avoid shell injection.
    Process {
        id: lyricsFetcher
        property string pendingArtist: ""
        property string pendingTitle:  ""
        command: [
            "sh", "-c",
            `jq -rn --arg a "$1" --arg t "$2" '"https://api.lyrics.ovh/v1/\\($a | @uri)/\\($t | @uri)"' | xargs curl -sf --connect-timeout 6 --max-time 10 | jq -r '.lyrics // "Lyrics not found."' || echo "Lyrics not found."`,
            "--", pendingArtist, pendingTitle
        ]
        stdout: SplitParser {
            onRead: (line) => {
                root.lyricsText += (root.lyricsText.length > 0 ? "\n" : "") + line;
            }
        }
        onRunningChanged: {
            if (!running) {
                if (root.lyricsText.length === 0)
                    root.lyricsText = "No lyrics found.";
                root.lyricsLoading = false;
            }
        }
    }

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

    // ══════════════════════════════════════════════════════════════════════
    // BACKGROUND: blurred album art
    // ══════════════════════════════════════════════════════════════════════
    Item {
        anchors.fill: parent
        clip: true

        Image {
            id: bgArtSrc
            anchors.fill: parent
            source: root.hasPlayer && root.player.trackArtUrl ? root.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 512
            sourceSize.height: 512
            asynchronous: true
            smooth: true
            mipmap: true
            visible: false
        }

        MultiEffect {
            source: bgArtSrc
            anchors.fill: parent
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            saturation: -0.15
            brightness: -0.40
            opacity: bgArtSrc.status === Image.Ready ? 0.60 : 0.0
            Behavior on opacity { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
        }
    }

    Rectangle { anchors.fill: parent; color: Theme.bgDeep; opacity: 0.68 }

    Rectangle {
        id: trackFlash
        anchors.fill: parent
        color: Theme.accentColor
        opacity: 0.0
    }

    // ══════════════════════════════════════════════════════════════════════
    // MAIN CONTENT
    // ══════════════════════════════════════════════════════════════════════
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 16

        // ── Vinyl disc ───────────────────────────────────────────────
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(parent.width - 16, 186)
            Layout.preferredHeight: width

            // Outer counter-rotating ring
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 22; height: parent.height + 22; radius: width / 2
                color: "transparent"
                border.width: 1; border.color: Theme.accentColor
                opacity: root.isPlaying ? 0.45 : 0.0
                Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

                RotationAnimator on rotation {
                    running: root.isPlaying
                    from: 0; to: -360; duration: 14000; loops: Animation.Infinite
                }
            }

            // Inner pulsing ring
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 8; height: parent.height + 8; radius: width / 2
                color: "transparent"
                border.width: 2; border.color: Theme.accentColor
                opacity: root.isPlaying ? 0.30 : 0.0
                Behavior on opacity { NumberAnimation { duration: 400 } }

                SequentialAnimation on scale {
                    running: root.isPlaying; loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.04; duration: 860; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.04; to: 1.0; duration: 860; easing.type: Easing.InOutSine }
                }
            }

            // Disc body (rotates with the art)
            Item {
                id: vinylDisc
                anchors.fill: parent
                rotation: root.vinylRotation

                // Black circular base (vinyl)
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.bgDeep
                }

                // Decorative groove rings (no-art state)
                Repeater {
                    model: 5
                    Rectangle {
                        required property int index
                        anchors.centerIn: parent
                        width: parent.width * (0.28 + index * 0.14); height: width; radius: width / 2
                        color: "transparent"
                        border.width: 0.5
                        border.color: Qt.rgba(1, 1, 1, 0.04 + index * 0.025)
                        visible: discArt.status !== Image.Ready
                    }
                }

                // High-resolution album art (rendered offscreen, then masked)
                Image {
                    id: discArt
                    anchors.fill: parent
                    source: root.hasPlayer && root.player.trackArtUrl ? root.player.trackArtUrl : ""
                    sourceSize.width: 512
                    sourceSize.height: 512
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    cache: true
                    visible: false   // hidden source, MultiEffect renders the masked copy
                    layer.enabled: true
                    layer.smooth: true

                    onSourceChanged: { artScale.scale = 1.07; artScaleAnim.restart(); }
                }

                // Circular mask source
                Item {
                    id: discMask
                    anchors.fill: parent
                    visible: false
                    layer.enabled: true
                    layer.smooth: true
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "white"
                        antialiasing: true
                    }
                }

                // Wrapper providing the entrance scale animation
                Item {
                    id: artScale
                    anchors.fill: parent

                    MultiEffect {
                        anchors.fill: parent
                        source: discArt
                        maskEnabled: true
                        maskSource: discMask
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                        visible: discArt.status === Image.Ready
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    }

                    NumberAnimation on scale {
                        id: artScaleAnim
                        from: 1.07; to: 1.0
                        duration: 380; easing.type: Easing.OutCubic
                        running: false
                    }
                }

                // Radial vignette over art (clipped to circle naturally)
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    visible: discArt.status === Image.Ready
                    color: "transparent"
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.06) }
                        GradientStop { position: 0.6; color: "transparent"          }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.45) }
                    }
                }

                // Placeholder note icon (no art)
                Text {
                    anchors.centerIn: parent
                    visible: discArt.status !== Image.Ready
                    text: "♪"; font.pixelSize: parent.width * 0.35
                    color: Theme.iconColor; opacity: 0.22
                }

                // Center spindle hole
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.10; height: width; radius: width / 2
                    color: Theme.bgDeep
                    border.width: 2
                    border.color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.80)
                    z: 10
                }
            }

            // Pause indicator overlay (fades in when halted)
            Rectangle {
                anchors.centerIn: parent
                width: 52; height: 52; radius: 26
                color: Qt.rgba(0, 0, 0, 0.58)
                opacity: root.hasPlayer && !root.isPlaying ? 0.92 : 0.0
                Behavior on opacity { NumberAnimation { duration: 260 } }

                Text {
                    anchors.centerIn: parent
                    text: root.hasPlayer ? "⏸" : "♪"
                    font.pixelSize: 20; color: "white"
                }
            }
        }

        // ── Animated EQ bars ─────────────────────────────────────────
        Row {
            Layout.alignment: Qt.AlignHCenter
            height: 36
            spacing: 4

            Repeater {
                model: 9
                delegate: Item {
                    required property int index
                    width: 6; height: 36

                    // 0..1 normalized level for this bar from cava
                    readonly property real level: Math.max(0, Math.min(1,
                        (root.eqLevels[index] || 0) / 100))

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        // 3 px floor + audio-driven amplitude up to bar height
                        height: 3 + parent.level * (parent.height - 3)
                        radius: 3
                        color: Theme.accentColor
                        opacity: root.isPlaying ? (0.55 + parent.level * 0.45) : 0.22
                        Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 220 } }
                    }
                }
            }
        }

        // ── Chromagram (12 pitch classes of currently playing audio) ──
        ChromaGraph {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            active: root.isPlaying
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

            // Lyrics toggle
            TransportButton {
                glyph: "♪"
                size: 30
                accent: root.showLyrics
                enabled: root.hasPlayer
                onActivated: root.showLyrics = !root.showLyrics
            }
        }

        // ── Lyrics panel ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.lyricsH
            visible: root.lyricsH > 0
            clip: true
            color: Theme.bgElevated
            radius: 8
            border.width: 1
            border.color: Theme.dividerColor

            // Pulsing "fetching" label
            Text {
                anchors.centerIn: parent
                visible: root.lyricsLoading
                text: "Fetching lyrics…"
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                color: Theme.textDim
                SequentialAnimation on opacity {
                    running: root.lyricsLoading
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.3; to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 1.0; to: 0.3; duration: 700; easing.type: Easing.InOutQuad }
                }
            }

            // Scrollable lyrics text
            ScrollView {
                anchors.fill: parent
                anchors.margins: 8
                visible: !root.lyricsLoading && root.lyricsText.length > 0
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Text {
                    width: parent.width - 16
                    text: root.lyricsText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                    lineHeight: 1.5
                }
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
