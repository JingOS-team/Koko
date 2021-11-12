/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) Zhang He Gang <zhanghegang@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef KOKO_ALLMEDIASMODEL_H
#define KOKO_ALLMEDIASMODEL_H
#include <QAbstractListModel>
#include "mediastorage.h"

class AllMediasModel : public QAbstractListModel
{
    Q_OBJECT
public:
    explicit AllMediasModel(QObject *parent = 0);

    enum Roles { FilePathRole = Qt::UserRole + 1 };

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

private Q_SLOTS:
    void slotPopulate();

private:
    QList<MediaInfo> m_medias;
};

#endif
