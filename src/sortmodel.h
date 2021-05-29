/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef JUNGLE_SORTMODEL_H
#define JUNGLE_SORTMODEL_H

#include <QItemSelectionModel>
#include <QJsonArray>
#include <QSize>
#include <QSortFilterProxyModel>
#include <QVariant>
#include <kdirmodel.h>
#include <kimagecache.h>
#include <kshareddatacache.h>
#include "mediamimetypemodel.h"
#include <QItemSelection>

namespace Jungle
{
class SortModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QByteArray sortRoleName READ sortRoleName WRITE setSortRoleName)
    Q_PROPERTY(bool containMedias READ containMedias WRITE setContainMedias NOTIFY containMediasChanged)
    Q_PROPERTY(bool hasSelectedMedias READ hasSelectedMedias NOTIFY selectedMediasChanged)
    Q_PROPERTY(int checkSelectCount READ checkSelectCount WRITE setCheckSelectCount NOTIFY checkSelectCountChanged)
    Q_PROPERTY(int photoSelectCount READ photoSelectCount WRITE setPhotoSelectCount NOTIFY photoSelectCountChanged)
    Q_PROPERTY(int videoSelectCount READ videoSelectCount WRITE setVideoSelectCount NOTIFY videoSelectCountChanged)

public:
    explicit SortModel(QObject *parent = 0);
    virtual ~SortModel();

    QByteArray sortRoleName() const;
    void setSortRoleName(const QByteArray &name);

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;
    bool lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const override;

    void setSourceModel(QAbstractItemModel *sourceModel) override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    bool containMedias();
    bool hasSelectedMedias();

    int checkSelectCount() {
        return m_checkSelectCount;
    }
    void setCheckSelectCount(int count) {
        m_checkSelectCount = count;
        emit checkSelectCountChanged();
    }
    int photoSelectCount() {
        return m_photoSelectCount;
    }
    void setPhotoSelectCount(int count) {
        m_photoSelectCount = count;
        emit photoSelectCountChanged();
    }
    int videoSelectCount() {
        return m_videoSelectCount;
    }
    void setVideoSelectCount(int count) {
        m_videoSelectCount = count;
        emit videoSelectCountChanged();
    }

    Q_INVOKABLE void deleteItemByModeIndex(int index);
    Q_INVOKABLE void deleteFileByModeIndex(QString path);

    Q_INVOKABLE void setSelected(int indexValue);
    Q_INVOKABLE void toggleSelected(int indexValue);
    Q_INVOKABLE bool isSelected(int indexValue);

    Q_INVOKABLE bool playVedio(QString url);

    Q_INVOKABLE void clearSelections();
    Q_INVOKABLE void selectAll();
    Q_INVOKABLE void deleteSelection();
    Q_INVOKABLE int proxyIndex(const int &indexValue);
    Q_INVOKABLE int sourceIndex(const int &indexValue);
    Q_INVOKABLE QJsonArray selectedMedias();
    Q_INVOKABLE void updatePreview(const QString &url, const int &indexValue);
    Q_INVOKABLE int updateSelectCount();

protected Q_SLOTS:
    void setContainMedias(bool);
    void showPreview(const KFileItem &item, const QPixmap &preview);
    void previewFailed(const KFileItem &item);
    void delayedPreview();
    void onSelctMediasChange();

signals:
    void containMediasChanged();
    void selectedMediasChanged();
    void checkSelectCountChanged();
    void photoSelectCountChanged();
    void videoSelectCountChanged();

private:
    QByteArray m_sortRoleName;
    QItemSelectionModel *m_selectionModel;
    QItemSelection m_selections;
    QTimer *m_previewTimer;
    QHash<QUrl, QPersistentModelIndex> m_filesToPreview;
    QSize m_screenshotSize;
    QHash<QUrl, QPersistentModelIndex> m_previewJobs;
    int m_checkSelectCount = 0;
    int m_photoSelectCount = 0;
    int m_videoSelectCount = 0;
    KImageCache *m_imageCache;
    bool m_containMedias;
    bool isUpdate;
};
}

#endif // JUNGLE_SORTMODEL_H
