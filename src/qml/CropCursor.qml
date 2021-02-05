import QtQuick 2.0

Item {
    id: root
    property string colorKey
    property alias mouseArea: mouseArea
    property int minX: 0
    property int minY: 0
    property int maxX: 400
    property int maxY: 400

    property int size: 64

    function clamp(a, x, b) {
        if (x < a) return a
        if (x > b) return b
        return x
    }

    width: size
    height: size

    MouseArea {
        id: mouseArea

        width: size
        height: size
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: -size/2
        anchors.leftMargin: -size/2

        drag.target: cursor

        // Appears to activate even when only mouseX changes
        onMouseYChanged: {
            root.x = clamp(minX, root.x + mouseX - size / 2, maxX)
            root.y = clamp(minY, root.y + mouseY - size / 2, maxY)
        }

        Rectangle {
            id: cursor

            width: size
            height: size
            radius: size / 2
            anchors.centerIn: parent

            color: "red"
            opacity: 0.0

            Drag.active: mouseArea.drag.active
            Drag.hotSpot.x: size / 2
            Drag.hotSpot.y: size / 2
            states: State {
                when: mouseArea.drag.active
                ParentChange {
                    target: cursor
                    parent: root
                }
            }
        }
    }
}