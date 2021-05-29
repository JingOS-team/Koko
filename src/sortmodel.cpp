/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "sortmodel.h"
#include "roles.h"
#include "types.h"

#include <QDebug>
#include <QIcon>
#include <QTimer>
#include <kimagecache.h>
#include <kio/copyjob.h>
#include <kio/previewjob.h>
#include <QProcess>
#include <QDBusConnection>
#include <QDBusReply>
#include <QDBusInterface>
#include <QDateTime>

#define SERVICE_NAME            "org.kde.haruna.qtdbus.playvideo"

using namespace Jungle;

SortModel::SortModel(QObject *parent)
    : QSortFilterProxyModel(parent)
    , m_screenshotSize(256, 256)
    , m_containMedias(false)
{
    setSortLocaleAware(true);
    sort(0);
    m_selectionModel = new QItemSelectionModel(this);

    m_previewTimer = new QTimer(this);
    m_previewTimer->setSingleShot(true);
    connect(m_previewTimer, &QTimer::timeout, this, &SortModel::delayedPreview);

    connect(this, &SortModel::rowsInserted, this, [this](const QModelIndex &parent, int first, int last) {
        Q_UNUSED(parent)
        for (int i = first; i <= last; i++) {
            if (Types::Media == data(index(i, 0, QModelIndex()), Roles::ItemTypeRole).toInt() && m_containMedias == false) {
                setContainMedias(true);
                break;
            }
        }
    });

    connect(this, &SortModel::sourceModelChanged, this, [this]() {
        if (!sourceModel()) {
            return;
        }
        for (int i = 0; i <= sourceModel()->rowCount(); i++) {
            if (Types::Media == sourceModel()->data(sourceModel()->index(i, 0, QModelIndex()), Roles::ItemTypeRole).toInt() && m_containMedias == false) {
                setContainMedias(true);
                break;
            }
        }
    });
    connect(this,&SortModel::selectedMediasChanged,this,&SortModel::onSelctMediasChange);

    // using the same cache of the engine, they index both by url
    m_imageCache =  MediaStorage::instance()->m_imageCache;

}

SortModel::~SortModel()
{
}

void SortModel::setContainMedias(bool value)
{
    m_containMedias = value;
    emit containMediasChanged();
}

QByteArray SortModel::sortRoleName() const
{
    int role = sortRole();
    return roleNames().value(role);
}

void SortModel::setSortRoleName(const QByteArray &name)
{
    if (!sourceModel()) {
        m_sortRoleName = name;
        return;
    }

    const QHash<int, QByteArray> roles = sourceModel()->roleNames();
    for (auto it = roles.begin(); it != roles.end(); it++) {
        if (it.value() == name) {
            setSortRole(it.key());
            return;
        }
    }
    qDebug() << "Sort role" << name << "not found";
}

QHash<int, QByteArray> SortModel::roleNames() const
{
    QHash<int, QByteArray> hash = sourceModel()->roleNames();
    hash.insert(Roles::SelectedRole, "selected");
    hash.insert(Roles::Thumbnail, "thumbnail");
    hash.insert(Roles::ThumbnailPixmap, "thumbnailPixmap");
    hash.insert(Roles::SourceIndex, "sourceIndex");
    return hash;
}

QVariant SortModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    switch (role) {
    case Roles::ThumbnailPixmap: {
        QString imageUrl = QString(/*"file://" + */ data(index, Roles::PreviewUrlRole).toString());
        QUrl thumbnailSource(imageUrl);
        KFileItem item(thumbnailSource, QString());
        QPixmap preview;

        if (m_imageCache->findPixmap(item.url().toString(), &preview)) {
            return "image://imageProvider/"+imageUrl;
        }

        m_previewTimer->start(100);
        const_cast<SortModel *>(this)->m_filesToPreview[item.url()] = QPersistentModelIndex(index);
        return "";
    }
    case Roles::SelectedRole: {
        return m_selectionModel->isSelected(index);
    }

    case Roles::Thumbnail: {
        QUrl thumbnailSource(QString(/*"file://" + */ data(index, Roles::PreviewUrlRole).toString()));

        KFileItem item(thumbnailSource, QString());
        QImage preview;

        if (m_imageCache->findImage(item.url().toString(), &preview)) {
            return preview;
        }
        m_previewTimer->start(100);
        const_cast<SortModel *>(this)->m_filesToPreview[item.url()] = QPersistentModelIndex(index);
        return {};
    }

    case Roles::SourceIndex: {
        return mapToSource(index).row();
    }
    }

    return QSortFilterProxyModel::sourceModel()->data(index, role);
}

