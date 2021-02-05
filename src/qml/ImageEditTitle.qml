

/*
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.0
import org.kde.kirigami 2.15
import "common.js" as CSJ

Rectangle {

    property var titleDateTime: "00:00:00"
    property var titleName: "All"
    property bool isVideoScreen
    property string rotateName: "qrc:/assets/rotate.png"
    property string cropName: "qrc:/assets/crop.png"
    property string saveName: "qrc:/assets/edit_savetofile.png"
    property string magicName: "qrc:/assets/magic.png"
    property string deleteName: "qrc:/assets/delete.png"

    signal backClicked
    signal cropCLicked
    signal rotateClicked
    signal magicClicked
    signal deleteClicked
    signal saveToFileClicked

    width: parent.width
    height: parent.height * 3 / 40
    color: "transparent"

    ShaderEffectSource {
        id: eff

        anchors.centerIn: fastBlur
        width: fastBlur.width
        visible: false
        height: fastBlur.height
        sourceItem: listView
        sourceRect: Qt.rect(0, 0, width, height)
    }
    FastBlur {
        id: fastBlur

        anchors.fill: parent
        source: eff
        radius: 64
        cached: true
        visible: false
    }

    Rectangle {
        id: maskRect

        anchors.fill: fastBlur
        visible: false
        clip: true
    }

    OpacityMask {
        id: mask

        anchors.fill: maskRect
        visible: true
        source: fastBlur
        maskSource: maskRect
    }

    Rectangle {
        color: "#80FFFFFF"
        width: parent.width
        height: parent.height
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
    }

    Rectangle {
        id: imageTitleLeft
        anchors.left: parent.left
        height: parent.height
        width: parent.width / 3
        color: "transparent"

        MouseArea {
            anchors.fill: parent

            onClicked: {
                backClicked()
            }
        }

        JIconButton {
            id: back

            anchors.verticalCenter: parent.verticalCenter
            anchors {
                left: parent.left
                leftMargin: 20
                rightMargin: 16
            }
            width: parent.height / 2
            height: width
            source: "qrc:/assets/back.png"

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    backClicked()
                }
            }
        }

        Text {
            id: titleNameView

            anchors.verticalCenter: parent.verticalCenter
            anchors {
                left: back.right
                leftMargin: 16
            }
            text: qsTr(titleName)
            font.pointSize: root.defaultFontSize + 6
            width: imageTitleLeft.width / 2
            elide: Text.ElideRight
            color: "#000000"
        }
    }
    Rectangle {
        id: imageTitleMiddle

        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.height
        width: parent.width / 3
        color: "transparent"

        Text {
            id: titleDate

            anchors.centerIn: parent
            text: qsTr(titleDateTime)
            font.pointSize: root.defaultFontSize - 3
            color: "#99000000"
        }
    }

    ListModel {
        id: imageTitleModel

        ListElement {
            name: "qrc:/assets/crop.png"
            flag: 1
        }
        ListElement {
            name: "qrc:/assets/edit_savetofile.png"
            flag: 2
        }
        ListElement {
            name: "qrc:/assets/magic.png"
            flag: 3
        }
        ListElement {
            name: "qrc:/assets/delete.png"
            flag: 4
        }
    }

    ListModel {
        id: imageVideoModel

        ListElement {
            name: "qrc:/assets/edit_savetofile.png"
            flag: 2
        }
        ListElement {
            name: "qrc:/assets/delete.png"
            flag: 4
        }
    }

    AlertDialog {
        id: deleteDialog

        msgContent: isVideoScreen ? CSJ.Dialog_Video_Text : CSJ.Dialog_Photo_Text
        onDialogLeftClicked: {
            deleteDialog.close()
        }
        onDialogRightClicked: {
            deleteClicked()
            deleteDialog.close()
        }
    }

    Row {
        id: imageTitleRight

        anchors {
            right: parent.right
            rightMargin: height / 8
        }
        height: parent.height
        spacing: (height * 3 / 5) / 2

        Repeater {
            id: btnRepeater

            model: isVideoScreen ? imageVideoModel : imageTitleModel
            delegate: Rectangle {
                id: actionRect

                width: action.width + 30
                height: parent.height
                opacity: btnRepeater.count
                         === 5 ? ((index === 2
                                   || index === 3) ? 0.5 : 1.0) : (index === 1 ? 0.5 : 1.0)
                color: "transparent"

                JIconButton {
                    id: action

                    anchors {
                        verticalCenter: parent.verticalCenter
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: height
                    height: 44 + 10
                    source: name

                    MouseArea {
                        width: parent.width + 30
                        height: parent.height + 30

                        onClicked: {
                            var flag = model.flag
                            switch (flag) {
                            case 0:
                                rotateClicked()
                                break
                            case 1:
                                cropCLicked()
                                break
                            case 2:
                                saveToFileClicked()
                                break
                            case 3:
                                magicClicked()
                                break
                            case 4:
                                deleteDialog.open()
                                break
                            }
                        }
                    }
                }
            }
        }
    }
}
