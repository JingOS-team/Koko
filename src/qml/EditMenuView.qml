/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Zhang He Gang <zhanghegang@jingos.com>
 *
 */
import QtQuick 2.12
import QtQuick.Controls 2.12
import "common.js" as CSJ
import QtGraphicalEffects 1.0
import org.kde.kirigami 2.15 as Kirigami

Kirigami.JPopupMenu {
    id: menu

    property int mwidth: 200 * appScaleSize
    property int m_menItemHeight: 180 * heightScaleSize / 4
    property int mheight: m_menItemHeight * menuItemCount
    property var separatorColor: "#4Dffffff"
    property int separatorWidth: mwidth * 8 / 10
    property int mouseX
    property int mouseY
    property int menuItemCount: menu.count
    property int backRadius: 12 * appScaleSize
    property bool hasSelectItem
    property bool isbulkVisible
    property var tabSelectText
    property int selectCount
    signal bulkClicked
    signal deleteClicked
    signal renameClicked
    signal saveClicked

    function rmBulkAction() {
    }
    function addBulkAction() {
    }

    Action { 
        text: i18n(CSJ.Left_View_Edit_Menu_Bulk)
        icon.source: "qrc:/assets/edit_bulk.svg"
        onTriggered:
        {
            bulkClicked()
            close()
        }
    }

    Kirigami.JMenuSeparator { }

    Action { 
        text: i18n(CSJ.Left_View_Edit_Menu_Delete)
        icon.source: "qrc:/assets/edit_delete.svg"
        onTriggered:
        {
            deleteDialog.open()
            close()
        }
    }
}
