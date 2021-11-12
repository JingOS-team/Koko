

/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Zhang He Gang <zhanghegang@jingos.com>
 *
 */
import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.jinggallery 0.2 as Koko
import QtGraphicalEffects 1.0
import "common.js" as CSJ

Rectangle {
    id: tabBar

    property int currentWidth: parent.width
    property int currentHeight: parent.height
    property string selectedItem
    property ListModel model: listModel
    property alias itemSelctCount: bulkView.selectCount
    property bool bulkIsVisible: bulkView.visible

    anchors {
        left: parent.left
        leftMargin: height / 3
    }
    width: 304 * appScaleSize
    height: 35 * appScaleSize
    radius: height * 2 / 7
    z: 1

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {

        }
    }

    ShaderEffectSource {
        id: eff

        anchors.centerIn: fastBlur
        width: fastBlur.width
        height: fastBlur.height
        visible: false
        sourceRect: Qt.rect(getItemX(width, height), getItemY(width, height),
                            width, height)
        sourceItem: gridRect

        function getItemX(width, height) {
            var mapItem = eff.mapToItem(gridRect, 0, 0)
            return mapItem.x
        }

        function getItemY(width, height) {
            var mapItem = eff.mapToItem(gridRect, 0, 0)
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
        radius: height * 2 / 7
        visible: false
        clip: true
    }

    OpacityMask {
        id: mask
        anchors.fill: maskRect
        source: fastBlur
        maskSource: maskRect
    }

    Rectangle {
        id: backRect

        width: parent.width
        height: parent.height
        radius: height * 2 / 7
        color: Kirigami.JTheme.headerBackground
    }

    BulkView {
        id: bulkView

        visible: false
        anchors.centerIn: parent
        selectCount: albumView.itemCheckSelectCount
        tabBarSelectText: selectedItem

        onCancelClicked: {
            cancelBulk()
        }

        onDeleteClicked: {
            albumView.deleteItemClicked()
            cancelBulk()
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
            bulkView.selectCount++
        } else {
            if (bulkView.selectCount > 0) {
                bulkView.selectCount--
            }
        }
    }

    ListModel {
        id: listModel
    }

    onSelectedItemChanged: {
        for (var i = 0; i < btnRepeater.count; ++i) {
            var btn = btnRepeater.itemAt(i)
            if (selectedItem === btn.text) {
                btn.checked = true
                btn.focus = true
            } else {
                btn.checked = false
                btn.focus = false
            }
        }
    }

    Component {
        id: btnDelegate
        Button {
            id: btn

            anchors.verticalCenter: idRow.verticalCenter
            width: tabBar.width / 3 - 2 * appScaleSize
            height: tabBar.height * 0.9
            checked: text == tabBar.selectedItem ? true : false
            focus: text == tabBar.selectedItem ? true : false
            focusPolicy: Qt.StrongFocus

            onPressed: {
                albumView.filterBy(btnContent.text)
                tabBar.selectedItem = btnContent.text
            }
            contentItem: Rectangle {

                color: "transparent"
                opacity: btnContent.text == tabBar.selectedItem ? 1.0 : 0.4

                Kirigami.Icon {
                    id: btnImage

                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: (parent.width - btnImage.width
                                     - btnContent.contentWidth - btn.height / 4) / 2
                    }
                    width: 22 * appScaleSize
                    height: width
                    source: getImageSource()
                    color: Kirigami.JTheme.majorForeground

                    function getImageSource() {
                        switch (index) {
                        case 0:
                            return "qrc:/assets/all.png"
                        case 1:
                            return "qrc:/assets/pic.png"
                        case 2:
                            return "qrc:/assets/video.png"
                        }
                        return ""
                    }
                }
                Text {
                    id: btnContent

                    anchors {
                        left: btnImage.right
                        leftMargin: btn.height / 4
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr(listModel.get(index).title)
                    color: Kirigami.JTheme.majorForeground
                    font.pixelSize: root.defaultFontSize * appFontSize
                }
            }
            background: Rectangle {
                radius: tabBar.radius
                color: btnContent.text
                       === tabBar.selectedItem ? Kirigami.JTheme.currentBackground : "transparent"
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
            id: btnRepeater
            model: listModel
            delegate: btnDelegate
        }
    }
}
