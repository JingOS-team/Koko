

/*
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */
import QtQuick 2.15
import org.kde.kquickcontrolsaddons 2.0 as KQA
import QtQuick.Controls 2.10 as QQC2
import org.kde.jinggallery.private 1.0 as KokoComponent
import org.kde.jinggallery 0.2 as Koko
import "common.js" as CSJ

Item {
    id: cropView

    property int cropImageMaxHeight: cropView.height * CSJ.Item_Crop_Heigh
                                     / CSJ.Item_Crop_View_Heigh
    property int cropImageMaxWidth: cropView.width * 4 / 5
    property int cropImageHeight: cropView.height * CSJ.Item_Crop_Heigh / CSJ.Item_Crop_View_Heigh
    property int cropImageWidth: cropView.width * 4 / 5

    width: parent.width
    height: parent.height

    Component.onCompleted: {
        cropImageHeight = cropEditImage.paintedHeight
        cropImageWidth = cropEditImage.paintedWidth
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    Connections {
        target: imageDoc
        onVisualImageChanged: {
            cropImageWidth = cropEditImage.paintedWidth
            cropImageHeight = cropEditImage.paintedHeight
        }
    }

    Flickable {
        id: flickable

        anchors.centerIn: cropView
        width: cropImageWidth
        height: cropImageHeight
        contentWidth: width
        contentHeight: height
        contentX: cropEditImage.x
        contentY: cropEditImage.y
        interactive: contentWidth > width || contentHeight > height
        clip: true

        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
            visible: !applicationWindow().controlsVisible
        }
        QQC2.ScrollBar.horizontal: QQC2.ScrollBar {
            visible: !applicationWindow().controlsVisible
        }

        PinchArea {
            id: imagepinchArea

            property real initialWidth
            property real initialHeight

            pinch.maximumScale: 3.0
            pinch.minimumScale: 0.3
            pinch.dragAxis: Pinch.XAndYAxis
            width: Math.max(flickable.contentWidth, flickable.width)
            height: Math.max(flickable.contentHeight, flickable.height)

            Koko.QImageItem {
                id: cropEditImage

                property bool isDouble

                fillMode: Koko.QImageItem.PreserveAspectFit
                width: flickable.contentWidth
                height: flickable.contentHeight
                image: imageDoc.visualImage

                Component.onCompleted: {
                    x = (flickable.width - width) / 2
                    y = (flickable.height - height) / 2
                }

                WheelHandler {
                    id: cropImageHandler
                    orientation: Qt.Vertical
                    acceptedDevices: PointerDevice.AllDevices

                    onWheel: {
                        if (event.modifiers & Qt.ControlModifier) {
                            if (event.angleDelta.y != 0) {
                                if (doneImage.opacity != 1.0) {
                                    doneImage.opacity = 1.0
                                }
                                var factor = 1 + event.angleDelta.y / 600
                                zoomAnim.running = false
                                flickable.resizeContent(
                                            flickable.contentWidth * factor,
                                            flickable.contentHeight * factor,
                                            Qt.point(flickable.width / 2,
                                                     flickable.height / 2))
                            } else if (event.pixelDelta.y != 0) {
                                flickable.resizeContent(
                                            Math.min(Math.max(
                                                         flickable.width, flickable.contentWidth
                                                         + wheel.pixelDelta.y), flickable.width
                                                     * 4), Math.min(
                                                Math.max(flickable.height,
                                                         flickable.contentHeight + wheel.pixelDelta.y),
                                                flickable.height * 4), event)
                            }
                        } else {
                            flickable.contentX += event.pixelDelta.x
                            flickable.contentY += event.pixelDelta.y
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    scrollGestureEnabled: false
                    onClicked: {
                        contextDrawer.drawerOpen = false
                    }
                }
            }

            onPinchStarted: {
                initialWidth = flickable.contentWidth
                initialHeight = flickable.contentHeight
                if (doneImage.opacity != 1.0) {
                    doneImage.opacity = 1.0
                }
            }

            onPinchUpdated: {
                flickable.resizeContent(initialWidth * pinch.scale,
                                        initialHeight * pinch.scale,
                                        pinch.center)
            }

            onPinchFinished: {
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
                property real width: flickable.width
                property real height: flickable.height
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

    VagueBackground {
        anchors.centerIn: flickable
        width: flickable.width
        height: flickable.height
        sourceView: flickable
    }

    KokoComponent.ResizeRectangle {
        id: resizeRectangle

        property bool isComponent
        property int itemMargins: -6

        width: cropImageWidth
        height: cropImageHeight
        x: (cropView.width - Math.min(cropView.width, flickable.width)) / 2
        y: (cropView.height - Math.min(cropView.height, flickable.height)) / 2

        onWidthChanged: {
            if (isComponent && doneImage.opacity != 1.0) {
                doneImage.opacity = 1.0
            }
        }
        onHeightChanged: {
            if (isComponent && doneImage.opacity != 1.0) {
                doneImage.opacity = 1.0
            }
        }

        Component.onCompleted: {
            isComponent = true
        }

        BasicResizeHandle {
            id: rzTopLeft

            rectangle: resizeRectangle
            resizeCorner: KokoComponent.ResizeHandle.TopLeft
            anchors {
                left: parent.left
                leftMargin: resizeRectangle.itemMargins
                top: parent.top
                topMargin: resizeRectangle.itemMargins + 1
            }
        }

        BasicResizeRightHandle {
            id: rzBottomLeft

            rectangle: resizeRectangle
            resizeCorner: KokoComponent.ResizeHandle.BottomLeft
            anchors {
                left: parent.left
                bottom: parent.bottom
                bottomMargin: resizeRectangle.itemMargins
            }
        }

        BasicResizeHandle {
            id: rzBottomRight

            rectangle: resizeRectangle
            resizeCorner: KokoComponent.ResizeHandle.BottomRight
            anchors {
                right: parent.right
                rightMargin: resizeRectangle.itemMargins
                bottom: parent.bottom
            }
        }

        BasicResizeRightHandle {
            rectangle: resizeRectangle
            resizeCorner: KokoComponent.ResizeHandle.TopRight
            anchors {
                right: parent.right
                top: parent.top
                topMargin: resizeRectangle.itemMargins + 1
            }
        }

        Rectangle {
            id: lineRect
            color: "#00000000"
            anchors.fill: parent
            ShaderEffectSource {
                id: ett

                sourceItem: flickable
                width: resizeRectangle.width
                height: resizeRectangle.height
                sourceRect: Qt.rect(getItemX(resizeRectangle.width,
                                             resizeRectangle.height),
                                    getItemY(resizeRectangle.width,
                                             resizeRectangle.height),
                                    resizeRectangle.width,
                                    resizeRectangle.height)

                function getItemX(width, height) {
                    mapToItem(resizeRectangle, ett.x, ett.y)
                    var mapItem = ett.mapToItem(flickable, ett.x, ett.y,
                                                width, height)
                    return mapItem.x
                }
                function getItemY(width, height) {
                    var mapItem = ett.mapToItem(flickable, ett.x, ett.y,
                                                width, height)
                    return mapItem.y
                }
            }

            Row {
                id: idRow

                anchors.fill: parent
                spacing: width / 3 - 1
                Repeater {
                    id: btnRepeater
                    model: 4
                    delegate: Rectangle {
                        width: 1
                        height: lineRect.height
                        color: "white"
                    }
                }
            }

            Column {
                id: idcolum

                anchors.fill: parent
                spacing: height / 3 - 1
                Repeater {
                    id: cline
                    model: 4
                    delegate: Rectangle {
                        width: lineRect.width
                        height: 1
                        color: "white"
                    }
                }
            }
        }

        ParallelAnimation {
            id: recAnima

            property real width: resizeRectangle.width
            property real height: resizeRectangle.height
            NumberAnimation {
                target: resizeRectangle
                property: "width"
                from: resizeRectangle.width
                to: recAnima.width
                duration: 500
                easing.type: Easing.InOutQuad
            }

            NumberAnimation {
                target: resizeRectangle
                property: "height"
                from: resizeRectangle.height
                to: recAnima.height
                duration: 500
                easing.type: Easing.InOutQuad
            }
            onStopped: {
                if (doneImage.opacity === 1.0) {
                    doneImage.opacity = 0.5
                }
            }
        }
    }

    Rectangle {
        id: rightToolView

        property bool isWheel: doneImage.opacity === 1.0

        width: parent.width / 10
        height: parent.height
        color: "transparent"
        anchors {
            top: parent.top
            topMargin: reduction.height * 2
            bottom: parent.bottom
            right: parent.right
        }

        Text {
            id: reduction

            color: rightToolView.isWheel ? "#FFFFFF" : "#99FFFFFF"
            text: qsTr("Reduction")
            anchors.horizontalCenter: parent.horizontalCenter
            font.pointSize: root.defaultFontSize + 2

            MouseArea {
                anchors.fill: reduction
                onClicked: {
                    if (rightToolView.isWheel) {
                        saveDialog.open()
                    }
                }
            }
        }

        AlertDialog {
            id: saveDialog
            titleContent: "Abandoning modification"
            msgContent: "Are you sure to discard the current modification"
            rightButtonContent: "Action"
            onDialogLeftClicked: {
                saveDialog.close()
            }
            onDialogRightClicked: {
                saveDialog.close()
                cropImageWidth = cropImageMaxWidth
                cropImageHeight = cropImageMaxHeight
                imageDoc.clearUndoImage()
                recAnima.width = flickable.width
                recAnima.height = flickable.height
                recAnima.running = true
            }
        }

        Image {
            id: rotateImage

            anchors {
                bottom: cancelImage.top
                bottomMargin: CSJ.Item_Crop_Done_Width
                horizontalCenter: parent.horizontalCenter
            }
            source: "qrc:/assets/crop_rotate.png"
            width: CSJ.Item_Crop_Done_Width
            height: width

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    cropImageWidth = cropImageMaxWidth
                    cropImageHeight = cropImageMaxHeight
                    rootEditorView.roatateClicked()
                }
            }
        }

        Image {
            id: cancelImage

            source: "qrc:/assets/crop_delete.png"
            width: CSJ.Item_Crop_Done_Width
            height: width
            anchors {
                bottom: doneImage.top
                bottomMargin: CSJ.Item_Crop_Done_Width
                horizontalCenter: parent.horizontalCenter
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    applicationWindow().pageStack.layers.pop()
                }
            }
        }
        Image {
            id: doneImage

            source: "qrc:/assets/done.png"
            width: CSJ.Item_Crop_Done_Width
            height: width
            opacity: 0.5
            anchors {
                bottom: parent.bottom
                bottomMargin: CSJ.Item_Crop_Done_Width
                horizontalCenter: parent.horizontalCenter
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (rightToolView.isWheel) {
                        crop()
                        applicationWindow().pageStack.layers.pop()
                    }
                }
            }
        }
    }

    function crop() {
        const ratioX = flickable.contentWidth * 1.0 / cropEditImage.nativeWidth
        const ratioY = flickable.contentHeight * 1.0 / cropEditImage.nativeHeight
        var cRect = cropEditImage.mapToItem(cropView, cropEditImage.x,
                                            cropEditImage.y)
        imageDoc.crop((resizeRectangle.x - cRect.x) / ratioX,
                      (resizeRectangle.y - cRect.y) / ratioY,
                      resizeRectangle.width / ratioX,
                      resizeRectangle.height / ratioY)
        listView.isCrop = false
        imageDoc.saveAs()
        listView.cropImageChanged(imageDoc.path, index)
    }
}
