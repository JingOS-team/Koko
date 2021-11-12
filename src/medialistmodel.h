/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2021 Zhang He Gang <zhanghegang@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#ifndef MEDIALISTMODEL_H
#define MEDIALISTMODEL_H

#include <QAbstractListModel>
#include "types.h"
#include "mediastorage.h"

class MediaListModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(Types::LocationGroup locationGroup READ locationGroup WRITE setLocationGroup NOTIFY locationGroupChanged)
    Q_PROPERTY(Types::TimeGroup timeGroup READ timeGroup WRITE setTimeGroup NOTIFY timeGroupChanged)
    Q_PROPERTY(Types::MimeType mimeType READ mimeType WRITE setMimeType NOTIFY mimeTypeChanged)
    Q_PROPERTY(Types::QueryType queryType READ queryType WRITE setQueryType)
    Q_PROPERTY(QByteArray query READ query WRITE setQuery NOTIFY queryChanged)

public:
    explicit MediaListModel(QObject *parent = 0);
    ~MediaListModel();

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    Types::MimeType mimeType() const;
    void setMimeType(const Types::MimeType &mimeType);

    Types::LocationGroup locationGroup() const;
    void setLocationGroup(const Types::LocationGroup &group);

    Types::TimeGroup timeGroup() const;
    void setTimeGroup(const Types::TimeGroup &group);

    Types::QueryType queryType() const;
    void setQueryType(const Types::QueryType &type);

    QByteArray query() const;
    void setQuery(const QByteArray &statement);

    Q_INVOKABLE QByteArray queryForIndex(const int &index);

    void slotLocationGroupChanged();
    void slotTimeGroupChanged();
    void slotResetModel();
    void slotMimeTypeChanged();

Q_SIGNALS:
    void mimeTypeChanged();
    void mediaListChanged();
    void locationGroupChanged();
    void timeGroupChanged();
    void queryChanged();

private:
    QList<MediaInfo> m_medias;
    Types::LocationGroup m_locationGroup;
    Types::TimeGroup m_timeGroup;
    Types::QueryType m_queryType;
    Types::MimeType m_mimeType;
    QByteArray m_query;

    QList<QPair<QByteArray, QString>> m_times;
    QList<QPair<QByteArray, QString>> m_locations;
    QString m_thumbFilePath = QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation) + "/video_thumb";

};

#endif
