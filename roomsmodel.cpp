#include "roomsmodel.h"

#include <QDebug>
#include <QSqlError>
#include <QSqlQuery>
#include <QSqlRecord>

static void createTable() {
    if (QSqlDatabase::database().tables().contains(QStringLiteral("rooms"))) {
        return;
    }

    QSqlQuery query;
    if (!query.exec(
        "CREATE TABLE IF NOT EXISTS 'rooms' ("
        "   'id' TEXT NOT NULL,"
        "   'name' TEXT NOT NULL,"
        "   'avatarUrl' TEXT NOT NULL,"
        "   PRIMARY KEY(id)"
        ")")) {
        qFatal("Failed to query database: %s", qPrintable(query.lastError().text()));
    }
}

RoomsModel::RoomsModel(QObject *parent) : QSqlTableModel(parent) {
    createTable();
    setTable("rooms");
    setSort(1, Qt::AscendingOrder);
    select();
    setEditStrategy(QSqlTableModel::OnRowChange);
}

QVariant RoomsModel::data(const QModelIndex &index, int role) const {
    if (role < Qt::UserRole)
        return QSqlTableModel::data(index, role);

    const QSqlRecord sqlRecord = record(index.row());
    return sqlRecord.value(role - Qt::UserRole);
}

QHash<int, QByteArray> RoomsModel::roleNames() const {
    QHash<int, QByteArray> names;
    names[Qt::UserRole] = "id";
    names[Qt::UserRole + 1] = "name";
    names[Qt::UserRole + 2] = "avatarUrl";
    return names;
}

void RoomsModel::addRoom(const QVariantList &id, const QVariantList &name, const QVariantList &avatarUrl) {
    QSqlQuery query;
    query.prepare("insert or replace into rooms values (?, ?, ?)");
    query.addBindValue(id);
    query.addBindValue(name);
    query.addBindValue(avatarUrl);
    if (!query.execBatch())
        qDebug("Failed to query database: %s", qPrintable(query.lastError().text()));

    sort(1, Qt::AscendingOrder);
    select();
}
