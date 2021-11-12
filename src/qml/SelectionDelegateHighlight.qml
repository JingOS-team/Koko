/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *                             Zhang He Gang <zhanghegang@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.7
import org.kde.kirigami 2.15 as Kirigami

Rectangle { 
    id: hoverItem

    z: gridView.z -1
//    color: "#2E747480"

    property bool isHover: true
    property bool itemHover
    property bool itemPressed
    property bool listMovewMend
    property bool isShow
    property alias itemContainsMouse : itemMouse.containsMouse

    signal itemClicked(var mouse)
    signal itemPressAndHold(var mouse)
    width: 180
    height: 40

    Component {
        id: highlightComponent
        Rectangle {
            width: hoverItem.width
            height: hoverItem.height
            radius: hoverItem.radius
            //"#4D787880" : "#33767680"
            color: hoverItem.itemPressed ? Kirigami.JTheme.pressBackground : Kirigami.JTheme.hoverBackground

            Behavior on y {
                SpringAnimation {
                    spring: 3
                    damping: 0.2
                }
            }
        }
    }

    Loader {
        id: hoverLoader
        anchors.fill: hoverItem
        sourceComponent: highlightComponent
        active: hoverItem.itemHover && !hoverItem.itemPressed
    }

    Loader {
        id: pressLoader
        anchors.fill: hoverItem
        sourceComponent: highlightComponent
        active: hoverItem.itemPressed && hoverItem.itemHover
    }

    Component {
        id: menuOpenComponent
        Rectangle {
            width: hoverItem.width
            height: hoverItem.height
            radius: hoverItem.radius
            color: Kirigami.JTheme.pressBackground//"#4D787880"

            Behavior on y {
                SpringAnimation {
                    spring: 3
                    damping: 0.2
                }
            }
        }
    }

    Loader {
        id: menuOpenLoader
        anchors.fill: hoverItem
        sourceComponent: menuOpenComponent
        active:isShow
    }

    MouseArea {
        id:itemMouse
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        anchors.fill: parent
        hoverEnabled: isHover
        onExited: itemHover = false
        onEntered: itemHover = true
        onPressed: itemPressed = true
        onReleased: itemPressed = false
        onClicked: {
            itemClicked(mouse)
        }
        onPressAndHold: {
            itemPressAndHold(mouse)
        }
    }
}
