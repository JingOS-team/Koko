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

    property int defaultFontSize : theme.defaultFont.pointSize
    property bool isVideo
    property bool isPhoto
    property bool isAll

    signal thumbnailChanged(var path)
    signal deleteItemData();
    signal filterBy(string value)

    width: root.screen.width
    height: root.screen.height
    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.None

    pageStack.initialPage: AlbumView {
        id: albumView
        model: mediasModel
    }

    onDeleteItemData: {
        switch(albumTabBar.selectedItem) {
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

    Rectangle{
        id:gradRect

        anchors.top: parent.top
        width: parent.width
        height: parent.height/10
        visible: albumTabBar.visible
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#DBFFFFFF"; }
            GradientStop { position: 1.0; color: "#00FFFFFF"; }
        }
    }

    AlbumTabBar {
        id: albumTabBar

        anchors{
            top: parent.top
            topMargin: height/4
        }
        visible: albumView.isCurrentPage
        selectedItem: i18n(CSJ.TopBarItemAllContent)

        Component.onCompleted:{
            model.append({
                             title:i18n(CSJ.TopBarItemAllContent)
                         });
            model.append({
                             title:i18n(CSJ.TopBarItemPhotoContent)
                         });
            model.append({
                             title:i18n(CSJ.TopBarItemVideoContent)
                         });
        }
    }
    
    onFilterBy: {
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
