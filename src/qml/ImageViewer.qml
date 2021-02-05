

/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2017 Marco Martin <mart@kde.org>
 *                             2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */
import QtQuick 2.12
import QtQuick.Window 2.2
import QtQuick.Controls 2.10 as Controls
import QtGraphicalEffects 1.0 as Effects
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.13 as Kirigami
import org.kde.jinggallery 0.2 as Koko
import org.kde.kquickcontrolsaddons 2.0 as KQA

Kirigami.Page {
    id: root

    property var startIndex
    property var imageviewModel
    property bool isFirst: false
    property var gradviewModel
    property bool isDeleteClicked
    property var currentMimeType
    property var imageGridView
    property bool isFirstOpenPage: true

    signal backToPage

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    globalToolBarStyle: Kirigami.ApplicationHeaderStyle.None

    Kirigami.Theme.textColor: imgColors.foreground
    Kirigami.Theme.backgroundColor: imgColors.background
    Kirigami.Theme.highlightColor: imgColors.highlight
    Kirigami.Theme.highlightedTextColor: Kirigami.ColorUtils.brightnessForColor(
                                             imgColors.highlight) === Kirigami.ColorUtils.Dark ? imgColors.closestToWhite : imgColors.closestToBlack

    background: Rectangle {
        color: "black"
    }

    Kirigami.ImageColors {
        id: imgColors
        source: listView.currentItem
    }

    KQA.MimeDatabase {
        id: mimeDB
    }

    Kirigami.ContextDrawer {
        id: contextDrawer
        title: i18n("Edit image")
        handleVisible: true
    }

    Component.onDestruction: {
        albumView.backToPage()
    }

    Component.onCompleted: {
        console.log("page onCompleteed")
        applicationWindow().controlsVisible = true
        listView.forceActiveFocus()
    }

    function close() {
        applicationWindow().controlsVisible = true
        if (applicationWindow().footer) {
            applicationWindow().footer.visible = true
        }
        applicationWindow().visibility = Window.Windowed
        applicationWindow().pageStack.layers.pop()
    }

    Keys.onPressed: {
        switch (event.key) {
        case Qt.LeftButton:
            break
        case Qt.Key_Escape:
            root.close()
            break
        case Qt.Key_F:
            applicationWindow().visibility = applicationWindow(
                        ).visibility == Window.FullScreen ? Window.Windowed : Window.FullScreen
            break
        default:
            break
        }
    }

    ShareDialog {
        id: shareDialog

        inputData: {
            "urls": [],
            "mimeType": ["image/", "video/"]
        }

        onFinished: {
            if (error == 0 && output.url !== "") {
                console.assert(output.url !== undefined)
                var resultUrl = output.url
                console.log("Received", resultUrl)
                notificationManager.showNotification(true, resultUrl)
                clipboard.content = resultUrl
            } else {
                notificationManager.showNotification(false)
            }
        }
    }

    onActiveFocusChanged: {
        if (!activeFocus && listView.isPlayImageClick) {
            listView.isPlayImageClick = false
            applicationWindow().pageStack.layers.pop()
        }
    }

    ListView {
        id: listView

        property bool isCrop
        property bool isPlayImageClick
        property bool isCropImageAfter
        property var currentCropPath
        property bool isMoving

        signal thumbnailChanged(var path, var index)
        signal cropImageChanged(var path, var index)

        anchors.fill: parent
        orientation: Qt.Horizontal
        snapMode: ListView.SnapOneItem
        maximumFlickVelocity: 10000
        highlightMoveVelocity: 9000
        highlightMoveDuration: 0
        highlightRangeMode: ListView.StrictlyEnforceRange
        interactive: !imageEditTitle.visible
        model: gradviewModel

        onThumbnailChanged: {
            console.info("onThumbnailChanged:path:" + path + " index::" + index)
            gradviewModel.updatePreview(path, index)
            imageGridView.reloadSource(listView.currentIndex)
        }

        onCropImageChanged: {
            currentCropPath = path
            isCropImageAfter = true
        }

        // Filter out directories
        onCountChanged: {
            if (isCropImageAfter) {
                isCropImageAfter = false
                var cropIndex = gradviewModel.sourceModel.findIndex(
                            currentCropPath)
                listView.currentIndex = cropIndex > -1 ? cropIndex : listView.currentIndex
            }
        }

        Component.onCompleted: {
            listView.currentIndex = startIndex
        }

        Timer {
            id: moveTimer
            interval: 200
            onTriggered: {
                listView.isMoving = false
            }
        }

        onMovementStarted: {
            if (moveTimer.running) {
                moveTimer.stop()
            }
            isMoving = true
        }

        onMovementEnded: {
            if (!moveTimer.running) {
                moveTimer.start()
            }
        }

        delegate: EditorView {

            readonly property string display: model.display

            width: root.width
            height: root.height
            mimeType: model.mimeType
            duration: model.duration
            imageTime: model.imageTime
            imagePath: model.previewurl
            thumbnailPixmapPath: model.thumbnailPixmap
            mediaUrl: model.mediaurl
            delegate: listView.currentItem
            index: listView.currentIndex
            mIndex: model.index

            Component.onCompleted: {
                if (!setCacheTimer.running & listView.cacheBuffer != listView.width * 5) {
                    setCacheTimer.start()
                }
            }

            Timer {
                id: setCacheTimer
                interval: 500
                onTriggered: {
                    if (listView.cacheBuffer != listView.width * 5) {
                        listView.cacheBuffer = listView.width * 5
                    }
                }
            }

            onItemClicked: {
                root.isFirst = !root.isFirst
            }

            onDeleteItemClicked: {
                listView.model.deleteItemByModeIndex(model.index)
            }

            onPlayVideoItem: {
                listView.isPlayImageClick = true
            }
        }
    }

    Rectangle {
        id: leftItem

        anchors {
            left: parent.left
        }
        height: parent.height
        width: leftArrow.width + 20
        color: "transparent"

        MouseArea {
            width: parent.width
            height: parent.height
            hoverEnabled: true

            onEntered: {
                console.info("qml leftItem arrow--" + leftArrow.opacity)
                leftArrow.opacity = 1.0
            }

            onExited: {
                leftArrow.opacity = 0.0
            }
        }

        Image {
            id: leftArrow

            anchors {
                left: parent.left
                leftMargin: Kirigami.Units.largeSpacing
                verticalCenter: parent.verticalCenter
            }
            source: "qrc:/assets/leftarrow.png"
            sourceSize: Qt.size(60, 60)
            opacity: 0.0

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    leftArrow.opacity = 1.0
                }

                onExited: {
                    leftArrow.opacity = 0.0
                }

                onClicked: {
                    listView.currentIndex > 1 ? (listView.currentIndex
                                                 -= 1) : (listView.currentIndex = 0)
                }
            }
        }
    }

    Rectangle {
        id: rightItem

        anchors {
            right: parent.right
        }
        height: parent.height
        width: rightArrow.width
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                rightArrow.opacity = 1.0
            }

            onExited: {
                rightArrow.opacity = 0.0
            }
        }

        Image {
            id: rightArrow

            anchors {
                right: parent.right
                rightMargin: Kirigami.Units.largeSpacing
                verticalCenter: parent.verticalCenter
            }
            source: "qrc:/assets/rightarrow.png"
            sourceSize: Qt.size(60, 60)
            opacity: 0.0

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    rightArrow.opacity = 1.0
                }

                onExited: {
                    rightArrow.opacity = 0.0
                }

                onClicked: {
                    (listView.currentIndex < listView.count
                     - 1) ? listView.currentIndex += 1 : listView.currentIndex
                            = listView.currentIndex
                }
            }
        }
    }

    Component {
        id: editorComponent

        EditorView {
            width: root.width
            height: root.height
            imagePath: listView.currentItem.currentImageSource
            delegate: listView.currentItem
            index: listView.currentIndex
        }
    }

    WorkerScript {
        id: myWorker
        source: "imagethread.mjs"
        onMessage: {
            listView.currentItem.rotateSave()
        }
    }

    ImageEditTitle {
        id: imageEditTitle

        property bool isRotateImage

        anchors {
            top: parent.top
        }
        visible: isFirst
        isVideoScreen: listView.currentItem.isVideo
        titleName: listView.currentItem.display
        titleDateTime: getDateTime()

        onVisibleChanged: {
            if (!visible && isRotateImage) {
                myWorker.sendMessage({})
                imageEditTitle.isRotateImage = false
            }
        }

        function getDateTime() {
            return listView.currentItem.imageTime
        }

        onBackClicked: {
            applicationWindow().pageStack.layers.pop()
        }

        onCropCLicked: {
            listView.currentItem.cropClicked()
        }

        onRotateClicked: {
            listView.currentItem.roatateClicked()
            imageEditTitle.isRotateImage = true
        }

        onDeleteClicked: {
            listView.currentItem.deleteItemClicked()
        }
    }
}
