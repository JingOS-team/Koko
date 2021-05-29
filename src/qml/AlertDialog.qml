/*
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

import QtQuick 2.12
import org.kde.kirigami 2.15 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.2
import "common.js" as CSJ

Kirigami.JDialog{
    id:dialog

    property var titleContent : i18n("Delete")
    property var msgContent : i18n("Are you sure you want to delete this photo?")
    property var rightButtonContent : i18n("Delete")
    property var leftButtonContent : i18n("Cancel")

    signal dialogRightClicked
    signal dialogLeftClicked

    title: titleContent
    text: msgContent
    rightButtonText: qsTr(rightButtonContent)
    leftButtonText: qsTr(leftButtonContent)
    visible:false

    onVisibleChanged:{
        if (!visible) {
            albumView.rightMenuPhoto = false;
            albumView.rightMenuVideo = false;
        }
    }

    onRightButtonClicked:{
        dialogRightClicked()
    }

    onLeftButtonClicked:{
        dialogLeftClicked()
    }

    function updateMsg(tabBarSelectText,count) {
        var updateMsgContent = ""
        if (albumView.isPhotoItem && !albumView.isVideoItem) {
            updateMsgContent = count > 1 ? CSJ.Dialog_Photos_Text:CSJ.Dialog_Photo_Text
        }else if (albumView.isVideoItem && ! albumView.isPhotoItem) {
            updateMsgContent = count > 1 ? CSJ.Dialog_Videos_Text:CSJ.Dialog_Video_Text
        }else if (albumView.isPhotoItem && albumView.isVideoItem) {
            updateMsgContent =count >1 ? CSJ.Dialog_All_More_Text : CSJ.Dialog_All_Singal_Text
        }
        return updateMsgContent === "" ?  CSJ.Dialog_All_Singal_Text : updateMsgContent;
    }
}
