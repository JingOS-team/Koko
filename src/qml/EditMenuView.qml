

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

    property int mwidth: 200 * appScaleSize//root.screen.width * CSJ.Left_view_Edit_Menu_width / CSJ.ScreenCurrentWidth
    property int m_menItemHeight: 180 * heightScaleSize / 4//(root.screen.height * CSJ.Left_view_Edit_Menu_height / CSJ.ScreenCurrentHeight) / 4
    property int mheight: m_menItemHeight * menuItemCount
    //black #4DFFFFFF
    property var separatorColor: "#4Dffffff"
    property int separatorWidth: mwidth * 8 / 10
    property int mouseX
    property int mouseY
    property int menuItemCount: menu.count
    property int backRadius: 12 * appScaleSize
    property bool hasSelectItem
    property bool isbulkVisible
    property var tabSelectText
    property int selectCount
    signal bulkClicked
    signal deleteClicked
    signal renameClicked
    signal saveClicked

    padding: 0
    margins: 0
    modal:true
    closePolicy:Popup.CloseOnEscape | Popup.CloseOnReleaseOutside
    Overlay.modal: Rectangle {
        color: "#00000000"
    }
    function rmBulkAction() {
        var ba = menu.actionAt(0)
        if (ba.text === CSJ.Left_View_Edit_Menu_Bulk) {
            menu.takeAction(0)
        }
        if(menu.count > 1){
            var nameAction = menu.actionAt(1)
            if (nameAction.text === CSJ.Left_View_Edit_Menu_Rename) {
                menu.takeAction(1)
            }
        }
    }
    function addBulkAction() {
        var ba = menu.actionAt(0)
        if (ba.text !== CSJ.Left_View_Edit_Menu_Bulk) {
            menu.insertAction(0, bulkAction)
        }
//        var nameAction = menu.actionAt(menu.count - 1)
//        if (nameAction.text !== CSJ.Left_View_Edit_Menu_Rename) {
//            menu.insertAction(2, renameAction)
//        }
    }

    Action {
        id: bulkAction
        text: i18n(CSJ.Left_View_Edit_Menu_Bulk)
        checkable: true
        checked: false
        onCheckedChanged: {
            bulkClicked()
        }
    }

    Action {
        text: i18n(CSJ.Left_View_Edit_Menu_Delete)
        checkable: true
        checked: false
        onCheckedChanged: {
            deleteDialog.open()
        }
    }

//    Action {
//        text: i18n(CSJ.Left_View_Edit_Menu_Save)
//        checkable: true
//        checked: false
//        onCheckedChanged: {
//            saveClicked()
//        }
//    }

    delegate: MenuItem {
        id: menuItem
        width: menu.mwidth
        height: mheight / menuItemCount
        implicitWidth: menu.mwidth
        implicitHeight: mheight / menuItemCount
        padding: 0
        opacity: menuItem.text === CSJ.Left_View_Edit_Menu_Save ? 0.5 : 1.0

        MouseArea {
            anchors.fill: parent
            enabled: menuItem.opacity === 0.5
        }

        arrow: Canvas {
            width: 0
            height: 0
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
            height: mheight / menuItemCount
            implicitWidth: getAllWidth()

            function getAllWidth() {
                return menu.mwidth
            }
            Text {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                leftPadding: mwidth / 20
                text: menuItem.text
                font.pixelSize: defaultFontSize
                //black #ffffff
                color: menuItem.highlighted ? "#3C3F48" : "#3C3F48"
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            Image {
                id: rightImage
                width: height
                height: 16
                anchors {
                    right: parent.right
                    rightMargin: mwidth / 20
                    verticalCenter: parent.verticalCenter
                }
//                sourceSize: Qt.size(32,32)
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
            height: mheight / menuItemCount
            implicitWidth: menu.mwidth
            implicitHeight: mheight / menuItemCount
            clip: true
            Rectangle {
                id: bline
                width: separatorWidth
                height: 1
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                visible: menuItemCount === 3 ? (menuItem.text !== CSJ.Left_View_Edit_Menu_Rename):(menuItem.text !== CSJ.Left_View_Edit_Menu_Delete)
                color: separatorColor
            }
            Rectangle {
                anchors.fill: parent
                anchors.bottomMargin: menuItemCount === 1 ? 0 : (menu.currentIndex === 0 ? -radius : 0)
                anchors.topMargin: menuItemCount === 1 ? 0 :  (menu.currentIndex === menu.count - 1 ? -radius : 0)
                radius: menuItemCount === 1 ? backRadius : (menu.currentIndex === 0
                        || menu.currentIndex === menu.count - 1 ? backRadius : 0)
                color: menuItemCount === 1 ? "transparent" : (menuItem.highlighted ? "#2E747480" : "transparent")
            }

        }
    }

    background: Rectangle {
        id: mBr

        property string shadowColor: "#80C3C9D9"

        width: mwidth
        implicitWidth: mwidth
        //black #CC000000
        color: "#00000000"
        radius: backRadius

        border {
            width: 1
            color: "#C7D3DBEE"
        }
        layer.enabled: true
        layer.effect: DropShadow {
            id: rectShadow
            anchors.fill: mBr
            color: mBr.shadowColor
            source: mBr
            samples: 9
            radius: 4
            horizontalOffset: 0
            verticalOffset: 0
            spread: 0
        }
        ShaderEffectSource {
            id: eff
            width: fastBlur.width
            height: fastBlur.height
            sourceItem: page
            anchors.centerIn: fastBlur
            visible: false
            sourceRect: Qt.rect(mouseX, mouseY, width, height)
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
            radius: backRadius
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
            anchors.fill: mBr
            radius: backRadius
            visible: true
            //black #4D000000
            color: "#99FFFFFF"
            clip: true
        }
    }
}
