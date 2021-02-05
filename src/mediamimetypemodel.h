/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef MEDIAMIMETYPEMODEL_H
#define MEDIAMIMETYPEMODEL_H

#include <QAbstractListModel>
#include <QStringList>

#include "types.h"
#include "mediastorage.h"

class MediaMimeTypeModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(Types::MimeType mimeType READ mimeType WRITE setMimeType NOTIFY mimeTypeChanged)

public:
    explicit MediaMimeTypeModel(QObject *parent = 0);

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    Types::MimeType mimeType() const;
    void setMimeType(Types::MimeType group);

    Q_INVOKABLE void thumbnailChanged(QString path);
    Q_INVOKABLE int findIndex(QString path);
    Q_INVOKABLE void deleteItemByIndex(int index);
    bool removeRows(int row, int count, const QModelIndex &parent = QModelIndex()) override;

signals:
    void mimeTypeChanged();
    void countChanged();

private slots:
    void slotPopulate();

private:
    Types::MimeType m_mimetype;
    QList<MediaInfo> m_medias;
    QList<MediaInfo> m_selectData;
    bool isDeleteOne = false;
};

#endif // IMAGELOCATIONMODEL_H
