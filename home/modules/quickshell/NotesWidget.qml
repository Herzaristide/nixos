import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtCore

Item {
    id: root

    // ── Persistence ──────────────────────────────────────────────────────────
    Settings {
        id: settings
        category: "notes_v2"
        property string notesJson: "[]"
    }

    // ── In-memory data ────────────────────────────────────────────────────────
    property var notesData: []     // source of truth: [{id, content, timestampMs, timestamp}]
    property string searchFilter: ""

    ListModel { id: displayModel }

    // ── Data helpers ──────────────────────────────────────────────────────────
    function loadNotes() {
        try {
            var parsed = JSON.parse(settings.notesJson);
            notesData = parsed instanceof Array ? parsed : [];
        } catch (e) {
            notesData = [];
        }
        refreshView(searchFilter);
    }

    function saveNotes() {
        settings.notesJson = JSON.stringify(notesData);
    }

    function addNote(text) {
        var trimmed = text.trim();
        if (trimmed === "") return;
        var now = new Date();
        var note = {
            id: now.getTime() + Math.random(),
            content: trimmed,
            timestampMs: now.getTime(),
            timestamp: now.toLocaleString(Qt.locale(), "dd MMM yyyy  HH:mm")
        };
        // prepend so most-recent is first in the source array too
        var arr = notesData.slice();
        arr.unshift(note);
        notesData = arr;
        saveNotes();
        refreshView(searchFilter);
        Qt.callLater(function() { noteList.positionViewAtBeginning(); });
    }

    function deleteNote(noteId) {
        var arr = notesData.filter(function(n) { return n.id !== noteId; });
        notesData = arr;
        saveNotes();
        refreshView(searchFilter);
    }

    function clearAllNotes() {
        notesData = [];
        saveNotes();
        refreshView(searchFilter);
    }

    function refreshView(filter) {
        displayModel.clear();
        var f = filter ? filter.toLowerCase() : "";
        for (var i = 0; i < notesData.length; i++) {
            var n = notesData[i];
            if (f === "" || n.content.toLowerCase().indexOf(f) !== -1) {
                displayModel.append({
                    noteId: n.id,
                    noteContent: n.content,
                    noteTimestamp: n.timestamp
                });
            }
        }
    }

    Component.onCompleted: loadNotes()

    // ── Layout ────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        // Header row ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "NOTES"
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                font.bold: true
                color: "#00FF88"
            }

            Text {
                text: notesData.length + " note" + (notesData.length !== 1 ? "s" : "")
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                color: "#444444"
            }

            Item { Layout.fillWidth: true }

            Text {
                id: clearBtn
                text: "[clear all]"
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                color: clearHover.containsMouse ? "#FF4444" : "#444444"

                MouseArea {
                    id: clearHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clearAllNotes()
                }
            }
        }

        // Search bar ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: ">"
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                color: "#00FF88"
            }

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "search…"
                placeholderTextColor: "#30FFFFFF"
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                color: "#00FF88"
                background: Item {}
                leftPadding: 0
                onTextChanged: {
                    root.searchFilter = text;
                    root.refreshView(text);
                }
            }
        }

        // Thin separator ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#FFFFFF"
            opacity: 0.12
        }

        // Note list ───────────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty state
            Text {
                anchors.centerIn: parent
                visible: displayModel.count === 0
                text: searchField.text !== "" ? "No matching notes." : "No notes yet…"
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                color: "#30FFFFFF"
            }

            ListView {
                id: noteList
                anchors.fill: parent
                clip: true
                spacing: 4
                model: displayModel
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 3
                        color: "#30FFFFFF"
                        radius: 2
                    }
                }

                delegate: Item {
                    required property var noteId
                    required property string noteContent
                    required property string noteTimestamp
                    width: noteList.width
                    height: noteCol.height + 10

                    // Hover highlight
                    Rectangle {
                        anchors.fill: parent
                        color: delHover.containsMouse ? "#0AFFFFFF" : "transparent"
                        radius: 3
                    }

                    Column {
                        id: noteCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: 4
                            rightMargin: 28
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 2

                        Text {
                            text: noteTimestamp
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            color: "#444444"
                            width: parent.width
                            elide: Text.ElideRight
                        }

                        TextEdit {
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            text: noteContent
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                            color: "#CCCCCC"
                            width: parent.width
                            selectionColor: "#00FF88"
                            selectedTextColor: "#000000"
                        }
                    }

                    // Delete button
                    Text {
                        id: delBtn
                        anchors {
                            right: parent.right
                            rightMargin: 4
                            verticalCenter: parent.verticalCenter
                        }
                        text: "×"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 14
                        color: delHover.containsMouse ? "#FF4444" : "#333333"

                        MouseArea {
                            id: delHover
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.deleteNote(noteId)
                        }
                    }
                }
            }
        }

        // Separator before input ──────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#FFFFFF"
            opacity: 0.12
        }

        // Input area ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: ">"
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                color: "#00FF88"
                Layout.alignment: Qt.AlignTop
                topPadding: 6
            }

            TextArea {
                id: inputArea
                Layout.fillWidth: true
                implicitHeight: Math.max(Math.min(contentHeight + topPadding + bottomPadding, 300), 10 * font.pixelSize * 1.4)
                topPadding: 6
                bottomPadding: 6
                leftPadding: 0
                wrapMode: TextEdit.Wrap
                placeholderText: "New note… (Enter to save, Shift+Enter for newline)"
                placeholderTextColor: "#30FFFFFF"
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                color: "#00FF88"
                background: Item {}
                selectByMouse: true

                Keys.onReturnPressed: (event) => {
                    if (event.modifiers & Qt.ShiftModifier) {
                        // Insert newline
                        inputArea.insert(inputArea.cursorPosition, "\n");
                    } else {
                        root.addNote(inputArea.text);
                        inputArea.text = "";
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
