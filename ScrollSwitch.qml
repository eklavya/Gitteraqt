import QtQuick 2.9
import QtQuick.Window 2.3
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3
import "gitterapi.js" as Gitter
import Qt.labs.settings 1.0
import gitter.qml 1.0
import QtQuick.Dialogs 1.2

Switch {
    id: scrollSwitch
    text: qsTr("Auto Scroll")
    indicator: Rectangle {
        implicitWidth: 48
        implicitHeight: 26
        x: scrollSwitch.leftPadding
        y: parent.height / 2 - height / 2
        radius: 13
        color: scrollSwitch.checked ? "#17a81a" : "#ffffff"
        border.color: scrollSwitch.checked ? "#17a81a" : "#cccccc"
        
        Rectangle {
            x: scrollSwitch.checked ? parent.width - width : 0
            width: 26
            height: 26
            radius: 13
            color: scrollSwitch.down ? "#cccccc" : "#ffffff"
            border.color: scrollSwitch.checked ? (scrollSwitch.down ? "#17a81a" : "#21be2b") : "#999999"
        }
    }
    contentItem: Text {
        text: scrollSwitch.text
        font: scrollSwitch.font
        opacity: enabled ? 1.0 : 0.3
        color: "#333333"
        verticalAlignment: Text.AlignVCenter
        leftPadding: scrollSwitch.indicator.width + scrollSwitch.spacing
    }
}
