/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2021 Zhang He Gang <zhanghegang@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef FILESYSTEMTRACKER_H
#define FILESYSTEMTRACKER_H

#include <QObject>
#include <QSet>
#include "types.h"
#include <QSqlResult>
#include <QTimer>
#include "mediastorage.h"

class FileSystemTracker : public QObject
{
    Q_OBJECT

public:
    explicit FileSystemTracker(QObject *parent = 0);
    virtual ~FileSystemTracker();

    void setFolder(const QString &folder);
    QString folder() const;

    void setSubFolder(const QString &folder);
    void reindexSubFolder();
    void fileContentChanaged(const QString &filePath);
    void updateCache();

    void setupDb();

signals:
    void mediaAdded(const QString &filePath, Types::MimeType type);
    void mediaRemoved(const QList<QString> &filePaths);
    void initialScanComplete();
    void subFolderChanged();

protected:
    void removeFile(const QString &filePath);
    void removeFile(const QList<QString> &filePaths);
    void addContent(const QString &filePath, Types::MimeType type);

private slots:
    void slotNewFiles(const QStringList &files);
    void slotMediaResult(const QString &filePath, Types::MimeType type);
    void slotFetchFinished();
    void delayUpdateDb();

private:
    QString m_folder;
    QString m_subFolder;
    QSet<QString> m_filePaths;
    QTimer *m_videoChangedTimer;
    QSet<QString> m_currentVideoPaths;
    QSet<QString> m_neetUpdateVideoPaths;
    QHash<QString,MediaInfo> m_allMedias;
    bool m_initRequest = true;

};

#endif
