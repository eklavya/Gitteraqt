import QtQml 2.2
import QtQuick 2.9
import QtWebSockets 1.0
import "gitterapi.js" as Gitter

Item {
    id: root

    property real retry: 10000

    // Auto-connects to the server once url is set; disconnects when set to ''
    property string url: ''

    property string token: ''

    property bool debug: false

    property string myId

    property string state

    property var queue: []

    property var calls: ({

                         })

    property var paths: ({

                         })

    signal reconnecting()

    // delay timer
    Timer {
        id: timer
        function setTimeout(cb, delayTime) {
            timer.interval = delayTime;
            timer.repeat = false;
            timer.triggered.connect(cb);
            timer.triggered.connect(function() {
                timer.triggered.disconnect(cb); // This is important
            });
            timer.start();
        }
    }


    onUrlChanged: url ? connect() : (status = '')

    function subscribe(channel, callback) {
        if (debug)
            console.debug("BayeuxClient subscribing to", channel)
        var parts = /^(.*?)(\/\*{1,2})?$/.exec(channel)
        var base = parts[1], wild = parts[2]
        if (!calls[base])
            calls[base] = []
        var index = calls[base].length
        calls[base].push({
                             "callback": callback,
                             "wild": wild,
                             "channel": channel
                         })
        publish('/meta/subscribe', {
                    "subscription": channel,
                    "ext": {
                        "token": token
                    }
                })
        return {
            "cancel": function () {
                publish('/meta/unsubscribe', {
                            "subscription": channel,
                            "ext": {
                                "token": token
                            }
                        })
                calls[base].splice(index, 1)
            }
        }
    }

    function publish(channel, data, options) {
        if (!options)
            options = {

            }
        var message = {
            "channel": channel,
            "ext": {
                "token": token
            }
        }
        Object.keys(data).forEach(function (key) {
            message[key] = data[key]
        })
        queue[options.beforeOthers ? 'unshift' : 'push'](message)
        processQueue()
    }

    function connect() {
        if (socket.status == WebSocket.Open) {
//            print("triggered connect")
            sendConnect()
            return
        }
        if (!url || state)
            return
        if (retry)
            retryConnect.restart()
        state = 'handshake'
        socket.connect()
    }

    function sendConnect() {
        publish('/meta/connect', {
                    "connectionType": 'websocket',
                    "ext": {
                        "token": token
                    }
                }, {
                    "beforeOthers": true
                })
    }

    function handleMessage(message) {
        if (!message)
            return
        if ("string" === typeof message)
            message = JSON.parse(message)
        if (message instanceof Array)
            return message.forEach(handleMessage)
        if (message.advice) {
            if (message.advice.reconnect === 'retry' && message.advice.interval)
                retry = message.advice.interval
            if (message.advice.timeout)
                socket.advisedTimeout = message.advice.timeout
        }
        switch (message.channel) {
        case '/meta/handshake':
//            console.assert(message.successful,
//                           "BayeuxClient xmlhttp handshake failed!")
            if (message.successful) {
//                print("handshake successful", JSON.stringify(message))
                myId = message.clientId
                if (~message.supportedConnectionTypes.indexOf('websocket'))
                    sendConnect()
//                else
//                    console.error(
//                                "BayeuxClient currently only supports WebSocket communication")
            } else
                state = ''
            break
        case '/meta/connect':
            if (message.successful)
                //                print("connected", myId, message.cliendId)
                processQueue()
            else {
                console.warn("BayeuxClient WebSocket connect failed!",
                             message.error)
                state = ''
            }
            break
        case '/meta/subscribe':
            if (!message.successful)
                publish('/meta/subscribe', {
                            "subscription": message.subscription,
                            "ext": {
                                "token": token
                            }
                        })
            break
        default:
            if (!paths[message.channel]) {
                var parts = message.channel.split('/')
                paths[message.channel] = parts.map(function (_, i) {
                    return parts.slice(0, i + 1).join('/')
                }).reverse()
            }
            paths[message.channel].forEach(function (path, index) {
                if (calls[path])
                    calls[path].forEach(function (o) {
                        if ((index === 0) || (index === 1 && o.wild)
                                || (o.wild === '/**'))
                            o.callback(message.channel.split('/')[4],
                                       message.data)
                    })
            })
        }
    }

    function processQueue() {
        if (socket.status == WebSocket.Open) {
            queue.forEach(function (message) {
                message.clientId = myId
                if (debug)
                    console.debug('BayeuxClient websock send:',
                                  JSON.stringify(message))
                socket.sendTextMessage(JSON.stringify(message))
            })
            queue.length = 0
        } else if (socket.status != WebSocket.Connecting)
            connect()
    }

    WebSocket {
        id: socket

        property int advisedTimeout: 30000

        function connect() {
            if (status == WebSocket.Connecting)
                return
            active = false
            active = true // toggle status to force reconnect if URL doesn't change
            var socketURL = root.url
            if (url != socketURL)
                url = socketURL
            state = 'connected'
        }

        onTextMessageReceived: {
            if (debug)
                console.log('BayeuxClient websock recv:', message)
            handleMessage(message)
        }

        onStatusChanged: {
            if (!socket)
                return debug && console.debug(
                            'BayeuxClient WebSocket has been deleted') // Happens when the app is shutting down
            if (debug)
                console.debug('BayeuxClient WebSocket status:', socket.status)
            switch (socket.status) {
            case WebSocket.Connecting:
                break
            case WebSocket.Open:
                sendTextMessage(
                            '[{"channel":"/meta/handshake","version":"1.0","supportedConnectionTypes":["websocket","long-polling"], "ext": {"token": "' + token + '"}}]')
                break
            case WebSocket.Error:
                console.log('BayeuxClient WebSocket error:', socket.errorString)
            case WebSocket.Closed:
                timer.setTimeout(function () {
                    if (debug)
                        console.debug('BayeuxClient attempting to reconnect...')
                    state = ''
                    reconnecting()
                    connect()
                    Object.keys(calls).forEach(function (base) {
                        calls[base].forEach(function (o) {
                            publish('/meta/subscribe', {
                                        "subscription": o.channel,
                                        "ext": {
                                            "token": token
                                        }
                                    })
                        })
                    })
                }, 5000)
                break
            }
        }
    }

    Timer {
        id: retryConnect
        repeat: true
        interval: (retry + socket.advisedTimeout) * 0.9
        Component.onCompleted: triggered.connect(connect)
    }
}
