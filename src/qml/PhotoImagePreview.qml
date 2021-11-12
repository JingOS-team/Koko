/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Zhang He Gang <zhanghegang@jingos.com>
 *
 */
import QtQuick 2.5
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0
import org.kde.kirigami 2.7 as Kirigami

Flickable
{
    id: flick

    property alias image: _imageLoader.item
    property bool animated: false
    property url source

    signal rightClicked();
    signal imageClicked();
    signal pressAndHold();

    contentWidth: flick.width
    contentHeight: flick.height

    interactive: (contentWidth > width || contentHeight > height)
    z: 1000

    onContentXChanged:{
          }

    ScrollBar.vertical: ScrollBar {}
    ScrollBar.horizontal: ScrollBar {}

    PinchArea
    {
        width: Math.max(flick.contentWidth, flick.width)
        height: Math.max(flick.contentHeight, flick.height)

        property real initialWidth
        property real initialHeight
        property int maxScale: 3

        onPinchStarted:
        {
            initialWidth = flick.contentWidth
            initialHeight = flick.contentHeight
        }

        onPinchUpdated:
        {
            // adjust content pos due to drag
            flick.contentX += pinch.previousCenter.x - pinch.center.x
            flick.contentY += pinch.previousCenter.y - pinch.center.y

            // resize content
            flick.resizeContent(Math.max(flick.width*0.7, initialWidth * pinch.scale), Math.max(flick.height*0.7, initialHeight * pinch.scale), pinch.center)
        }

        onPinchFinished:
        {
            // Move its content within bounds.
            if (flick.contentWidth < flick.width || flick.contentHeight < flick.height)
            {
                zoomAnim.x = 0;
                zoomAnim.y = 0;
                zoomAnim.width = flick.width;
                zoomAnim.height = flick.height;
                zoomAnim.running = true;
            } else {
                flick.returnToBounds();
            }

            if(initialWidth * pinch.scale > flick.width * maxScale){
                flick.resizeContent(flick.width * maxScale,
                                        flick.height * maxScale,
                                        pinch.previousCenter)
                zoomContent.width = flick.width * maxScale
                zoomContent.height = flick.height * maxScale
                zoomContent.running = true
            }
        }

        ParallelAnimation
        {
            id: zoomContent
            property real x: 0
            property real y: 0
            property real width: flick.width
            property real height: flick.height

            NumberAnimation
            {
                target: flick
                property: "contentWidth"
                from: flick.contentWidth
                to: zoomContent.width
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }

            NumberAnimation
            {
                target: flick
                property: "contentHeight"
                from: flick.contentHeight
                to: zoomContent.height
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        ParallelAnimation
        {
            id: zoomAnim
            property real x: 0
            property real y: 0
            property real width: flick.width
            property real height: flick.height

            NumberAnimation
            {
                target: flick
                property: "contentWidth"
                from: flick.contentWidth
                to: zoomAnim.width
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }

            NumberAnimation
            {
                target: flick
                property: "contentHeight"
                from: flick.contentHeight
                to: zoomAnim.height
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }

            NumberAnimation
            {
                target: flick
                property: "contentY"
                from: flick.contentY
                to: zoomAnim.y
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }

            NumberAnimation
            {
                target: flick
                property: "contentX"
                from: flick.contentX
                to: zoomAnim.x
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }



        Loader
        {
            id: _imageLoader
            property int clickCount
            property bool isDouble

            width: flick.contentWidth
            height: flick.contentHeight

            sourceComponent: flick.animated ? _animatedImageComponent : _stillImageComponent

            Timer {
                id: photoClickTimer
                interval: 200
                onTriggered: {
                    _imageLoader.clickCount = 0
                    imageClicked()
                }
            }

            MouseArea
            {
                anchors.fill: parent
                // propagateComposedEvents: true

                acceptedButtons:  Qt.RightButton | Qt.LeftButton
                onClicked:  {
                    _imageLoader.clickCount ++
                    if (_imageLoader.clickCount === 2) {
                        _imageLoader.clickCount = 0
                        if (photoClickTimer.running) {
                            photoClickTimer.stop()
                        }
                        if (flick.interactive) {
                            zoomAnim.x = 0;
                            zoomAnim.y = 0;
                            zoomAnim.width = flick.width;
                            zoomAnim.height = flick.height;
                            zoomAnim.running = true;
                        } else {
                            zoomAnim.x = mouse.x * 2;
                            zoomAnim.y = mouse.y *2;
                            zoomAnim.width = flick.width * 3;
                            zoomAnim.height = flick.height * 3;
                            zoomAnim.running = true;
                        }
                    } else if (!photoClickTimer.running) {
                        photoClickTimer.start()
                    }
                }

                onPressAndHold: flick.pressAndHold()

                onDoubleClicked:
                {
                    _imageLoader.clickCount = 0
                    if (photoClickTimer.running) {
                        photoClickTimer.stop()
                    }
                    if (flick.interactive) {
                        zoomAnim.x = 0;
                        zoomAnim.y = 0;
                        zoomAnim.width = flick.width;
                        zoomAnim.height = flick.height;
                        zoomAnim.running = true;
                    } else {
                        zoomAnim.x = mouse.x * 2;
                        zoomAnim.y = mouse.y *2;
                        zoomAnim.width = flick.width * 3;
                        zoomAnim.height = flick.height * 3;
                        zoomAnim.running = true;
                    }
                }

                onWheel:
                {
                    if (wheel.modifiers & Qt.ControlModifier)
                    {
                        if (wheel.angleDelta.y != 0) {
                            var factor = 1 + wheel.angleDelta.y / 600;
                            zoomAnim.running = false;

                            zoomAnim.width = Math.min(Math.max(flick.width, zoomAnim.width * factor), flick.width * 4);
                            zoomAnim.height = Math.min(Math.max(flick.height, zoomAnim.height * factor), flick.height * 4);

                            //actual factors, may be less than factor
                            var xFactor = zoomAnim.width / flick.contentWidth;
                            var yFactor = zoomAnim.height / flick.contentHeight;

                            zoomAnim.x = flick.contentX * xFactor + (((wheel.x - flick.contentX) * xFactor) - (wheel.x - flick.contentX))
                            zoomAnim.y = flick.contentY * yFactor + (((wheel.y - flick.contentY) * yFactor) - (wheel.y - flick.contentY))
                            zoomAnim.running = true;

                        } else if (wheel.pixelDelta.y != 0) {
                            flick.resizeContent(Math.min(Math.max(flick.width, flick.contentWidth + wheel.pixelDelta.y), flick.width * 4),
                                                Math.min(Math.max(flick.height, flick.contentHeight + wheel.pixelDelta.y), flick.height * 4),
                                                wheel);
                        }
                    }
                    wheel.accepted=false
                }
            }
        }

        Component
        {
            id: _animatedImageComponent
            AnimatedImage
            {
                fillMode: Image.PreserveAspectFit
                autoTransform: true
                asynchronous: true
                source: flick.source
                playing: true
                cache: true
                onStatusChanged: {
                    if (status === AnimatedImage.Ready
                            && listView.currentIndex == mIndex) {
                        isFirstOpenPage = false
                    }
                }
            }
        }

        Component
        {
            id: _stillImageComponent
            Image
            {
                fillMode: Image.PreserveAspectFit
                autoTransform: true
                asynchronous: true
                source: flick.source
                onStatusChanged: {
                    if (status === Image.Ready
                            && listView.currentIndex == mIndex) {
                        isFirstOpenPage = false
                    }
                }
            }
        }
    }

    function fit()
    {
        image.width = image.sourceSize.width
    }

    function fill()
    {
        image.width = parent.width
    }

    function rotateLeft()
    {
        image.rotation = image.rotation - 90
    }

    function rotateRight()
    {
        image.rotation = image.rotation + 90
    }
}