void SortModel::deleteItemByModeIndex(int indexValue)
{
    int si = sourceIndex(indexValue);
//    beginRemoveRows({},indexValue,indexValue);
//    sourceModel()->removeRows(indexValue,1, {});
    qobject_cast<MediaMimeTypeModel*>(sourceModel())->dataRemoveRows(indexValue,1,si, {});
//    endRemoveRows();
}

void SortModel::deleteFileByModeIndex(QString path)
{
    if (path.startsWith("file://"))
        path = path.mid(7);
    bool isSUc = QFile::moveToTrash(path);
}

bool SortModel::lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const
{
    if (sourceModel()) {
        if ((sourceModel()->data(source_left, Roles::ItemTypeRole) == Types::Folder && sourceModel()->data(source_right, Roles::ItemTypeRole) == Types::Folder) ||
                (sourceModel()->data(source_left, Roles::ItemTypeRole) != Types::Folder && sourceModel()->data(source_right, Roles::ItemTypeRole) != Types::Folder)) {
            return QSortFilterProxyModel::lessThan(source_left, source_right);
        } else if (sourceModel()->data(source_left, Roles::ItemTypeRole) == Types::Folder && sourceModel()->data(source_right, Roles::ItemTypeRole) != Types::Folder) {
            return true;
        } else {
            return false;
        }
    }

    return false;
}

void SortModel::setSourceModel(QAbstractItemModel *sourceModel)
{
    QSortFilterProxyModel::setSourceModel(sourceModel);

    if (!m_sortRoleName.isEmpty()) {
        setSortRoleName(m_sortRoleName);
        m_sortRoleName.clear();
    }
}
int SortModel::rowCount(const QModelIndex &parent) const
{
    return sourceModel()->rowCount(parent);
}

bool SortModel::containMedias()
{
    return m_containMedias;
}

bool SortModel::hasSelectedMedias()
{
    return m_selectionModel->hasSelection();
}

void SortModel::setSelected(int indexValue)
{
    if (indexValue < 0)
        return;

    QModelIndex index = QSortFilterProxyModel::index(indexValue, 0);
    m_selectionModel->select(index, QItemSelectionModel::Select);
    emit dataChanged(index, index);
    emit selectedMediasChanged();
}

bool SortModel::isSelected(int indexValue)
{
    QModelIndex index = QSortFilterProxyModel::index(indexValue, 0);
    return m_selectionModel->isSelected(index);
}

bool SortModel::playVedio(QString url)
{
    QString kill = "killall -9 haruna";
    QProcess process(this);
    process.execute(kill);
    QStringList arguments;//用于传参数
    QString program = "/usr/bin/haruna";
    arguments << QString::number(0);
    arguments << QString::number(0);
    arguments << url;
    process.startDetached(program, arguments);
    return true;
}

void SortModel::toggleSelected(int indexValue)
{
    if (indexValue < 0)
        return;

    QModelIndex index = QSortFilterProxyModel::index(indexValue, 0);
    m_selectionModel->select(index, QItemSelectionModel::Toggle);

    bool isSelect = m_selectionModel->isSelected(index);
    QString mimeType = data(index,Roles::MimeTypeRole).toString();
    if (mimeType.startsWith("image")) {
        if (isSelect) {
            m_photoSelectCount++;
        } else {
            m_photoSelectCount --;
        }
        setPhotoSelectCount(m_photoSelectCount);
    } else if (mimeType.startsWith("video")) {
        if (isSelect) {
            m_videoSelectCount++;
        } else {
            m_videoSelectCount --;
        }
        setVideoSelectCount(m_videoSelectCount);
    }
    emit dataChanged(index, index);
    emit selectedMediasChanged();
}

void SortModel::clearSelections()
{
    if (m_selectionModel->hasSelection()) {
        QModelIndexList selectedIndex = m_selectionModel->selectedIndexes();
        m_selectionModel->clear();
        foreach (QModelIndex indexValue, selectedIndex) {
            emit dataChanged(indexValue, indexValue);
        }

        setPhotoSelectCount(0);
        setVideoSelectCount(0);
    }
    emit selectedMediasChanged();
}

