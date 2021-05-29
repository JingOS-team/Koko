

/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *                             2021 Wang Rui <wangrui@jingos.com>
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */
import QtQuick 2.7
import QtQuick.Controls 2.1 as Controls
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.kirigami 2.15 as Kirigami
import org.kde.jinggallery 0.2 as Koko
import "common.js" as CSJ

Rectangle {
    id: albumDelegate

    property alias containsMouse: selectionHighlight.itemContainsMouse
    property QtObject modelData
    property string mimeType: modelData.mimeType
    property bool isVideoType: modelData.mediaType === 1
    property int duration: modelData.duration
    property bool itemHoverd
    property alias isMenuOpen : selectionHighlight.isShow
    property int count
    property int checkboxHeight: 22 
    signal clicked(var mouse)
    signal rightClicked(var mouse)
    signal pressAndHold(var mouse)
    signal activated

    width: gridView.cellWidth
    height: gridView.cellHeight
    color: "transparent"

    function reloadImage() {
        image.cache = false
        image.source = ""
    }

    Image {
        id: image

        property string imageSource: modelData.thumbnailPixmap

        anchors.centerIn: albumDelegate
        width: parent.width - (8 * appScaleSize)
        height: parent.height - (8 * appScaleSize)
        smooth: true
        asynchronous: true
        sourceSize: Qt.size(width, height)
        source: (isVideoType
                 && imageSource == "") ? "qrc:/assets/video_default.png" : imageSource //+"*"+count//"image://imageProvider/"+ modelData.mediaurl //"file:///home/test/Pictures/abhi-bakshi--adV1rnXsWQ-unsplash.jpg"
        fillMode: Image.PreserveAspectCrop

        onVisibleChanged: {
            if (visible) {
                if (image.source == "") {
                    image.source = modelData.thumbnailPixmap
                }
            }
        }
    }

    SelectionDelegateHighlight {
        id: selectionHighlight

        width: parent.width
        height: parent.height
//        visible: albumDelegate.itemHoverd
        color: "transparent"
        onItemClicked: {
            if (mouse.button !== Qt.RightButton && itemCheckBox.visible) {
                gridView.model.toggleSelected(model.index)
            } else {
                albumDelegate.clicked(mouse)
            }
        }
        onItemPressAndHold: {
            albumDelegate.pressAndHold(mouse)
        }
    }

//    MouseArea {
//        id: albumThumbnailMouseArea

//        acceptedButtons: Qt.LeftButton | Qt.RightButton
//        anchors.fill: parent
//        hoverEnabled: true

//        onEntered: {
//            albumDelegate.itemHoverd = true
//        }
//        onExited: {
//            albumDelegate.itemHoverd = false
//        }
//        onPressAndHold: {
//            albumDelegate.pressAndHold(mouse)
//        }
//        onClicked: {
//            if (mouse.button !== Qt.RightButton && itemCheckBox.visible) {
//                gridView.model.toggleSelected(model.index)
//            } else {
//                albumDelegate.clicked(mouse)
//            }
//        }
//    }

    Keys.onPressed: {
        switch (event.key) {
        case Qt.Key_Enter:
        case Qt.Key_Return:
        case Qt.Key_Space:
            activated()
            break
        default:
            break
        }
    }

    ItemCheckBox {
        id: itemCheckBox

        property int rightBottomMargin: 0
        anchors {
            right: parent.right
            rightMargin: 4 * appScaleSize
            bottom: image.bottom
            bottomMargin: rightBottomMargin * appScaleSize
        }
        visible: albumTabBar.bulkIsVisible
        radiusCB: width / 5
        enabled: false
        checked: getSelectMedias()
        isItem: true
        width: checkboxHeight
        height: width
        csource: checked ? "qrc:/assets/item_check_ok.png" : "qrc:/assets/item_check_default.png"

        function getSelectMedias() {
            return model.selected
        }
    }

    Rectangle {
        id: videoRect

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: image.bottom
        }
        width: image.width
        height: width / 7
        color: "#30000000"
        visible: getMimeType() && !itemCheckBox.visible

        function getMimeType() {
            return isVideoType
        }

        Image {
            id: videoImage

            anchors {
                left: parent.left
                leftMargin: height / 5
                verticalCenter: parent.verticalCenter
            }
            width: 18 //* appScaleSize//parent.width * CSJ.Item_Video_Width / CSJ.Item_Width
            height: width
//            sourceSize: Qt.size(36,36)
            source: "qrc:/assets/audio.png"
        }

        Text {
            id: timeText

            property int min
            property int hour

            anchors {
                right: parent.right
                rightMargin: videoImage.height / 5
                verticalCenter: parent.verticalCenter
            }
            text: getDurationTime()
            font.pixelSize: root.defaultFontSize - 3
            color: "#FFFFFF"

            function getDurationTime() {
                var seconds = duration % 60
                min = (duration % 3600) / 60
                hour = duration / 3600
                var secondsS = seconds > 9 ? seconds : "0" + seconds
                var minS = min > 9 ? min : "0" + min
                var hourS = hour > 9 ? hour : "0" + hour
                return hour > 0 ? (hourS + ":" + minS + ":" + secondsS) : ( minS + ":" + secondsS)
            }
        }
    }
}
