/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *                             2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "filesystemtracker.h"
#include "filesystemmediafetcher.h"
#include "mediastorage.h"

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QDBusConnection>
#include <QDebug>
#include <QDir>
#include <QMimeDatabase>
#include <QStandardPaths>
#include <KDirNotify>
#include <kdirwatch.h>

FileSystemTracker::FileSystemTracker(QObject *parent)
    : QObject(parent)
{
    QObject::connect(KDirWatch::self(), &KDirWatch::dirty, this, &FileSystemTracker::setSubFolder);

    org::kde::KDirNotify *kdirnotify = new org::kde::KDirNotify(QString(), QString(), QDBusConnection::sessionBus(), this);

    connect(kdirnotify, &org::kde::KDirNotify::FilesRemoved, this, [this](const QStringList &files) {
        for (const QString &filePath : files) {
            removeFile(filePath);
        }
    });
    connect(kdirnotify, &org::kde::KDirNotify::FilesAdded, this, &FileSystemTracker::setSubFolder);
    connect(kdirnotify, &org::kde::KDirNotify::FileRenamedWithLocalPath, this, [this](const QString &src, const QString &dst, const QString &) {
        QMimeDatabase mimeDb;
        QString mimetype = mimeDb.mimeTypeForFile(src).name();
        removeFile(src);
        slotNewFiles({dst});
    });

    // Real time updates
    QDBusConnection con = QDBusConnection::sessionBus();
    con.connect(QString(), QLatin1String("/files"), QLatin1String("org.kde"), QLatin1String("changed"), this, SLOT(slotNewFiles(QStringList)));

    connect(this, &FileSystemTracker::subFolderChanged, this, &FileSystemTracker::reindexSubFolder);
}

void FileSystemTracker::setupDb()
{
    static QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/jinggallery/";
    QDir().mkpath(dir);

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), QStringLiteral("fstracker"));
    db.setDatabaseName(dir + "/fstracker.sqlite3");
    if (!db.open()) {
        qWarning() << "Failed to open db" << db.lastError().text();
        return;
    }

    if (MediaStorage::DATA_TABLE_NAME == TABLE_NORMAL_MODE) {
        if (db.tables().contains(MediaStorage::DATA_TABLE_NAME)) {
            return;
        }
    }

    QSqlQuery query(db);
    if (MediaStorage::DATA_TABLE_NAME == TABLE_COMMANDLINE_MODE) {
        if (db.tables().contains(MediaStorage::DATA_TABLE_NAME)) {
            query.exec("DROP TABLE "+MediaStorage::DATA_TABLE_NAME);
            db.transaction();
        }
    }
    bool ret =
        query.exec("CREATE TABLE "+MediaStorage::DATA_TABLE_NAME+"("
                   "id INTEGER PRIMARY KEY, "
                   "url TEXT NOT NULL UNIQUE,"
                   "type INTERGER DEFAULT 0)");
    if (!ret) {
        qWarning() << "Could not create files table" << query.lastError().text();
        return;
    }

    ret = query.exec("CREATE INDEX fileUrl_index ON "+MediaStorage::DATA_TABLE_NAME+" (url)");
    if (!ret) {
        qWarning() << "Could not create tags index" << query.lastError().text();
        return;
    }

    ret = query.exec("CREATE INDEX fileType_index ON "+MediaStorage::DATA_TABLE_NAME+" (type)");
    if (!ret) {
        qWarning() << "Could not create tags index" << query.lastError().text();
        return;
    }

    //
    // WAL Journaling mode has much lower io writes than the traditional journal
    // based indexing.
    //
    ret = query.exec(QLatin1String("PRAGMA journal_mode = WAL"));
    if (!ret) {
        qWarning() << "Could not set WAL journaling mode" << query.lastError().text();
        return;
    }
}

FileSystemTracker::~FileSystemTracker()
{
    QSqlDatabase::removeDatabase(QStringLiteral("fstracker"));
}

void FileSystemTracker::slotMediaResult(const QString &filePath, Types::MimeType fileType)
{

    QSqlQuery query(QSqlDatabase::database("fstracker"));
    query.prepare("SELECT id from " + MediaStorage::DATA_TABLE_NAME + " where url = ?");
    query.addBindValue(filePath);
    if (!query.exec()) {
        qWarning() << query.lastError();
        return;
    }

    if (!query.next()) {
        QSqlQuery query(QSqlDatabase::database("fstracker"));
        query.prepare("INSERT into " + MediaStorage::DATA_TABLE_NAME + "(url, type) VALUES (?,?)");
        query.addBindValue(filePath);
        query.addBindValue(fileType);
        if (!query.exec()) {
            qWarning() << query.lastError();
            return;
        }
        emit mediaAdded(filePath, fileType);
    }
    m_filePaths << filePath;
}

void FileSystemTracker::slotFetchFinished()
{
    QSqlQuery query(QSqlDatabase::database("fstracker"));
    query.prepare("SELECT url from "+MediaStorage::DATA_TABLE_NAME+"");
    if (!query.exec()) {
        qWarning() << query.lastError();
        return;
    }

    while (query.next()) {
        QString filePath = query.value(0).toString();

        if (filePath.contains(m_subFolder) && !m_filePaths.contains(filePath)) {
            removeFile(filePath);
        }
    }

    QSqlDatabase::database("fstracker").commit();
    m_filePaths.clear();
    emit initialScanComplete();
}

void FileSystemTracker::removeFile(const QString &filePath)
{
    QString realPath = filePath;

    if (filePath.startsWith("file://"))
        realPath = filePath.mid(7);

    emit mediaRemoved(realPath);

    QSqlQuery query(QSqlDatabase::database("fstracker"));
    query.prepare("DELETE from "+MediaStorage::DATA_TABLE_NAME+" where url = ?");
    query.addBindValue(realPath);
    if (!query.exec()) {
        qWarning() << query.lastError();
    }
}

void FileSystemTracker::slotNewFiles(const QStringList &files)
{
    if (!m_filePaths.isEmpty()) {
        // A scan is already going on. No point interrupting it.
        return;
    }

    QMimeDatabase db;
    for (const QString &file : files) {
        QMimeType mimetype = db.mimeTypeForFile(file);
        if (mimetype.name().startsWith("image/")) {
            slotMediaResult(file, Types::MimeType::Image);
        } else if (mimetype.name().startsWith("video/")) {
            slotMediaResult(file,Types::MimeType::Video);
        }
    }

    m_filePaths.clear();
}

void FileSystemTracker::setFolder(const QString &folder)
{
    if (m_folder == folder) {
        return;
    }

    KDirWatch::self()->removeDir(m_folder);
    m_folder = folder;
    KDirWatch::self()->addDir(m_folder, KDirWatch::WatchSubDirs);
}

QString FileSystemTracker::folder() const
{
    return m_folder;
}

void FileSystemTracker::setSubFolder(const QString &folder)
{
    if (QFileInfo(folder).isDir()) {
        m_subFolder = folder;
        emit subFolderChanged();
    }
}

void FileSystemTracker::reindexSubFolder()
{
    FileSystemMediaFetcher *fetcher = new FileSystemMediaFetcher(m_subFolder);
    connect(fetcher, &FileSystemMediaFetcher::mediaResult, this, &FileSystemTracker::slotMediaResult, Qt::QueuedConnection);
    connect(fetcher, &FileSystemMediaFetcher::finished, this, [this, fetcher] {
        slotFetchFinished();
        fetcher->deleteLater();
    }, Qt::QueuedConnection);
    fetcher->fetch();
    QSqlDatabase::database("fstracker").transaction();
}
