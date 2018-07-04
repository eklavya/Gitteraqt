import QtQuick 2.9
import QtQuick.Window 2.3
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3
import "gitterapi.js" as Gitter
import Qt.labs.settings 1.0
import gitter.qml 1.0
import QtQuick.Dialogs 1.2

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
        msgs.model.room = curRoom
        msgs.onRoomChanged()
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

                model: RoomsModel {
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
                property int lastCount: count

                flickableDirection: Flickable.VerticalFlick

                visible: curRoom !== ''

                function onRoomChanged() {
                    positionViewAtEnd()
                }

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

                onCountChanged: {
                    if (window.autoScrollSwitch.checked) {
                        positionViewAtIndex(count - 1, ListView.End)
                    } else {
                        positionViewAtIndex(lastInd, ListView.Center)
                    }
                }

                headerPositioning: ListView.PullBackHeader

                highlightMoveDuration: 200

                model: MessagesModel {
                    //                    id: msgsModel
                    room: window.curRoom
                    //                    onModelReset: {
                    //                        if (!canFetchMore(msgsModel))
                    //                            msgs.modelWasReset()
                    //                    }
                }

                delegate: Item {

                    width: parent.width
                    height: con.height + 20

                    Row {
                        id: row2
                        padding: 4
                        anchors.fill: parent

                        property var sender: JSON.parse(model.fromUser)

                        Image {
                            width: 32
                            height: 32
                            source: row2.sender.avatarUrlSmall
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
                                    text: row2.sender.displayName + " @" + row2.sender.username
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

                Component.onCompleted: {
                    currentIndex = count - 1
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
                    var ids = []
                    var names = []
                    var avatarUrls = []
                    for (var i = 0; i < rms.length; i++) {
                        var r = rms[i]
                        ids.push(r.id)
                        names.push(r.name)
                        avatarUrls.push(r.avatarUrl)
                    }
                    rooms.model.addRoom(ids, names, avatarUrls)

                    for (var j = 0; j < rms.length; j++) {
                        var rid = rms[j].id
                        Gitter.getMessages(settings.token, rid, 50, "", "",
                                           function (ms, r) {
                                               var ids = []
                                               var htmls = []
                                               var fromUsers = []
                                               var roomIds = []
                                               var sents = []
                                               for (var k = 0; k < ms.length; k++) {
                                                   var m = ms[k]
                                                   ids.push(m.id)
                                                   htmls.push(m.html)
                                                   fromUsers.push(
                                                               JSON.stringify(
                                                                   m.fromUser))
                                                   roomIds.push(r)
                                                   sents.push(m.sent)
                                               }
                                               msgs.model.addMessage(
                                                           ids, htmls,
                                                           fromUsers,
                                                           roomIds, sents)
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
            var ids = []
            var names = []
            var avatarUrls = []
            for (var i = 0; i < rms.length; i++) {
                var r = rms[i]
                ids.push(r.id)
                allRooms.push(r.id)
                names.push(r.name)
                avatarUrls.push(r.avatarUrl)
            }
            rooms.model.addRoom(ids, names, avatarUrls)

            refreshRooms(allRooms)

            for (var j = 0; j < rms.length; j++) {
                var rid = rms[j].id
                stream.subscribe("/api/v1/rooms/" + rid + "/chatMessages",
                                 function (rm, payload) {
                                     switch (payload.operation) {
                                     case "create":
                                         var m1 = payload.model
                                         msgs.model.addMessage(
                                                     [m1.id], [m1.html],
                                                     [JSON.stringify(
                                                          m1.fromUser)], [rm],
                                                     [m1.sent])
                                         incrUnread(rm, 1)
                                         break
                                     case "update":
                                         var m2 = payload.model
                                         msgs.model.updateMessage(rm, m2.id,
                                                                  m2.html)
                                         break
                                     default:

                                     }
                                 })
            }
        })
    }

    function refreshRooms(rms) {
        for (var i = 0; i < rms.length; i++) {
            let rid = rms[i]
            var lastId = msgs.model.lastIdForRoom(rid)
            Gitter.getMessages(settings.token, rid, "", "", lastId,
                               function (ms, r) {
                                   var ids = []
                                   var htmls = []
                                   var fromUsers = []
                                   var roomIds = []
                                   var sents = []
                                   for (var k = 0; k < ms.length; k++) {
                                       var m = ms[k]
                                       ids.push(m.id)
                                       htmls.push(m.html)
                                       fromUsers.push(JSON.stringify(
                                                          m.fromUser))
                                       roomIds.push(r)
                                       sents.push(m.sent)
                                   }
                                   msgs.model.addMessage(ids, htmls,
                                                         fromUsers,
                                                         roomIds, sents)

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
                               msgs.model.addMessage([message.id],
                                                     [message.html],
                                                     [JSON.stringify(
                                                          message.fromUser)],
                                                     [rmId], [message.sent])
                           })
        curMsg.text = ""
    }
}
