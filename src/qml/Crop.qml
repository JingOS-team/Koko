/*
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

Image {
    id: img

    property int size: parent.width * 0.9
    property string croppedAreaColor: "#88000000"
    property string cropBorderColor: "red"

    anchors.margins: cursor1.size
    fillMode: Image.PreserveAspectFit
    smooth: true
    antialiasing: true
    cache: false
    sourceSize.width: size

    function reset_cursors() {
        cursor1.minX = (img.width - img.paintedWidth)/2
        cursor1.minY = (img.height - img.paintedHeight)/2
        cursor2.maxX= img.paintedWidth + cursor1.minX
        cursor2.maxY= img.paintedHeight + cursor1.minY
        cursor1.x = cursor1.minX
        cursor1.y = cursor1.minY
        cursor2.x = cursor2.maxX
        cursor2.y = cursor2.maxY
    }

    Component.onCompleted: reset_cursors()

    onSourceChanged: {
        timer.start()
    }

    Timer {
        id: timer
        repeat: false
        interval: 25
        onTriggered: reset_cursors()
    }

    CropCursor {
        id: cursor1
        maxX: cursor2.x - cursor1.size
        maxY: cursor2.y - cursor1.size
    }

    CropCursor {
        id: cursor2
        minX: cursor1.x + cursor1.size
        minY: cursor1.y + cursor1.size
    }

    // Border of cropped area
    Rectangle {
        id: rectangle
        
        width: cursor2.x - cursor1.x
        height: cursor2.y - cursor1.y
        x: cursor1.x
        y: cursor1.y
        color: "#00000000"
        border.color: cropBorderColor
        border.width: 5

        // Circles on movable corners
        Rectangle {
            width: 16
            height: width
            x: rectangle.width-width/2
            y: rectangle.height-height/2
            radius: width/2
            color: cropBorderColor
        }
        Rectangle {
            width: 16
            height: width
            x: -width/2
            y: -height/2
            radius: width/2
            color: cropBorderColor
        }
    }

    // Upper and lower areas which are cropped away
    Rectangle {
        color: croppedAreaColor
        x: cursor1.minX
        y: cursor2.y
        width: cursor2.maxX - cursor1.minX
        height: cursor2.maxY - cursor2.y
    }

    Rectangle {
        color: croppedAreaColor
        x: cursor1.minX
        y: cursor1.minY
        width: cursor2.maxX - cursor1.minX
        height: cursor1.y - cursor1.minY
        border.width: 0
    }

    // Left and right areas which are cropped away
    Rectangle {
        color: croppedAreaColor
        x: cursor1.minX
        y: cursor1.y
        width: cursor1.x - cursor1.minX
        height: cursor2.y - cursor1.y
    }

    Rectangle {
        color: croppedAreaColor
        x: cursor2.x
        y: cursor1.y
        width: cursor2.maxX - cursor2.x
        height: cursor2.y - cursor1.y
    }
}
