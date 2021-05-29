

/*
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */
import QtQuick 2.0
import QtQuick.Controls 2.2 as Controls
import QtQuick.Layouts 1.2
import "common.js" as CSJ
import org.kde.kirigami 2.15

Item {
    id: leftTitleView

    property var titleText
    property bool isEditShow: true
    property int checkboxHeight: 22 //* appScaleSize//root.height * (CSJ.Left_View_Cancel_Height / CSJ.ScreenHeight)
    property int skillHeight: 32 //* appScaleSize
    property var colorRow: "#00000000"
    property var editTextContent: "0"
    property ItemCheckBox allCheckBox: itemCheckBox
    property int selectCount
    property string tabBarSelectText

    signal editClicked
    signal cancelClicked
    signal deleteClicked
    signal allChecked(var status)

    width: parent.width
    height: 40

    Rectangle {
        id: checkboxshowRect

        property int immwidth: 20

        anchors {
            left: parent.left
            right: parent.right
            bottomMargin: 19
            rightMargin: 19
            leftMargin: 19
        }
        visible: isEditShow
        color: "transparent"
        width: parent.width
        height: parent.height

        RowLayout {
            id: rowLayout

            spacing: 0
            anchors {
                right: parent.right
                left: parent.left
                verticalCenter: parent.verticalCenter
            }

            Rectangle {
                color: colorRow
                Layout.fillWidth: true
                Layout.minimumHeight: skillHeight
                Layout.minimumWidth: (checkboxshowRect.width - checkboxshowRect.immwidth) / 2

                ItemCheckBox {
                    id: itemCheckBox

                    anchors {
                        left: parent.left
//                        bottom: parent.bottom
                        verticalCenter: parent.verticalCenter
                    }
                    radiusCB: width / 5
                    width: checkboxHeight
                    height: width
                    imageSourceDefault: selectCount !== albumView.gridViewCount
                                        && selectCount > 0 ? "qrc:/assets/check_ok.png" : "qrc:/assets/check_default.png"
                    checked: selectCount === albumView.gridViewCount

                    MouseArea {
                        width: itemCheckBox.width + 40
                        height: itemCheckBox.height + 40
                        anchors.centerIn: itemCheckBox
                        onClicked: {
                            allChecked(!itemCheckBox.checked)
                        }
                    }
                }

                Text {
                    id: ltTextView

                    anchors {
//                        bottom: itemCheckBox.bottom
                        verticalCenter: itemCheckBox.verticalCenter
                        left: itemCheckBox.right
                        leftMargin: 5 * appScaleSize
                    }
                    verticalAlignment: Text.AlignBottom
                    text: selectCount > albumView.gridViewCount
                          || selectCount < 0 ? 0 : selectCount
                    color: "#000000"
                    font.pixelSize: root.defaultFontSize
                }
            }

//            Rectangle {
//                color: colorRow
//                Layout.fillWidth: true
//                Layout.minimumHeight: checkboxHeight
//                Layout.minimumWidth: (checkboxshowRect.width - checkboxshowRect.immwidth) / 3
//                opacity: 0.5

//                JIconButton {
//                    id: foldersImage

//                    anchors.verticalCenter: parent.verticalCenter
//                    anchors.left: parent.left
//                    width: height
//                    height: checkboxHeight + 10
//                    source: selectCount <= 0 ? "qrc:/assets/folders_default.png" : "qrc:/assets/edit_savetofile.png"
//                }
//            }

            Rectangle {
                color: colorRow
                Layout.fillWidth: true
                Layout.minimumHeight: skillHeight
                Layout.minimumWidth: (checkboxshowRect.width - checkboxshowRect.immwidth) / 2 - 19

                JIconButton {
                    id: deleteImage

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    width: height
                    height: skillHeight
                    source: selectCount
                            <= 0 ? "qrc:/assets/delete_default.png" : "qrc:/assets/edit_delete.png"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (selectCount > 0) {
                            deleteDialog.open()
                        }
                    }
                }
            }

            AlertDialog {
                id: deleteDialog

                msgContent: updateMsg(tabBarSelectText, selectCount)

                onDialogLeftClicked: {
                    deleteDialog.close()
                }
                onDialogRightClicked: {
                    deleteClicked()
                    deleteDialog.close()
                }
            }

            Rectangle {
                color: colorRow
                Layout.fillWidth: true
                Layout.minimumHeight: skillHeight
                Layout.minimumWidth: (checkboxshowRect.width - checkboxshowRect.immwidth) / 3

                JIconButton {
                    id: cancelChecked
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    width: height
                    height: skillHeight
                    source: "qrc:/assets/cancel.png"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        cancelClicked()
                    }
                }
            }
        }
    }
}
