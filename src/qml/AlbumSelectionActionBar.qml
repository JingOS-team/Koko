/*
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.jinggallery 0.2 as Koko

Rectangle {    
    id: tabBar

    property var model

    width: Kirigami.Units.gridUnit * 4
    height: Kirigami.Units.gridUnit * 2
    color:"#80000000"
    radius: height / 2
    z: 1

    Row {
        id:tabRow

        anchors.fill: parent
        anchors.margins: {
            leftMargin: height * 0.25
            topMargin: height * 0.05
            rightMargin: height * 0.25
            bottomMargin: height * 0.05
        }
        spacing:height * 0.2

        // RoundButton {
        //     id: idDelect

        //     anchors.verticalCenter: parent.verticalCenter
        //     width: parent.width
        //     height: parent.height * 0.9
        //     radius: height / 2
        //     text: i18n("Del")
        //     enabled: model.hasSelectedImages
            
        //     onClicked: {
        //         model.deleteSelection()
        //         page.state = "browsing"
        //     }
        //     background: Rectangle {
        //         radius: parent.radius
        //     }
        // }
    }
}
