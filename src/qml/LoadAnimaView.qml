import QtQuick 2.0

Item {
    property alias timerRun: animTimer.running
    property int updateIndex

    Timer {
        id: animTimer
        interval: 500
        repeat: true
        onTriggered: {
            updateIndex ++
            if (updateIndex >= 3) {
                updateIndex = 0
            }
        }
    }

    Row {
        id: animaRow
        spacing: 20
        anchors.centerIn: parent
        Repeater {
            model: 3
            delegate: Rectangle {
                width: 14
                height: width
                radius: width / 2
                color: index === updateIndex ? "#803C3C43" : "#4D3C3C43"
            }
        }
    }
}
