/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Zhang He Gang <zhanghegang@jingos.com>
 *
 */

import QtQuick 2.0
import QtGraphicalEffects 1.0

Item {

    property int mouseX;
    property int mouseY;
    property var sourceView;
    property int blurValue:128;

    ShaderEffectSource{
        id:eff

        anchors.centerIn: fastBlur
        width: fastBlur.width
        visible: false
        height: fastBlur.height
        sourceItem: sourceView
        sourceRect: Qt.rect(getItemX(width,height),getItemY(width,height),width,height)

        function getItemX(width,height) {
            var mapItem = eff.mapToItem(sourceView,eff.x,eff.y,width,height)
            return mapItem.x
        }

        function getItemY(width,height) {
            var mapItem = eff.mapToItem(sourceView,eff.x,eff.y,width,height)
            return mapItem.y
        }
    }

    FastBlur{
        id:fastBlur

        anchors.fill: parent
        source: eff
        radius: blurValue
        cached: true
        visible: false
    }

    Rectangle{
        id:maskRect

        anchors.fill:fastBlur
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
}
