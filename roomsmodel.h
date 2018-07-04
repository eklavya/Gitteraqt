#ifndef ROOMSMODEL_H
#define ROOMSMODEL_H

#include <QSqlTableModel>

class RoomsModel : public QSqlTableModel
{
    Q_OBJECT

public:
    RoomsModel(QObject *parent = nullptr);
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void addRoom(const QVariantList &id, const QVariantList &name, const QVariantList &avatarUrl);

signals:

};

#endif // ROOMSMODEL_H
