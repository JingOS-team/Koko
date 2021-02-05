/*
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.12 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.jinggallery 0.2 as Koko
import QtGraphicalEffects 1.0
import "common.js" as CSJ

Rectangle {    
    id: tabBar

    property int currentWidth:parent.width
    property int currentHeight:parent.height
    property string selectedItem
    property ListModel  model: listModel
    property alias itemSelctCount : bulkView.selectCount
    property bool bulkIsVisible:bulkView.visible

    anchors{
        left: parent.left
        leftMargin:height/3
    }
    width:currentWidth *CSJ.TopBarWidth/CSJ.ScreenWidth
    height: currentHeight * CSJ.TopBarHeight/CSJ.ScreenHeight
    color:"transparent"
    radius: height*2/7
    z: 1

    MouseArea{
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
        }
    }

    ShaderEffectSource{
        id:eff

        anchors.centerIn: fastBlur
        width: fastBlur.width
        height: fastBlur.height
        visible: false
        sourceRect: Qt.rect(getItemX(width,height),getItemY(width,height),width,height)
        sourceItem: albumView

        function getItemX(width,height) {
            var mapItem = eff.mapToItem(albumView,eff.x,eff.y,width,height)
            return mapItem.x
        }

        function getItemY(width,height) {
            var mapItem = eff.mapToItem(albumView,eff.x,eff.y,width,height)
            return mapItem.y
        }
    }
    FastBlur{
        id:fastBlur

        anchors.fill: parent
        source: eff
        radius: 64
        cached: true
        visible: false
    }

    Rectangle{
        id:maskRect

        anchors.fill:fastBlur
        radius: height*2/7
        visible: false
        clip: true
    }

    OpacityMask{
        id:mask
        anchors.fill: maskRect
        visible: true
        source: fastBlur
        maskSource: maskRect
    }

    Rectangle{
        id:backRect

        width: parent.width
        height: parent.height
        radius: height*2/7
        color: "#80FFFFFF"
    }

    BulkView{
        id:bulkView

        visible: false
        anchors.centerIn: parent
        selectCount : albumView.itemCheckSelectCount
        tabBarSelectText: selectedItem

        onCancelClicked: {
            cancelBulk()
        }

        onDeleteClicked: {
            albumView.deleteItemClicked()
            cancelBulk();
        }

        onAllChecked: {
            albumView.allChecked(status)
        }
    }

    function cancelBulk() {
        if (bulkView.visible) {
            bulkView.visible = false
        }
        albumView.allChecked(false)
    }

    function bulkClick() {
        if (!bulkView.visible) {
            bulkView.visible = true
        }
    }

    function itemCheckBoxClick(isChecked) {
        if (isChecked) {
            bulkView.selectCount++;
        } else {
            if (bulkView.selectCount > 0) {
                bulkView.selectCount--;
            }
        }
    }

    ListModel{
        id:listModel
    }
    
    onSelectedItemChanged: {
        for (var i=0; i < btnRepeater.count; ++i)
        {
            var btn = btnRepeater.itemAt(i);
            if (selectedItem === btn.text) {
                btn.checked = true
                btn.focus = true
            } else {
                btn.checked = false
                btn.focus = false
            }
        }
    }

    Component{
        id:btnDelegate
        Button {
            id: btn

            anchors.verticalCenter: idRow.verticalCenter
            width: tabBar.width/3-2
            height: tabBar.height *0.9
            checked: text == tabBar.selectedItem ? true : false
            focus: text == tabBar.selectedItem ? true : false
            focusPolicy:Qt.StrongFocus

            onPressed: {
                root.filterBy(btnContent.text)
                tabBar.selectedItem = btnContent.text
            }
            contentItem: Rectangle{

                color: "transparent"
                opacity: btnContent.text == tabBar.selectedItem ? 1.0 : 0.4

                Image {
                    id: btnImage

                    anchors{
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: (parent.width-btnImage.width-btnContent.contentWidth- btn.height/4)/2
                    }
                    width: btn.height/2
                    height: width
                    source:getImageSource()

                    function getImageSource() {
                        switch(index) {
                        case 0:
                            return "qrc:/assets/all.png";
                        case 1:
                            return "qrc:/assets/pic.png";
                        case 2:
                            return "qrc:/assets/video.png";
                        }
                        return ""
                    }
                }
                Text {
                    id: btnContent

                    anchors{
                        left: btnImage.right
                        leftMargin: btn.height/4
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr(listModel.get(index).title)
                    color: "#000000"
                    font.pointSize: root.defaultFontSize + 2
                }
            }
            background: Rectangle {
                radius: tabBar.radius
                color: btnContent.text === tabBar.selectedItem ?"#FFFFFF": "transparent"
                opacity: btnContent.text == tabBar.selectedItem ? 1.0 : 0.6
            }
        }
    }
    Row {
        id: idRow

        anchors.fill: parent
        anchors.margins: {
            topMargin: height * 0.05
            bottomMargin: height * 0.05
        }
        visible: !bulkView.visible

        Repeater {
            id:btnRepeater
            model:listModel
            delegate: btnDelegate
        }
    }
}
