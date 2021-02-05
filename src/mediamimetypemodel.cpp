/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include <QDebug>
#include "mediamimetypemodel.h"
#include "mediastorage.h"
#include "roles.h"
#include <kio/copyjob.h>
#include <kio/jobuidelegate.h>
#include <QMimeDatabase>
#include <QDir>
#include <QStandardPaths>
#include <QFile>
#define WEEKDAY_SEC  24 * 3600 * 7
#define DAY_SEC  24 * 3600

MediaMimeTypeModel::MediaMimeTypeModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_mimetype(Types::MimeType::All)
{
    connect(MediaStorage::instance(), SIGNAL(storageModified()), this, SLOT(slotPopulate()));
    connect(this, &QAbstractItemModel::rowsInserted, this, &MediaMimeTypeModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &MediaMimeTypeModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &MediaMimeTypeModel::countChanged);
}

void MediaMimeTypeModel::thumbnailChanged(QString path)
{
    for (int i = 0; i < m_medias.size(); i++)
    {
        if (path == m_medias[i].path)
        {
            QModelIndex index = QAbstractListModel::index(i, 0);
            emit dataChanged(index, index);
            return;
        }
    }
}

int MediaMimeTypeModel::findIndex(QString path)
{
    if (!path.startsWith("file://")) {
        path  = "file://"+path;
    }
    for (int i = 0; i < m_medias.size(); i++)
    {
        if (path == m_medias[i].path)
        {
            return i;
        }
    }
    return -1;
}

void MediaMimeTypeModel::deleteItemByIndex(int index)
{
    MediaInfo mi = m_medias.at(index);
    if (mi.path.startsWith("file://"))
        mi.path = mi.path.mid(7);
    isDeleteOne = true;
    QFile::moveToTrash(mi.path);
    m_medias.removeAt(index);
    emit countChanged();
}

void MediaMimeTypeModel::slotPopulate()
{
    if (!isDeleteOne) {
        beginResetModel();
        m_medias = MediaStorage::instance()->mediasForMimeType(m_mimetype);
        endResetModel();
    }
    isDeleteOne = false;
}

QHash<int, QByteArray> MediaMimeTypeModel::roleNames() const
{
    auto hash = QAbstractItemModel::roleNames();
    hash.insert(Roles::DurationRole, "duration");
    // the url role returns the url of the cover image of the collection
    hash.insert(Roles::MediaUrlRole, "mediaurl");
    hash.insert(Roles::ItemTypeRole, "itemType");
    hash.insert(Qt::DisplayRole, "display");
    hash.insert(Roles::MimeTypeRole, "mimeType");
    hash.insert(Roles::DateTimeRole, "imageTime");
    hash.insert(Roles::PreviewUrlRole, "previewurl");
    return hash;
}

QVariant MediaMimeTypeModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    int indexValue = index.row();
    switch (role) {
    case Qt::DisplayRole: {
        QString path = m_medias.at(indexValue).path.mid(7);
        QFileInfo file(path);
        return file.fileName();
    }

    case Roles::MediaUrlRole: {
        return m_medias.at(indexValue).path;
    }

    case Roles::PreviewUrlRole: {
        if (m_medias.at(indexValue).mimeType == Types::MimeType::Image)
        {
            return m_medias.at(indexValue).path;
        } else {
            QDir dir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + (m_medias.at(indexValue).path.mid(7)));
            if (dir.exists("preview.jpg")) {
                return QString("file://" + dir.absoluteFilePath("preview.jpg"));
            } else {
                return m_medias.at(indexValue).path;
            }
        }
        return QVariant();
    }

    case Roles::DurationRole:
        return m_medias.at(indexValue).duration;
    case Roles::DateTimeRole:
    {
        QString dateString;
        QDateTime currentDate =  QDateTime::currentDateTime();
        QDateTime qdate = m_medias.at(indexValue).dateTime;
        int dayoffset = qdate.daysTo(currentDate);

        if (dayoffset <= 7) {
            if (dayoffset < 1) {
                dateString = qdate.toString("hh:mm AP");
            } else if (dayoffset == 1) {
                dateString = "yestday "+ qdate.toString("hh:mm AP");
            } else {
                //qdate.date().dayOfWeek() +
                dateString =  qdate.toString("dddd hh:mm AP");
            }
        } else {
            int currentYear = currentDate.date().year();
            int dataYear = qdate.date().year();
            if (currentYear == dataYear) {
                dateString = qdate.toString("MM-dd hh:mm AP");
            } else {
                dateString = qdate.toString("yyyy-MM-dd hh:mm AP");

            }

        }
        return dateString;
    }


    case Roles::ItemTypeRole: {
        return Types::Media;
    }
    case Roles::MimeTypeRole: {
        QMimeDatabase db;
        QMimeType type = db.mimeTypeForFile(m_medias.at(indexValue).path);
        return type.name();
    }
    }

    return QVariant();
}

int MediaMimeTypeModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_medias.size();
}

bool MediaMimeTypeModel::removeRows(int row, int count, const QModelIndex &parent)
{
    for (int i = row; i < count+row; i++)
    {
        if (i > 0 && i < m_medias.size())
            deleteItemByIndex(i);
    }
    return true;
}

void MediaMimeTypeModel::setMimeType(Types::MimeType mimeType)
{
    beginResetModel();
    m_mimetype = mimeType;
    m_medias = MediaStorage::instance()->mediasForMimeType(m_mimetype);
    for (int i = 0; i < m_medias.size() ; i++) {
        MediaInfo item = m_medias.at(i);
    }
    endResetModel();

    emit mimeTypeChanged();
}

Types::MimeType MediaMimeTypeModel::mimeType() const
{
    return m_mimetype;
}
