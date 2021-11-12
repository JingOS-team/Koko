/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Zhang He Gang <zhanghegang@jingos.com>
 *
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
    }
}
