

/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Zhang He Gang <zhanghegang@jingos.com>
 *
 */
import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.15 as Kirigami
import org.kde.jinggallery 0.2 as Koko
import QtQuick.Window 2.0
import "common.js" as CSJ

Rectangle {
    id: page
    property alias defaultImageDataModel: mediasModel
    property alias model: gridView.model
    property alias barSelectName: albumTabBar.selectedItem
    property var grideSortModel
    property bool isPhotoItem: albumTabBar.bulkIsVisible ? photoItemCount > 0 : rightMenuPhoto
    property bool isVideoItem: albumTabBar.bulkIsVisible ? videoItemCount > 0 : rightMenuVideo
    property bool rightMenuPhoto
    property bool rightMenuVideo
    property int itemCheckSelectCount: model.checkSelectCount
    property int photoItemCount: model.photoSelectCount
    property int videoItemCount: model.videoSelectCount
    property int gridViewCount: gridView.count
    property string commandLinePathString: CommandLineInto
    property bool currentDataIsImage: albumTabBar.selectedItem === CSJ.TopBarItemPhotoContent
    property bool isDeleting: false

    signal collectionSelected(QtObject selectedModel, string cover)
    signal folderSelected(QtObject selectedModel, string cover)
    signal backToPage
    signal deleteItemClicked
    signal allChecked(var status)
    signal deleteItemData
    signal filterBy(string value)

    Kirigami.JToolTip {
        id: toast
        font.pixelSize: 17 * appFontSize
    }

    function showToast(tips,time) {
        toast.text = tips
        toast.show(tips, time)
    }

//    Koko.MediaMimeTypeModel {
//        id:imageSourceModel
//        mimeType: Koko.Types.Image
//    }

//    Koko.MediaMimeTypeModel {
//        id:videoSourceModel
//        mimeType: Koko.Types.Video
//    }

    Koko.MediaMimeTypeModel {
        id:allSourceModel
        mimeType: Koko.Types.All
        onErrorInfoTip: {
            failDialog.close()
            if (errorText !== "") {
                failDialog.text = errorText
            }
            failDialog.open()
        }
    }

    Timer {
       id: toastHideTimer
       interval: 3000
       onTriggered: {
           isDeleting = false
           toast.hide()
           toast.visible = false
       }
    }

    Koko.SortModel {
        id: mediasModel
        sourceModel: allSourceModel
        onErrorInfoPopup: {
            console.log(" error info popup:" + errorText)
            if (errorText !== "") {
                failDialog.text = errorText
            }
            failDialog.open()
        }

        onMoveToTrashChanged: {
            console.log(" onMoveToTrashChanged:" + finish)
            if (finish) {
                if (!toastHideTimer.running) {
                    toastHideTimer.start()
                } else {
                   toastHideTimer.restart()
                }
            } else {
                showToast(i18n("Deleting, please wait"),-1)
                toast.visible = true
                isDeleting = true
            }
        }
    }

//    Koko.SortModel {
//        id: imagesModel
//        sourceModel: imageSourceModel
//    }

//    Koko.SortModel {
//        id: videosModel
//        sourceModel: videoSourceModel
//    }

    onDeleteItemClicked: {
        gridView.model.deleteSelection()
    }
    onAllChecked: {
        if (status) {
            gridView.model.selectAll()
        } else {
            gridView.model.clearSelections()
        }
    }

    onBackToPage: {

    }

    states: [
        State {
            name: "browsing"
            when: !model.hasSelectedMedias
        },
        State {
            name: "selecting"
            when: model.hasSelectedMedias
        }
    ]

    Timer {
        id: rectgetFocusTimer
        interval: 300
        onTriggered: {
            page.forceActiveFocus()
        }
    }

    Component.onCompleted: {
        rectgetFocusTimer.start()
        model = mediasModel
        root.thumbnailChanged.connect(albumThumbnailChanged)
    }
    focus: true
    Keys.onPressed: {
        switch (event.key) {
        case Qt.Key_Escape:
            gridView.model.clearSelections()
            break
        case Qt.Key_Left:
        case Qt.Key_Right:
        case Qt.Key_Down:
        case Qt.Key_Up:
            console.log(" onPress:: down up home end:::")
            gridView.forceActiveFocus()
            if (gridView.currentIndex === -1) {
                gridView.currentIndex = 0
            }
            break
        default:
            break
        }
    }

    onVisibleChanged: {
        if (visible) {
            gridView.isDeleteClicked = false
        }
    }

    onCollectionSelected: pageStack.push(Qt.resolvedUrl("AlbumView.qml"), {
                                             "model": selectedModel,
                                             "globalToolBarStyle": Kirigami.ApplicationHeaderStyle.None
                                         })
    onFolderSelected: pageStack.push(Qt.resolvedUrl("AlbumView.qml"), {
                                         "model": selectedModel,
                                         "globalToolBarStyle": Kirigami.ApplicationHeaderStyle.None
                                     })

    property var gaFrom: 0.5
    property var gaTo: 1

    function grideHide() {
        if (gaFrom !== 0.5) {
            gaFrom = 1
            gaTo = 0.5
            grideViewAnima.running = true
        }
    }

    function grideShow() {
        if (gaFrom !== 1) {
            gaFrom = 0.5
            gaTo = 1
            grideViewAnima.running = true
        }
//        gridView.currentIndex = gridView.count > 0 ? (gridView.count - 1) : 0
        rectgetFocusTimer.start()
    }

    NumberAnimation {
        id: grideViewAnima
        target: gridView
        property: "opacity"
        from: gaFrom
        to: gaTo
        duration: 250
        easing.type: Easing.InOutQuad
    }
    Rectangle {
        id: gridRect
        anchors {
            top: parent.top
            topMargin: 20 * appScaleSize
            bottom: parent.bottom
        }
        width: parent.width
        height: parent.height
        color: "transparent"

        GridView {
            id: gridView

            property bool isDeleteClicked
            property int clickIndex
            property real widthToApproximate: (applicationWindow(
                                                   ).wideScreen ? applicationWindow(
                                                                      ).pageStack.defaultColumnWidth : page.width) - (1 || Kirigami.Settings.tabletMode ? Kirigami.Units.gridUnit : 0)
            property var currentLoadStatus: model.sourceModel.loadStatus
            property bool isCrossScreen: gridView.contentHeight > parent.height
            property bool loadFinished: jingGalleryProcessor.finished
            property bool isDataFail: false
            property bool deleteFileStatusByModel: gridView.model.sourceModel.deleteFilesStatus
            property bool isScrollBarShow: false

            anchors {
                top: parent.top
                topMargin: isCrossScreen ? 0 : (albumTabBar.height * 5 / 4)
                left: parent.left
                right: parent.right
                leftMargin: height / 120
                bottom: parent.bottom
                bottomMargin: 40 * appScaleSize
            }
            width: parent.width
            height: parent.height
            cellWidth: (width - height / 120) / 7
            cellHeight: cellWidth - cellWidth / 6
            highlightMoveDuration: 0
            cacheBuffer: root.height * 5
            keyNavigationEnabled: true
            keyNavigationWraps: false
            currentIndex: count > 0 ? (count - 1) : 0

            onDeleteFileStatusByModelChanged: {
                if (!deleteFileStatusByModel) {
                    failDialog.open()
                }
            }

            Kirigami.JDialog {
                id: failDialog

                anchors.centerIn: parent

                title: i18n("Delete file")
                text: i18n("Some files failed to be deleted due to lack of permission")
                centerButtonText: i18n("OK")
                dim: true
                focus: true

                onCenterButtonClicked: {
                    failDialog.close()
                    gridView.model.sourceModel.deleteFilesStatus = true
                }
            }

            Connections {
                target: jingGalleryProcessor
                onFinishedChanged: {

                }
            }

            function cmdToDescript(commandLineIndex) {

                var previousObj = applicationWindow().pageStack.layers.push(
                            previewItem, {
                                "startIndex": commandLineIndex,
                                "imagesModel"//page.model.index(gridView.currentIndex, 0),//sortedListModel.index
                                : gridView.model,
                                "imageDetailTitle": albumTabBar.selectedItem
                            })

                previousObj.close.connect(gridView.previewPageRequestClose)
                previousObj.cropImageFinished.connect(
                            gridView.previewPageCropImageFinished)
                previousObj.deleteCurrentPicture.connect(
                            gridView.previewPageDeletePicture)
                previousObj.requestFullScreen.connect(
                            gridView.previewPageRequestFullScreen)
                previousObj.playVideo.connect(gridView.playVideo)
            }

            onLoadFinishedChanged: {
                if (loadFinished) {
                    if (commandLinePathString !== "") {
                        var commandLineIndex = gridView.model.sourceModel.findIndex(
                                    commandLinePathString)

                        isDataFail = true
                        if (commandLineIndex < 0) {
                            return
                        }
                        commandLinePathString = ""
                        cmdToDescript(commandLineIndex)
                    }
                }
            }

            Timer {
                id: getFocusTimer
                interval: 10
                onTriggered: {
                    gridView.forceActiveFocus()
                }
            }

            highlight: Rectangle {
                color: "#33767680"
                radius: 5
                visible: gridView.activeFocus
            }

            Controls.ScrollIndicator.vertical: Controls.ScrollIndicator {
                minimumSize: 0.1
                active: true
            }

            onCountChanged: {
                if (count > 0) {
                    loadTimer.stop()
                    model.updateSelectCount()
                    if (isDataFail & commandLinePathString !== "") {
                        var commandLineIndex = gridView.model.sourceModel.findIndex(
                                    commandLinePathString)
                        commandLinePathString = ""
                        isDataFail = false

                        if (commandLineIndex >= 0) {
                            cmdToDescript(commandLineIndex)
                        }
                    }
                    if (albumTabBar.visible) {
                      gridView.currentIndex = gridView.count > 0 ? (gridView.count - 1) : 0
                    }
                }
            }

            displaced: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: 250
                }
            }

            Koko.SortModel {
                id: sortedListModel
            }

            function reloadSource(reloadIndex) {
                gridView.itemAtIndex(reloadIndex).reloadImage()
            }

            EditMenuView {
                id: editMenu

                hasSelectItem: itemCheckSelectCount > 0
                isbulkVisible: albumTabBar.bulkIsVisible
                tabSelectText: albumTabBar.selectedItem
                selectCount: itemCheckSelectCount
                modal: true
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                Controls.Overlay.modal: Rectangle {
                    color: "#00000000"
                }

                onBulkClicked: {
                    albumTabBar.bulkClick()
                }
                onDeleteClicked: {
                    if (albumTabBar.bulkIsVisible) {
                        deleteItemClicked()
                        albumTabBar.cancelBulk()
                    } else {
                        albumView.deleteItemData()
                        gridView.model.deleteItemByModeIndex(
                                    gridView.clickIndex)
                    }
                }
                onSaveClicked: {

                }
            }

            AlertDialog {
                id: deleteDialog

                msgContent: updateMsg(albumTabBar.selectedItem,
                                      itemCheckSelectCount)
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
                    PropertyAction {
                        target: delegate
                        property: "GridView.delayRemove"
                        value: true
                    }
                    NumberAnimation {
                        target: delegate
                        property: "scale"
                        to: 0
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                    PropertyAction {
                        target: delegate
                        property: "GridView.delayRemove"
                        value: false
                    }
                }

                onClicked: {
                    gridView.clickIndex = model.index
                    gridView.currentIndex = model.index

                    if (mouse.button === Qt.RightButton) {
                        if (isVideoType) {
                            albumView.rightMenuVideo = true
                        } else {
                            albumView.rightMenuPhoto = true
                        }
                        if (!editMenu.opened) {
                            var jx = mapToItem(page, mouse.x, mouse.y)
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
                        } else {
                            activated()
                        }
                    }
                }
                onPressAndHold: {
                    gridView.clickIndex = model.index
                    gridView.currentIndex = model.index

                    if (isVideoType) {
                        albumView.rightMenuVideo = true
                    } else {
                        albumView.rightMenuPhoto = true
                    }

                    if (!editMenu.opened) {
                        var jx = mapToItem(page, mouse.x, mouse.y)
                        editMenu.mouseX = jx.x
                        editMenu.mouseY = jx.y
                        if (albumTabBar.bulkIsVisible) {
                            editMenu.rmBulkAction()
                        } else {
                            editMenu.addBulkAction()
                            editMenu.popup(page, jx.x, jx.y)
                        }
                    }
                }

                onActivated: {
                    gridView.model.clearSelections()
                    gridView.currentIndex = model.index
                    gridView.clickIndex = model.index

                    switch (model.itemType) {
                    case Koko.Types.Album:
                    {
                        break
                    }
                    case Koko.Types.Folder:
                    {
                        imageFolderModel.url = model.imageurl
                        sortedListModel.sourceModel = mediasModel
                        folderSelected(sortedListModel, model.display)
                        break
                    }
                    case Koko.Types.Media:
                    {
                        var previousObj = applicationWindow(
                                    ).pageStack.layers.push(previewItem, {
                                                                "startIndex": gridView.currentIndex,
                                                                "imagesModel"//page.model.index(gridView.currentIndex, 0),//sortedListModel.index
                                                                : page.model,
                                                                "imageDetailTitle": albumTabBar.selectedItem
                                                            })

                        previousObj.close.connect(
                                    gridView.previewPageRequestClose)
                        previousObj.cropImageFinished.connect(
                                    gridView.previewPageCropImageFinished)
                        previousObj.deleteCurrentPicture.connect(
                                    gridView.previewPageDeletePicture)
                        previousObj.requestFullScreen.connect(
                                    gridView.previewPageRequestFullScreen)
                        previousObj.playVideo.connect(gridView.playVideo)
                        break
                    }
                    default:
                    {
                        console.log("Unknown")
                        break
                    }
                    }
                }
            }

            Component {
                id: previewItem
                Kirigami.JImagePreviewItem {}
            }

            //图片预览控件请求关闭
            function previewPageRequestClose() {
                applicationWindow().pageStack.layers.pop()
                rectgetFocusTimer.start()
            }

            //预览控件裁剪图片完成
            function previewPageCropImageFinished(path) {}
            //预览图片控件请求是否全屏
            function previewPageRequestFullScreen() {
                applicationWindow().visibility
                        = (applicationWindow().visibility
                           == Window.FullScreen) ? Window.Windowed : Window.FullScreen
            }
            //预览图片控件请求删除图片
            function previewPageDeletePicture(index, path) {
                page.model.deleteItemByModeIndex(index)
            }

            function playVideo(mediaUrl) {}

            Timer {
                id: popCurrentPage
                interval: 1000
                onTriggered: {
                    applicationWindow().pageStack.layers.pop()
                }
            }
        }
    }

    Component {
        id: nullComponent

        Rectangle {
            id: nullPageView
            x: root.width / 2 - width / 2
            y: root.height / 2 - height / 2
            visible: !loadAnim.visible & gridView.count == 0
            width: tipText.width
            color: "transparent"
            height: nullImage.height + tipText.height + nullImage.height / 4

            Kirigami.Icon {
                id: nullImage
                anchors.horizontalCenter: tipText.horizontalCenter
                source: albumTabBar.selectedItem === CSJ.TopBarItemAllContent ? "qrc:/assets/null_all.png" : (currentDataIsImage ? "qrc:/assets/null_image.png" : "qrc:/assets/null_video.png")
                width: 60 * appScaleSize
                height: width
                color: Kirigami.JTheme.majorForeground
            }

            Text {
                id: tipText
                anchors.horizontalCenter: parent.horizontalCenter
                anchors {
                    top: nullImage.bottom
                    topMargin: nullImage.height / 4
                }
                color: Kirigami.JTheme.disableForeground
                font.pixelSize: root.defaultFontSize * appFontSize
                text: albumTabBar.selectedItem === CSJ.TopBarItemAllContent ? i18n("There are no photos and videos at present") : (currentDataIsImage ? i18n("There are no photos at present") : i18n("There are no videos at present"))
            }
        }
    }

    Loader {
        id: nullLoader
        sourceComponent: nullComponent
        active: !loadAnim.visible & gridView.count == 0
    }

    Timer {
        id: loadTimer
        interval: 1000
        running: true
        onTriggered: {
            loadAnim.visible = false
        }
    }

    LoadAnimaView {
        id: loadAnim
        anchors.centerIn: parent
        timerRun: visible
        visible: loadTimer.running
    }

    Rectangle {
        id: gradRect

        anchors.top: parent.top
        width: parent.width
        height: parent.height / 10
        visible: albumTabBar.visible
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Kirigami.JTheme.headerBackground
            }
            GradientStop {
                position: 1.0
                color: "#00FFFFFF"
            }
        }
    }

    AlbumTabBar {
        id: albumTabBar

        anchors {
            top: parent.top
            topMargin: height / 4 + 20 * appScaleSize
        }
        selectedItem: i18n(CSJ.TopBarItemAllContent)

        Component.onCompleted: {
            model.append({
                             "title": i18n(CSJ.TopBarItemAllContent)
                         })
            model.append({
                             "title": i18n(CSJ.TopBarItemPhotoContent)
                         })
            model.append({
                             "title": i18n(CSJ.TopBarItemVideoContent)
                         })
        }
    }

    function albumThumbnailChanged() {
//        imagesModel.sourceModel.thumbnailChanged(path)
        mediasModel.sourceModel.thumbnailChanged(path)
    }

    onDeleteItemData: {
        switch (albumView.barSelectName) {
        case CSJ.TopBarItemAllContent:
            isVideo = true
            isPhoto = true
            isAll = false
            break
        case CSJ.TopBarItemPhotoContent:
            isVideo = true
            isPhoto = false
            isAll = true
            break
        case CSJ.TopBarItemVideoContent:
            isVideo = false
            isPhoto = tue
            isAll = true
            break
        }
    }

    Timer {
      id:switchTimer
      property int kokoType: 2
      interval: 300
      onTriggered: {
          mediasModel.sourceModel.mimeType = switchTimer.kokoType
          albumView.model = mediasModel
      }
    }

    function switchModel(kokoModelType) {
        switchTimer.kokoType = kokoModelType
        if (switchTimer.running) {
            switchTimer.stop()
        }
        switchTimer.start()
    }

    onFilterBy: {
        if (value !== currentTabBarTitle) {
            albumView.grideHide()
        }
        switch (value) {
        case CSJ.TopBarItemPhotoContent:
        {
//            mediasModel.setFilterType(Koko.Types.Image)
//            mediasModel.sourceModel.mimeType = Koko.Types.Image
//            albumView.model = mediasModel
            switchModel(Koko.Types.Image)
            break
        }
        case CSJ.TopBarItemVideoContent:
        {
            //            mediasModel.setFilterType(Koko.Types.Video)
//            mediasModel.sourceModel.mimeType = Koko.Types.Video
//            albumView.model = mediasModel
            switchModel(Koko.Types.Video)
            break
        }
        case CSJ.TopBarItemAllContent:
        {
//            mediasModel.setFilterType(Koko.Types.All)
//            mediasModel.sourceModel.mimeType = Koko.Types.All
//            albumView.model = mediasModel
            switchModel(Koko.Types.All)
            break
        }
        }
        if (value !== currentTabBarTitle) {
            albumView.grideShow()
        }
        currentTabBarTitle = value
    }

    MouseArea {
        anchors.fill: parent
        enabled: isDeleting
    }
}
