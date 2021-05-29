/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *                             2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.12 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.jinggallery 0.2 as Koko
import "common.js" as CSJ

Kirigami.ApplicationWindow {
    id: root

    property int defaultFontSize : 14//theme.defaultFont.pointSize
    property bool isVideo
    property bool isPhoto
    property bool isAll
    property string currentTabBarTitle
    property var appScaleSize: width / 888
    property var heightScaleSize: height / 648

    signal thumbnailChanged(var path)
    signal deleteItemData();
    signal filterBy(string value)

    width: root.screen.width
    height: root.screen.height
    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.None
    color: "#E8EFFF"

    Component.onCompleted:{
    }

    pageStack.initialPage: AlbumView {
        id: albumView
        anchors{
            top: parent.top
//            topMargin: 20
        }
        width:root.width
        height:root.height
        model: mediasModel
        color: "transparent"
    }

    onDeleteItemData: {
        switch(albumView.barSelectName) {
            case CSJ.TopBarItemAllContent:
                isVideo = true;
                isPhoto = true;
                isAll = false;
                break;
            case CSJ.TopBarItemPhotoContent:
                isVideo = true;
                isPhoto = false;
                isAll = true;
                break;
            case CSJ.TopBarItemVideoContent:
                isVideo = false;
                isPhoto = tue;
                isAll = true;
                break;
        }
    }

    onThumbnailChanged: {
        imagesModel.sourceModel.thumbnailChanged(path)
        mediasModel.sourceModel.thumbnailChanged(path)
    }

    function switchApplicationPage(page) {
        if (!page || pageStack.currentItem == page) {
            return;
        }
        pageStack.pop(albumView);
        pageStack.push(page);
        page.forceActiveFocus();
    }


    
    onFilterBy: {
        if(value !== currentTabBarTitle){
            albumView.grideHide()
        }
        switch(value) {
            case CSJ.TopBarItemPhotoContent: {
                if (isPhoto) {
                    imagesModel.sourceModel.mimeType = Koko.Types.Image;
                }
                albumView.model = imagesModel;
                mediaListModel.locationGroup = -1;
                mediaListModel.timeGroup = -1;
                mediaListModel.mimeType = Koko.Types.Image;
                break;
            }
            case CSJ.TopBarItemVideoContent: {
                if (isVideo) {
                    isVideo = false;
                    videosModel.sourceModel.mimeType = Koko.Types.Video;
                }
                albumView.model = videosModel;
                mediaListModel.locationGroup = -1;
                mediaListModel.timeGroup = -1;
                mediaListModel.mimeType = Koko.Types.Video;
                break;
            }
            case CSJ.TopBarItemAllContent: {
                if (isAll) {
                    isAll = false;
                    mediasModel.sourceModel.mimeType = Koko.Types.All;
                }
                albumView.model = mediasModel;
                mediaListModel.locationGroup = -1;
                mediaListModel.timeGroup = -1;
                mediaListModel.mimeType = Koko.Types.All;
                break;
            }
        }
        if(value !== currentTabBarTitle){
            albumView.grideShow()
        }
        currentTabBarTitle = value
    }

    Koko.MediaMimeTypeModel {
        id:mmt
        mimeType: Koko.Types.All
    }
    
    Koko.SortModel {
        id: mediasModel
        sourceModel: Koko.MediaMimeTypeModel {
            mimeType: Koko.Types.All
        }
    }

    Koko.SortModel {
        id: imagesModel
        sourceModel: Koko.MediaMimeTypeModel {
            mimeType: Koko.Types.Image
        }
    }

    Koko.SortModel {
        id: videosModel
        sourceModel: Koko.MediaMimeTypeModel {
            mimeType: Koko.Types.Video
        }
    }
    
    Koko.MediaListModel {
        id: mediaListModel
        mimeType: Koko.Types.All
    }
    
    Koko.NotificationManager {
        id: notificationManager
    }
    
    KQA.Clipboard {
        id: clipboard
    }

    Kirigami.AboutPage {
        id: aboutPage
        aboutData: jinggalleryAboutData
    }
}
