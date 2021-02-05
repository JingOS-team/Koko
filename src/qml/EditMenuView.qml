

/*
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */
import QtQuick 2.12
import QtQuick.Controls 2.12
import "common.js" as CSJ
import QtGraphicalEffects 1.0
import org.kde.kirigami 2.15

Menu {
    id: menu

    property int mwidth: root.width * CSJ.Left_view_Edit_Menu_width / CSJ.ScreenWidth
    property int mheight: root.height * CSJ.Left_view_Edit_Menu_height / CSJ.ScreenHeight
    property var separatorColor: "#4DFFFFFF"
    property int separatorWidth: mwidth * 9 / 10
    property int mouseX
    property int mouseY
    property bool hasSelectItem
    property bool isbulkVisible
    property var tabSelectText
    property int selectCount

    signal bulkClicked
    signal deleteClicked
    signal renameClicked
    signal saveClicked

    function rmBulkAction() {
        var ba = menu.actionAt(0)
        if (ba.text === CSJ.Left_View_Edit_Menu_Bulk) {
            menu.takeAction(0)
        }
    }

    function addBulkAction() {
        var ba = menu.actionAt(0)
        if (ba.text !== CSJ.Left_View_Edit_Menu_Bulk) {
            menu.insertAction(0, bulkAction)
        }
    }

    Action {
        id: bulkAction

        text: qsTr(CSJ.Left_View_Edit_Menu_Bulk)
        checkable: true
        checked: false
        onCheckedChanged: {
            bulkClicked()
        }
    }

    Action {
        id: deleteAction

        text: qsTr(CSJ.Left_View_Edit_Menu_Delete)
        checkable: true
        checked: false

        onCheckedChanged: {
            if (isbulkVisible) {
                if (hasSelectItem) {
                    deleteDialog.open()
                }
            } else {
                deleteDialog.open()
            }
        }
    }

    Action {
        id: saveAction

        text: qsTr(CSJ.Left_View_Edit_Menu_Save)
        checkable: true
        checked: false
        onCheckedChanged: {
            saveClicked()
        }
    }

    AlertDialog {
        id: deleteDialog

        msgContent: updateMsg(tabSelectText, selectCount)
        onDialogLeftClicked: {
            deleteDialog.close()
        }
        onDialogRightClicked: {
            deleteClicked()
            deleteDialog.close()
        }
    }

    delegate: MenuItem {
        id: menuItem

        anchors {
            left: parent.left
            right: parent.right
        }
        width: menu.mwidth
        height: mheight / 4
        opacity: menuItem.text === CSJ.Left_View_Edit_Menu_Save ? 0.5 : 1.0

        MouseArea {
            anchors.fill: parent
            enabled: menuItem.opacity === 0.5
        }

        arrow: Canvas {
            x: parent.width - width
            width: 40
            height: 40
            visible: menuItem.subMenu
            onPaint: {
                var ctx = getContext("2d")
                ctx.fillStyle = menuItem.highlighted ? "#ffffff" : "#21be2b"
                ctx.moveTo(15, 15)
                ctx.lineTo(width - 15, height / 2)
                ctx.lineTo(15, height - 15)
                ctx.closePath()
                ctx.fill()
            }
        }

        indicator: Item {
            width: 0
            height: 0
        }

        contentItem: Item {
            id: munuContentItem

            width: menuItem.width
            height: mheight / 4
            Text {
                leftPadding: mwidth / 20
                text: menuItem.text
                font.pointSize: root.defaultFontSize + 2
                anchors.verticalCenter: parent.verticalCenter
                color: menuItem.highlighted ? "#000000" : "#000000"
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            JIconButton {
                id: rightImage

                anchors {
                    right: parent.right
                    rightMargin: mwidth / 10
                }
                anchors.verticalCenter: parent.verticalCenter
                width: height
                height: parent.height / 2 + 10
                source: getSource()

                function getSource() {
                    switch (menuItem.text) {
                    case CSJ.Left_View_Edit_Menu_Bulk:
                        return "qrc:/assets/edit_bulk.png"
                    case CSJ.Left_View_Edit_Menu_Delete:
                        return "qrc:/assets/edit_delete.png"
                    case CSJ.Left_View_Edit_Menu_Rename:
                        return "qrc:/assets/edit_rename.png"
                    case CSJ.Left_View_Edit_Menu_Save:
                        return "qrc:/assets/edit_savetofile.png"
                    }
                    return ""
                }
            }
        }

        background: Item {
            width: menu.mwidth
            height: mheight / 4
            implicitWidth: menu.mwidth
            implicitHeight: mheight / menuItemCount
            clip: true

            Rectangle {
                anchors.fill: parent
                anchors.bottomMargin: menu.currentIndex === 0 ? -radius : 0
                anchors.topMargin: menu.currentIndex === menu.count - 1 ? -radius : 0
                radius: menu.currentIndex === 0
                        || menu.currentIndex === menu.count - 1 ? 20 : 0
                color: menuItem.highlighted ? "#2E747480" : "transparent"
            }
            Rectangle {
                id: bline

                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: separatorWidth
                height: 1
                visible: menuItem.text !== CSJ.Left_View_Edit_Menu_Save
                color: separatorColor
            }
        }
    }

    background: Rectangle {
        width: mwidth
        color: "#60FFFFFF"
        border.width: 0
        radius: height / 10
        ShaderEffectSource {
            id: eff

            anchors.centerIn: fastBlur
            width: fastBlur.width
            height: fastBlur.height
            visible: false
            sourceItem: albumView
            sourceRect: Qt.rect(mouseX, mouseY, width, height)

            function getItemX(width, height) {
                var mapItem = eff.mapToItem(albumView, mouseX, mouseY,
                                            width, height)
                return mapItem.x
            }

            function getItemY(width, height) {
                var mapItem = eff.mapToItem(albumView, mouseX, mouseY,
                                            width, height)
                return mapItem.y
            }
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
            radius: height / 10
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
            color: "#99FFFFFF"
            width: parent.width
            height: parent.height
            radius: height / 10
        }
    }
}
