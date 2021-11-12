/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Zhang He Gang <zhanghegang@jingos.com>
 *
 */
import QtQuick 2.15
import org.kde.kquickcontrolsaddons 2.0 as KQA
import QtQuick.Controls 2.10 as QQC2
import org.kde.jinggallery.private 1.0 as KokoComponent
import org.kde.jinggallery 0.2 as Koko
import "common.js" as CSJ

Item {
    id: cropView

    property int cropImageMaxHeight: 515 * appScaleSize
    property int cropImageMaxWidth: cropView.width * 4 / 5
    property int cropImageHeight: 515 * appScaleSize
    property int cropImageWidth: cropView.width * 4 / 5

    width: parent.width
    height: parent.height

    Component.onCompleted: {
        imageDoc.path = imagePath
        rotateCount = 0
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
            recAnima.width = cropImageWidth
            recAnima.height = cropImageHeight
            recAnima.running = true
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

        onWidthChanged: {
            contentWidth = width
        }
        onHeightChanged: {
            contentHeight = height
        }

        Component.onCompleted: {
            cropImageMaxWidth = flickable.width
            cropImageMaxHeight = flickable.height
        }

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
            property int maxScale: 3

            pinch.maximumScale: 2
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
                                var wheelChangeWidth = flickable.contentWidth * factor
                                if(wheelChangeWidth < flickable.width * imagepinchArea.maxScale && wheelChangeWidth > flickable.width){
                                    flickable.resizeContent(
                                                wheelChangeWidth,
                                                flickable.contentHeight * factor,
                                                Qt.point(flickable.width / 2,
                                                         flickable.height / 2))
                                }
                            } else if (event.pixelDelta.y != 0) {
                                var wheelPW = Math.min(Math.max(
                                                           flickable.width, flickable.contentWidth
                                                           + wheel.pixelDelta.y), flickable.width
                                                       * 4)
                                if(wheelPW < flickable.width * imagepinchArea.maxScale && wheelPW > flickable.width){
                                    flickable.resizeContent(
                                                wheelPW , Math.min(
                                                    Math.max(flickable.height,
                                                             flickable.contentHeight + wheel.pixelDelta.y),
                                                    flickable.height * 4), event)
                                }
                            }
                        } else {
                            if(flickable.contentWidth > flickable.width || flickable.contentHeight > flickable.height){
                                flickable.contentX += event.pixelDelta.x
                                flickable.contentY += event.pixelDelta.y
                            }
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
                var changeWidth = initialWidth * pinch.scale
                var changeHeight = initialHeight * pinch.scale
                if (pinch.scale < 1.0
                        && flickable.contentWidth < flickable.width) {
                    zoomAnim.currentWidth = changeWidth
                    zoomAnim.currentHeight = changeHeight
                    zoomAnim.width = flickable.width
                    zoomAnim.height = flickable.height
                    zoomAnim.running = true
                }

                if(changeWidth > flickable.width * maxScale){
                    flickable.resizeContent(flickable.width * maxScale,
                                            flickable.height * maxScale,
                                            pinch.previousCenter)
                    zoomContent.currentWidth = changeWidth
                    zoomContent.currentHeight = changeHeight
                    zoomContent.width = flickable.width * maxScale
                    zoomContent.height = flickable.height * maxScale
                    zoomContent.running = true
                }
            }

            ParallelAnimation {
                id: zoomContent

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
                    to: zoomContent.width
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: flickable
                    property: "contentHeight"
                    from: currentHeight
                    to: zoomContent.height
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
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
        id:vabView
        anchors.centerIn: flickable
        width: flickable.width
        height: flickable.height
        sourceView: flickable
    }

    NumberAnimation {
        id:vabAnima
        target: vabView
        property: "opacity"
        from: 0
        to: 1
        duration: 250
        easing.type: Easing.InOutQuad
    }

    Rectangle{
      anchors.fill: vabView
      color: "#80000000"
      visible: vabView.visible
    }

    KokoComponent.ResizeRectangle {
        id: resizeRectangle

        property bool isComponent
        property int itemMargins: - rzTopLeft.rhHeight
        property bool isRectChanged
        property int whiteLineWidth: 1

        width: cropImageWidth > flickable.width ? flickable.width : cropImageWidth
        height: cropImageHeight > flickable.height ? flickable.height : cropImageHeight
        x: (cropView.width - Math.min(cropView.width, flickable.width)) / 2
        y: (cropView.height - Math.min(cropView.height, flickable.height)) / 2
        moveAreaRect: Qt.rect(flickable.x,flickable.y,flickable.width,flickable.height)


        onMoveRect: {
         if(isMove){
             vabView.visible = false
         } else {
             vabView.visible = true
         }
        }

        onWidthChanged: {
            isRectChanged = (width !== cropEditImage.width)
            if(vabView.opacity !== 0){
                vabAnima.from = 1.0
                vabAnima.to = 0
                vabAnima.running = true
            }
            if (isComponent && doneImage.opacity != 1.0) {
                doneImage.opacity = 1.0
            }
            if(!isRectChanged && !recAnima.isRotationImage){
              doneImage.opacity = 0.5
            }
        }
        onHeightChanged: {
            isRectChanged = (height !== cropEditImage.height)

            if(vabView.opacity !== 0){
                vabAnima.from = 1.0
                vabAnima.to = 0
                vabAnima.running = true
            }
            if (isComponent && doneImage.opacity != 1.0) {
                doneImage.opacity = 1.0
            }
            if(!isRectChanged && !recAnima.isRotationImage){
              doneImage.opacity = 0.5
            }
        }

        Component.onCompleted: {
            isComponent = true
        }

        BasicResizeHandle {
            id: rzTopLeft

            onOnReleased: {
                if(vabView !== 1){
                    vabAnima.from = 0
                    vabAnima.to = 1.0
                    vabAnima.running = true
                }
            }
            rectangle: resizeRectangle
            resizeCorner: KokoComponent.ResizeHandle.TopLeft
            moveAreaRect:  Qt.rect(flickable.x,flickable.y,flickable.width,flickable.height)
            anchors {
                left: parent.left
                leftMargin: resizeRectangle.itemMargins
                top: parent.top
                topMargin: resizeRectangle.itemMargins
            }
        }

        BasicResizeRightHandle {
            id: rzBottomLeft

            onOnReleased: {
                if(vabView !== 1){
                    vabAnima.from = 0
                    vabAnima.to = 1.0
                    vabAnima.running = true
                }
            }
            rectangle: resizeRectangle
            resizeCorner: KokoComponent.ResizeHandle.BottomLeft
            moveAreaRect:  Qt.rect(flickable.x,flickable.y,flickable.width,flickable.height)

            anchors {
                left: parent.left
                bottom: parent.bottom
                bottomMargin: resizeRectangle.itemMargins - resizeRectangle.whiteLineWidth
            }
        }

        BasicResizeHandle {
            id: rzBottomRight

            onOnReleased: {
                if(vabView !== 1){
                    vabAnima.from = 0
                    vabAnima.to = 1.0
                    vabAnima.running = true
                }
            }
            rectangle: resizeRectangle
            resizeCorner: KokoComponent.ResizeHandle.BottomRight
            moveAreaRect:  Qt.rect(flickable.x,flickable.y,flickable.width,flickable.height)

            anchors {
                right: parent.right
                rightMargin: resizeRectangle.itemMargins - resizeRectangle.whiteLineWidth
                bottom: parent.bottom
                bottomMargin: -resizeRectangle.whiteLineWidth
            }
        }

        BasicResizeRightHandle {
            rectangle: resizeRectangle
            resizeCorner: KokoComponent.ResizeHandle.TopRight
            moveAreaRect:  Qt.rect(flickable.x,flickable.y,flickable.width,flickable.height)

            onOnReleased: {
                if(vabView !== 1){
                    vabAnima.from = 0
                    vabAnima.to = 1.0
                    vabAnima.running = true
                }
            }
            anchors {
                right: parent.right
                top: parent.top
                topMargin: resizeRectangle.itemMargins
                rightMargin: -resizeRectangle.whiteLineWidth
            }
        }

        Rectangle {
            id: lineRect
            color: "#00000000"
            anchors.fill: parent
            ShaderEffectSource {
                id: ett

                visible: vabView.visible
                sourceItem: flickable
                width: resizeRectangle.width
                height: resizeRectangle.height
                sourceRect: visible ? Qt.rect(getItemX(resizeRectangle.width,
                                             resizeRectangle.height),
                                    getItemY(resizeRectangle.width,
                                             resizeRectangle.height),
                                    resizeRectangle.width,
                                    resizeRectangle.height) : Qt.rect(getItemX(resizeRectangle.width,
                                                                                              resizeRectangle.height),
                                                                                     getItemY(resizeRectangle.width,
                                                                                              resizeRectangle.height),
                                                                                     resizeRectangle.width,
                                                                                     resizeRectangle.height)

                function getItemX(width, height) {
                   var mapItem = ett.mapToItem(flickable, 0, 0)
                    return mapItem.x
                }
                function getItemY(width, height) {
                    var mapItem = ett.mapToItem(flickable, 0, 0)
                    return mapItem.y
                }
            }

            Row {
                id: idRow

                anchors.fill: parent
                spacing: width / 3 - resizeRectangle.whiteLineWidth
                Repeater {
                    id: btnRepeater
                    model: 4
                    delegate: Rectangle {
                        width: resizeRectangle.whiteLineWidth
                        height: lineRect.height
                        color: "white"
                    }
                }
            }

            Column {
                id: idcolum

                width: parent.width + resizeRectangle.whiteLineWidth
                height: parent.height
                spacing: height / 3 - resizeRectangle.whiteLineWidth
                Repeater {
                    id: cline
                    model: 4
                    delegate: Rectangle {
                        width: idcolum.width
                        height: resizeRectangle.whiteLineWidth
                        color: "white"
                    }
                }
            }
        }

        ParallelAnimation {
            id: recAnima

            property real width: resizeRectangle.width
            property real height: resizeRectangle.height
            property bool isRotationImage

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
                if (doneImage.opacity === 1.0 && !isRotationImage) {
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

            color: rightToolView.isWheel ? "#FFFFFF" : "#4DFFFFFF"
            text: i18n("Reduction")
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: root.defaultFontSize

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
            titleContent: i18n("Abandoning modification")
            msgContent:i18n("Are you sure to discard the current modification")
            rightButtonContent: i18n("Action")
            onDialogLeftClicked: {
                saveDialog.close()
            }
            onDialogRightClicked: {
                rootEditorView.rotateCount = 0
                vabView.visible = false
                saveDialog.close()
                cropImageWidth = cropImageMaxWidth
                cropImageHeight = cropImageMaxHeight
                flickable.contentWidth = flickable.width
                flickable.contentHeight = flickable.height
                recAnima.isRotationImage = false
                imageDoc.clearUndoImage()
                
                resizeRectangle.x = flickable.x
                resizeRectangle.y = flickable.y
                vabView.visible = true
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
                    vabView.visible = false
                    cropImageWidth = cropImageMaxWidth
                    cropImageHeight = cropImageMaxHeight
                    flickable.contentWidth = flickable.width
                    flickable.contentHeight = flickable.height
                    recAnima.isRotationImage = true
                    rootEditorView.roatateClicked()
                    resizeRectangle.x = flickable.x
                    resizeRectangle.y = flickable.y
                    vabView.visible = true
                    if(rootEditorView.rotateCount % 4 == 0){
                        doneImage.opacity = 0.5
                    }else {
                        doneImage.opacity = 1.0
                    }
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
