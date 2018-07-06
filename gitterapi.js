.pragma library

// #TODO timeouts

function getMessages(token, roomId, limit, beforeId, afterId, onMessages) {
    var xhr = new XMLHttpRequest();
    xhr.open("GET", "https://api.gitter.im/v1/rooms/" + roomId + "/chatMessages?limit=" + limit + "&beforeId=" + beforeId + "&afterId=" + afterId, true);
    xhr.setRequestHeader("Authorization", "Bearer " + token);
    xhr.onreadystatechange = function() {
        if(xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status !== 200) print(xhr.statusText, xhr.responseText)
            var object = JSON.parse(xhr.responseText.toString());
            onMessages(object, roomId);
        }
    }
    xhr.send();
}

function getRooms(token, user, onRooms) {
    var xhr = new XMLHttpRequest();
    xhr.open("GET", "https://api.gitter.im/v1/user/" + user.id + "/rooms", true);
    xhr.setRequestHeader("Authorization", "Bearer " + token);
    xhr.onreadystatechange = function() {
        if(xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status !== 200) print(xhr.statusText, xhr.responseText)
            var object = JSON.parse(xhr.responseText.toString());
//            print(xhr.responseText);
            onRooms(object);
        }
    }
    xhr.send();
}

function getRoomUsers(token, roomId, onUsers) {
    var xhr = new XMLHttpRequest();
    xhr.open("GET", "https://api.gitter.im/v1/rooms/"+ roomId + "/users", true);
    xhr.setRequestHeader("Authorization", "Bearer " + token);
    xhr.onreadystatechange = function() {
        if(xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status !== 200) print(xhr.statusText, xhr.responseText)
            var object = JSON.parse(xhr.responseText.toString());
//            print(xhr.responseText);
            onUsers(roomId, object);
        }
    }
    xhr.send();
}

function getUsers(token, onUser) {
    var xhr = new XMLHttpRequest();
    xhr.open("GET", "https://api.gitter.im/v1/user", true);
    xhr.setRequestHeader("Authorization", "Bearer " + token);
    xhr.onreadystatechange = function() {
        if(xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status !== 200) print(xhr.statusText, xhr.responseText)
            var object = JSON.parse(xhr.responseText.toString());
            onUser(object[0]);
        }
    }
    xhr.send();
}

function markRead(token, userId, roomId, msgIds) {
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "https://api.gitter.im/v1/user/" + userId + "/rooms/" + roomId + "/unreadItems", true);
    xhr.setRequestHeader("Authorization", "Bearer " + token);
    xhr.onreadystatechange = function() {
        if(xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status !== 200) print(xhr.statusText, xhr.responseText)
        }
    }
    xhr.send({"chat": JSON.stringify(msgIds)});
}

function sendMessage(token, roomId, m) {
    print(token, roomId, m);
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "https://api.gitter.im/v1/rooms/" + roomId + "/chatMessages", true);
    xhr.setRequestHeader("Authorization", "Bearer " + token);
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.onreadystatechange = function() {
        if(xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status !== 200) print(xhr.statusText, xhr.responseText)
//            if (xhr.status === 200) {
//                var message = JSON.parse(xhr.responseText);
//                onSuccess(roomId, message);
//            }
        }
    }
    var body = JSON.stringify({"text": m});
    xhr.send(body);
}

function updateMessage(token, roomId, messageId, m) {
    var xhr = new XMLHttpRequest();
    xhr.open("PUT", "https://api.gitter.im/v1/rooms/" + roomId + "/chatMessages/" + messageId, true);
    xhr.setRequestHeader("Authorization", "Bearer " + token);
    xhr.onreadystatechange = function() {
        if(xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status !== 200) print(xhr.statusText, xhr.responseText)
        }
    }
    xhr.send({"text": m});
}
