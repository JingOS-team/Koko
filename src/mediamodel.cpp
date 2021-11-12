/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2017 by Marco Martin <mart@kde.org>
 * SPDX-FileCopyrightText: (C) Zhang He Gang <zhanghegang@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "mediamodel.h"
#include "roles.h"
#include "types.h"
#include <QDebug>
#include <QDir>
#include <QImage>
#include <QMimeDatabase>
#include <QPixmap>
#include <QProcess>
#include <QStandardPaths>
#include <KIO/EmptyTrashJob>
#include <kdirlister.h>

MediaModel::MediaModel(QObject *parent)
    : KDirModel(parent)
{
    QMimeDatabase db;
    QList<QMimeType> mimeList = db.allMimeTypes();
    m_mimeTypes << "inode/directory";
    foreach (const QMimeType &mime, mimeList) {
        if (mime.name().startsWith(QStringLiteral("image/")) ||
                mime.name().startsWith(QStringLiteral("video/"))) {
            m_mimeTypes << mime.name();
        }
    }

    dirLister()->setMimeFilter(m_mimeTypes);
    connect(this, &QAbstractItemModel::rowsInserted, this, &MediaModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &MediaModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &MediaModel::countChanged);
}

MediaModel::~MediaModel()
{
}

QHash<int, QByteArray> MediaModel::roleNames() const
{
    return {{Qt::DisplayRole, "display"}, {Qt::DecorationRole, "decoration"}, {Roles::MediaUrlRole, "mediaurl"}, {Roles::MimeTypeRole, "mimeType"}, {Roles::ItemTypeRole, "itemType"}};
}

QString MediaModel::url() const
{
    return dirLister()->url().toString();
}

void MediaModel::setUrl(QString &url)
{
    url = QUrl(url).path();

    if (url.isEmpty()) {
        // need clearify Location for photo & video
        QStringList locations = QStandardPaths::standardLocations(QStandardPaths::PicturesLocation);
        if ((locations.size() < 1))
            locations = QStandardPaths::standardLocations(QStandardPaths::MoviesLocation);
        Q_ASSERT(locations.size() >= 1);
        url = locations.first().append("/");
    }

    url = QUrl::fromLocalFile(url).toString();
    Q_ASSERT(QUrl(url).isLocalFile());

    if (dirLister()->url().path() == QUrl(url).path()) {
        dirLister()->updateDirectory(QUrl(url));
        return;
    }

    beginResetModel();
    dirLister()->openUrl(QUrl(url));
    endResetModel();
    emit urlChanged();
}

int MediaModel::indexForUrl(const QString &url) const
{
    QModelIndex index = KDirModel::indexForUrl(QUrl(url));
    return index.row();
}

QVariantMap MediaModel::get(int i) const
{
    QModelIndex modelIndex = index(i, 0);

    KFileItem item = itemForIndex(modelIndex);
    QString url = item.url().toString();
    QString mimeType = item.mimetype();

    QVariantMap ret;
    ret.insert(QStringLiteral("url"), QVariant(url));
    ret.insert(QStringLiteral("mimeType"), QVariant(mimeType));

    return ret;
}

void MediaModel::emptyTrash()
{
    KIO::emptyTrash();
}

QVariant MediaModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }

    switch (role) {
    case Roles::MediaUrlRole: {
        KFileItem item = itemForIndex(index);
        return item.url().toString();
    }
    case Roles::MimeTypeRole: {
        KFileItem item = itemForIndex(index);
        return item.mimetype();
    }

    case Roles::ItemTypeRole: {
        KFileItem item = itemForIndex(index);
        if (item.isDir()) {
            return Types::Folder;
        } else {
            return Types::Media;
        }
    }

    default:
        return KDirModel::data(index, role);
    }
}

#include "moc_mediamodel.cpp"
