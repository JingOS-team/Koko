/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2021 Zhang He Gang <zhanghegang@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef MEDIAMIMETYPEMODEL_H
#define MEDIAMIMETYPEMODEL_H

#include <QAbstractListModel>
#include <QStringList>

#include "types.h"
#include "mediastorage.h"
#include <KSharedConfig>
#include <KConfigGroup>
#include <KConfigWatcher>
#define FORMAT24H "HH:mm:ss"
#define FORMAT12H "h:mm:ss ap"
#include <kio/copyjob.h>
#include <kio/previewjob.h>

class MediaMimeTypeModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(Types::MimeType mimeType READ mimeType WRITE setMimeType NOTIFY mimeTypeChanged)
    Q_PROPERTY(int loadStatus READ loadStatus NOTIFY loadStatusChanged)
    Q_PROPERTY(bool deleteFilesStatus READ deleteFilesStatus WRITE setDeleteFilesStatus NOTIFY deleteFilesStatusChanged)

public:
    explicit MediaMimeTypeModel(QObject *parent = 0);

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int dataRequestCount = 0;

    Types::MimeType mimeType() const;
    int loadStatus(){
        return m_loadStatus;
    }
    bool deleteFilesStatus();
    void setDeleteFilesStatus(bool currentStatus);
    void setMimeType(Types::MimeType group);

    Q_INVOKABLE void thumbnailChanged(QString path);
    Q_INVOKABLE int findIndex(QString path);
    Q_INVOKABLE void deleteItemByIndex(int index, int pIndex);
    Q_INVOKABLE bool is24HourFormat() const;
    void delayedPreview();
    bool dataRemoveRows(int row, int count, int dIndex, const QModelIndex &parent = QModelIndex());

signals:
    void mimeTypeChanged();
    void countChanged();
    void loadStatusChanged();
    void deleteFilesStatusChanged();
    void errorInfoTip(QString errorText);

private slots:
    void slotPopulate();
    void showPreview(const KFileItem &item, const QPixmap &preview);

public slots:
    void onRemoveData(const QModelIndex &parent, int first, int last);

private:
    Types::MimeType m_mimetype;
    QList<MediaInfo> m_medias;
    QList<MediaInfo> m_selectData;
    bool isDeleteOne = false;
    int m_loadStatus = -1;
    KConfigWatcher::Ptr m_localeConfigWatcher;
    KSharedConfig::Ptr m_localeConfig;
    QHash<QUrl, QPersistentModelIndex> m_filesToPreview;
    QHash<QUrl, QPersistentModelIndex> m_previewJobs;
    QSize m_screenshotSize;
    bool m_deleteFilesStatus = true;
    QString m_thumbFilePath = QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation) + "/video_thumb";

};

#endif // IMAGELOCATIONMODEL_H
