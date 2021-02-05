/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *                             2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "medialistmodel.h"
#include "mediastorage.h"
#include "roles.h"
#include <QDebug>
#include <QMimeDatabase>
#include <QDir>
#include <QStandardPaths>

MediaListModel::MediaListModel(QObject *parent)
    : QAbstractListModel(parent)
{
    connect(this, &MediaListModel::locationGroupChanged, this, &MediaListModel::slotLocationGroupChanged);
    connect(this, &MediaListModel::timeGroupChanged, this, &MediaListModel::slotTimeGroupChanged);
    connect(this, &MediaListModel::mimeTypeChanged, this, &MediaListModel::slotMimeTypeChanged);
    connect(this, &MediaListModel::queryChanged, this, &MediaListModel::slotResetModel);
    connect(MediaStorage::instance(), &MediaStorage::storageModified, this, &MediaListModel::slotResetModel);
}

MediaListModel::~MediaListModel()
{
}

QHash<int, QByteArray> MediaListModel::roleNames() const
{
    QHash<int, QByteArray> hash = QAbstractListModel::roleNames();
    hash.insert(Roles::DateTimeRole, "imageTime");
    hash.insert(Roles::DurationRole, "duration");
    hash.insert(Roles::PreviewUrlRole, "previewurl");
    hash.insert(Roles::MediaUrlRole, "mediaurl");
    hash.insert(Roles::ItemTypeRole, "itemType");
    hash.insert(Roles::MimeTypeRole, "mimeType");
    return hash;
}

QVariant MediaListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }

    int indexValue = index.row();
    switch (role) {
    case Roles::DateTimeRole:
    {
        return m_medias.at(indexValue).dateTime.toString("yyyy.MM.dd hh:mm ap");
    }
    case Qt::DisplayRole:
        // TODO: return the filename component
    {
        QString path = m_medias.at(indexValue).path.mid(7);
        QFileInfo file(path);
        return file.fileName();
    }

    case Roles::MediaUrlRole:
        return m_medias.at(indexValue).path;

    case Roles::PreviewUrlRole: {
        if (m_medias.at(indexValue).mimeType == Types::MimeType::Image)
        {
            return m_medias.at(indexValue).path;
        } else {
            QDir dir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + (m_medias.at(indexValue).path.mid(7)));
            if (dir.exists("preview.jpg")) {
                return QString("file://" + dir.absoluteFilePath("preview.jpg"));
            }
        }
        return QVariant();
    }

    case Roles::DurationRole:
        return m_medias.at(indexValue).duration;

    case Roles::ItemTypeRole:
        return Types::Media;

    case Roles::MimeTypeRole: {
        QMimeDatabase db;
        QMimeType type = db.mimeTypeForFile(m_medias.at(indexValue).path);
        return type.name();
    }
    }

    return QVariant();
}

int MediaListModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_medias.size();
}

void MediaListModel::slotLocationGroupChanged()
{
    if (m_locationGroup != -1) {
        m_locations = MediaStorage::instance()->locations(static_cast<Types::LocationGroup>(m_locationGroup));
        m_queryType = Types::LocationQuery;
    }
}

void MediaListModel::slotMimeTypeChanged()
{
    if (m_mimeType != -1) {
        m_queryType = Types::MimeTypeQuery;
    }
    emit queryChanged();
}

void MediaListModel::slotTimeGroupChanged()
{
    if (m_timeGroup != -1) {
        m_times = MediaStorage::instance()->timeTypes(static_cast<Types::TimeGroup>(m_timeGroup));
        m_queryType = Types::TimeQuery;
    }
}

void MediaListModel::slotResetModel()
{
    beginResetModel();
    if (m_queryType == Types::LocationQuery) {
        m_medias = MediaStorage::instance()->mediasForLocation(m_query, static_cast<Types::LocationGroup>(m_locationGroup));
    } else if (m_queryType == Types::TimeQuery) {
        m_medias = MediaStorage::instance()->mediasForTime(m_query, static_cast<Types::TimeGroup>(m_timeGroup));
    } else if (m_queryType == Types::MimeTypeQuery) {
        m_medias = MediaStorage::instance()->mediasForMimeType(static_cast<Types::MimeType>(m_mimeType));
    }
    endResetModel();
}

Types::MimeType MediaListModel::mimeType() const
{
    return m_mimeType;
}

void MediaListModel::setMimeType(const Types::MimeType &mimeType)
{
    m_queryType = Types::MimeTypeQuery;
    m_mimeType = mimeType;
    emit mimeTypeChanged();
}

Types::LocationGroup MediaListModel::locationGroup() const
{
    return m_locationGroup;
}

void MediaListModel::setLocationGroup(const Types::LocationGroup &group)
{
    m_locationGroup = group;
    emit locationGroupChanged();
}

Types::TimeGroup MediaListModel::timeGroup() const
{
    return m_timeGroup;
}

void MediaListModel::setTimeGroup(const Types::TimeGroup &group)
{
    m_timeGroup = group;
    emit timeGroupChanged();
}

Types::QueryType MediaListModel::queryType() const
{
    return m_queryType;
}

void MediaListModel::setQueryType(const Types::QueryType &type)
{
    m_queryType = type;
}

QByteArray MediaListModel::query() const
{
    return m_query;
}
void MediaListModel::setQuery(const QByteArray &statement)
{
    m_query = statement;
    emit queryChanged();
}

QByteArray MediaListModel::queryForIndex(const int &index)
{
    if (m_queryType == Types::LocationQuery) {
        return m_locations.at(index).first;
    } else if (m_queryType == Types::TimeQuery) {
        return m_times.at(index).first;
    }
    return QByteArray();
}

#include "moc_medialistmodel.cpp"
