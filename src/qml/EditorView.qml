

/*
 *   Copyright 2017 by Atul Sharma <atulsharma406@gmail.com>
 *             2021 Wang Rui <wangrui@jingos.com>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
import QtQuick 2.15
import QtQuick.Controls 2.10 as QQC2
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.kirigami 2.15 as Kirigami
import org.kde.jinggallery 0.2 as Koko
import org.kde.jinggallery.private 1.0 as KokoComponent
import QtQuick.Dialogs 1.0

Item {
    id: rootEditorView

    property var mediaType
    property int duration
    property string imageTime
    //mimeType.search("video") === 0
    property bool isVideo: mediaType === 1
    property bool resizing: false
    property var index
    property int mIndex
    property var delegate
    property string imagePath
    property string thumbnailPixmapPath
    property string mediaUrl
    property bool isViewClicked: false
    property int rotateCount
    property bool plStatus: previewLoader.status === Loader.Ready
    property bool isGif

    signal itemClicked
    signal deleteItemClicked
    signal playVideoItem

    Component.onDestruction: {
        root.backToPage()
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    function correctPos() {
        var w = editImage.width
        editImage.width = editImage.height
        editImage.height = w
        var factor = Math.min(rootEditorView.width * 1.0 / editImage.width,
                              rootEditorView.height * 1.0 / editImage.height)
        factor = Math.min(Math.max(factor, 1.0), 4.0)
        editImage.width = factor * editImage.width
        editImage.height = factor * editImage.height
        if (editImage.width < rootEditorView.width) {
            editImage.x = (rootEditorView.width - editImage.width) / 2
        } else if (editImage.x > 0) {
            editImage.x = 0
        } else if (editImage.right < rootEditorView.width) {
            editImage.x = rootEditorView.width - editImage.width
        }

        if (editImage.height < rootEditorView.height) {
            editImage.y = (rootEditorView.height - editImage.height) / 2
        } else if (editImage.y > 0) {
            editImage.y = 0
        } else if (editImage.bottom < rootEditorView.height) {
            editImage.y = rootEditorView.height - editImage.height
        }
    }

    function crop() {
        const ratioX = editImage.width * 1.0 / editImage.nativeWidth
        const ratioY = editImage.height * 1.0 / editImage.nativeHeight
        rootEditorView.resizing = false
        imageDoc.crop((resizeRectangle.x - editImage.x) / ratioX,
                      (resizeRectangle.y - editImage.y) / ratioY,
                      resizeRectangle.width / ratioX,
                      resizeRectangle.height / ratioY)
        listView.isCrop = false
    }

    Image {
        id: firstThumbImage

        width: rootEditorView.width
        height: rootEditorView.height
        source: thumbnailPixmapPath
        visible: isFirstOpenPage
        fillMode: Image.PreserveAspectFit
        autoTransform: true
    }

//    Image {
//        id: thumbImage

//        width: rootEditorView.width
//        height: rootEditorView.height
//        source: imagePath
//        asynchronous: true
//        visible: !previewLoader.active || previewLoader.status != Loader.Ready
//        fillMode: Image.PreserveAspectFit
//        autoTransform: true

//        onStatusChanged: {
//            if (thumbImage.status == Image.Ready
//                    && listView.currentIndex == mIndex) {
//                isFirstOpenPage = false
//            }
//        }

//        MouseArea {
//            anchors.fill: parent
//            onClicked: {
//                itemClicked()
//            }
//        }
//    }

    Component{
        id:moveComponent
        Item {
            id: moveContent

            width: rootEditorView.width
            height: rootEditorView.height

            PhotoImagePreview{
                id: thumbImage
                source: imagePath
                width: moveContent.width
                height: moveContent.height
                animated: model.mimeType === "image/gif"
//                visible: !previewLoader.active || previewLoader.status != Loader.Ready
                onImageClicked: {
                    itemClicked()
                }
            }
        }
    }

    Loader {
        id: moveLoader
        sourceComponent: moveComponent
        active: true//!previewLoader.active || previewLoader.status != Loader.Ready
    }

    Loader {
        id: previewLoader
        sourceComponent: previewComponent
        active: false//listView.currentIndex === mIndex && !listView.interactive && model.mimeType !== "image/gif"
    }

    Koko.ImageDocument {
        id: imageDoc
    }

    Component {
        id: previewComponent

        Item {
            id: content

            width: rootEditorView.width
            height: rootEditorView.height

            Component.onCompleted: {
                imageDoc.path = imagePath
            }

            Flickable {
                id: flickable

                width: rootEditorView.width
                height: rootEditorView.height
                contentWidth: width
                contentHeight: height
                contentX: editImage.x
                contentY: editImage.y
                interactive: contentWidth > width || contentHeight > height
                clip: true

                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    visible: !applicationWindow().controlsVisible
                }

                QQC2.ScrollBar.horizontal: QQC2.ScrollBar {
                    visible: !applicationWindow().controlsVisible
                }

                PinchArea {

                    property real initialWidth
                    property real initialHeight

                    width: Math.max(flickable.contentWidth, flickable.width)
                    height: Math.max(flickable.contentHeight, flickable.height)
                    pinch.maximumScale: 3.0
                    pinch.minimumScale: 0.3
                    pinch.dragAxis: Pinch.XAndYAxis

                    Koko.QImageItem {
                        id: editImage

                        property bool isDouble
                        property int clickCount

                        width: flickable.contentWidth
                        height: flickable.contentHeight
                        image: imageDoc.visualImage
                        fillMode: Koko.QImageItem.PreserveAspectFit

                        Timer {
                            id: signalClickTimer
                            interval: 200
                            onTriggered: {
                                editImage.clickCount = 0
                                itemClicked()
                            }
                        }

                        WheelHandler {
                            id: imageHandler
                            orientation: Qt.Vertical
                            acceptedDevices: PointerDevice.AllDevices
                            onWheel: {
                                if (event.modifiers & Qt.ControlModifier) {
                                    if (event.angleDelta.y != 0
                                            && event.angleDelta.x === 0) {
                                        var factor = 1 + event.angleDelta.y / 600
                                        zoomAnim.running = false
                                        flickable.resizeContent(
                                                    flickable.contentWidth * factor,
                                                    flickable.contentHeight * factor,
                                                    Qt.point(
                                                        flickable.width / 2,
                                                        flickable.height / 2))
                                    } else if (event.pixelDelta.y != 0) {
                                        flickable.resizeContent(
                                                    Math.min(Math.max(
                                                                 flickable.width, flickable.contentWidth + wheel.pixelDelta.y), flickable.width * 4), Math.min(
                                                        Math.max(flickable.height,
                                                                 flickable.contentHeight + wheel.pixelDelta.y),
                                                        flickable.height * 4),
                                                    event)
                                    }
                                }
                            }
                        }

                        MouseArea {

                            anchors.fill: parent

                            onClicked: {
                                editImage.clickCount++
                                if (editImage.clickCount === 2) {
                                    editImage.clickCount = 0
                                    if (signalClickTimer.running) {
                                        signalClickTimer.stop()
                                    }
                                    if (editImage.isDouble) {
                                        flickable.contentHeight = flickable.height
                                        flickable.contentWidth = flickable.width
                                        editImage.isDouble = false
                                        flickable.contentX = 0
                                        flickable.contentY = 0
                                    } else {
                                        flickable.contentHeight *= 2
                                        flickable.contentWidth *= 2
                                        editImage.isDouble = true
                                        flickable.contentX += flickable.contentWidth / 4
                                        flickable.contentY += flickable.contentHeight / 4
                                    }
                                } else if (!signalClickTimer.running) {
                                    signalClickTimer.start()
                                }
                                contextDrawer.drawerOpen = false
                            }

                            onDoubleClicked: {
                                editImage.clickCount = 0
                                if (signalClickTimer.running) {
                                    signalClickTimer.stop()
                                }
                                if (editImage.isDouble) {
                                    flickable.contentHeight = flickable.height
                                    flickable.contentWidth = flickable.width
                                    editImage.isDouble = false
                                    flickable.contentX = 0
                                    flickable.contentY = 0
                                } else {
                                    flickable.contentHeight *= 2
                                    flickable.contentWidth *= 2
                                    editImage.isDouble = true
                                    flickable.contentX += flickable.contentWidth / 4
                                    flickable.contentY += flickable.contentHeight / 4
                                }
                            }
                        }
                    }

                    onPinchStarted: {
                        initialWidth = flickable.contentWidth
                        initialHeight = flickable.contentHeight
                    }

                    onPinchUpdated: {
                        // resize content
                        flickable.resizeContent(
                                    Math.max(rootEditorView.width * 0.7,
                                             initialWidth * pinch.scale),
                                    Math.max(rootEditorView.height * 0.7,
                                             initialHeight * pinch.scale),
                                    pinch.center)
                    }

                    onPinchFinished: {
                        // Move its content within bounds.
                        if (pinch.scale < 1.0
                                && flickable.contentWidth < flickable.width) {
                            zoomAnim.currentWidth = initialWidth * pinch.scale
                            zoomAnim.currentHeight = initialHeight * pinch.scale
                            zoomAnim.width = flickable.width
                            zoomAnim.height = flickable.height
                            zoomAnim.running = true
                        }
                    }

                    ParallelAnimation {
                        id: zoomAnim

                        property real x: 0
                        property real y: 0
                        property real width: rootEditorView.width
                        property real height: rootEditorView.height
                        property real currentWidth: flickable.contentWidth
                        property real currentHeight: flickable.contentHeight

                        NumberAnimation {
                            target: flickable
                            property: "contentWidth"
                            from: currentWidth
                            to: zoomAnim.width
                            duration: Kirigami.Units.longDuration
                            easing.type: Easing.InOutQuad
                        }

                        NumberAnimation {
                            target: flickable
                            property: "contentHeight"
                            from: currentHeight
                            to: zoomAnim.height
                            duration: Kirigami.Units.longDuration
                            easing.type: Easing.InOutQuad
                        }

                        NumberAnimation {
                            target: flickable
                            property: "contentY"
                            from: flickable.contentY
                            to: zoomAnim.y
                            duration: Kirigami.Units.longDuration
                            easing.type: Easing.InOutQuad
                        }

                        NumberAnimation {
                            target: flickable
                            property: "contentX"
                            from: flickable.contentX
                            to: zoomAnim.x
                            duration: Kirigami.Units.longDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: videoPicLoader
        sourceComponent: videoPicComponent
        active: isVideo
        asynchronous: true
    }

    Component {
        id: videoPicComponent
        Item {
            width: rootEditorView.width
            height: rootEditorView.height
            Kirigami.JIconButton {
                id: videoPic

                anchors.centerIn: parent
                width: 120
                height: width
                source: "qrc:/assets/edit_audio.png"
                visible: isVideo

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        listView.model.playVedio(mediaUrl)
                        playVideoItem()
                    }
                }
            }
        }
    }

    Connections {
        target: imageDoc
        onUpdateThumbnail: {
            listView.thumbnailChanged(imagePath, index)
        }
    }

    function cropClicked() {
        listView.isCrop = true
        applicationWindow().pageStack.layers.push(comCrop)
    }

    function roatateClicked() {
        rotateCount++
        imageDoc.rotate(90)
    }

    function rotateSave() {
        imageDoc.save()
    }

    Component {
        id: comCrop

        CropView {
            id: cropView
            visible: listView.isCrop
        }
    }
}
