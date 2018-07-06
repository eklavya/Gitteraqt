import QtQuick 2.9
import QtQuick.Window 2.3
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3
import "gitterapi.js" as Gitter
import Qt.labs.settings 1.0
import QtQuick.Dialogs 1.2
import QtLevelDB 1.0 as LDB

Window {
    id: window
    visible: true
    width: 840
    height: 630
    title: qsTr("Gitteraqt")

    property Switch autoScrollSwitch: null

    property string curRoom: ""

    property var allRooms: []


    // when we add autocomplete
    //    property var roomUsers: ({})
    property var notifier: ({

                            })

    property var notifierState: ({

                                 })

    onCurRoomChanged: {
        msgs.model.clear()
        var mids = db.get(curRoom + "-msgs")
        var ids = mids ? JSON.parse(mids) : []
        var latest = ids.slice(-500)
        ids.forEach(function (mid) {
            var m = JSON.parse(db.get(JSON.stringify(mid)))
            msgs.model.append(m)
        })
        if (notifier.hasOwnProperty(curRoom))
            notifier[curRoom].changeHighlight(false)
        settings.roomState[curRoom] = 0
    }

    Settings {
        id: settings
        property var user: ({

                            })
        property string token: ""
        property var roomState: ({

                                 })
    }

    LDB.LevelDB {
        id: db
        source: "file://" + appdir + "/gitterdb"

        onLastErrorChanged: {
            console.error(appdir, lastError)
        }

        onOpenedChanged: {
            var rms = JSON.parse(db.get("rooms"))
            rms.forEach(function (rm) {
                var mids = db.get(rm.id + "-msgs")
                var ids = mids ? JSON.parse(mids) : []
                ids = ids.slice(0, ids.length - 500)
                ids.forEach(function (i) {
                    db.del(JSON.stringify(i))
                })
            })
        }
    }

    Row {
        id: row
        anchors.fill: parent
        Rectangle {
            width: parent.width * 0.20
            height: parent.height
            anchors.left: parent.left
            color: "#eeeeee"
            ListView {
                id: rooms
                width: parent.width
                height: parent.height
                anchors.left: parent.left

                model: ListModel {
                }

                currentIndex: -1

                highlight: Rectangle {
                    color: 'lightblue'
                }

                highlightMoveDuration: 200
                delegate: Item {
                    width: parent.width
                    height: 40
                    Rectangle {
                        id: highlighter
                        anchors.fill: parent
                        color: "#FFE082"
                        visible: notifierState.hasOwnProperty(model.id)
                                 && notifierState[model.id]
                    }

                    Row {
                        id: row1
                        padding: 4
                        Image {
                            width: 32
                            height: 32
                            source: model.avatarUrl
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: 128
                            sourceSize.height: 128
                        }

                        Text {
                            text: model.name
                            width: parent.parent.width - 44
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                            maximumLineCount: 1
                        }
                        spacing: 10
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            rooms.currentIndex = index
                            window.curRoom = model.id
                        }
                    }

                    Component.onCompleted: {
                        window.notifier[model.id] = {
                            "changeHighlight": function (shouldHighlight) {
                                notifierState[model.id] = shouldHighlight
                                highlighter.visible = shouldHighlight
                            }
                        }
                    }
                }
                spacing: 10
            }
        }

        Column {
            id: msgArea
            width: parent.width * 0.80
            height: parent.height
            anchors.right: parent.right
            anchors.rightMargin: 0
            padding: 2
            Text {
                text: "Please select a room on the left."
                font.bold: true
                font.pointSize: 24
                anchors.centerIn: parent
                visible: curRoom === ''
            }

            ListView {
                id: msgs
                width: parent.width

                height: parent.height - 60
                anchors.right: parent.right
                anchors.rightMargin: 0

                property int lastInd: count - 1

                flickableDirection: Flickable.VerticalFlick

                visible: curRoom !== ''

                cacheBuffer: 200

                header: Rectangle {
                    z: 2
                    color: "#eeeeee"
                    opacity: 1.0
                    radius: 2
                    height: 40
                    width: 140
                    anchors.right: parent.right

                    ScrollSwitch {
                        id: scrollSwitch
                    }

                    Component.onCompleted: {
                        scrollSwitch.checked = true
                        window.autoScrollSwitch = scrollSwitch
                    }
                }

                headerPositioning: ListView.PullBackHeader

                highlightMoveDuration: 200

                model: ListModel {
                    onCountChanged: {
                        if (window.autoScrollSwitch.checked) {
                            msgs.positionViewAtIndex(count - 1, ListView.End)
                        } else {
                            msgs.positionViewAtIndex(msgs.lastInd, ListView.Center)
                        }
                    }
                }

                delegate: Item {

                    width: parent.width
                    height: con.height + 20

                    Row {
                        padding: 4
                        anchors.fill: parent

                        Image {
                            width: 32
                            height: 32
                            source: model.fromUser.avatarUrlSmall
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: 128
                            sourceSize.height: 128
                        }
                        Column {
                            height: parent.height
                            width: parent.width - 44
                            Row {
                                width: parent.width
                                height: 20
                                Text {
                                    text: model.fromUser.displayName + " @"
                                          + model.fromUser.username
                                    color: "#888888"
                                }
                                Text {
                                    id: time
                                    text: ''
                                    color: "#888888"
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                }
                            }
                            ScrollView {
                                height: con.height
                                width: parent.width
                                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                                ScrollBar.vertical.interactive: false
                                clip: true

                                Flickable {
                                    flickableDirection: Flickable.HorizontalFlick
                                    height: con.height
                                    width: parent.width
                                    clip: true

                                    TextEdit {
                                        id: con
                                        text: model.html
                                        textFormat: TextEdit.RichText
                                        height: contentHeight + 4
                                        width: parent.parent.width - 4
                                        wrapMode: Text.Wrap
                                        readOnly: true
                                        selectByMouse: true
                                        selectionColor: "#64B5F6"
                                        activeFocusOnPress: true

                                        onActiveFocusChanged: {
                                            if (activeFocus)
                                                msgs.lastInd = index
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            acceptedButtons: Qt.NoButton
                                            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        }

                                        onLinkActivated: Qt.openUrlExternally(
                                                             link)
                                    }
                                }
                            }
                        }
                        spacing: 10
                    }

                    Component.onCompleted: {
                        var a = new Date(Date.parse(model.sent))
                        time.text = a.toLocaleDateString(
                                    Qt.locale(),
                                    "MMM d ") + a.toLocaleTimeString(
                                    Qt.locale(), "hh:mm AP")
                    }
                }
                spacing: 10
            }

            Row {
                width: parent.width
                height: 40
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                visible: curRoom !== ''

                Rectangle {
                    width: parent.width - 60
                    height: 40
                    border.color: curMsg.focus ? "#64B5F6" : "#eeeeee"

                    Flickable {
                        id: flick

                        width: parent.width
                        height: 40
                        contentWidth: curMsg.paintedWidth
                        contentHeight: curMsg.paintedHeight
                        clip: true

                        function ensureVisible(r) {
                            if (contentX >= r.x)
                                contentX = r.x
                            else if (contentX + width <= r.x + r.width)
                                contentX = r.x + r.width - width
                            if (contentY >= r.y)
                                contentY = r.y
                            else if (contentY + height <= r.y + r.height)
                                contentY = r.y + r.height - height
                        }

                        TextEdit {
                            id: curMsg
                            width: flick.width
                            focus: true
                            wrapMode: TextEdit.Wrap
                            selectionColor: "#64B5F6"
                            onCursorRectangleChanged: flick.ensureVisible(
                                                          cursorRectangle)
                            textMargin: 4

                            Keys.onReturnPressed: {
                                if (event.modifiers === Qt.ControlModifier
                                        || event.modifiers === Qt.MetaModifier) {
                                    event.accepted = true
                                    sendMessage()
                                } else {
                                    event.accepted = false
                                }
                            }
                        }
                    }
                }

                Button {
                    id: send
                    width: 60
                    text: "Send"
                    onClicked: sendMessage()
                }
            }
        }
    }

    Dialog {
        id: tokenDialog
        visible: false
        title: "Need token."
        standardButtons: StandardButton.Save
        modality: Qt.ApplicationModal
        property string token: ""

        onAccepted: {
            token = tokenEdit.text
            Gitter.getUsers(token, function (user) {
                settings.token = token
                settings.user = user
                Gitter.getRooms(settings.token, user, function (rms) {
                    db.put("rooms", JSON.stringify(rms))
                    for (var i = 0; i < rms.length; i++) {
                        var r = rms[i]
                        rooms.model.append(r)
                    }

                    for (var j = 0; j < rms.length; j++) {
                        var rid = rms[j].id
                        Gitter.getMessages(settings.token, rid, 50, "", "",
                                           function (ms, r) {
                                               for (var k = 0; k < ms.length; k++) {
                                                   var m = ms[k]
                                                   if (curRoom === r)
                                                       msgs.model.append(m)
                                                   saveMessage(r, m)
                                               }
                                           })
                    }
                })

                init()
            })
        }

        height: 120
        width: 340
        Column {
            width: parent.width * 0.8
            height: 40
            anchors.centerIn: parent
            Text {
                text: "Please enter your gitter token."
            }
            TextField {
                id: tokenEdit
            }
            spacing: 10
        }
    }

    BayeuxClient {
        id: stream
        debug: false
        token: settings.token
        url: "wss://ws.gitter.im/bayeux"

        onReconnecting: refreshRooms(allRooms)
    }

    Component.onCompleted: {
        if (settings.token === "") {
            tokenDialog.visible = true
        } else {
            init()
        }
    }

    function init() {
        Gitter.getRooms(settings.token, settings.user, function (rms) {
            db.put("rooms", JSON.stringify(rms))
            rooms.model.clear()
            for (var i = 0; i < rms.length; i++) {
                var r = rms[i]
                allRooms.push(r.id)
                rooms.model.append(r)
            }

            refreshRooms(allRooms)

            for (var j = 0; j < rms.length; j++) {
                var rid = rms[j].id
                stream.subscribe("/api/v1/rooms/" + rid + "/chatMessages",
                                 function (rm, payload) {
                                     switch (payload.operation) {
                                     case "create":
                                         var m1 = payload.model
                                         if (curRoom === rm)
                                             msgs.model.append(m1)
                                         saveMessage(rm, m1)
                                         incrUnread(rm, 1)
                                         break
                                     case "update":
                                         var m2 = payload.model
                                         db.put(JSON.stringify(m2.id),
                                                JSON.stringify(m2))
                                         break
                                     default:

                                     }
                                 })
            }
        })
    }

    function refreshRooms(rms) {
        for (var i = 0; i < rms.length; i++) {
            var rid = rms[i]
            var mids = db.get(rid + "-msgs")
            var ids = mids ? JSON.parse(mids) : []
            var lastId = ids.length > 0 ? ids.slice(-1)[0] : ''
            Gitter.getMessages(settings.token, rid, "", "", lastId,
                               function (ms, r) {
                                   for (var k = 0; k < ms.length; k++) {
                                       var m = ms[k]
                                       if (curRoom === r)
                                           msgs.model.append(m)
                                       saveMessage(r, m)
                                   }

                                   incrUnread(r, ms.length)
                               })
            //            Gitter.getRoomUsers(settings.token, rid, function (roomId, users) {
            //                roomUsers[roomId] = users
            //            })
        }
    }

    function incrUnread(rmId, by) {
        if (settings.roomState[rmId]) {
            settings.roomState[rmId] = settings.roomState[rmId] + by
        } else {
            settings.roomState[rmId] = by
        }
        if (curRoom !== rmId && settings.roomState[rmId] > 0
                && notifier.hasOwnProperty(rmId))
            notifier[rmId].changeHighlight(true)
    }

    function sendMessage() {
        Gitter.sendMessage(settings.token, window.curRoom, curMsg.text,
                           function (rmId, message) {
                               msgs.model.append(message)
                               saveMessage(rmId, message)
                           })
        curMsg.text = ""
    }

    function saveMessage(roomId, message) {
        var mids = db.get(roomId + "-msgs")
        var ids = mids ? JSON.parse(mids) : []
        db.put(JSON.stringify(message.id), JSON.stringify(message))
        ids.push(message.id)
        db.put(roomId + "-msgs", JSON.stringify(ids))
    }
}
