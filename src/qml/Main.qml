/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *                             Zhang He Gang <zhanghegang@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.jinggallery 0.2 as Koko
import "common.js" as CSJ
import jingos.display 1.0

Kirigami.ApplicationWindow {
    id: root

    property int defaultFontSize : 14
    property bool isVideo
    property bool isPhoto
    property bool isAll
    property string currentTabBarTitle
    property var appScaleSize: JDisplay.dp(1.0)
    property var heightScaleSize: JDisplay.dp(1.0)
    property var appFontSize: JDisplay.sp(1.0)

    signal thumbnailChanged(var path)

    width: root.screen.width
    height: root.screen.height
    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.None
    color: Kirigami.JTheme.background

    visible: realVisible
    Component.onCompleted:{
    }

    pageStack.initialPage: AlbumView {
        id: albumView
        anchors{
            top: parent.top
        }
        width:root.width
        height:root.height
        model: defaultImageDataModel
        color: "transparent"
    }
    
}
