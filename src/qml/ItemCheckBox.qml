

/*
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */
import QtQuick 2.12
import QtQuick.Controls 1.4 as Controls
import QtQuick.Layouts 1.2
import QtQuick.Controls.Styles 1.4
import "common.js" as CSJ

Controls.CheckBox {
    id: itemCheckBox

    property int radiusCB
    property int bordWidth
    property var csource
    property bool isItem: false
    property var imageSourceDefault: "qrc:/assets/check_default.png"

    style: CheckBoxStyle {
        indicator:
            Item{
            implicitWidth: itemCheckBox.width
            implicitHeight: itemCheckBox.width
            Rectangle {

            anchors{
                fill: parent
                topMargin: isItem ? 0 : 2 * appScaleSize
                rightMargin: 4 * appScaleSize//isItem ? 4 * appScaleSize : 0
                bottomMargin: isItem ? 4 * appScaleSize : 2 * appScaleSize
            }
            color: checked ? "#3C4BE8" : "transparent"
            radius: radiusCB

            Image {
                id: cBackground

                anchors.centerIn: parent
                width: itemCheckBox.width
                height: itemCheckBox.width
//                sourceSize: Qt.size(44,44)
                source: isItem ? csource : (control.checked ? "qrc:/assets/item_check_ok.png" : imageSourceDefault)
            }
        }
    }

    }
}
