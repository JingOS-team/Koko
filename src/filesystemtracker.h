/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef FILESYSTEMTRACKER_H
#define FILESYSTEMTRACKER_H

#include <QObject>
#include <QSet>
#include "types.h"

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

    void setupDb();

signals:
    void mediaAdded(const QString &filePath, Types::MimeType type);
    void mediaRemoved(const QString &filePath);
    void initialScanComplete();
    void subFolderChanged();

protected:
    void removeFile(const QString &filePath);
    void addContent(const QString &filePath, Types::MimeType type);

private slots:
    void slotNewFiles(const QStringList &files);
    void slotMediaResult(const QString &filePath, Types::MimeType type);
    void slotFetchFinished();

private:
    QString m_folder;
    QString m_subFolder;
    QSet<QString> m_filePaths;
};

#endif
