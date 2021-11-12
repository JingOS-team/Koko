/*
 * Copyright (C) 2014  Vishesh Handa <vhanda@kde.org>
 *               2021 Zhang He Gang <zhanghegang@jingos.com>
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

#ifndef MEDIASTORAGE_H
#define MEDIASTORAGE_H

#include <QDataStream>
#include <QDateTime>
#include <QObject>
#include <QMutex>
#include <QMutexLocker>
#include <kdirmodel.h>
#include <kimagecache.h>
#include <QStandardPaths>

#include "jinggallery_export.h"
#include "types.h"
#include "committimer.h"

#define TABLE_COMMANDLINE_MODE "commandline_files"
#define TABLE_NORMAL_MODE "files"

typedef struct MediaInfo {
    QString path;
    Types::MimeType mimeType;
    int width;
    int height;
    int duration;
    QDateTime dateTime;
    bool isChecked;
    int rotation;
} MediaInfo;

class JINGGALLERY_EXPORT MediaStorage : public QObject
{
    Q_OBJECT
public:
    MediaStorage(QObject *parent = 0);
    virtual ~MediaStorage();

    Q_INVOKABLE void addMedia(const MediaInfo &ii);
    Q_INVOKABLE void updateMedia(const MediaInfo &ii);
    void addImage(const QString &filePath);

    void removeMedia(const QList<QString> &filePaths);
    void removeAllMedia();
    void commit();

    static MediaStorage *instance();

    QList<QPair<QByteArray, QString>> locations(Types::LocationGroup loca);
    QList<MediaInfo> mediasForLocation(const QByteArray &name, Types::LocationGroup loc);
    QString mediaForLocation(const QByteArray &name, Types::LocationGroup loc);

    QList<QPair<QByteArray, QString>> timeTypes(Types::TimeGroup group);
    QList<MediaInfo> mediasForTime(const QByteArray &name, Types::TimeGroup group);
    QString mediaForTime(const QByteArray &name, Types::TimeGroup group);

    QDate dateForKey(const QByteArray &key, Types::TimeGroup group);

    QList<MediaInfo> mediasForMimeType(Types::MimeType mimeType);
    /**
     * Fetch all the medias ordered by descending date time.
     */
    QList<MediaInfo> allMedias(int size = -1, int offset = 0);

    Q_INVOKABLE bool isExistData(const QString &filePath);
    int getVideoAngle(const QString &filePath);
    void emitModelRefresh();

    static void reset();
    static QString DATA_TABLE_NAME;
public Q_SLOTS:
    void getAllMedias();
protected Q_SLOTS:
    void gotPreviewed(const KFileItem &item, const QPixmap &preview);
    void process();

signals:
    void storageModified();
    void requestAllMedias();
    void getAllMediasFinish(QHash<QString,MediaInfo> allMedias);

public:
    KImageCache *m_imageCache;
    QString m_filePath;
    QString m_thumbFilePath = QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation) + "/video_thumb";

private:
    mutable QMutex m_mutex;
    int loadVideoSize = 0;
    QTimer *m_videoChangedTimer;
    QTimer *m_refreshChangedTimer;
};

Q_DECLARE_METATYPE(MediaInfo);

#endif // MediaStorage_H
