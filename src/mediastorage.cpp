/*
 * Copyright (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * Copyright (C) 2014  Vishesh Handa <vhanda@kde.org>
 *               Zhang He Gang <zhanghegang@jingos.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#include <QDataStream>
#include <QDebug>
#include <QProcess>
#include <QDir>
#include <QUrl>
#include <QSize>
#include <QPixmap>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QMimeDatabase>
#include <QTextCodec>
#define UNICODE
#include <MediaInfo/MediaInfo.h>

#include <kio/copyjob.h>
#include <kio/previewjob.h>
#include "exiv2extractor.h"
#include "mediastorage.h"


QString MediaStorage::DATA_TABLE_NAME = "files";

MediaStorage::MediaStorage(QObject *parent)
    : QObject(parent)
{
    qWarning() << "init media storage";
    if(!m_videoChangedTimer){
        m_videoChangedTimer = new QTimer(this);
        m_videoChangedTimer->setSingleShot(true);
        connect(m_videoChangedTimer, &QTimer::timeout, this, [this](){
            if(loadVideoSize <= 0){
                emitModelRefresh();
            }
        });
    }

    if(!m_refreshChangedTimer){
        m_refreshChangedTimer = new QTimer(this);
        m_refreshChangedTimer->setSingleShot(true);
        connect(m_refreshChangedTimer, &QTimer::timeout, this, [this](){
            emit storageModified();
            getAllMedias();
        });
    }
    connect(this, &MediaStorage::requestAllMedias, this, &MediaStorage::getAllMedias,Qt::ConnectionType::QueuedConnection);

    m_imageCache = new KImageCache(QStringLiteral("org.kde.jingallery"), 256*1024*1024);

    QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/jinggallery";
    QDir().mkpath(dir);

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
    db.setDatabaseName(dir + "/mediaData.sqlite3");

    if (!db.open()) {
        qWarning() << "Failed to open db" << db.lastError().text();
        return;
    }
    if (DATA_TABLE_NAME == TABLE_NORMAL_MODE) {
        if (db.tables().contains(DATA_TABLE_NAME)) {
            db.transaction();
            return;
        }
    }

    QSqlQuery query(db);
    if (DATA_TABLE_NAME == TABLE_COMMANDLINE_MODE) {
        if (db.tables().contains(DATA_TABLE_NAME)) {
            query.exec("DROP TABLE "+DATA_TABLE_NAME);
            db.transaction();
        }
    }
    query.exec(
        "CREATE TABLE locations (id INTEGER PRIMARY KEY, country TEXT, state TEXT, city TEXT"
        "                        , UNIQUE(country, state, city) ON CONFLICT REPLACE"
        ")");
    query.exec(
        "CREATE TABLE "+DATA_TABLE_NAME+" (url TEXT NOT NULL UNIQUE PRIMARY KEY,"
        "                    type INTEGER DEFAULT 0,"
        "                    duration INTEGER DEFAULT -1,"
        "                    location INTEGER,"
        "                    dateTime datetime NOT NULL,"
        "                    FOREIGN KEY(location) REFERENCES locations(id)"
        "                    )");

    db.transaction();

}

MediaStorage::~MediaStorage()
{
    QString name;
    {
        QSqlDatabase db = QSqlDatabase::database();
        db.commit();
        name = db.connectionName();
    }
    QSqlDatabase::removeDatabase(name);
    delete m_imageCache;
}

MediaStorage *MediaStorage::instance()
{
    static MediaStorage storage;
    return &storage;
}

void MediaStorage::addMedia(const MediaInfo &ii)
{
    QMutexLocker lock(&m_mutex);
    QSqlQuery query;
    query.prepare("INSERT INTO "+DATA_TABLE_NAME+"(url, type, duration, dateTime) VALUES(?, ?, ?, ?)");
    query.addBindValue(ii.path);
    query.addBindValue(ii.mimeType);
    query.addBindValue(ii.duration);
    query.addBindValue(ii.dateTime.toString(Qt::ISODate));
    if (!query.exec()) {
        // qDebug() << "FILE INSERT" << query.lastError();
        if (ii.mimeType == 1) {
            QSqlQuery updateQuery;
            updateQuery.prepare("UPDATE "+DATA_TABLE_NAME+" SET url=?, type=?, duration=?, dateTime=? WHERE url = ?");
            updateQuery.addBindValue(ii.path);
            updateQuery.addBindValue(ii.mimeType);
            updateQuery.addBindValue(ii.duration);
            updateQuery.addBindValue(ii.dateTime.toString(Qt::ISODate));
            updateQuery.addBindValue(ii.path);
            if (!updateQuery.exec()) {
                qWarning() << "FILE UPDATE" << query.lastError();
            }
        }
    }

    if (ii.mimeType == Types::MimeType::Video) {
        QDir dir(m_thumbFilePath + ii.path);
        if (!dir.exists("preview.jpg"))
        {
            dir.mkpath(dir.absolutePath());
            QStringList plugins;
            plugins << KIO::PreviewJob::availablePlugins();
            KFileItemList list;
            KFileItem item = KFileItem(QUrl("file://"+ii.path),  QString(), ii.rotation);
            list.append(item);

            KIO::PreviewJob *job = KIO::filePreview(list, QSize(ii.width, ii.height), &plugins);
            job->setIgnoreMaximumSize(true);
            job->setScaleType(KIO::PreviewJob::ScaleType::Unscaled);
            connect(job, &KIO::PreviewJob::gotPreview, this, &MediaStorage::gotPreviewed);
            loadVideoSize ++;
        }
    }
}

void MediaStorage::updateMedia(const MediaInfo &ii)
{
    QMutexLocker lock(&m_mutex);
    QSqlQuery query;
    query.prepare("UPDATE "+DATA_TABLE_NAME+" SET url=?, type=?, duration=?, dateTime=? WHERE url = ?");
    query.addBindValue(ii.path);
    query.addBindValue(ii.mimeType);
    query.addBindValue(ii.duration);
    query.addBindValue(ii.dateTime.toString(Qt::ISODate));
    query.addBindValue(ii.path);

    if (!query.exec()) {
        qWarning() << "FILE UPDATE" << query.lastError();
    }
}

int MediaStorage::getVideoAngle(const QString &filePath)
{
    int angleValue = 0;
    MediaInfoLib::MediaInfo MI;
    if (MI.Open(filePath.toStdWString())) {
        QString rotationStr = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_Video, 0, __T("Rotation")));
        angleValue = rotationStr.toDouble();
    }
    return angleValue;
}
void MediaStorage::process() {
    MediaInfo ii;
    ii.path = m_filePath;
    ii.mimeType = Types::MimeType::Image;

    if (ii.mimeType == Types::MimeType::Image) {
        Exiv2Extractor extractor;
        extractor.extract(m_filePath);
        if (extractor.error()) {
            return;
        }

        ii.dateTime = extractor.dateTime();
        if (ii.dateTime.isNull()) {
            ii.dateTime = QFileInfo(m_filePath).birthTime();
        }
        ii.duration = -1;
    } else {
        // Baloo::File file(m_path);
        MediaInfoLib::MediaInfo MI;
        if (MI.Open(m_filePath.toStdWString())) {
            ii.duration = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_Video, 0, __T("Duration"), MediaInfoLib::Info_Text, MediaInfoLib::Info_Name)).toInt() / 1000;
            ii.width = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_Video, 0, __T("Width"), MediaInfoLib::Info_Text, MediaInfoLib::Info_Name)).toInt();
            ii.width = ii.width > 0 ? ii.width : 800;
            ii.height = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_Video, 0, __T("Height"), MediaInfoLib::Info_Text, MediaInfoLib::Info_Name)).toInt();
            ii.height = ii.height > 0 ? ii.height : 600;
        } else {
            ii.duration = 0;
            ii.width = 800;
            ii.height = 600;
        }

        MI.Close();
        ii.dateTime = QFileInfo(m_filePath).birthTime();
    }
    addMedia(ii);
    emit storageModified();
}

void MediaStorage::addImage(const QString &filePath)
{
    m_filePath = filePath;
    QTimer::singleShot(0, this, SLOT(process()));
}

void MediaStorage::gotPreviewed(const KFileItem &item, const QPixmap &preview)
{
    QString itemMime = item.url().toString();

    QDir dir(m_thumbFilePath + item.localPath());
    dir.mkpath(dir.absolutePath());
    if(item.mode() > 0){
        QTransform tranform;
        tranform.rotate(item.mode());
        QPixmap transPix = QPixmap(preview.transformed(tranform,Qt::SmoothTransformation));
        transPix.save(dir.absolutePath()+ "/preview.jpg", "JPG");

    } else {
        preview.save(dir.absolutePath()+ "/preview.jpg", "JPG");
    }
    loadVideoSize --;
    if(!m_videoChangedTimer){
        m_videoChangedTimer = new QTimer(this);
    }
    if(m_videoChangedTimer->isActive()){
        m_videoChangedTimer->stop();
    }
    m_videoChangedTimer->start(1000);
}

void MediaStorage::removeMedia(const QList<QString> &filePaths)
{
    if (filePaths.size() <= 0) {
        return;
    }
    QMutexLocker lock(&m_mutex);

    QSqlQuery query;
    QString sqlString = "DELETE FROM "+DATA_TABLE_NAME+" WHERE";
    for (int i = 0; i< filePaths.size() ; i++) {
        if (i == 0) {
           sqlString.append(" URL = ?");
        } else {
           sqlString.append(" OR URL = ?");
        }
    }
    query.prepare(sqlString);
    foreach (QString filePath, filePaths) {
        query.addBindValue(filePath);
    }

    if (!query.exec()) {
        qWarning() << "FILE del" << query.lastError();
    }

    foreach (QString filePath, filePaths) {
        QMimeDatabase mimeDb;
        QString mimetype = mimeDb.mimeTypeForFile(filePath, QMimeDatabase::MatchExtension).name();

        if (mimetype.startsWith("video/"))
        {
            QDir dir(m_thumbFilePath + filePath + "/preview.jpg");
            if (dir.exists()) {
                dir.removeRecursively();
            }
        }
    }

}

void MediaStorage::removeAllMedia()
{
    qWarning() << Q_FUNC_INFO;

    QSqlQuery query;
    query.prepare("DELETE FROM "+DATA_TABLE_NAME);
    if (!query.exec()) {
        qWarning() << "FILE del" << query.lastError();
        return;
    }
    emitModelRefresh();
}

void MediaStorage::commit()
{
    {
        QMutexLocker lock(&m_mutex);
        QSqlDatabase db = QSqlDatabase::database();
        db.commit();
        db.transaction();
    }
   emitModelRefresh();
}

void MediaStorage::emitModelRefresh()
{
    if(!m_refreshChangedTimer){
        m_refreshChangedTimer = new QTimer(this);
        m_refreshChangedTimer->setSingleShot(true);
        connect(m_refreshChangedTimer, &QTimer::timeout, this, [this](){
            emit storageModified();
            getAllMedias();
        });
    }

    if(!m_refreshChangedTimer->isActive()){

        m_refreshChangedTimer->start(3000);
    }
   
}

QList<QPair<QByteArray, QString>> MediaStorage::locations(Types::LocationGroup loca)
{
    QMutexLocker lock(&m_mutex);
    QList<QPair<QByteArray, QString>> list;

    if (loca == Types::LocationGroup::Country) {
        QSqlQuery query;
        query.prepare("SELECT DISTINCT country from locations");

        if (!query.exec()) {
            qWarning() << loca << query.lastError();
            return list;
        }

        while (query.next()) {
            QString val = query.value(0).toString();
            list << qMakePair(val.toUtf8(), val);
        }
        return list;
    } else if (loca == Types::LocationGroup::State) {
        QSqlQuery query;
        query.prepare("SELECT DISTINCT country, state from locations");

        if (!query.exec()) {
            qWarning() << loca << query.lastError();
            return list;
        }

        QStringList groups;
        while (query.next()) {
            QString country = query.value(0).toString();
            QString state = query.value(1).toString();
            QString display = state + ", " + country;

            QByteArray key;
            QDataStream stream(&key, QIODevice::WriteOnly);
            stream << country << state;

            list << qMakePair(key, display);
        }
        return list;
    } else if (loca == Types::LocationGroup::City) {
        QSqlQuery query;
        query.prepare("SELECT DISTINCT country, state, city from locations");

        if (!query.exec()) {
            qWarning() << loca << query.lastError();
            return list;
        }

        while (query.next()) {
            QString country = query.value(0).toString();
            QString state = query.value(1).toString();
            QString city = query.value(2).toString();

            QString display;
            if (!city.isEmpty()) {
                display = city + ", " + state + ", " + country;
            } else {
                display = state + ", " + country;
            }

            QByteArray key;
            QDataStream stream(&key, QIODevice::WriteOnly);
            stream << country << state << city;

            list << qMakePair(key, display);
        }
        return list;
    }

    return list;
}

QList<MediaInfo> MediaStorage::mediasForLocation(const QByteArray &name, Types::LocationGroup loc)
{
    QMutexLocker lock(&m_mutex);
    QSqlQuery query;
    if (loc == Types::LocationGroup::Country) {
        query.prepare("SELECT DISTINCT url,type,duration from "+DATA_TABLE_NAME+", locations where country = ? AND "+DATA_TABLE_NAME+".location = locations.id");
        query.addBindValue(QString::fromUtf8(name));
    } else if (loc == Types::LocationGroup::State) {
        QDataStream st(name);

        QString country;
        QString state;
        st >> country >> state;

        query.prepare("SELECT DISTINCT url,type,duration from "+DATA_TABLE_NAME+", locations where country = ? AND state = ? AND "+DATA_TABLE_NAME+".location = locations.id");
        query.addBindValue(country);
        query.addBindValue(state);
    } else if (loc == Types::LocationGroup::City) {
        QDataStream st(name);

        QString country;
        QString state;
        QString city;
        st >> country >> state >> city;

        query.prepare("SELECT DISTINCT url,type,duration from "+DATA_TABLE_NAME+", locations where country = ? AND state = ? AND "+DATA_TABLE_NAME+".location = locations.id");
        query.addBindValue(country);
        query.addBindValue(state);
    }

    QList<MediaInfo> files;
    if (!query.exec()) {
        qWarning() << loc << query.lastError();
        return files;
    }

    while (query.next()) {
        MediaInfo info;
        info.path = QString("file://" + query.value(0).toString());
        info.mimeType = static_cast<Types::MimeType>(query.value(1).toInt());
        info.duration = query.value(2).toInt();
        files << info;
    }
    return files;
}

QString MediaStorage::mediaForLocation(const QByteArray &name, Types::LocationGroup loc)
{
    QMutexLocker lock(&m_mutex);
    QSqlQuery query;
    if (loc == Types::LocationGroup::Country) {
        query.prepare("SELECT DISTINCT url from "+DATA_TABLE_NAME+", locations where country = ? AND "+DATA_TABLE_NAME+".location = locations.id");
        query.addBindValue(QString::fromUtf8(name));
    } else if (loc == Types::LocationGroup::State) {
        QDataStream st(name);

        QString country;
        QString state;
        st >> country >> state;

        query.prepare("SELECT DISTINCT url from "+DATA_TABLE_NAME+", locations where country = ? AND state = ? AND "+DATA_TABLE_NAME+".location = locations.id");
        query.addBindValue(country);
        query.addBindValue(state);
    } else if (loc == Types::LocationGroup::City) {
        QDataStream st(name);

        QString country;
        QString state;
        QString city;
        st >> country >> state >> city;

        query.prepare("SELECT DISTINCT url from "+DATA_TABLE_NAME+", locations where country = ? AND state = ? AND "+DATA_TABLE_NAME+".location = locations.id");
        query.addBindValue(country);
        query.addBindValue(state);
    }

    if (!query.exec()) {
        qWarning() << loc << query.lastError();
        return QString();
    }

    if (query.next()) {
        return QString("file://" + query.value(0).toString());
    }
    return QString();
}


QList<MediaInfo> MediaStorage::mediasForMimeType(Types::MimeType mimeType)
{
    QMutexLocker lock(&m_mutex);

    QList<MediaInfo> files;
    QSqlQuery query;

    if (mimeType == Types::MimeType::All) {
        query.prepare("SELECT DISTINCT url,type,duration,dateTime from "+DATA_TABLE_NAME+" ORDER BY dateTime,url ASC");
    }
    else if (mimeType == Types::MimeType::Video || mimeType == Types::MimeType::Image) {
        int type = mimeType == Types::MimeType::Video ? 1 : 0;
        query.prepare("SELECT DISTINCT url,type,duration,dateTime from "+DATA_TABLE_NAME+" where type = ?   ORDER BY dateTime,url ASC");
        query.addBindValue(type);
    }
    {
        if (!query.exec()) {
            qWarning() << mimeType << query.lastError();
            return files;
        }

        while (query.next()) {
            MediaInfo info;
            info.path = QString("file://" + query.value(0).toString());
            info.mimeType = static_cast<Types::MimeType>(query.value(1).toInt());
            info.duration = query.value(2).toInt();
            info.dateTime = query.value(3).toDateTime();
            files << info;
        }
    }
    return files;
}

QList<QPair<QByteArray, QString>> MediaStorage::timeTypes(Types::TimeGroup group)
{
    QMutexLocker lock(&m_mutex);
    QList<QPair<QByteArray, QString>> list;

    QSqlQuery query;
    if (group == Types::TimeGroup::Year) {
        query.prepare("SELECT DISTINCT strftime('%Y', dateTime) from "+DATA_TABLE_NAME+"");
        if (!query.exec()) {
            qWarning() << group << query.lastError();
            return list;
        }

        while (query.next()) {
            QString val = query.value(0).toString();
            list << qMakePair(val.toUtf8(), val);
        }
        return list;
    } else if (group == Types::TimeGroup::Month) {
        query.prepare("SELECT DISTINCT strftime('%Y', dateTime), strftime('%m', dateTime) from "+DATA_TABLE_NAME+"");
        if (!query.exec()) {
            qWarning() << group << query.lastError();
            return list;
        }

        QStringList groups;
        while (query.next()) {
            QString year = query.value(0).toString();
            QString month = query.value(1).toString();

            QString display = QLocale().monthName(month.toInt(), QLocale::LongFormat) + ", " + year;

            QByteArray key;
            QDataStream stream(&key, QIODevice::WriteOnly);
            stream << year << month;

            list << qMakePair(key, display);
        }
        return list;
    } else if (group == Types::TimeGroup::Week) {
        query.prepare("SELECT DISTINCT strftime('%Y', dateTime), strftime('%m', dateTime), strftime('%W', dateTime) from "+DATA_TABLE_NAME+"");
        if (!query.exec()) {
            qWarning() << group << query.lastError();
            return list;
        }

        while (query.next()) {
            QString year = query.value(0).toString();
            QString month = query.value(1).toString();
            QString week = query.value(2).toString();

            QString display = "Week " + week + ", " + QLocale().monthName(month.toInt(), QLocale::LongFormat) + ", " + year;

            QByteArray key;
            QDataStream stream(&key, QIODevice::WriteOnly);
            stream << year << week;

            list << qMakePair(key, display);
        }
        return list;
    } else if (group == Types::TimeGroup::Day) {
        query.prepare("SELECT DISTINCT date(dateTime) from "+DATA_TABLE_NAME+"");
        if (!query.exec()) {
            qWarning() << group << query.lastError();
            return list;
        }

        while (query.next()) {
            QDate date = query.value(0).toDate();

            QString display = date.toString(Qt::SystemLocaleLongDate);
            QByteArray key = date.toString(Qt::ISODate).toUtf8();

            list << qMakePair(key, display);
        }
        return list;
    }

    Q_ASSERT(0);
    return list;
}

QList<MediaInfo> MediaStorage::mediasForTime(const QByteArray &name, Types::TimeGroup group)
{
    QMutexLocker lock(&m_mutex);
    QSqlQuery query;
    if (group == Types::TimeGroup::Year) {
        query.prepare("SELECT DISTINCT url,type,duration,dateTime from "+DATA_TABLE_NAME+" where strftime('%Y', dateTime) = ?");
        query.addBindValue(QString::fromUtf8(name));
    } else if (group == Types::TimeGroup::Month) {
        QDataStream stream(name);
        QString year;
        QString month;
        stream >> year >> month;

        query.prepare("SELECT DISTINCT url,type,duration,dateTime from "+DATA_TABLE_NAME+" where strftime('%Y', dateTime) = ? AND strftime('%m', dateTime) = ?");
        query.addBindValue(year);
        query.addBindValue(month);
    } else if (group == Types::TimeGroup::Week) {
        QDataStream stream(name);
        QString year;
        QString week;
        stream >> year >> week;

        query.prepare("SELECT DISTINCT url,type,duration,dateTime from "+DATA_TABLE_NAME+" where strftime('%Y', dateTime) = ? AND strftime('%W', dateTime) = ?");
        query.addBindValue(year);
        query.addBindValue(week);
    } else if (group == Types::TimeGroup::Day) {
        QDate date = QDate::fromString(QString::fromUtf8(name), Qt::ISODate);

        query.prepare("SELECT DISTINCT url,type,duration,dateTime from "+DATA_TABLE_NAME+" where date(dateTime) = ?");
        query.addBindValue(date);
    }

    if (!query.exec()) {
        qWarning() << group << query.lastError();
        return QList<MediaInfo>();
    }

    QList<MediaInfo> files;
    while (query.next()) {
        MediaInfo info;
        info.path = QString("file://" + query.value(0).toString());
        info.mimeType = static_cast<Types::MimeType>(query.value(1).toInt());
        info.duration = query.value(2).toInt();
        info.dateTime = query.value(3).toDateTime();
        files << info;
    }

    Q_ASSERT(!files.isEmpty());
    return files;
}

QString MediaStorage::mediaForTime(const QByteArray &name, Types::TimeGroup group)
{
    QMutexLocker lock(&m_mutex);
    Q_ASSERT(!name.isEmpty());

    QSqlQuery query;
    if (group == Types::TimeGroup::Year) {
        query.prepare("SELECT DISTINCT url from "+DATA_TABLE_NAME+" where strftime('%Y', dateTime) = ? LIMIT 1");
        query.addBindValue(QString::fromUtf8(name));
    } else if (group == Types::TimeGroup::Month) {
        QDataStream stream(name);
        QString year;
        QString month;
        stream >> year >> month;

        query.prepare("SELECT DISTINCT url from "+DATA_TABLE_NAME+" where strftime('%Y', dateTime) = ? AND strftime('%m', dateTime) = ? LIMIT 1");
        query.addBindValue(year);
        query.addBindValue(month);
    } else if (group == Types::TimeGroup::Week) {
        QDataStream stream(name);
        QString year;
        QString week;
        stream >> year >> week;

        query.prepare("SELECT DISTINCT url from "+DATA_TABLE_NAME+" where strftime('%Y', dateTime) = ? AND strftime('%W', dateTime) = ? LIMIT 1");
        query.addBindValue(year);
        query.addBindValue(week);
    } else if (group == Types::TimeGroup::Day) {
        QDate date = QDate::fromString(QString::fromUtf8(name), Qt::ISODate);

        query.prepare("SELECT DISTINCT url from "+DATA_TABLE_NAME+" where date(dateTime) = ? LIMIT 1");
        query.addBindValue(date);
    }

    if (!query.exec()) {
        qWarning() << group << query.lastError();
        return QString();
    }

    if (query.next()) {
        return QString("file://" + query.value(0).toString());
    }

    Q_ASSERT(0);
    return QString();
}

QDate MediaStorage::dateForKey(const QByteArray &key, Types::TimeGroup group)
{
    if (group == Types::TimeGroup::Year) {
        return QDate(key.toInt(), 1, 1);
    } else if (group == Types::TimeGroup::Month) {
        QDataStream stream(key);
        QString year;
        QString month;
        stream >> year >> month;

        return QDate(year.toInt(), month.toInt(), 1);
    } else if (group == Types::TimeGroup::Week) {
        QDataStream stream(key);
        QString year;
        QString week;
        stream >> year >> week;

        int month = week.toInt() / 4;
        int day = week.toInt() % 4;
        return QDate(year.toInt(), month, day);
    } else if (group == Types::TimeGroup::Day) {
        return QDate::fromString(QString::fromUtf8(key), Qt::ISODate);
    }

    Q_ASSERT(0);
    return QDate();
}

void MediaStorage::reset()
{
    QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/jinggallery";
    QDir(dir).removeRecursively();
}

bool MediaStorage::isExistData(const QString &filePath)
{
    QMutexLocker lock(&m_mutex);

    bool isOldData = false;

    QSqlQuery query(QSqlDatabase::database());
    query.prepare("SELECT duration from "+DATA_TABLE_NAME+" where url = ?");
    query.addBindValue(filePath);
    if (query.exec()) {
        int duration = query.value(0).toInt();
        if(duration == 0){
            isOldData = false;
        } else {
            isOldData = true;
        }
    } else {
        qWarning() <<"video Query error:" << query.lastError();
        isOldData = true;
    }
    return isOldData;
}

QList<MediaInfo> MediaStorage::allMedias(int size, int offset)
{
    QMutexLocker lock(&m_mutex);

    QSqlQuery query;
    if (size == -1) {
        query.prepare("SELECT DISTINCT url,type,duration from "+DATA_TABLE_NAME+" ORDER BY dateTime DESC");
    } else {
        query.prepare("SELECT DISTINCT url,type,duration from "+DATA_TABLE_NAME+" ORDER BY dateTime DESC LIMIT ? OFFSET ?");
        query.addBindValue(size);
        query.addBindValue(offset);
    }

    QList<MediaInfo> files;
    if (!query.exec()) {
        qWarning() << query.lastError();
        return files;
    }

    while (query.next()) {
        MediaInfo info;
        info.path = QString("file://" + query.value(0).toString());
        info.mimeType = static_cast<Types::MimeType>(query.value(1).toInt());
        info.duration = query.value(2).toInt();
        files << info;
    }

    return files;
}

void MediaStorage::getAllMedias()
{
    QMutexLocker lock(&m_mutex);

    QSqlQuery query;
    query.prepare("SELECT DISTINCT url,type,duration from "+DATA_TABLE_NAME+" ORDER BY dateTime DESC");

    QHash<QString,MediaInfo> files;
    if (!query.exec()) {
        qWarning() << query.lastError();
        return ;
    }

    while (query.next()) {
        MediaInfo info;
        info.path = QString(query.value(0).toString());
        info.mimeType = static_cast<Types::MimeType>(query.value(1).toInt());
        info.duration = query.value(2).toInt();
        files.insert(info.path,info);
    }
    emit getAllMediasFinish(files);
}
