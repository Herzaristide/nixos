import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

import qs.Data as Dat
import qs.Generics as Gen

Rectangle {
  id: root

  color: Dat.Colors.current.surface_container_low
  height: 24
  implicitWidth: workspaceRow.width + 12
  radius: 12

  RowLayout {
    id: workspaceRow

    anchors.centerIn: parent
    spacing: 4

    Repeater {
      model: 9

      Rectangle {
        id: workspaceButton

        readonly property int workspaceId: index + 1
        readonly property bool isActive: Hyprland.focusedWorkspace?.id === workspaceId
        readonly property bool hasWindows: {
          for (const ws of Hyprland.workspaces.values) {
            if (ws.id === workspaceId) {
              return ws.windows.length > 0
            }
          }
          return false
        }

        Layout.preferredHeight: 20
        Layout.preferredWidth: 20

        border.color: isActive ? Dat.Colors.current.primary : "transparent"
        border.width: 2
        color: hasWindows ? Dat.Colors.current.primary_container : "transparent"
        radius: 10

        Text {
          anchors.centerIn: parent
          color: workspaceButton.isActive
            ? Dat.Colors.current.primary
            : workspaceButton.hasWindows
              ? Dat.Colors.current.on_primary_container
              : Dat.Colors.current.outline
          font.pointSize: 9
          font.weight: workspaceButton.isActive ? Font.Bold : Font.Normal
          text: workspaceButton.workspaceId
        }

        Gen.MouseArea {
          layerColor: Dat.Colors.current.primary
          layerRadius: 10

          onClicked: {
            Hyprland.dispatch(`workspace ${workspaceButton.workspaceId}`)
          }
        }

        Behavior on color {
          ColorAnimation {
            duration: Dat.MaterialEasing.standardTime
            easing.bezierCurve: Dat.MaterialEasing.standard
          }
        }

        Behavior on border.color {
          ColorAnimation {
            duration: Dat.MaterialEasing.standardTime
            easing.bezierCurve: Dat.MaterialEasing.standard
          }
        }
      }
    }
  }
}
