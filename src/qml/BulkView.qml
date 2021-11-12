/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Zhang He Gang <zhanghegang@jingos.com>
 *
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
    property int checkboxHeight: 22 * appScaleSize
    property int skillHeight: 32 * appScaleSize
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

        property int immwidth: 20 * appScaleSize

        anchors {
            left: parent.left
            right: parent.right
            bottomMargin: 19 * appScaleSize
            rightMargin: 19 * appScaleSize
            leftMargin: 19 * appScaleSize
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

                JIconButton{
                    id: jicon
                    anchors {
                        left: itemCheckBox.left
                        leftMargin: -5 * appScaleSize
                        verticalCenter: parent.verticalCenter
                    }
                    width: checkboxHeight + 5 * appScaleSize
                    height: checkboxHeight + 5 * appScaleSize
                    visible: selectCount !== albumView.gridViewCount
                    source: selectCount !== albumView.gridViewCount && selectCount > 0 ? "qrc:/assets/check_ok.png" : "qrc:/assets/check_default.png"
                    MouseArea {
                        width: itemCheckBox.width + 5 * appScaleSize
                        height: itemCheckBox.height + 5 * appScaleSize
                        anchors.centerIn: jicon
                        onClicked: {
                            allChecked(!itemCheckBox.checked)
                        }
                    }
                }

                ItemCheckBox {
                    id: itemCheckBox
                    visible: !jicon.visible

                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    radiusCB: width / 5
                    width: checkboxHeight
                    height: width
                    imageSourceDefault: selectCount !== albumView.gridViewCount
                                        && selectCount > 0 ? "qrc:/assets/check_ok.png" : "qrc:/assets/check_default.png"
                    checked: selectCount === albumView.gridViewCount

                    MouseArea {
                        width: itemCheckBox.width + 5
                        height: itemCheckBox.height + 5
                        anchors.centerIn: itemCheckBox
                        onClicked: {
                            allChecked(!itemCheckBox.checked)
                        }
                    }
                }

                Text {
                    id: ltTextView

                    anchors {
                        verticalCenter: itemCheckBox.verticalCenter
                        left: itemCheckBox.right
                        leftMargin: 5 * appScaleSize
                    }
                    verticalAlignment: Text.AlignBottom
                    text: selectCount > albumView.gridViewCount
                          || selectCount < 0 ? 0 : selectCount
                    color: JTheme.majorForeground//"#000000"
                    font.pixelSize: root.defaultFontSize * appFontSize
                }
            }

            Rectangle {
                color: colorRow
                Layout.fillWidth: true
                Layout.minimumHeight: skillHeight
                Layout.minimumWidth: (checkboxshowRect.width - checkboxshowRect.immwidth) / 2 - 19 * appScaleSize

                JIconButton {
                    id: deleteImage

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    width: height
                    height: skillHeight
                    source: selectCount
                            <= 0 ?  "qrc:/assets/delete_default.png": "qrc:/assets/edit_delete.svg"
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
                    source: "qrc:/assets/cancel.svg"
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
