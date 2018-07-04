#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QStandardPaths>
#include <QSqlDatabase>
#include <QSqlError>
#include <QtQml>

#include "messagesmodel.h"
#include "roomsmodel.h"

static void connectToDatabase(const QString &path)
{
    QSqlDatabase database = QSqlDatabase::addDatabase("QSQLITE");
    if (!database.isValid())
        qFatal("Cannot add database: %s", qPrintable(database.lastError().text()));
    // Ensure that we have a writable location on all devices.
    const QString fileName = path + "/gitteraqt.sqlite3";
    // When using the SQLite driver, open() will create the SQLite database if it doesn't exist.
    database.setDatabaseName(fileName);
    qDebug() << fileName;
    if (!database.open()) {
        QFile::remove(fileName);
        qFatal("Cannot open database: %s", qPrintable(database.lastError().text()));
    }
}

class CachingFactory : public QQmlNetworkAccessManagerFactory
{
public:
    virtual QNetworkAccessManager *create(QObject *parent);
};

QNetworkAccessManager *CachingFactory::create(QObject *parent)
{
    QNetworkAccessManager *manager = new QNetworkAccessManager(parent);
    QNetworkDiskCache *diskCache = new QNetworkDiskCache(parent);
    const QDir writeDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    diskCache->setCacheDirectory(writeDir.absolutePath() + "/cache");
    manager->setCache(diskCache);
    return manager;
}

void noMessageOutput(QtMsgType, const QMessageLogContext &, const QString &) {}

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setApplicationName("Gitteraqt");
    QCoreApplication::setApplicationVersion("1.0");
    QCoreApplication::setOrganizationDomain("eklavya.com");
    QCoreApplication::setOrganizationName("Eklavya");

    const QDir writeDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (!writeDir.mkpath("."))
        qFatal("Failed to create writable directory at %s", qPrintable(writeDir.absolutePath()));

    const QString writePath = writeDir.absolutePath();

    QSettings::setPath(QSettings::defaultFormat(), QSettings::UserScope, writePath);

    QGuiApplication app(argc, argv);

    qmlRegisterType<MessagesModel>("gitter.qml", 1, 0, "MessagesModel");
    qmlRegisterType<RoomsModel>("gitter.qml", 1, 0, "RoomsModel");

    connectToDatabase(writePath);

    QQmlApplicationEngine engine;
    engine.setNetworkAccessManagerFactory(new CachingFactory);

#ifndef QT_DEBUG
    qInstallMessageHandler(noMessageOutput);
#endif

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