void SortModel::selectAll()
{
    qint64 startTime = QDateTime::currentMSecsSinceEpoch();

    if (m_selectionModel->hasSelection()) {
        m_selectionModel->clear();
    }

//    if(m_selections.count() > 0){
//        m_selections.clear();
//    }
    QModelIndex topLeft;
    QModelIndex bottomRight;

    topLeft = index(0, 0, QModelIndex());
    bottomRight = index(rowCount() - 1, 0, QModelIndex());
    QItemSelection cselection(topLeft, bottomRight);

//    m_selections.select(index(0, 0, QModelIndex()), index(rowCount() - 1, 0, QModelIndex()));
    m_selectionModel->select(cselection, QItemSelectionModel::Select);

    emit dataChanged(index(0, 0, QModelIndex()), index(rowCount() - 1, 0, QModelIndex()));
    emit selectedMediasChanged();

    for (int row = 0; row < rowCount(); row++) {
        QString mimeType = data(index(row, 0, QModelIndex()),Roles::MimeTypeRole).toString();
        if (mimeType.startsWith("image")) {
            m_photoSelectCount++;
            setPhotoSelectCount(m_photoSelectCount);
            if (m_videoSelectCount > 1) {
                break;
            }
        } else if (mimeType.startsWith("video")) {
            m_videoSelectCount++;
            setVideoSelectCount(m_videoSelectCount);
            if (m_photoSelectCount > 1) {
                break;
            }
        }
    }
    qint64 fte = QDateTime::currentMSecsSinceEpoch();
}

void SortModel::deleteSelection()
{
    QList<QUrl> filesToDelete;

    foreach (QModelIndex index, m_selectionModel->selectedIndexes()) {
        QUrl url = data(index, Roles::MediaUrlRole).toUrl();
        filesToDelete << url ;
    }

    auto trashJob = KIO::trash(filesToDelete, KIO::HideProgressInfo);
    trashJob->exec();
    clearSelections();
}

int SortModel::updateSelectCount()
{
    int count = m_selectionModel->selectedIndexes().size();
    setCheckSelectCount(count);
    return count;
}

void SortModel::onSelctMediasChange()
{
    int count = m_selectionModel->selectedIndexes().size();
    setCheckSelectCount(count);
}

int SortModel::proxyIndex(const int &indexValue)
{
    if (sourceModel()) {
        return mapFromSource(sourceModel()->index(indexValue, 0, QModelIndex())).row();
    }
    return -1;
}

int SortModel::sourceIndex(const int &indexValue)
{
    return mapToSource(index(indexValue, 0, QModelIndex())).row();
}

QJsonArray SortModel::selectedMedias()
{
    QJsonArray arr;

    foreach (QModelIndex index, m_selectionModel->selectedIndexes()) {
        arr.push_back(QJsonValue(data(index, Roles::MediaUrlRole).toString()));
    }

    return arr;
}

void SortModel::delayedPreview()
{
    QHash<QUrl, QPersistentModelIndex>::const_iterator i = m_filesToPreview.constBegin();

    KFileItemList list;

    while (i != m_filesToPreview.constEnd()) {
        QUrl file = i.key();
        QPersistentModelIndex index = i.value();

        if (!m_previewJobs.contains(file) && file.isValid()) {
            list.append(KFileItem(file, QString(), 0));
            m_previewJobs.insert(file, QPersistentModelIndex(index));
        }

        ++i;
    }

    if (list.size() > 0) {
        QStringList plugins;
        plugins << KIO::PreviewJob::availablePlugins();
        KIO::PreviewJob *job = KIO::filePreview(list, m_screenshotSize, &plugins);
        job->setIgnoreMaximumSize(true);
        connect(job, &KIO::PreviewJob::gotPreview, this, &SortModel::showPreview);
    }

    m_filesToPreview.clear();
}

void SortModel::updatePreview(const QString &url, const int &indexValue)
{
    KFileItemList list;
    list.append(KFileItem(url, QString(), 0));
    m_previewJobs.insert(url, QPersistentModelIndex(QSortFilterProxyModel::index(indexValue, 0)));

    KIO::PreviewJob *job = KIO::filePreview(list, m_screenshotSize);
    job->setIgnoreMaximumSize(true);

    isUpdate = true;
    connect(job, &KIO::PreviewJob::gotPreview, this, &SortModel::showPreview);
}

void SortModel::showPreview(const KFileItem &item, const QPixmap &preview)
{
    QPersistentModelIndex index = m_previewJobs.value(item.url());
    m_previewJobs.remove(item.url());

    if (!index.isValid()) {
        return;
    }
    m_imageCache->insertPixmap(item.url().toString(), preview);
    emit dataChanged(index, index);
}

void SortModel::previewFailed(const KFileItem &item)
{
    // Use folder image instead of displaying nothing then thumbnail generation fails
    QPersistentModelIndex index = m_previewJobs.value(item.url());
    m_previewJobs.remove(item.url());

    if (!index.isValid()) {
        return;
    }

    m_imageCache->insertImage(item.url().toString(), QIcon::fromTheme("folder").pixmap(m_screenshotSize).toImage());
    Q_EMIT dataChanged(index, index);
}


