/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *                              2021 Wang Rui <wangrui@jingos.com>
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.15 as Kirigami
import org.kde.jinggallery 0.2 as Koko
import QtQuick.Window 2.0
import "common.js" as CSJ

Rectangle {
    id: page

    property alias model: gridView.model
    property alias barSelectName: albumTabBar.selectedItem
    property var grideSortModel
    property bool isPhotoItem : albumTabBar.bulkIsVisible ? photoItemCount > 0 : rightMenuPhoto
    property bool isVideoItem : albumTabBar.bulkIsVisible ? videoItemCount > 0 :rightMenuVideo
    property bool rightMenuPhoto
    property bool rightMenuVideo
    property int itemCheckSelectCount : model.checkSelectCount
    property int photoItemCount : model.photoSelectCount
    property int videoItemCount : model.videoSelectCount
    property int gridViewCount:gridView.count
    property string commandLinePathString:CommandLineInto
    property bool currentDataIsImage : gridView.model.sourceModel.mimeType === Koko.Types.Image

    signal collectionSelected(QtObject selectedModel, string cover)
    signal folderSelected(QtObject selectedModel, string cover)
    signal backToPage()
    signal deleteItemClicked()
    signal allChecked(var status)

    onDeleteItemClicked: {
        gridView.model.deleteSelection()
    }
    onAllChecked: {
        if (status) {
            gridView.model.selectAll()
        } else {
            gridView.model.clearSelections();
        }
    }

    onBackToPage: {
//        albumTabBar.visible = true
        actionBar.visible = false
    }

    AlbumSelectionActionBar {
        id: actionBar

        anchors {
            left: parent.left
            leftMargin: parent.width / 2
            bottom: parent.bottom
            bottomMargin: Kirigami.Units.gridUnit * 2
        }
        model: gridView.model
        visible: false
    }

    states: [
        State {
            name: "browsing"
            when: !model.hasSelectedMedias
        },
        State {
            name: "selecting"
            when: model.hasSelectedMedias // && Kirigami.Settings.tabletMode
        }
    ]

    Timer{
        id:rectgetFocusTimer
        interval: 300
        onTriggered: {
            page.forceActiveFocus()
        }
    }

    Component.onCompleted: {
      rectgetFocusTimer.start()
    }
    focus: true
    Keys.onPressed: {
        switch (event.key) {
        case Qt.Key_Escape:
            gridView.model.clearSelections()
            break;
        case Qt.Key_Left:
        case Qt.Key_Right:
        case Qt.Key_Down:
        case Qt.Key_Up:
            gridView.forceActiveFocus()
            gridView.currentIndex = 0
            break;
        default:
            break;
        }
    }

    // ShareDialog {
    //     id: shareMenu

    //     inputData: {
    //         "urls": [],
    //         "mimeType": ["image/", "video/"]
    //     }
    //     onFinished: {
    //         if (error==0 && output.url !== "") {
    //             var resultUrl = output.url;
    //             notificationManager.showNotification( true, resultUrl);
    //             clipboard.content = resultUrl;
    //         } else {
    //             notificationManager.showNotification( false);
    //         }
    //     }
    // }
    onVisibleChanged: {
        if (visible) {
            gridView.isDeleteClicked = false
        }
    }

    onCollectionSelected: pageStack.push( Qt.resolvedUrl("AlbumView.qml"), { "model": selectedModel, "globalToolBarStyle": Kirigami.ApplicationHeaderStyle.None})
    onFolderSelected: pageStack.push( Qt.resolvedUrl("AlbumView.qml"), { "model": selectedModel, "globalToolBarStyle": Kirigami.ApplicationHeaderStyle.None})

    property var gaFrom : 0.5
    property var gaTo : 1

    function grideHide(){
        if(gaFrom !== 0.5){
            gaFrom = 1
            gaTo = 0.5
            grideViewAnima.running = true
        }
    }

    function grideShow(){
        if(gaFrom !== 1){
            gaFrom = 0.5
            gaTo = 1
            grideViewAnima.running = true
        }
        gridView.currentIndex = gridView.count > 0 ? (gridView.count-1) : 0
        rectgetFocusTimer.start()
    }

    NumberAnimation {
        id:grideViewAnima
        target: gridView
        property: "opacity"
        from: gaFrom
        to: gaTo
        duration: 250
        easing.type: Easing.InOutQuad
    }

    GridView {
        id: gridView

        property bool isDeleteClicked
        property bool isLoadStop : false
        property int clickIndex
        property real widthToApproximate: (applicationWindow().wideScreen ? applicationWindow().pageStack.defaultColumnWidth : page.width) - (1||Kirigami.Settings.tabletMode ? Kirigami.Units.gridUnit : 0)
        property var currentLoadStatus: model.sourceModel.loadStatus
        property bool isCrossScreen: gridView.contentHeight > parent.height

        anchors{
            top: isCrossScreen ? parent.top : albumTabBar.bottom
            topMargin:  isCrossScreen ? 0 : 3 * appScaleSize
            left: parent.left
            right: parent.right
            leftMargin: height/120
            bottom: parent.bottom
            bottomMargin: 40
        }
        width: parent.width
        height: parent.height
        cellWidth: (width-height/120)/7
        cellHeight: cellWidth-cellWidth/6
        highlightMoveDuration: 0
        cacheBuffer: root.height*5
        keyNavigationEnabled: true

        Timer{
            id:getFocusTimer
            interval: 10
            onTriggered: {
                gridView.forceActiveFocus()
            }
        }

        highlight: Rectangle { color: "#33767680";
            radius: 5
            visible: gridView.activeFocus
        }
        currentIndex: count > 0 ? count-1 : 0
        Controls.ScrollBar.vertical: Controls.ScrollBar{
                active: true
                minimumSize: 0.1
            }

        onCurrentLoadStatusChanged: {
            if(currentLoadStatus !== -1){
                isLoadStop = true
            }
        }
        onCountChanged: {
            if(count > 0){
                loadTimer.stop()
                model.updateSelectCount()
            }
        }

        displaced: Transition {
                 NumberAnimation { properties: "x,y"; duration: 250 }
             }

        Koko.SortModel {
            id: sortedListModel
        }

        function reloadSource(reloadIndex) {
            gridView.itemAtIndex(reloadIndex).reloadImage();
        }

        EditMenuView{
            id:editMenu

            hasSelectItem:itemCheckSelectCount > 0
            isbulkVisible: albumTabBar.bulkIsVisible
            tabSelectText:albumTabBar.selectedItem
            selectCount : itemCheckSelectCount

            onBulkClicked: {
                albumTabBar.bulkClick()
            }
            onDeleteClicked: {
                if (albumTabBar.bulkIsVisible) {
                    deleteItemClicked()
                    albumTabBar.cancelBulk()
                } else {
                    root.deleteItemData()
                    gridView.model.deleteItemByModeIndex(gridView.clickIndex)
                }
            }
            onSaveClicked: {}
        }

        AlertDialog {
            id: deleteDialog

            msgContent: updateMsg(albumTabBar.selectedItem, itemCheckSelectCount)
            onDialogLeftClicked: {
                deleteDialog.close()
            }
            onDialogRightClicked: {
                editMenu.deleteClicked()
                deleteDialog.close()
            }
        }

        delegate: AlbumDelegate {
            id: delegate

            modelData: model
            isMenuOpen: editMenu.visible & (gridView.clickIndex === index)

            GridView.onRemove: SequentialAnimation {
                PropertyAction { target: delegate; property: "GridView.delayRemove"; value: true }
                NumberAnimation { target: delegate; property: "scale"; to: 0; duration: 250; easing.type: Easing.InOutQuad }
                PropertyAction { target: delegate; property: "GridView.delayRemove"; value: false }
            }

            Component.onCompleted: {
                if (commandLinePathString !== "") {
                    var commandLineIndex = gridView.model.sourceModel.findIndex(commandLinePathString);
                    if (commandLineIndex === index) {
                        commandLinePathString = ""
//                        applicationWindow().pageStack.layers.push(Qt.resolvedUrl("ImageViewer.qml"), {
//                                                                      startIndex: commandLineIndex,
//                                                                      imageviewModel: page.model,
//                                                                      gradviewModel: page.model,
//                                                                      imageGridView:gridView
//                                                                  })
//                        albumTabBar.visible = false
                        var previousObj = applicationWindow().pageStack.layers.push(previewItem, {
                                                                                          startIndex: commandLineIndex,//page.model.index(gridView.currentIndex, 0),//sortedListModel.index
                                                                                          imagesModel: page.model,
                                                                                          imageDetailTitle:albumTabBar.selectedItem
                                                                                      });

                        previousObj.close.connect(gridView.previewPageRequestClose);
                        previousObj.cropImageFinished.connect(gridView.previewPageCropImageFinished);
                        previousObj.deleteCurrentPicture.connect(gridView.previewPageDeletePicture)
                        previousObj.requestFullScreen.connect(gridView.previewPageRequestFullScreen);
                        previousObj.playVideo.connect(gridView.playVideo)
                    }
                }
            }

            onClicked: {
                gridView.clickIndex = model.index
                gridView.currentIndex = model.index;

                if (mouse.button ===  Qt.RightButton) {
                    if (isVideoType) {
                        albumView.rightMenuVideo = true
                    } else {
                        albumView.rightMenuPhoto = true
                    }
                    if (!editMenu.opened) {
                        var jx = mapToItem(page,mouse.x,mouse.y)
                        editMenu.mouseX = jx.x
                        editMenu.mouseY = jx.y
                        if (albumTabBar.bulkIsVisible) {
                            editMenu.rmBulkAction()
                        } else {
                            editMenu.addBulkAction()
                            editMenu.popup()
                        }
                    }
                } else {
                    if (page.state == "selecting") {
                        gridView.model.toggleSelected(model.index)
                    }
                    else {
                        activated();
                    }
                }
            }
            onPressAndHold: {
                gridView.clickIndex = model.index
                gridView.currentIndex = model.index;

                if (!editMenu.opened) {
                    var jx = mapToItem(page,mouse.x,mouse.y)
                    editMenu.mouseX = jx.x
                    editMenu.mouseY = jx.y
                    if (albumTabBar.bulkIsVisible) {
                        editMenu.rmBulkAction()
                    } else {
                        editMenu.addBulkAction()
                        editMenu.popup(page,jx.x,jx.y)
                    }
                }
            }

            onActivated: {
                gridView.model.clearSelections()
                gridView.currentIndex = model.index;
                gridView.clickIndex = model.index

                switch( model.itemType) {
                    case Koko.Types.Album: {
                        mediaListModel.query = mediaListModel.queryForIndex( model.sourceIndex)
                        sortedListModel.sourceModel = mediaListModel
                        collectionSelected( sortedListModel, model.display)
                        break;
                    }
                    case Koko.Types.Folder: {
                        imageFolderModel.url = model.imageurl
                        sortedListModel.sourceModel = mediasModel
                        folderSelected( sortedListModel, model.display)
                        break;
                    }
                    case Koko.Types.Media: {
//                        albumTabBar.visible = false
//                        applicationWindow().pageStack.layers.push(Qt.resolvedUrl("ImageViewer.qml"), {
//                                                                    startIndex: gridView.currentIndex,//page.model.index(gridView.currentIndex, 0),//sortedListModel.index
//                                                                    imageviewModel: page.model,
//                                                                    gradviewModel: page.model,
//                                                                    imageGridView:gridView,
//                                                                    imageDetailTitle:albumTabBar.selectedItem
//                                                                })

                        var previousObj = applicationWindow().pageStack.layers.push(previewItem, {
                                                                                          startIndex: gridView.currentIndex,//page.model.index(gridView.currentIndex, 0),//sortedListModel.index
                                                                                          imagesModel: page.model,
                                                                                          imageDetailTitle:albumTabBar.selectedItem
                                                                                      });

                        previousObj.close.connect(gridView.previewPageRequestClose);
                        previousObj.cropImageFinished.connect(gridView.previewPageCropImageFinished);
                        previousObj.deleteCurrentPicture.connect(gridView.previewPageDeletePicture)
                        previousObj.requestFullScreen.connect(gridView.previewPageRequestFullScreen);
                        previousObj.playVideo.connect(gridView.playVideo)
                        break;
                    }
                    default: {
                        console.log("Unknown")
                        break;
                    }
                }
            }
        }


        Component{
            id:previewItem
            Kirigami.JImagePreviewItem{

            }
        }

        //图片预览控件请求关闭
        function previewPageRequestClose(){
            applicationWindow().pageStack.layers.pop();
//            albumTabBar.visible = true
            actionBar.visible = false
            rectgetFocusTimer.start()
        }

        //预览控件裁剪图片完成
        function previewPageCropImageFinished(path){
        }
        //预览图片控件请求是否全屏
        function previewPageRequestFullScreen(){
            applicationWindow().visibility = (applicationWindow().visibility == Window.FullScreen) ? Window.Windowed : Window.FullScreen;
        }
        //预览图片控件请求删除图片
        function previewPageDeletePicture(index, path){
            page.model.deleteItemByModeIndex(index)
        }

        function playVideo(mediaUrl){
            gridView.model.playVedio(mediaUrl)
            popCurrentPage.start()

        }

        Timer{
            id:popCurrentPage
            interval: 1000
            onTriggered: {
                applicationWindow().pageStack.layers.pop()
//                albumTabBar.visible = true
                actionBar.visible = false
            }
        }
    }


    Rectangle{
     id:nullPageView
     x: root.width/2 - width/2
     y: root.height/2 - height/2
     visible: !loadAnim.visible & gridView.count == 0
     width: tipText.width
     color: "transparent"
     height: nullImage.height + tipText.height + nullImage.height/4

     Image {
         id: nullImage
         anchors.horizontalCenter: tipText.horizontalCenter
         source: albumTabBar.selectedItem === CSJ.TopBarItemAllContent ? "qrc:/assets/null_all.png" : (currentDataIsImage ? "qrc:/assets/null_image.png" : "qrc:/assets/null_video.png")
         sourceSize: Qt.size(120,120)
         width: 60
         height: width
         asynchronous: true
     }

     Text {
         id:tipText
         anchors.horizontalCenter: parent.horizontalCenter
         anchors{
             top: nullImage.bottom
             topMargin: nullImage.height/4
         }
         color: "#4D3C3C43"
         font.pixelSize: root.defaultFontSize
         text: albumTabBar.selectedItem === CSJ.TopBarItemAllContent ? i18n("There are no photos and videos at present") :(currentDataIsImage ? i18n("There are no photos at present") : i18n("There are no videos at present"))
     }
    }

    Timer{
        id:loadTimer
        interval: 1000
        running: true
        onTriggered: {
            loadAnim.visible = false
        }
    }

    LoadAnimaView{
        id:loadAnim
        anchors.centerIn: parent
        timerRun: visible
        visible: loadTimer.running
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
            topMargin: height/4+20
        }
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
}
