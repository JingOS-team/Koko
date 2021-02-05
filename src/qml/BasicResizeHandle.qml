/*
 *  Copyright 2019 Marco Martin <mart@kde.org>
 *            2021 Wang Rui <wangrui@jingos.com>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
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

import QtQuick 2.12
import org.kde.kirigami 2.12 as Kirigami
import org.kde.jinggallery.private 1.0 as KokoComponent

KokoComponent.ResizeHandle {

    property int rhHeight:width/10

    width: 60
    height: width
    scale: 1

    function getWidthHeight(isOne) {
        switch(resizeCorner) {
        case KokoComponent.ResizeHandle.TopLeft:
            return isOne ? false : true
        case KokoComponent.ResizeHandle.BottomRight:
            return isOne ? true : false
        }
    }

    Kirigami.ShadowedRectangle {
        id:topRect

        anchors.top: getWidthHeight(true) ? parent.bottom : parent.top
        width:parent.width
        height:rhHeight

        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
        shadow {
            size: 4
            color: "transparent"
        }

    }

    Kirigami.ShadowedRectangle {
        id:bottomRect

        anchors.left: getWidthHeight(false) ? topRect.left : topRect
        anchors.right: getWidthHeight(false) ? topRect : topRect.right
        anchors.bottom: getWidthHeight(false) ?  parent :topRect.bottom
        width:rhHeight
        height:parent.width
        
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: "white"
        shadow {
            size: 4
            color: "transparent"
        }
    }
}
