#ifndef MESSAGES_MODEL_H
#define MESSAGES_MODEL_H

#include <QSqlTableModel>

class MessagesModel : public QSqlTableModel
{
    Q_OBJECT
    Q_PROPERTY(QString room READ room WRITE setRoom NOTIFY roomChanged)

public:
    MessagesModel(QObject *parent = nullptr);

    QString room() const;
    void setRoom(const QString &room);

    QVariant data(const QModelIndex &index, int role) const override;
    Q_INVOKABLE QString lastIdForRoom(const QString &roomId) const;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void addMessage(const QVariantList &id, const QVariantList &html, const QVariantList &fromUser, const QVariantList &roomId, const QVariantList &sent);
    Q_INVOKABLE void updateMessage(const QString &roomId, const QString &id, const QString &html);

signals:
    void roomChanged();

private:
    QString m_room;

    // QSqlTableModel interface
protected:
    QString selectStatement() const override;
};

#endif // MESSAGES_MODEL_H
