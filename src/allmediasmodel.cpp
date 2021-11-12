/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) Zhang He Gang <zhanghegang@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "allmediasmodel.h"
#include "mediastorage.h"

AllMediasModel::AllMediasModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_medias = MediaStorage::instance()->allMedias();
    connect(MediaStorage::instance(), SIGNAL(storageModified()), this, SLOT(slotPopulate()));
}

void AllMediasModel::slotPopulate()
{
    beginResetModel();
    m_medias = MediaStorage::instance()->allMedias();
    endResetModel();
}

QHash<int, QByteArray> AllMediasModel::roleNames() const
{
    auto hash = QAbstractItemModel::roleNames();
    hash.insert(FilePathRole, "filePath");
    hash.insert(FilePathRole, "modelData");

    return hash;
}

QVariant AllMediasModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }

    QString filePath = m_medias.at(index.row()).path;

    switch (role) {
    case Qt::DisplayRole: {
        QString fileName = filePath.mid(filePath.lastIndexOf('/') + 1);
        return fileName;
    }

    case FilePathRole:
        return filePath;
    }

    return QVariant();
}

int AllMediasModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_medias.size();
}
