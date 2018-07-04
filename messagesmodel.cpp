#include "messagesmodel.h"

#include <QDateTime>
#include <QDebug>
#include <QSqlError>
#include <QSqlRecord>
#include <QSqlQuery>

static const char *messagesTableName = "messages";

static void createTable() {
    if (QSqlDatabase::database().tables().contains(messagesTableName)) {
        return;
    }

    QSqlQuery query;
    if (!query.exec(
                "CREATE TABLE IF NOT EXISTS 'messages' ("
                "'id' TEXT NOT NULL,"
                "'html' TEXT,"
                "'fromUser' TEXT NOT NULL,"
                "'roomId' TEXT NOT NULL,"
                "'sent' TEXT NOT NULL,"
                "PRIMARY KEY(id))")) {
        qFatal("Failed to query database: %s", qPrintable(query.lastError().text()));
    }

    if (!query.exec(
                "create index if not exists "
                "sentIndex on messages (sent)")) {
        qFatal("Failed to query database: %s", qPrintable(query.lastError().text()));
    }
}

static void pruneOld() {
    QSqlQuery query;
    query.exec("select id from rooms");
    QStringList list;
    while (query.next()) list << query.value(0).toString();
    query.prepare("delete FROM messages WHERE id IN (SELECT id FROM messages where roomId = ? ORDER BY sent DESC LIMIT -1 OFFSET 200)");
    query.addBindValue(list);
    if (!query.execBatch())
        qFatal("Failed to query database: %s", qPrintable(query.lastError().text()));
    qDebug() << query.lastQuery();
    query.last();
    qDebug() << query.numRowsAffected();

}

MessagesModel::MessagesModel(QObject *parent) :
    QSqlTableModel(parent) {
    createTable();
    pruneOld();
    setTable(messagesTableName);
    setSort(4, Qt::AscendingOrder);
    setEditStrategy(QSqlTableModel::OnRowChange);
}

QString MessagesModel::room() const {
    return m_room;
}

void MessagesModel::setRoom(const QString &room) {
    if (room == m_room)
        return;

    m_room = room;

    const QString filterString = QString::fromLatin1(
                "roomId = '%1'").arg(m_room);
    setFilter(filterString);
    select();

    emit roomChanged();
}

QVariant MessagesModel::data(const QModelIndex &index, int role) const {
    if (role < Qt::UserRole)
        return QSqlTableModel::data(index, role);

    const QSqlRecord sqlRecord = record(index.row());
    return sqlRecord.value(role - Qt::UserRole);
}

QHash<int, QByteArray> MessagesModel::roleNames() const {
    QHash<int, QByteArray> names;
    names[Qt::UserRole] = "id";
    names[Qt::UserRole + 1] = "html";
    names[Qt::UserRole + 2] = "fromUser";
    names[Qt::UserRole + 3] = "roomId";
    names[Qt::UserRole + 4] = "sent";
    return names;
}

void MessagesModel::addMessage(const QVariantList &id, const QVariantList &html, const QVariantList &fromUser, const QVariantList &roomId, const QVariantList &sent) {
    QSqlQuery query;
    query.prepare("insert or replace into messages values (?, ?, ?, ?, ?)");
    query.addBindValue(id);
    query.addBindValue(html);
    query.addBindValue(fromUser);
    query.addBindValue(roomId);
    query.addBindValue(sent);
    if (!query.execBatch())
        qDebug("Failed to query database: %s", qPrintable(query.lastError().text()));

    // TODO: how to avoid this?
    if (!roomId.isEmpty() && m_room == roomId.first().toString()) {
        select();
    }
}

void MessagesModel::updateMessage(const QString &roomId, const QString &id, const QString &html) {
    QSqlQuery query;
    query.prepare("update messages set html = ? where id = ?");
    query.bindValue(0, html);
    query.bindValue(1, id);
    if(!query.exec())
        qFatal("Failed to query database: %s", qPrintable(query.lastError().text()));
    if (m_room == roomId) {
        select();
    }
}


QString MessagesModel::lastIdForRoom(const QString &roomId) const {
    QSqlQuery query;
    query.prepare("select id from messages where roomId = ? order by sent DESC limit 1");
    query.bindValue(0, roomId);
    query.exec();
    if (query.next())
        return query.value(0).toString();
    else return "";
}

QString MessagesModel::selectStatement() const {
    return QSqlTableModel::selectStatement() + QString(" LIMIT 200");
}
