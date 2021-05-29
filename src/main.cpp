/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>

#include <QDebug>
#include <QDir>
#include <QStandardPaths>
#include <QThread>

#include <KLocalizedContext>
#include <KLocalizedString>
#include <KAboutData>
#include <KDBusService>

#include <QApplication>
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QQuickView>
#include <QQuickStyle>

#include <iostream>
#include <QDateTime>

#include "filesystemtracker.h"
#include "mediastorage.h"
#include "jinggalleryconfig.h"
#include "processor.h"
#include "resizehandle.h"
#include "resizerectangle.h"
#include "listimageprovider.h"

#ifdef Q_OS_ANDROID
#include <QtAndroid>
#endif

int main(int argc, char **argv)
{
    qint64 startTime = QDateTime::currentMSecsSinceEpoch();
    KLocalizedString::setApplicationDomain("Photos");
    KAboutData aboutData(QStringLiteral("Photos"),
                         xi18nc("@title", "<application>Photos</application>"),
                         QStringLiteral("0.2-dev"),
                         xi18nc("@title", "Photos is an image viewer for your image collection."),
                         KAboutLicense::LGPL,
                         xi18nc("@info:credit", "(c) 2013-2020 KDE Contributors"));

    aboutData.setOrganizationDomain(QByteArray("kde.org"));
    aboutData.setProductName(QByteArray("Photos"));

    aboutData.addAuthor(xi18nc("@info:credit", "Vishesh Handa"),
                        xi18nc("@info:credit","Developer"),
                        "vhanda@kde.org");

    aboutData.addAuthor(xi18nc("@info:credit", "Atul Sharma"),
                        xi18nc("@info:credit", "Developer"),
                        "atulsharma406@gmail.com");

    aboutData.addAuthor(xi18nc("@info:credit", "Marco Martin"),
                        xi18nc("@info:credit", "Developer"),
                        "mart@kde.org");

    aboutData.addAuthor(xi18nc("@info:credit", "Nicolas Fella"),
                        xi18nc("@info:credit", "Developer"),
                        "nicolas.fella@gmx.de");

    aboutData.addAuthor(xi18nc("@info:credit", "Carl Schwan"),
                        xi18nc("@info:credit", "Developer"),
                        "carl@carlschwan.eu");

    KAboutData::setApplicationData(aboutData);

    QApplication app(argc, argv);
    app.setAttribute(Qt::AA_UseHighDpiPixmaps, true);
    app.setApplicationDisplayName("Photos");
    app.setOrganizationDomain("kde.org");
    KDBusService* service = new KDBusService(KDBusService::Unique | KDBusService::Replace,&app);

    QCommandLineParser parser;
    parser.addOption(QCommandLineOption("reset", i18n("Reset the database")));
    parser.addPositionalArgument("image", i18n("path of image you want to open"));
    parser.addHelpOption();
    parser.addVersionOption();

    aboutData.setupCommandLine(&parser);
    parser.process(app);
    aboutData.processCommandLine(&parser);

    QApplication::setApplicationName(aboutData.componentName());
    QApplication::setApplicationDisplayName(aboutData.displayName());
    QApplication::setOrganizationDomain(aboutData.organizationDomain());
    QApplication::setApplicationVersion(aboutData.version());
    QApplication::setWindowIcon(QIcon::fromTheme(QStringLiteral("jinggallery")));

    QString checkPaths;
    QString CommandLinePath;


    if (parser.positionalArguments().size() > 1) {
        parser.showHelp(1);
    } else if (parser.positionalArguments().size() == 1) {
        QString pa = parser.positionalArguments().first();
        QUrl comlinePath = QUrl::fromUserInput(pa,QDir::currentPath(),QUrl::AssumeLocalFile);

        QFileInfo comLineFile(comlinePath.path());
        checkPaths = comLineFile.path();
        MediaStorage::DATA_TABLE_NAME = "commandline_files";
        CommandLinePath = comlinePath.path();
    } else {
        MediaStorage::DATA_TABLE_NAME = "files";
        QStringList locations = QStandardPaths::standardLocations(QStandardPaths::HomeLocation);
        Q_ASSERT(locations.size() >= 1);
        checkPaths = locations.first();
    }

    if (parser.isSet("reset")) {
        MediaStorage::reset();
    }

    QThread trackerThread;
#ifdef Q_OS_ANDROID
    QtAndroid::requestPermissionsSync({"android.permission.WRITE_EXTERNAL_STORAGE"});
#endif

    qRegisterMetaType<Types::MimeType>("Types::MimeType");
    FileSystemTracker tracker;
    tracker.setFolder(checkPaths);
    tracker.moveToThread(&trackerThread);

    JingGallery::Processor processor;
    QObject::connect(&tracker, &FileSystemTracker::mediaAdded, &processor, &JingGallery::Processor::addFile);
    QObject::connect(&tracker, &FileSystemTracker::mediaRemoved, &processor, &JingGallery::Processor::removeFile);
    QObject::connect(&tracker, &FileSystemTracker::initialScanComplete, &processor, &JingGallery::Processor::initialScanCompleted);

    QObject::connect(&trackerThread, &QThread::started, &tracker, &FileSystemTracker::setupDb);

    trackerThread.start();
    tracker.setSubFolder(tracker.folder());

    JingGalleryConfig config;
    QObject::connect(&config, &JingGalleryConfig::IconSizeChanged, &config, &JingGalleryConfig::save);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));

    engine.rootContext()->setContextProperty("jingGalleryProcessor", &processor);
    engine.rootContext()->setContextProperty("jingGalleryConfig", &config);
    engine.rootContext()->setContextProperty(QStringLiteral("jinggalleryAboutData"), QVariant::fromValue(aboutData));

    engine.rootContext()->setContextProperty("CommandLineInto", CommandLinePath);
    engine.rootContext()->setContextProperty("MainStartTime",startTime);

    qmlRegisterType<ResizeHandle>("org.kde.jinggallery.private", 1, 0, "ResizeHandle");
    qmlRegisterType<ResizeRectangle>("org.kde.jinggallery.private", 1, 0, "ResizeRectangle");

    ListImageProvider *lp = new ListImageProvider(QQmlImageProviderBase::Pixmap);
    engine.addImageProvider(QLatin1String("imageProvider"), lp);

    QString path;
    // we want different main files on desktop or mobile
    // very small difference as they as they are subclasses of the same thing
    if (qEnvironmentVariableIsSet("QT_QUICK_CONTROLS_MOBILE") && (QString::fromLatin1(qgetenv("QT_QUICK_CONTROLS_MOBILE")) == QStringLiteral("1") || QString::fromLatin1(qgetenv("QT_QUICK_CONTROLS_MOBILE")) == QStringLiteral("true"))) {
        engine.load(QUrl(QStringLiteral("qrc:/qml/mobileMain.qml")));
    } else {
        engine.load(QUrl(QStringLiteral("qrc:/qml/desktopMain.qml")));
    }
    qint64 endTime = QDateTime::currentMSecsSinceEpoch();
    int rt = app.exec();
    trackerThread.quit();
    return rt;
}
