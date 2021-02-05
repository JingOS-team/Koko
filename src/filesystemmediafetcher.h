/*
 * SPDX-FileCopyrightText: (C) 2012-2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef FILESYSTEMMEDIAFETCHER_H
#define FILESYSTEMMEDIAFETCHER_H

#include "jinggallery_export.h"
#include <QObject>
#include "types.h"

class JINGGALLERY_EXPORT FileSystemMediaFetcher : public QObject
{
    Q_OBJECT
public:
    explicit FileSystemMediaFetcher(const QString &folder, QObject *parent = 0);
    void fetch();

signals:
    void mediaResult(const QString &filePath, Types::MimeType type);
    void finished();

private slots:
    void slotProcess();

private:
    QString m_folder;
};

#endif // FileSystemMediaFetcher_H
