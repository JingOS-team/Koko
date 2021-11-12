/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) Zhang He Gang <zhanghegang@jingos.com>
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
#include <KLocalizedString>
#include <QUrl>

#define WEEKDAY_SEC  24 * 3600 * 7
#define DAY_SEC  24 * 3600

MediaMimeTypeModel::MediaMimeTypeModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_mimetype(Types::MimeType::All)
    , m_screenshotSize(256,256)
{
    m_localeConfig = KSharedConfig::openConfig(QStringLiteral("kdeglobals"), KConfig::FullConfig);
    m_localeConfigWatcher = KConfigWatcher::create(m_localeConfig);

    // watch for changes to locale config, to update 12/24 hour time
    bool dirWatcherConnect = connect(m_localeConfigWatcher.data(), &KConfigWatcher::configChanged,
            this, [this](const KConfigGroup &group, const QByteArrayList &names){
        if (group.name() == "Locale") {
            slotPopulate();
        }
    });

    connect(MediaStorage::instance(), SIGNAL(storageModified()), this, SLOT(slotPopulate()));
    connect(this, &QAbstractItemModel::rowsInserted, this, &MediaMimeTypeModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &MediaMimeTypeModel::onRemoveData);
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

void MediaMimeTypeModel::deleteItemByIndex(int index, int pIndex)
{
    MediaInfo mi = m_medias.at(index);

    isDeleteOne = true;
    bool dResult = false;
    if (mi.path.contains("%")) {
        if (mi.path.startsWith("file://"))
            mi.path = mi.path.mid(7);
        dResult = QFile::moveToTrash(mi.path);
    } else {
        auto fileTrashJob = KIO::trash(QUrl::fromUserInput(mi.path), KIO::HideProgressInfo);
        QObject::connect(fileTrashJob, &KJob::result, [=] (KJob *job) {
                if (job->error()) {
                    QString errorContent = job->errorString();
                    qDebug() << "deleteItemByIndex TRAASH ERROR : " << errorContent;
                    emit errorInfoTip(errorContent);
                }
         });
        dResult = fileTrashJob->exec();
    }
    if(dResult){
        beginRemoveRows({},pIndex,pIndex);
        m_medias.removeAt(index);
        endRemoveRows();
        emit countChanged();
    } else {
        setDeleteFilesStatus(false);
    }
}

bool MediaMimeTypeModel::is24HourFormat() const
{
    KSharedConfig::Ptr  m_localeConfig = KSharedConfig::openConfig(QStringLiteral("kdeglobals"), KConfig::SimpleConfig);
    KConfigGroup  m_localeSettings = KConfigGroup(m_localeConfig, "Locale");

    QString m_currentLocalTime  =  m_localeSettings.readEntry("TimeFormat", QStringLiteral(FORMAT24H));
    return (m_currentLocalTime == FORMAT24H) ;
}

void MediaMimeTypeModel::slotPopulate()
{
    if (!isDeleteOne) {
        beginResetModel();
        m_medias = MediaStorage::instance()->mediasForMimeType(m_mimetype);
        endResetModel();
        m_loadStatus = 1;
        emit loadStatusChanged();
    }
    isDeleteOne = false;
}

void MediaMimeTypeModel::onRemoveData(const QModelIndex &parent, int first, int last)
{
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
    hash.insert(Roles::MediaTypeRole, "mediaType");
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
        const_cast<MediaMimeTypeModel *>(this) -> dataRequestCount ++ ;
        QVariant previewVariant;
        if (m_medias.at(indexValue).mimeType == Types::MimeType::Image)
        {
            previewVariant = m_medias.at(indexValue).path;
        } else {
            QDir dir(m_thumbFilePath + (m_medias.at(indexValue).path.mid(7)));
            if (dir.exists("preview.jpg")) {
                previewVariant = QString("file://" + dir.absoluteFilePath("preview.jpg"));
            } else {
                const_cast<MediaMimeTypeModel *>(this) -> m_filesToPreview[m_medias.at(indexValue).path] = QPersistentModelIndex(index);
                previewVariant = "";//m_medias.at(indexValue).path;
            }
        }
        if(const_cast<MediaMimeTypeModel *>(this) -> dataRequestCount == m_medias.size()) {
            const_cast<MediaMimeTypeModel *>(this) -> delayedPreview();
            const_cast<MediaMimeTypeModel *>(this) -> dataRequestCount = 0;
        }
        return previewVariant;
    }

    case Roles::DurationRole:
        return m_medias.at(indexValue).duration;
    case Roles::DateTimeRole:
    {
        QString dateString;
        QDateTime currentDate =  QDateTime::currentDateTime();
        QDateTime qdate = m_medias.at(indexValue).dateTime;
        int dayoffset = qdate.daysTo(currentDate);
        bool getLocalTimeIs24 = is24HourFormat();
        QString apStr = qdate.toString("AP");
        QString currentDayString;
        if(apStr == "AM" || apStr == "PM"){
            currentDayString = getLocalTimeIs24 ? "hh:mm" : (QLatin1String("hh:mm") + " AP");
        } else {
            currentDayString = getLocalTimeIs24 ? "hh:mm" : "AP " +(QLatin1String("hh:mm"));
        }

        if (dayoffset <= 7) {
            if (dayoffset < 1) {
                dateString = qdate.toString(currentDayString);
            } else if (dayoffset == 1) {
                dateString = i18n("yestday ")+ qdate.toString(currentDayString);
            } else {
                //qdate.date().dayOfWeek() +
                dateString =  qdate.toString("dddd " + currentDayString);
            }
        } else {
            int currentYear = currentDate.date().year();
            int dataYear = qdate.date().year();
            if (currentYear == dataYear) {
                dateString = qdate.toString("MM-dd " + currentDayString);
            } else {
                dateString = qdate.toString("yyyy-MM-dd " + currentDayString);

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
    case Roles::MediaTypeRole: {
        return m_medias.at(indexValue).mimeType;
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

void MediaMimeTypeModel::delayedPreview()
{
    if(m_filesToPreview.size() <= 0) {
        return;
    }
    QHash<QUrl, QPersistentModelIndex>::const_iterator i = m_filesToPreview.constBegin();

    KFileItemList list;

    while (i != m_filesToPreview.constEnd()) {
        QUrl file = i.key();
        QPersistentModelIndex index = i.value();

        if (!m_previewJobs.contains(file) && file.isValid()) {
            int angle = MediaStorage::instance()->getVideoAngle(file.toString());
            list.append(KFileItem(file, QString(), angle));
            m_previewJobs.insert(file, QPersistentModelIndex(index));
        }

        ++i;
    }

    if (list.size() > 0) {
        QStringList plugins;
        plugins << KIO::PreviewJob::availablePlugins();
        KIO::PreviewJob *job = KIO::filePreview(list, m_screenshotSize, &plugins);
        job->setIgnoreMaximumSize(true);
        connect(job, &KIO::PreviewJob::gotPreview, this, &MediaMimeTypeModel::showPreview);
    }

    m_filesToPreview.clear();
}

void MediaMimeTypeModel::showPreview(const KFileItem &item, const QPixmap &preview)
{
    QPersistentModelIndex index = m_previewJobs.value(item.url());
    QDir dir(m_thumbFilePath + item.localPath());
    dir.mkpath(dir.absolutePath());

    if(item.mode() > 0){
        QTransform tranform;
        tranform.rotate(item.mode());
        QPixmap transPix = QPixmap(preview.transformed(tranform,Qt::SmoothTransformation));
        transPix.save(dir.absolutePath()+ "/preview.jpg", "JPG");

    } else {
        preview.save(dir.absolutePath()+ "/preview.jpg", "JPG");
    }
    emit dataChanged(index, index);
}


bool MediaMimeTypeModel::dataRemoveRows(int row, int count, int dIndex, const QModelIndex &parent)
{
    for (int i = row; i < count+row; i++)
    {
        deleteItemByIndex(i,dIndex);
    }
    return true;
}

void MediaMimeTypeModel::setMimeType(Types::MimeType mimeType)
{
    beginResetModel();
    m_mimetype = mimeType;
    m_medias = MediaStorage::instance()->mediasForMimeType(m_mimetype);
    endResetModel();

    emit mimeTypeChanged();
}

Types::MimeType MediaMimeTypeModel::mimeType() const
{
    return m_mimetype;
}

bool MediaMimeTypeModel::deleteFilesStatus()
{
    return m_deleteFilesStatus;
}
void MediaMimeTypeModel::setDeleteFilesStatus(bool currentStatus)
{
    m_deleteFilesStatus = currentStatus;
    emit deleteFilesStatusChanged();
}
